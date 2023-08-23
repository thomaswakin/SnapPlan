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
    @Binding var isEditing: Bool
    @Environment(\.presentationMode) private var presentationMode
    //var createTaskClosure: (UIImage) -> Void
    var sourceType: UIImagePickerController.SourceType
    var viewContext: NSManagedObjectContext 

    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self) // Pass the closure to the Coordinator
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("IP:makeUIViewController:")
        let picker = CustomImagePickerController()
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
        print("MakeUIViewController:return:", picker.sourceType)
        picker.delegate = context.coordinator // Set the delegate to the Coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        print("ImagePicker:updateUIViewController")
        
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        //var createTaskClosure: (UIImage) -> Void // Add this property
        let parent: ImagePicker

        init(_ parent: ImagePicker) { // Modify the initializer
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            print("imagePickerController")
            if let image = info[.originalImage] as? UIImage {
                print("imagePickerController:let image")
                let fixedImage = image.fixOrientation()
                let imageData = fixedImage.pngData() // Convert the image to data
                // Create a new task with the image data
                
                if parent.isEditing {
                    // Update the existing task
                    parent.selectedTask?.rawPhotoData = imageData
                } else {
                    // Create a new task
                    let newTask = SnapPlanTask(context: parent.viewContext)
                    newTask.id = UUID()
                    newTask.rawPhotoData = imageData
                    newTask.state = "Todo"
                    newTask.dueDate = Date()
                    parent.selectedTask = newTask
                }
                
                // Save the context
                do {
                    print("imagePickerController:parent.viewContext.save")
                    try parent.viewContext.save()
                } catch {
                    print("Failed to save new task:", error)
                }
            }
            print("imagePIckerController:presentationmode.dismiss")
            parent.presentationMode.wrappedValue.dismiss()
        }

    }

}



extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    func rotate(radians: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.rotate(by: radians)
        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
