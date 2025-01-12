//
//  BackupManager.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/10/25.
//


import SwiftUI


import SwiftUI

class BackupManager: ObservableObject {
    let dbName: String = "donations_db.sqlite"
    /// Returns the original URL of your SQLite database in your app’s documents or elsewhere.
     func getDatabaseURL() -> URL? {
        // Example: Use your own logic to locate the SQLite database
        // e.g. documents directory -> "database.sqlite"
        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        do {
            let databaseURL = try fileManager
                                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                .appendingPathComponent(dbName)
            return databaseURL

        } catch {
                print("Error creating database URL: \(error)")
            return nil
        }

//        let dbURL = docsURL.appendingPathComponent("database.sqlite")
//        return dbURL
    }
    
    func closeDatabase() {
        DatabaseManager.shared.closeConnections()
    }
    
    func openDatabase()  {
        DatabaseManager.shared.connectToDB()
    }

    func backupLocally() -> URL? {
            guard let originalURL = getDatabaseURL() else {
                print("Database file not found.")
                return nil
            }

            closeDatabase()
            // defer executes when the function exits, either normally or due to an error
            defer { openDatabase() }

            let fileManager = FileManager.default
            do {
                let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let backupsFolderURL = docsURL.appendingPathComponent("LocalBackups")
                if !fileManager.fileExists(atPath: backupsFolderURL.path) {
                    try fileManager.createDirectory(at: backupsFolderURL,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
                }
                let timestamp = ISO8601DateFormatter().string(from: Date())
                let backupFileName = "databaseBackup-\(timestamp).sqlite"
                let backupFileURL = backupsFolderURL.appendingPathComponent(backupFileName)
                try fileManager.copyItem(at: originalURL, to: backupFileURL)
                print("Database backed up locally at: \(backupFileURL.path)")
                return backupFileURL
            } catch {
                print("Error backing up database: \(error)")
                return nil
            }
    }

}
