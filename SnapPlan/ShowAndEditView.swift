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
    
    @State private var rotationAngle: Angle = .degrees(0)
    @State private var isImagePickerPresented: Bool = false
    @State private var forceRedraw: Bool = false
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width - 10
        if let task = task {
            let imageData = task.rawPhotoData
            let uiImage = imageData.flatMap { UIImage(data: $0) }
            VStack {
                // Display the task's image
                if let uiImage = uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: UIScreen.main.bounds.height / 2)
                        .rotationEffect(rotationAngle)
                        .gesture(RotationGesture().onChanged { angle in
                            rotationAngle = angle
                        })
                        .onTapGesture {
                            isImagePickerPresented = true
                        }
                } else {
                    StickyNoteView(color: TaskFormatter.shared.stateColor(task: task))
                        .frame(height: UIScreen.main.bounds.height / 2)
                        .onTapGesture {
                            isImagePickerPresented = true
                        }
                }
                HStack {
                    Button("Rotate Left") {
                        rotationAngle += .degrees(-90)
                    }
                    Spacer()
                    Button("Rotate Right") {
                        rotationAngle += .degrees(90)
                    }
                }
                Spacer()
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
                TextEditor(text: $editedNote)
                    .frame(height: UIScreen.main.bounds.height / 5)
                    .padding()
                    .border(Color.gray, width: 1)
                    .onChange(of: editedNote) { newValue in
                        task.note = newValue
                        saveContext()
                    }

                HStack {
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
                .padding(.bottom)
            }
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                // Initialize the state
                selectedState = task.state ?? "Todo"
                selectedDueDate = task.dueDate as Date? ?? Date()
                editedNote = task.note ?? ""
            }
            .frame(width: screenWidth)
            .sheet(item: $task) { task in
                ShowAndEditView(task: $task)
                    .onDisappear {
                        forceRedraw.toggle()
                        //viewModel.fetchTasks()
                        //viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                    }
            }
        } else {
            Text("No Task Selected")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveContext() {
        print("ShowAndEditView:saveContext")
        do {
            try viewContext.save()
        } catch {
            print("Failed to save changes:", error)
        }
    }
}
