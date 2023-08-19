//
//  ShowAndEditView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI
import CoreData

struct ShowAndEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var task: SnapPlanTask?
    
    @State private var selectedState: String = "Todo"
    @State private var selectedDueDate: Date = Date()
    @State private var editedNote: String = ""
    
    var body: some View {
        if let task = task,
           let imageData = task.rawPhotoData {
                let uiImage = UIImage(data: imageData) // Convert the data to UIImage
                VStack {
                    // Display the task's image
                    if let uiImage = uiImage {
                        Image(uiImage: uiImage)
                    }
                    // State Picker
                    Picker("State", selection: $selectedState) {
                        Text("Todo").tag("Todo")
                        Text("Doing").tag("Doing")
                        Text("Done").tag("Done")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedState) { newValue in
                        task.state = newValue
                        saveContext()
                    }
                    
                    // Due Date Picker
                    DatePicker("Due Date", selection: $selectedDueDate, displayedComponents: .date)
                        .onChange(of: selectedDueDate) { newValue in
                            task.dueDate = newValue
                            saveContext()
                        }
                    
                    // Note Editor
                    TextField("Note", text: $editedNote)
                        .onChange(of: editedNote) { newValue in
                            task.note = newValue
                            saveContext()
                        }
                    
                    // Delete Button
                    Button("Delete") {
                        viewContext.delete(task)
                        saveContext()
                        self.task = nil // Dismiss the view
                    }
                    .foregroundColor(.red)
                    
                    // Done Button
                    Button("Done") {
                        saveContext()
                        self.task = nil // Dismiss the view
                    }
                }
                .onAppear {
                    // Initialize the state
                    selectedState = task.state ?? "Todo"
                    selectedDueDate = task.dueDate as Date? ?? Date()
                    editedNote = task.note ?? ""
                }
        } else {
            Text("No Task Selected")
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save changes:", error)
        }
    }
}
