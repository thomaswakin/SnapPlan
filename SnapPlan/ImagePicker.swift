//
//  ImagePicker.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/18/23.
//

import SwiftUI
import CoreData

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var showStickyNoteView: Bool // Add this binding
    @Binding var selectedTask: SnapPlanTask?
    @Environment(\.presentationMode) private var presentationMode
    var createTaskClosure: (UIImage) -> Void
    var sourceType: UIImagePickerController.SourceType
    var viewContext: NSManagedObjectContext // Add this line
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, createTaskClosure: createTaskClosure) // Pass the closure to the Coordinator
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("IP:makeUIViewController:")
        let picker = UIImagePickerController()
        // Check if the sourceType is camera and if the camera is available
        if sourceType == .camera && UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            // If the camera is not available or the sourceType is not camera, attempt to use the photo library
            picker.sourceType = .photoLibrary
        } else {
            print("Error: Camera and Photo library are not available.")
            showStickyNoteView = true // Show the sticky note view
            presentationMode.wrappedValue.dismiss() // Dismiss the picker
            return picker
        }
        picker.delegate = context.coordinator // Set the delegate to the Coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        print("ImagePicker:updateUIViewController")
        
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var createTaskClosure: (UIImage) -> Void // Add this property
        let parent: ImagePicker

        init(_ parent: ImagePicker, createTaskClosure: @escaping (UIImage) -> Void) { // Modify the initializer
            self.parent = parent
            self.createTaskClosure = createTaskClosure
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                let imageData = image.pngData() // Convert the image to data
                // Create a new task with the image data
                let newTask = SnapPlanTask(context: parent.viewContext)
                newTask.id = UUID()
                newTask.rawPhotoData = imageData // Set the rawPhotoData attribute
                newTask.state = "Todo" // Set the default state
                newTask.dueDate = Date() // Set the default due date
                // Set the selected task to the new task
                parent.selectedTask = newTask
                // Save the context
                do {
                    try parent.viewContext.save()
                } catch {
                    print("Failed to save new task:", error)
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

    }

}
