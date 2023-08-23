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
    @State private var showingStickyNote: Bool = true
    @State private var uiImage: UIImage? = nil
    
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width - 10
        if let task = task {
            let imageData = task.rawPhotoData
            //let uiImage = imageData.flatMap { UIImage(data: $0) }
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
                } else {
                    StickyNoteView(color: TaskFormatter.shared.stateColor(task: task))
                        .frame(height: UIScreen.main.bounds.height / 2)
                }
                HStack(alignment: .top) {
                    Button(action: {
                        rotationAngle += .degrees(-90)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    Button(action: {
                        rotationAngle += .degrees(90)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    Spacer()
                    Button(action: {
                        sourceType = .camera
                        isImagePickerPresented = true
                    }) {
                        Image(systemName: "camera")
                    }
                    Button(action: {
                        sourceType = .photoLibrary
                        isImagePickerPresented = true
                    }) {
                        Image(systemName: "photo")
                    }                }
                .padding(.top, 10)
               
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
                        if let uiImage = uiImage {
                            let rotatedImage = uiImage.rotate(radians: rotationAngle.radians)
                            task.rawPhotoData = rotatedImage?.jpegData(compressionQuality: 1.0)
                        }
                        saveContext()
                        self.task = nil // Dismiss the view
                    }
                }
                .padding(.bottom)
            }
            //.onTapGesture {
            //    hideKeyboard()
            //}
            .onAppear {
                // Initialize the state
                uiImage = task.rawPhotoData.flatMap { UIImage(data: $0) }
                selectedState = task.state ?? "Todo"
                selectedDueDate = task.dueDate as Date? ?? Date()
                editedNote = task.note ?? ""
            }
            .frame(width: screenWidth)
            .onDisappear {
                forceRedraw.toggle()
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $uiImage, showStickyNoteView: $showingStickyNote, selectedTask: $task, sourceType: sourceType, viewContext: viewContext)
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


