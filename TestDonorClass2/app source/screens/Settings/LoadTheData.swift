    //
    //  LoadTheData.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/13/25.
    //

import SwiftCSV
import SwiftUI

struct CSVHandler {
    // Singleton instance
    static var shared: CSVHandler?

    private let csv: CSV<Named> // CSV instance as a private property

    // Private initializer to prevent multiple initializations
    private init(fileName: String, fileExtension: String) throws {
        // Locate the CSV file in the app bundle
        guard let path = Bundle.main.path(forResource: fileName, ofType: fileExtension) else {
            throw NSError(domain: "CSVHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "CSV file not found in the bundle."])
        }

        // Create a URL for the CSV file
        let fileURL = URL(fileURLWithPath: path)

        // Initialize the CSV parser
        self.csv = try CSV<Named>(url: fileURL)
    }

    // Function to initialize the shared instance
    static func initialize(fileName: String, fileExtension: String = "csv") throws {
        shared = try CSVHandler(fileName: fileName, fileExtension: fileExtension)
    }

    // Example: Get rows from the CSV
    func getRows() -> [[String: String]] {
        return csv.rows
    }

    // Example: Print specific columns (e.g., "last" and "Street")
    func printLastAndStreet() {
        for (index, row) in csv.rows.enumerated() {
            if let last = row["last"], let street = row["Street"] {
                print("Row \(index + 1): last = \(last), Street = \(street)")
            } else {
                print("Row \(index + 1): Missing data for 'last' or 'Street'")
            }
        }
    }
}


    struct LoadTheData {

    }


    extension LoadTheData: View {
        var body: some View {
            VStack(spacing:24) {
                Text("Hello, World!")
                Button("Open Resources") { openResources() }
//                Button("Print First 3 Records") { printFirst3(<#CSV<Named>#>) }
            }
        }
    }

    extension LoadTheData {
        
        func openResources() {

            do {
                // Ensure the file exists in the bundle
                guard let path = Bundle.main.path(forResource: "UTISample", ofType: "csv") else {
                    print("CSV file not found in the bundle.")
                    return
                }

                // Create a URL for the CSV file
                let fileURL = URL(fileURLWithPath: path)

                // Initialize the CSV parser
                let csv = try CSV<Named>(url: fileURL)

                printFirst3(csv)

            } catch let parseError as CSVParseError {
                print("CSV Parsing Error: \(parseError)")
            } catch {
                print("An error occurred: \(error)")
            }

        }

        fileprivate func printFirst3(_ csv: CSV<Named>) {
                // Access the first three rows and print desired columns
            let rows = csv.rows
            for (index, row) in rows.enumerated() where index < 3 {
                if let column1 = row["last"], let column2 = row["Street"] {
                    print("Row \(index + 1): Column1 = \(column1), Column2 = \(column2)")
                } else {
                    print("Row \(index + 1): Missing data for specified columns")
                }
            }
        }
        
    }

    #Preview {
        LoadTheData()
    }
