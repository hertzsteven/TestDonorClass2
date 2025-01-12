//
//  FolderPickerView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/10/25.
//


import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct FolderPickerView: UIViewControllerRepresentable {
    /// Typealias for a callback that returns the chosen folder URL or `nil` if cancelled.
    typealias CompletionHandler = (URL?) -> Void
    
    let completionHandler: CompletionHandler
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // For iOS 14+, you can use UTType.folder.identifier directly (if you import UniformTypeIdentifiers).
        // Otherwise, you can fall back to using kUTTypeFolder as a String.
        let folderUTI = UTType.folder.identifier  // e.g. "public.folder"
        
        // Create a Document Picker for opening folders
        let controller = UIDocumentPickerViewController(documentTypes: [folderUTI], in: .open)
        controller.delegate = context.coordinator
        
        // We want the user to pick a folder, not multiple items
        controller.allowsMultipleSelection = false
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No live updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completionHandler)
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
