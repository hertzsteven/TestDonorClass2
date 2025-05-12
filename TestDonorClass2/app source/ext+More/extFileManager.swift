//
//  extFileManager.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 5/11/25.
//

import Foundation
import SwiftUI

extension FileManager {

    /// Copies SQLite database files from the app bundle to the Application Support directory
    ///
    /// This function handles the copying of SQLite database files from the app bundle to the
    /// Application Support directory, including associated WAL and SHM files if they exist.
    ///
    /// - Parameters:
    ///   - databaseName: The name of the database file without extension
    ///   - fileExtension: The file extension of the database (defaults to "sqlite")
    ///   - subdirectory: Optional subdirectory path within Application Support
    ///   - copyFromBundleIfNeeded: Whether to copy the file if it doesn't exist (defaults to true)
    ///   - forceCopy:: Whether to copy the file even if exists
    ///
    /// - Returns: URL to the database file in Application Support directory
    ///
    /// - Throws: FileManager errors if copying fails or if database file is not found in bundle
    
    func copySqliteDatabasesFromResourcesToAppSupp(
        databaseName: String,
        fileExtension: String = "sqlite",
        subdirectory: String? = nil,
        copyFromBundleIfNeeded: Bool = true,
        forceCopy: Bool = false
    ) throws -> URL {

        // Get the Application Support directory
        let appSupportURL = try url(for: .applicationSupportDirectory,
                                   in: .userDomainMask,
                                   appropriateFor: nil,
                                   create: true)
        
        // Add subdirectory if specified
        var destinationDirectoryURL = appSupportURL
        if let subdirectory = subdirectory {
            destinationDirectoryURL = appSupportURL.appendingPathComponent(subdirectory, isDirectory: true)
            try createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        
        // Create the destination URL for the database
        let destinationURL = destinationDirectoryURL.appendingPathComponent("\(databaseName).\(fileExtension)")
        

        guard (forceCopy) || (!fileExists(atPath: destinationURL.path) && copyFromBundleIfNeeded)  else {
            print("\n databses url: \(databaseName) already exists, no need to copy \n")
            return destinationURL
        }
        
        if  (!fileExists(atPath: destinationURL.path) && copyFromBundleIfNeeded) {
            print("\n databses url: \(databaseName) does not exist, copying from bundle \n")
        }
        if forceCopy {
            print("\n databses url: \(databaseName) force copying \n")
        }
        
        return try doCopySQLiteFromBundleToAppSupport(
            databaseName: databaseName,
            fileExtension: fileExtension,
            subdirectory: subdirectory
        )
    }
    
    /// Performs the actual copy of SQLite database files from bundle to Application Support
    ///
    /// This internal function handles the actual copying process of SQLite database files and their
    /// associated WAL and SHM files from the app bundle to the Application Support directory.
    ///
    /// - Parameters:
    ///   - databaseName: The name of the database file without extension
    ///   - fileExtension: The file extension of the database (defaults to "sqlite")
    ///   - subdirectory: Optional subdirectory path within Application Support
    ///
    /// - Returns: URL to the copied database file in Application Support directory
    ///
    /// - Throws: FileManager errors if copying fails or if database file is not found in bundle
    func doCopySQLiteFromBundleToAppSupport(
        databaseName: String,
        fileExtension: String = "sqlite",
        subdirectory: String? = nil
        ) throws -> URL {
            
        // Get the URL to the database in the app bundle
        guard let bundleURL = Bundle.main.url(forResource: databaseName, withExtension: fileExtension) else {
            throw NSError(domain: "FileManagerExtension", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Database \(databaseName).\(fileExtension) not found in app bundle"])
        }
        
        // Get the Application Support directory
        let appSupportURL = try url(for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
        
        // Add subdirectory if specified
        var destinationDirectoryURL = appSupportURL
        if let subdirectory = subdirectory {
            destinationDirectoryURL = appSupportURL.appendingPathComponent(subdirectory, isDirectory: true)
            try createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Create the destination URL for the database
        let destinationURL = destinationDirectoryURL.appendingPathComponent("\(databaseName).\(fileExtension)")
        
        // Check if the database already exists in the Application Support directory
        if fileExists(atPath: destinationURL.path) {
            // Database already exists, so we don't need to copy it again
            print("Database already exists at \(destinationURL.path)")
            // Need code to delete the file if already exists
            try? FileManager.default.removeItem(at: destinationURL)
         }
        
            
        // Copy the main SQLite file
        try copyItem(at: bundleURL, to: destinationURL)
        
        // Copy the associated files
        let associatedExtensions = ["-wal", "-shm"]
        
        for ext in associatedExtensions {
            // Check if associated file exists in bundle
            if let associatedBundleURL = Bundle.main.url(forResource: databaseName, withExtension: fileExtension + ext) {
                let associatedDestURL = destinationURL.appendingPathExtension(ext)
                // Check if the database already exists in the Application Support directory
                if fileExists(atPath: associatedDestURL.path) {
                    // Database already exists, so we don't need to copy it again
                    print("Database already exists at \(associatedDestURL.path)")
                    // Need code to delete the file if already exists
                    try? FileManager.default.removeItem(at: associatedDestURL)
                }
                do {
                    try copyItem(at: associatedBundleURL, to: associatedDestURL)
                } catch {
                    print("Warning: Could not copy associated file \(ext): \(error.localizedDescription)")
                    // Continue even if an associated file couldn't be copied
                }
            }
        }
        
        return destinationURL
    }
}
