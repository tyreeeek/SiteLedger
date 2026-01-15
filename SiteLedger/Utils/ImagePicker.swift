import SwiftUI
import UIKit

/// Shared ImagePicker for selecting photos from library or camera
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: ((UIImage) -> Void)? // CHANGED: Removed var, made it let
    
    init(image: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType = .photoLibrary, onImageSelected: ((UIImage) -> Void)? = nil) {
        self._image = image
        self.sourceType = sourceType
        self.onImageSelected = onImageSelected
        print("📦 ImagePicker INIT - callback is NIL: \(onImageSelected == nil)")
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                print("🎯 IMAGE SELECTED")
                
                // Force binding update on main thread
                DispatchQueue.main.async {
                    print("🔵 SETTING BINDING ON MAIN THREAD")
                    self.parent.image = image
                    print("🔵 BINDING SET - image exists: \(self.parent.image != nil)")
                }
                
                // Force callback to fire BEFORE dismiss
                if let callback = parent.onImageSelected {
                    print("🎯 CALLING CALLBACK")
                    callback(image)
                    print("🎯 CALLBACK DONE")
                } else {
                    print("❌ CALLBACK IS NIL")
                }
            }
            
            // Delay dismissal to allow binding to propagate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
