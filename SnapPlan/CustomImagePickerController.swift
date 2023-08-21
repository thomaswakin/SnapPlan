//
//  CustomImagePickerController.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/20/23.
//

import Foundation
import UIKit

class CustomImagePickerController: UIImagePickerController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if sourceType == .camera {
            showsCameraControls = false
            let overlayView = createCameraOverlay()
            cameraOverlayView = overlayView
        }
    }
    
    func createCameraOverlay() -> UIView {
        let overlayView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        let photoLibraryButton = UIButton(frame: CGRect(x: 20, y: UIScreen.main.bounds.height - 60, width: 40, height: 40))
        photoLibraryButton.setImage(UIImage(systemName: "photo.fill"), for: .normal)
        photoLibraryButton.addTarget(self, action: #selector(switchToPhotoLibrary), for: .touchUpInside)
        overlayView.addSubview(photoLibraryButton)
        return overlayView
    }
    
    @objc func switchToPhotoLibrary() {
        sourceType = .photoLibrary
        cameraOverlayView = nil
        showsCameraControls = true
    }
}
