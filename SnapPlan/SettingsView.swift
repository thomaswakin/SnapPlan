//
//  SettingsView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI
import CoreData

class Settings: ObservableObject {
    static let shared = Settings()
    @Published var dueDateDisplay: Int {
        didSet {
            NSUbiquitousKeyValueStore.default.set(Int64(dueDateDisplay), forKey: "dueDateDisplay")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    init() {
        self.dueDateDisplay = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "dueDateDisplay"))
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: FilterEntity.entity(), sortDescriptors: [])
    private var filterEntities: FetchedResults<FilterEntity>
    
    @Environment(\.presentationMode) var presentationMode
    @State private var newFilter: String = ""
    @State private var isEditingFilters: Bool = false
    @State private var showingDeleteAlert = false  // New State variable
    
    let dueDateDisplayOptions = ["Show Due Dates", "Show Days Until Due"]
        
    private func addDefaultTodayFilter() {
        let newFilterEntity = FilterEntity(context: viewContext)
        newFilterEntity.name = "Today"
        newFilterEntity.order = Int16(filterEntities.count)
        do {
            try viewContext.save()
        } catch {
            print("Failed to save new filter:", error)
        }
    }
    
    private func addDefaultHomeworkFilter() {
        let newFilterEntity = FilterEntity(context: viewContext)
        newFilterEntity.name = "Homework"
        newFilterEntity.order = Int16(filterEntities.count)
        do {
            try viewContext.save()
        } catch {
            print("Failed to save new filter:", error)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Due")) {
                    Picker("Display", selection: $settings.dueDateDisplay) {
                        ForEach(0 ..< dueDateDisplayOptions.count, id: \.self) {
                            Text(self.dueDateDisplayOptions[$0])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Moved this section inside the Form
                Section(header: Text("Filters")) {
                    if isEditingFilters {
                        ForEach(filterEntities, id: \.self) { filterEntity in
                            Text(filterEntity.name ?? "")
                        }
                        .onMove(perform: moveFilter)
                        .onDelete(perform: deleteFilter)
                    } else {
                        ForEach(filterEntities, id: \.self) { filterEntity in
                            Text(filterEntity.name ?? "")
                        }
                    }

                    if isEditingFilters {
                        HStack {
                            TextField("New Filter", text: $newFilter)
                            Button("Add") {
                                addFilter()
                            }
                        }
                    }
                }
                // Manually create an "Edit" button
                Button(isEditingFilters ? "Done" : "Edit Filters") {
                    isEditingFilters.toggle()
                }
                
                //Section to delete tasks
                Section {
                    Button("Delete Done Tasks") {
                        showingDeleteAlert = true
                    }
                    .alert(isPresented: $showingDeleteAlert) {
                        Alert(title: Text("Are you sure you want to delete all Done Tasks?"),
                              primaryButton: .destructive(Text("Yes")) {
                                  // Logic to delete all Done tasks
                                  deleteDoneTasks()
                              },
                              secondaryButton: .cancel())
                    }
                }

            }
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
            })
        }
        .onAppear {
            if UserDefaults.standard.object(forKey: "isFirstRun") == nil {
                addDefaultTodayFilter()
                addDefaultHomeworkFilter()
                UserDefaults.standard.set(false, forKey: "isFirstRun")
            }
        }
    }
    
    private func moveFilter(from source: IndexSet, to destination: Int) {
        var revisedItems: [FilterEntity] = filterEntities.map { $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)
        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].order = Int16(reverseIndex)
        }
        try? viewContext.save()
    }
    
    private func addFilter() {
        if !newFilter.isEmpty {
            let newFilterEntity = FilterEntity(context: viewContext)
            newFilterEntity.name = newFilter
            newFilterEntity.order = Int16(filterEntities.count)
            newFilter = ""
            try? viewContext.save()
        }
    }

    private func deleteFilter(at offsets: IndexSet) {
        for index in offsets {
            let filterEntity = filterEntities[index]
            viewContext.delete(filterEntity)
        }
        try? viewContext.save()
    }
    
    private func deleteDoneTasks() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SnapPlanTask")
        fetchRequest.predicate = NSPredicate(format: "state == %@", "Done")
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(batchDeleteRequest)
            try viewContext.save()
            NotificationCenter.default.post(name: NSNotification.Name("refreshTasks"), object: nil)
        } catch {
            print("Failed to delete Done tasks: \(error)")
        }
    }
}



