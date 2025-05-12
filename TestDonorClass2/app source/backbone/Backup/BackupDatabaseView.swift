import SwiftUI

struct BackupDatabaseView: View {
    @StateObject private var backupManager = BackupManager()
    
    @State private var showFolderPicker = false
    @State private var backupStatus: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Backup Your Database")
                .font(.title)
            
            Button("copy over resource") {
                performCopy()
            }
            
             
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
        
        //  Attempt to start accessing the security-scoped folder
        guard folderURL.startAccessingSecurityScopedResource() else {
            return "Error: Couldn't access security-scoped folder."
        }
        
        //  Guarantee we stop accessing when this function exits
        defer { folderURL.stopAccessingSecurityScopedResource() }
        
        let backupManager = BackupManager()
        var dbWasOpen = true
        
        // Close database before backup
        do {
            try backupManager.closeDatabase()
        } catch {
            return "Error closing database before backup: \(error.localizedDescription)"
        }
        
        // Ensure database gets reopened
        defer {
            if dbWasOpen {
                do {
                    try backupManager.openDatabase()
                } catch {
                    print("CRITICAL ERROR: Failed to reopen database after backup: \(error)")
                }
            }
        }
        
        //  Generate a timestamp string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss" // Adjust as needed
        let timestamp = dateFormatter.string(from: Date())
 
        
        // Do the file operation
        let fileManager = FileManager.default
        
        do {
            // Get the Application Support directory
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory,
                                      in: .userDomainMask,
                                      appropriateFor: nil,
                                      create: true)
        
            // Get all files in the directory
            let fileURLs = try fileManager.contentsOfDirectory(
                at: appSupportURL,
                includingPropertiesForKeys: nil
            )
            
            var successCount = 0
            var errors: [String] = []
            
            for fileURL in fileURLs {
                print(fileURL.lastPathComponent)
                let destinationURL = folderURL.appendingPathComponent("\(timestamp)_\(fileURL.lastPathComponent)")
                do {
                    print("from \(fileURL.lastPathComponent) to \(destinationURL.lastPathComponent)")
                    try fileManager.copyItem(at: fileURL, to: destinationURL)
                    successCount += 1
                } catch {
                    errors.append("\(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            if errors.isEmpty {
                return "Successfully backed up \(successCount) files"
            } else {
                return "Backed up \(successCount) files with errors:\n" + errors.joined(separator: "\n")
            }
            
        } catch {
            return "Error accessing files: \(error.localizedDescription)"
        }
        
//        return "Successfully backed up to: ---"
    }

    private func performBackupOld(to folderURL: URL) -> String {
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
    
    private func performCopy() -> String {
        
            // Do the file operation
        let fileManager = FileManager.default
        
            // get a file from project resources
        let fileURL = Bundle.main.url(forResource: "UTIMAIN", withExtension: "csv")!
        print("fileURL: \(fileURL)")
        
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)
        
        do {
                // If a file already exists at the same name, remove it
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
                // Copy your DB file
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            return "Successfully backed up to: \(destinationURL.lastPathComponent)"
        } catch {
            return "Error copying database: \(error.localizedDescription)"
        }
    }
}
