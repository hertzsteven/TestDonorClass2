import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct FolderPickerView: UIViewControllerRepresentable {
    /// Typealias for a callback that returns the chosen folder URL or `nil` if cancelled.
    typealias CompletionHandler = (URL?) -> Void
    
    let completionHandler: CompletionHandler
    let startInICloud: Bool
    
    init(startInICloud: Bool = false, completion: @escaping CompletionHandler) {
        self.startInICloud = startInICloud
        self.completionHandler = completion
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // For iOS 14+, you can use UTType.folder.identifier directly (if you import UniformTypeIdentifiers).
        // Otherwise, you can fall back to using kUTTypeFolder as a String.
        let folderUTI = UTType.folder.identifier  // e.g. "public.folder"
        
        // Create a Document Picker for opening folders
        let controller = UIDocumentPickerViewController(documentTypes: [folderUTI], in: .open)
        controller.delegate = context.coordinator
        
        // We want the user to pick a folder, not multiple items
        controller.allowsMultipleSelection = false
        
        if startInICloud, let iCloudURL = getICloudDriveURL() {
            controller.directoryURL = iCloudURL
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No live updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completionHandler)
    }
    
    private func getICloudDriveURL() -> URL? {
        let fileManager = FileManager.default
        
        if let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) {
            return iCloudURL.appendingPathComponent("Documents")
        }
        
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let iCloudPath = documentsURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Library")
                .appendingPathComponent("Mobile Documents")
                .appendingPathComponent("com~apple~CloudDocs")
            
            if fileManager.fileExists(atPath: iCloudPath.path) {
                return iCloudPath
            }
        }
        
        return nil
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: CompletionHandler
        
        init(completion: @escaping CompletionHandler) {
            self.completion = completion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            // If a folder is picked, pass its URL to the completion handler
            completion(urls.first)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // If the user cancels, pass nil
            completion(nil)
        }
    }
}
