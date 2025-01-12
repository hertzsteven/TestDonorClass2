import SwiftUI

struct BackupDatabaseView: View {
    @StateObject private var backupManager = BackupManager()
    
    @State private var showFolderPicker = false
    @State private var backupStatus: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Backup Your Database")
                .font(.title)
            
            Button("Pick Folder to Backup") {
                showFolderPicker = true
            }
            
            if !backupStatus.isEmpty {
                Text(backupStatus)
                    .font(.headline)
                    .padding()
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView { folderURL in
                guard let folderURL = folderURL else {
                    backupStatus = "Folder selection cancelled."
                    return
                }
                
                    // Perform the backup with security scope
                backupStatus = performBackup(to: folderURL)
                
                showFolderPicker = false
            }
        }
        .padding()
    }
    
    private func performBackup(to folderURL: URL) -> String {
            // 1. Attempt to start accessing the security-scoped folder
        guard folderURL.startAccessingSecurityScopedResource() else {
            return "Error: Couldn't access security-scoped folder."
        }
            // 2. Guarantee we stop accessing when this function exits
        defer { folderURL.stopAccessingSecurityScopedResource() }
        
            // 3. Do the file operation
        let fileManager = FileManager.default
        
        guard let dbURL = backupManager.getDatabaseURL() else {
            return "Database file not found."
        }
        
            // 1. Generate a timestamp string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss" // Adjust as needed
        let timestamp = dateFormatter.string(from: Date())
        
            // 2. Use the timestamp in your backup filename
        let backupFileName = "databaseBackup-\(timestamp).sqlite"
        let destinationURL = folderURL.appendingPathComponent(backupFileName)
        
        
        do {
                // If a file already exists at the same name, remove it
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
                // Copy your DB file
            try fileManager.copyItem(at: dbURL, to: destinationURL)
            return "Successfully backed up to: \(destinationURL.lastPathComponent)"
        } catch {
            return "Error copying database: \(error.localizedDescription)"
        }
    }
}
