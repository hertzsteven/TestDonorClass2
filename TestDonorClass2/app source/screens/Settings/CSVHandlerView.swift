    //
    //  CSVHandlerView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/13/25.
    //

    import SwiftUI
    import SwiftCSV

    struct CSVColumns {
        static let urcrd = "urcrd"
        static let duplicate = "duplicate"
        static let mnf = "mnf"
        static let pushka = "PUSHKA"
        static let stamp = "Stamp"
        static let salutation = "Salutation"
        static let nexch = "nexch"
        static let crrt = "CRRT"
        static let slush = "Slush"
        static let dpb = "DPB"
        static let first = "First"
        static let jewName = "jew.name"
        static let parnt = "parnt"
        static let last = "last"
        static let parntOrOther = "parnt_or_other"
        static let company = "company"
        static let street = "Street"
        static let suite = "suite"
        static let day = "DAY"
        static let city = "City"
        static let state = "State"
        static let zip = "Zip"
        static let oldAddr = "old_addr"
        static let uti90 = "uti90"
        static let uti91 = "uti91"
        static let uti92 = "uti92"
        static let uti931 = "uti931"
        static let uti932 = "uti932"
        static let uti941 = "uti941"
        static let uti942 = "uti942"
        static let initial = "initial"
        static let lastContributions = "LAST_CONTRIBUTIONS"
        static let addlContrib = "ADD'L_CONTRIB"
        static let new92 = "new92"
        static let new93 = "new93"
        static let new94 = "new94"
        static let list = "list"
        static let uti = "uti"
        static let sml = "sml"
        static let lrge = "lrge"
        static let corr = "corr"
        static let lg = "LG"
        static let lgy = "LGY"
        static let prarqst = "prarqst"
        static let na = "na"
        static let coacct = "COACCT#"
        static let dynlist = "dynlist#"
        static let cCard = "c.card"
        static let sources = "Sources"
        static let pa98 = "pa98"
        static let newlist = "newlist"
        static let dynacct = "dynacct#"
        static let airCond = "air_cond"
        static let aircondAmount = "aircond$"
        static let inscript = "inscript."
        static let addl = "addl"
        static let contributions = "contibutions"
    }


    struct CSVHandlerView {
        @EnvironmentObject var donorObject: DonorObjectClass

        @State private var initializationMessage: String = ""
        @State private var rowCount: Int = 0
        @State private var lastAndStreetOutput: [String] = []
        @State private var dumpOutput: String = ""
        
        init() {
            do {
//                try CSVHandler.initialize(fileName: "UTISample")
                try CSVHandler.initialize(fileName: "UTIMAIN")
                initializationMessage = "CSVHandler initialized successfully."
            } catch {
                initializationMessage = "Error initializing CSVHandler: \(error.localizedDescription)"
            }
        }
        
    }

    extension CSVHandlerView {

        
        fileprivate func getRowCount() {
            if let csvHandler = CSVHandler.shared {
                rowCount = csvHandler.getRows().count
                initializationMessage = "Row count fetched: \(rowCount)"
            } else {
                initializationMessage = "CSVHandler is not initialized."
            }
        }
        
        fileprivate func printLastNameStreet() {
            if let csvHandler = CSVHandler.shared {
                let rows = csvHandler.getRows()
                lastAndStreetOutput = rows.compactMap { row in
                    if let last = row["last"], let street = row["Street"] {
                        return "Last: \(last), Street: \(street)"
                    }
                    return nil
                }
                initializationMessage = "Fetched 'last' and 'Street' columns."
            } else {
                initializationMessage = "CSVHandler is not initialized."
            }
        }
        
    }

    extension CSVHandlerView: View {
        
        fileprivate func addDonorCSV() {

            guard let csvHandler = CSVHandler.shared else {
                fatalError("No CSVHandler")
            }
            let rows = csvHandler.getRows()
            rows.forEach { row in
                if row[CSVColumns.mnf]?.isEmpty ?? true {
                    print("Skipping row")
                } else {
                  print(row[CSVColumns.mnf])
                    }

                let donor = Donor(uuid: UUID().uuidString,
                              salutation: row[CSVColumns.salutation]?.isEmpty ?? true ? nil : row[CSVColumns.salutation],
                              firstName: row[CSVColumns.first] ?? "",
                              lastName: row[CSVColumns.last] ?? "",
                              jewishName: row[CSVColumns.jewName]?.isEmpty ?? true ? nil : row[CSVColumns.jewName],
                              address: row[CSVColumns.street]?.isEmpty ?? true ? nil : row[CSVColumns.street],
                              city: row[CSVColumns.city]?.isEmpty ?? true ? nil : row[CSVColumns.city],
                              state: row[CSVColumns.state]?.isEmpty ?? true ? nil : row[CSVColumns.state],
                              zip: row[CSVColumns.zip]?.isEmpty ?? true ? nil : row[CSVColumns.zip],
//                              email: row[CSVColumns.city]?.isEmpty ?? true ? nil : row[CSVColumns.city],
//                              phone: row[CSVColumns.city]?.isEmpty ?? true ? nil : row[CSVColumns.city],
//                              donorSource: row[CSVColumns.city]?.isEmpty ?? true ? nil : row[CSVColumns.city],
                              notes: row[CSVColumns.lastContributions]?.isEmpty ?? true ? nil : row[CSVColumns.lastContributions])
                Task {
                    do {
                        try await donorObject.addDonor(donor)
                    } catch {
                            // Handle error if needed
                    }
                }
            }
    //        let donor = Donor(
    //            uuid: UUID().uuidString,
    //            //            salutation: salutation.isEmpty ? nil : salutation,
    //            firstName: "Sammy",
    //            lastName: "Boy"
    //            //            jewishName: jewishName.isEmpty ? nil : jewishName,
    //            //            address: address.isEmpty ? nil : address,
    //            //            city: city.isEmpty ? nil : city,
    //            //            state: state.isEmpty ? nil : state,
    //            //            zip: zip.isEmpty ? nil : zip,
    //            //            email: email.isEmpty ? nil : email,
    //            //            phone: phone.isEmpty ? nil : phone,
    //            //            notes: notes.isEmpty ? nil : notes
    //        )
            
    //        Task {
    //            do {
    //                try await donorObject.addDonor(donor)
    //            } catch {
    //                    // Handle error if needed
    //            }
    //        }
        }
        
        fileprivate func addDonor() {
           let donor = Donor(
                uuid: UUID().uuidString,
    //            salutation: salutation.isEmpty ? nil : salutation,
                firstName: "Sammy",
                lastName: "Boy"
    //            jewishName: jewishName.isEmpty ? nil : jewishName,
    //            address: address.isEmpty ? nil : address,
    //            city: city.isEmpty ? nil : city,
    //            state: state.isEmpty ? nil : state,
    //            zip: zip.isEmpty ? nil : zip,
    //            email: email.isEmpty ? nil : email,
    //            phone: phone.isEmpty ? nil : phone,
    //            notes: notes.isEmpty ? nil : notes
            )
            Task {
                do {
                        try await donorObject.addDonor(donor)
                } catch {
                    // Handle error if needed
                }
            }
        }
        
        fileprivate func getRowCount() -> some View {
            return // Button to get the total number of rows
            Button("Get Row Count") {
                getRowCount()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        
        fileprivate func printtheThree() -> some View {
            return // Button to print "last" and "Street" columns
            Button("Print Last and Street Columns") {
                printLastNameStreet()
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        
        var body: some View {
            VStack(spacing: 20) {
                Text("CSV Handler Example")
                    .font(.title)
                    .padding()

                // Message to show initialization status
                Text(initializationMessage)
                    .foregroundColor(initializationMessage.contains("Error") ? .red : .green)

                Button("add donor") {
                    addDonorCSV()
                }
                
                getRowCount()

                printtheThree()
                
                    // New Button to dump all rows into CSVRow
                    Button("Dump All Rows") {
                        if let csvHandler = CSVHandler.shared {
                            let rows = csvHandler.getRows()
                            let csvRows: [CSVRow] = rows.compactMap { row in
                                guard let data = try? JSONSerialization.data(withJSONObject: row, options: []),
                                      let csvRow = try? JSONDecoder().decode(CSVRow.self, from: data) else {
                                    print("Failed to decode row: \(row)")
                                    return nil
                                }
                                dump(csvRow)
                                return csvRow
                            }

                            // Create a dump-like output
    //                        dumpOutput = csvRows.map { row -> String in
    //                            var dumpDescription = ""
    //                            dump(row, to: &dumpDescription)
    //                            return dumpDescription
    //                        }.joined(separator: "\n---------------------\n")

                            initializationMessage = "Dumped all rows successfully."
                        } else {
                            initializationMessage = "CSVHandler is not initialized."
                        }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                // Output Section
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(lastAndStreetOutput, id: \.self) { output in
                            Text(output)
                                .padding(.bottom, 5)
                                .lineLimit(nil)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
