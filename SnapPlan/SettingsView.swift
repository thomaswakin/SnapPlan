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
    let dueDateDisplayOptions = ["Show Due Dates", "Show Days Until Due"]
    
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
                        .onDelete(perform: deleteFilter)
                        .onMove(perform: moveFilter) 
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
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
            })
        }
    }
    
    private func moveFilter(from source: IndexSet, to destination: Int) {
        var revisedItems: [FilterEntity] = filterEntities.map{$0}
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
}
