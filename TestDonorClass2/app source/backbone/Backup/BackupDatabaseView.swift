import SwiftUI
import UniformTypeIdentifiers

struct BackupDatabaseView: View {
    @StateObject private var backupManager = BackupManager()
    
    @State private var showFolderPicker = false
    @State private var backupStatus: String = ""
    @State private var useICloudBackup = true
    @State private var showImportPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Backup Your Database")
                .font(.title)
            
            Toggle("Backup to iCloud Drive", isOn: $useICloudBackup)
                .padding(.horizontal)
                .onChange(of: useICloudBackup) { _ in
                    backupStatus = ""
                }
            if useICloudBackup {
                Button("Backup to iCloud Drive") {
                    backupStatus = performICloudBackup()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Pick Folder to Backup") {
                    showFolderPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Step 1: Import from Downloads
            Button("Import from Downloads") {
                showImportPicker = true
            }
            .buttonStyle(.borderedProminent)
            
            if !backupStatus.isEmpty {
                Text(backupStatus)
                    .font(.headline)
                    .padding()
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView(startInICloud: useICloudBackup) { folderURL in
                guard let folderURL = folderURL else {
                    backupStatus = "Folder selection cancelled."
                    return
                }
                
                if useICloudBackup && !isICloudURL(folderURL) {
                    backupStatus = "Warning: Selected folder may not be in iCloud Drive. Proceeding with backup..."
                }
                
                backupStatus = performBackup(to: folderURL)
                showFolderPicker = false
            }
        }
        // File importer to access external files (e.g., Downloads folder)
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                backupStatus = performRestore(from: urls)
            case .failure(let error):
                backupStatus = "Import error: \(error.localizedDescription)"
            }
        }
        .padding()
    }
    
    private func performICloudBackup() -> String {
        // For now, always use folder picker but start in iCloud
        showFolderPicker = true
        return "Opening folder picker in iCloud Drive..."
    }
    
    private func getICloudDriveURL() -> URL? {
        let fileManager = FileManager.default
        
        // Method 1: Try ubiquity container
        print("Trying method 1: ubiquity container")
        if let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) {
            let documentsURL = iCloudURL.appendingPathComponent("Documents")
            print("Checking path: \(documentsURL.path)")
            if fileManager.fileExists(atPath: documentsURL.path) {
                print("Method 1 successful!")
                return documentsURL
            }
            print("Documents folder doesn't exist, trying root iCloud URL")
            if fileManager.fileExists(atPath: iCloudURL.path) {
                print("Method 1 successful with root URL!")
                return iCloudURL
            }
        } else {
            print("ubiquity container returned nil")
        }
        
        // Method 2: Try standard iCloud Drive path via Documents directory
        print("Trying method 2: Documents directory approach")
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let iCloudPath = documentsURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Library")
                .appendingPathComponent("Mobile Documents")
                .appendingPathComponent("com~apple~CloudDocs")
            
            print("Checking path: \(iCloudPath.path)")
            if fileManager.fileExists(atPath: iCloudPath.path) {
                print("Method 2 successful!")
                return iCloudPath
            }
        }
        
        // Method 3: Alternative path using Application Support directory
        print("Trying method 3: Application Support approach")
        do {
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: false)
            let iCloudPath = appSupportURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Library")
                .appendingPathComponent("Mobile Documents")
                .appendingPathComponent("com~apple~CloudDocs")
            
            print("Checking path: \(iCloudPath.path)")
            if fileManager.fileExists(atPath: iCloudPath.path) {
                print("Method 3 successful!")
                return iCloudPath
            }
        } catch {
            print("Error accessing alternative iCloud path: \(error)")
        }
        
        // Method 4: Try alternative iCloud container approach
        print("Trying method 4: Alternative container approach")
        if let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) {
            print("Got ubiquity container, checking if it exists: \(iCloudURL.path)")
            if fileManager.fileExists(atPath: iCloudURL.path) {
                print("Method 4 successful!")
                return iCloudURL
            }
        }
        
        print("All methods failed to find iCloud Drive")
        return nil
    }
    
    private func isICloudURL(_ url: URL) -> Bool {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isUbiquitousItemKey])
            if let isUbiquitous = resourceValues.isUbiquitousItem {
                return isUbiquitous
            }
        } catch {
            print("Error checking ubiquitous status: \(error)")
        }
        
        let path = url.path
        return path.contains("com~apple~CloudDocs") ||
               path.contains("iCloud Drive") ||
               path.contains("Mobile Documents") ||
               path.contains("iCloud")
    }

    private func performBackup(to folderURL: URL) -> String {
        
        guard folderURL.startAccessingSecurityScopedResource() else {
            return "Error: Couldn't access security-scoped folder."
        }
        
        defer { folderURL.stopAccessingSecurityScopedResource() }
        
        let backupManager = BackupManager()
        var dbWasOpen = true
        
        do {
            try backupManager.closeDatabase()
        } catch {
            return "Error closing database before backup: \(error.localizedDescription)"
        }
        
        defer {
            if dbWasOpen {
                do {
                    try backupManager.openDatabase()
                } catch {
                    print("CRITICAL ERROR: Failed to reopen database after backup: \(error)")
                }
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let backupSubfolderName = "DonorApp_Backup_\(timestamp)"
        let backupFolderURL = folderURL.appendingPathComponent(backupSubfolderName)
 
        let fileManager = FileManager.default
        
        do {
            try fileManager.createDirectory(at: backupFolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return "Error creating backup subfolder: \(error.localizedDescription)"
        }
        
        do {
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory,
                                      in: .userDomainMask,
                                      appropriateFor: nil,
                                      create: true)
        
            let fileURLs = try fileManager.contentsOfDirectory(
                at: appSupportURL,
                includingPropertiesForKeys: nil
            )
            
            var successCount = 0
            var errors: [String] = []
            
            for fileURL in fileURLs {
                print(fileURL.lastPathComponent)
                let destinationURL = backupFolderURL.appendingPathComponent(fileURL.lastPathComponent)
                do {
                    print("from \(fileURL.lastPathComponent) to \(destinationURL.lastPathComponent)")
                    try fileManager.copyItem(at: fileURL, to: destinationURL)
                    successCount += 1
                } catch {
                    errors.append("\(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            if errors.isEmpty {
                let locationText = isICloudURL(folderURL) ? " to iCloud Drive" : ""
                return "Successfully backed up \(successCount) files\(locationText) in folder: \(backupSubfolderName)"
            } else {
                return "Backed up \(successCount) files with errors in folder \(backupSubfolderName):\n" + errors.joined(separator: "\n")
            }
            
        } catch {
            return "Error accessing files: \(error.localizedDescription)"
        }
    }

    private func performCopy() -> String {
        
        let fileManager = FileManager.default
        
        let fileURL = Bundle.main.url(forResource: "UTIMAIN", withExtension: "csv")!
        print("fileURL: \(fileURL)")
        
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            return "Successfully backed up to: \(destinationURL.lastPathComponent)"
        } catch {
            return "Error copying database: \(error.localizedDescription)"
        }
    }
    
    /// Restores the selected files into the app’s Application Support directory.
    private func performRestore(from fileURLs: [URL]) -> String {
        // Only keep SQLite store files
        let allowedExtensions = ["sqlite", "sqlite-wal", "sqlite-shm"]
        let restoreURLs = fileURLs.filter { allowedExtensions.contains($0.pathExtension) }
        guard !restoreURLs.isEmpty else {
            return "No database files (.sqlite, .sqlite-wal, .sqlite-shm) selected for restore."
        }
        // Ensure all three store files are present
        let requiredExtensions: Set<String> = ["sqlite", "sqlite-wal", "sqlite-shm"]
        let selectedExts = Set(restoreURLs.map { $0.pathExtension })
        guard requiredExtensions.isSubset(of: selectedExts) else {
            return "Please select all three database files (.sqlite, .sqlite-wal, .sqlite-shm) to restore."
        }

        // 1. Security-scoped access
        for url in restoreURLs {
            _ = url.startAccessingSecurityScopedResource()
        }
        defer {
            for url in restoreURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // 2. Close the live database
        do {
            try backupManager.closeDatabase()
        } catch {
            return "Error closing database before restore: \(error.localizedDescription)"
        }

        // 3. Determine database directory from backupManager or fallback
        let fileManager = FileManager.default
        let targetDirectory: URL
        if let databaseURL = backupManager.getDatabaseURL() {
            targetDirectory = databaseURL.deletingLastPathComponent()
//        if let databaseURL = backupManager.databaseURL {
            // Use the actual directory where the database lives
//            targetDirectory = databaseURL.deletingLastPathComponent()
        } else {
            do {
                targetDirectory = try fileManager.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            } catch {
                return "Cannot locate target database directory: \(error.localizedDescription)"
            }
        }

        // 4. Copy each file into target directory
        var successCount = 0
        var errors: [String] = []

        for src in restoreURLs {
            let dst = targetDirectory.appendingPathComponent(src.lastPathComponent)
            do {
                if fileManager.fileExists(atPath: dst.path) {
                    try fileManager.removeItem(at: dst)
                }
                try fileManager.copyItem(at: src, to: dst)
                successCount += 1
            } catch {
                errors.append("\(src.lastPathComponent): \(error.localizedDescription)")
            }
        }

        // 5. Re-open the database
        do {
            try backupManager.openDatabase()
        } catch {
            return "Restored \(successCount) files, but failed to reopen database: \(error.localizedDescription)"
        }

        // 6. Build status message
        if errors.isEmpty {
            return "Successfully restored \(successCount) files."
        } else {
            return "Restored \(successCount) files with errors: " + errors.joined(separator: "; ")
        }
    }
}
