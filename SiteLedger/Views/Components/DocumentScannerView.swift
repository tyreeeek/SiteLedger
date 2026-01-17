import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            print("📄 Document Scanner finished. Pages: \(scan.pageCount)")
            
            if scan.pageCount == 0 {
                parent.dismiss()
                return
            }
            
            // For multi-page receipts, stitch all pages vertically
            if scan.pageCount > 1 {
                print("🧵 Stitching \(scan.pageCount) pages for long receipt...")
                parent.image = stitchPages(scan: scan)
            } else {
                // Single page - use as-is
                parent.image = scan.imageOfPage(at: 0)
            }
            
            parent.dismiss()
        }
        
        /// Stitch multiple scanned pages into a single vertical image
        private func stitchPages(scan: VNDocumentCameraScan) -> UIImage? {
            var images: [UIImage] = []
            
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            
            guard !images.isEmpty else { return nil }
            
            // Calculate total height and max width
            let maxWidth = images.map { $0.size.width }.max() ?? 0
            let totalHeight = images.reduce(0) { $0 + $1.size.height }
            
            // Create combined size
            let combinedSize = CGSize(width: maxWidth, height: totalHeight)
            
            // Render all images vertically
            UIGraphicsBeginImageContextWithOptions(combinedSize, false, images[0].scale)
            defer { UIGraphicsEndImageContext() }
            
            var yOffset: CGFloat = 0
            for image in images {
                image.draw(at: CGPoint(x: 0, y: yOffset))
                yOffset += image.size.height
            }
            
            let stitchedImage = UIGraphicsGetImageFromCurrentImageContext()
            print("✅ Stitched \(images.count) pages into \(Int(combinedSize.width))x\(Int(combinedSize.height)) image")
            return stitchedImage
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("❌ Document Scanner failed: \(error.localizedDescription)")
            parent.dismiss()
        }
    }
}
