//
//  DocumentPickerView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/10/25.
//

import SwiftUI

struct DocumentPickerView: UIViewControllerRepresentable {
    typealias Callback = ([URL]) -> Void
    
    let fileURLs: [URL]        // The files you want to export
    let callback: Callback     // A closure to call with the selected URLs
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // For exporting (sharing) files
        let documentPicker = UIDocumentPickerViewController(forExporting: fileURLs)
        documentPicker.delegate = context.coordinator
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed in this scenario
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(callback: callback)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let callback: Callback
        
        init(callback: @escaping Callback) {
            self.callback = callback
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            // Called when the user has picked a location (the new file URL) or completed an export
            callback(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Called if the user cancels
            callback([])
        }
    }
}
