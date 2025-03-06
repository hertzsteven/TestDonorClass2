    //
    //  Untitled.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 12/24/24.
    //

    //
    //  DatabaseManager.swift
    //  Understanding Passing into mvvm
    //
    //  Created by Steven Hertz on 12/17/24.
    //
    import GRDB
    import Foundation
    // MARK: - Updated DatabaseManager
    class DatabaseManager {
        let dbName: String = "donations_db.sqlite"
        static let shared = DatabaseManager()
        private var dbPool: DatabasePool!


        private init() {
            connectToDB()
        }
        
        func connectToDB() {
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            print("Catalyst documents path:", docsURL?.path ?? "nil")

            let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            print("Catalyst library path:", libraryURL?.path ?? "nil")
            print("Catalyst library path:", libraryURL?.path ?? "nil")

            do {
                let databaseURL = try FileManager.default
                    .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent(dbName)
                
                let fileManager = FileManager.default
                
                    // get a file from project resources
                let fileURL = Bundle.main.url(forResource: "donations_db", withExtension: "sqlite")!
                print("fileURL: \(fileURL)")
                
                do {
                        // If a file already exists at the same name, remove it
                    if !fileManager.fileExists(atPath: databaseURL.path) {
                        print("DB file not found, copying from bundle.")
                        
                            // Copy your DB file
                        try fileManager.copyItem(at: fileURL, to: databaseURL)
                    } else {
                        print("DB file found.")
                    }
                } catch {
                    fatalError("could not copy the file")
                }
                

                dbPool = try DatabasePool(path: databaseURL.path)
                    // Enable foreign key constraints
                try dbPool.write { db in
                    try db.execute(sql: "PRAGMA foreign_keys = ON;")
                }
                
                print(databaseURL.absoluteString)
                    // Add this line to ensure table exists
                try ensureDonorTableExists()
                try updateDonationTableForReceipts() // Add this line
                
                    // Migrate database
                    //                try migrator.migrate(dbPool)
            } catch {
                fatalError("Database initialization failed: \(error)")
            }
        }
        
        
        func getDbPool() -> DatabasePool {
            dbPool
        }
        // close dbPool
        
        func closeConnections() {
            do {
                try dbPool.close()
                dbPool = nil
            } catch let error {
                print("Error closing database: \(error)")
            }
        }
        
        // Make function throwing and fix the scalar issue
        //            func testDatabaseConnection() throws {  // Added throws here
        //                do {
        //                    try dbPool.write { db in
        //                        // List all tables
        //                        let tables = try String.fetchAll(db, sql: """
        //                            SELECT name FROM sqlite_master
        //                            WHERE type='table'
        //                            ORDER BY name
        //                            """)
        //                        print("All tables in database:", tables)
        //
        //                        // Try to read donor table
        //                        let donorCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM donor") ?? 0  // Changed to fetchOne
        //                        print("Donor table exists with \(donorCount) records")
        //
        //                        // Try to read donation table
        //                        let donationCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM donation") ?? 0  // Changed to fetchOne
        //                        print("Donation table exists with \(donationCount) records")
        //
        //                        // Try to read campaign table
        //                        let campaignCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM campaign") ?? 0  // Changed to fetchOne
        //                        print("Campaign table exists with \(campaignCount) records")
        //
        //                        // Try a test query on each table
        //                        if donorCount > 0 {
        //                            let firstDonor = try String.fetchOne(db, sql: "SELECT first_name || ' ' || last_name FROM donor LIMIT 1")
        //                            print("Sample donor:", firstDonor ?? "None")
        //                        }
        //
        //                        if campaignCount > 0 {
        //                            let firstCampaign = try String.fetchOne(db, sql: "SELECT name FROM campaign LIMIT 1")
        //                            print("Sample campaign:", firstCampaign ?? "None")
        //                        }
        //
        //                        if donationCount > 0 {
        //                            let firstDonation = try Double.fetchOne(db, sql: "SELECT amount FROM donation LIMIT 1")
        //                            print("Sample donation amount:", firstDonation ?? 0)
        //                        }
        //                    }
        //                    print("Database test completed successfully")
        //                } catch {
        //                    print("Database test failed: \(error)")
        //                    throw error
        //                }
        //            }
        // FIXME: - Not Used Currently
        func testDatabaseConnection() throws {
            // Print database path
            print("Database path: \(dbPool.path)")
            do {
                try dbPool.write { db in
                    // List all tables
                    let tables = try String.fetchAll(db, sql: """
                        SELECT name FROM sqlite_master 
                        WHERE type='table' 
                        ORDER BY name
                        """)
                    print("\n=== Tables in database ===")
                    print(tables)
                    // Get counts with explicit messages for zero
                    let donorCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM donor") ?? 0
                    print("\n=== Record Counts ===")
                    print("Donors: \(donorCount) records" + (donorCount == 0 ? " (empty)" : ""))
                    let donationCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM donation") ?? 0
                    print("Donations: \(donationCount) records" + (donationCount == 0 ? " (empty)" : ""))
                    let campaignCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM campaign") ?? 0
                    print("Campaigns: \(campaignCount) records" + (campaignCount == 0 ? " (empty)" : ""))
                    // Sample data section only if records exist
                    if donorCount > 0 || donationCount > 0 || campaignCount > 0 {
                        print("\n=== Sample Data ===")
                        if donorCount > 0 {
                            let firstDonor = try String.fetchOne(db, sql: "SELECT first_name || ' ' || last_name FROM donor LIMIT 1")
                            print("Sample donor:", firstDonor ?? "None")
                        }
                        if campaignCount > 0 {
                            let firstCampaign = try String.fetchOne(db, sql: "SELECT name FROM campaign LIMIT 1")
                            print("Sample campaign:", firstCampaign ?? "None")
                        }
                        if donationCount > 0 {
                            let firstDonation = try Double.fetchOne(db, sql: "SELECT amount FROM donation LIMIT 1")
                            print("Sample donation amount:", firstDonation ?? 0)
                        }
                    }
                }
                print("\nDatabase test completed successfully")
            } catch {
                print("\nDatabase test failed: \(error)")
                throw error
            }
        }
        // MARK: - Migrations
        private var migrator: DatabaseMigrator {
            var migrator = DatabaseMigrator()
            // Initial migration - Create new tables
            migrator.registerMigration("createDonationSystem") { db in
                // Create donors table
                // Create donors table
                try db.create(table: "donor") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("uuid", .text).notNull().unique()
                    t.column("salutation", .text)
                    t.column("first_name", .text) // .notNull()
                    t.column("last_name", .text)  // .notNull()
                    t.column("jewish_name", .text)
                    t.column("address", .text)
                    t.column("city", .text)
                    t.column("state", .text)
                    t.column("zip", .text)
                    t.column("email", .text)
                    t.column("phone", .text)
                    t.column("donor_source", .text)
                    t.column("notes", .text)
                    t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                }
                // Create donor indexes
                try db.create(index: "idx_donor_name", on: "donor", columns: ["last_name", "first_name"])
                try db.create(index: "idx_donor_email", on: "donor", columns: ["email"])
                try db.create(index: "idx_donor_uuid", on: "donor", columns: ["uuid"])
                // Create campaigns table
                try db.create(table: "campaign") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("uuid", .text).notNull().unique()
                    t.column("campaign_code", .text).notNull().unique()
                    t.column("name", .text).notNull()
                    t.column("description", .text)
                    t.column("start_date", .date)
                    t.column("end_date", .date)
                    t.column("status", .text).notNull().defaults(to: "DRAFT")
                    t.column("goal", .double)
                    t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                }
                // Create campaign indexes
                try db.create(index: "idx_campaign_code", on: "campaign", columns: ["campaign_code"])
                try db.create(index: "idx_campaign_status", on: "campaign", columns: ["status"])
                try db.create(index: "idx_campaign_dates", on: "campaign", columns: ["start_date", "end_date"])
                // Create donations table
                try db.create(table: "donation") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("uuid", .text).notNull().unique()
                    t.column("donor_id", .integer).references("donor", onDelete: .setNull)
                    t.column("campaign_id", .integer).references("campaign", onDelete: .setNull)
                    t.column("amount", .double).notNull()
                    t.column("donation_type", .text).notNull()
                    t.column("payment_status", .text).notNull().defaults(to: "PENDING")
                    t.column("transaction_number", .text)
                    t.column("receipt_number", .text)
                    t.column("payment_processor_info", .text)
                    t.column("request_email_receipt", .boolean).notNull().defaults(to: false)
                    t.column("request_printed_receipt", .boolean).notNull().defaults(to: false)
                    t.column("notes", .text)
                    t.column("is_anonymous", .boolean).notNull().defaults(to: false)
                    t.column("donation_date", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                }
                // Create donation indexes
                try db.create(index: "idx_donation_donor", on: "donation", columns: ["donor_id"])
                try db.create(index: "idx_donation_campaign", on: "donation", columns: ["campaign_id"])
                try db.create(index: "idx_donation_date", on: "donation", columns: ["donation_date"])
                try db.create(index: "idx_donation_status", on: "donation", columns: ["payment_status"])
            }
            //                        }
            // Add triggers for updated_at timestamps
            migrator.registerMigration("addTimestampTriggers") { db in
                try db.execute(sql: """
                    CREATE TRIGGER update_donor_timestamp AFTER UPDATE ON donor
                    BEGIN
                        UPDATE donor SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
                    END;
                """)
                try db.execute(sql: """
                    CREATE TRIGGER update_donation_timestamp AFTER UPDATE ON donation
                    BEGIN
                        UPDATE donation SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
                    END;
                """)
                try db.execute(sql: """
                    CREATE TRIGGER update_campaign_timestamp AFTER UPDATE ON campaign
                    BEGIN
                        UPDATE campaign SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
                    END;
                """)
            }
            // If you need to migrate data from old tables
            migrator.registerMigration("migrateExistingData") { db in
                // Check if old tables exist before attempting migration
                let oldTablesExist = try db.tableExists("customer")
                if oldTablesExist {
                    // Migrate customers to donors
                    try db.execute(sql: """
                        INSERT INTO donor (uuid, first_name, last_name)
                        SELECT uuid, name, '' FROM customer;
                    """)
                    // Drop old tables
                    try db.drop(table: "customer")
                    try db.drop(table: "product")
                    try db.drop(table: "customer_product_interest")
                }
            }
            return migrator
        }
    }
    // FIXME: - Not Used Currently
    // MARK: - Record Protocols
    protocol DatabaseModel: Codable {
        var id: Int { get }  // Changed from UUID to Int since we're using auto-increment
        var uuid: UUID { get }  // Added UUID as a separate requirement
    }

    extension DatabaseManager {
        func ensureDonorTableExists() throws {
            try dbPool.write { db in
                // Check if donor table exists
                let donorTableExists = try db.tableExists("donor")
                if !donorTableExists {
                    print("Donor table does not exist. Creating...")
                    // Create donors table
                    try db.create(table: "donor") { t in
                        t.autoIncrementedPrimaryKey("id")
                        t.column("uuid", .text).notNull().unique()
                        t.column("company", .text)
                        t.column("salutation", .text)
                        t.column("first_name", .text) // .notNull()
                        t.column("last_name", .text)  // .notNull()
                        t.column("jewish_name", .text)
                        t.column("address", .text)
                        t.column("addl_line", .text)
                        t.column("suite", .text)
                        t.column("city", .text)
                        t.column("state", .text)
                        t.column("zip", .text)
                        t.column("email", .text)
                        t.column("phone", .text)
                        t.column("donor_source", .text)
                        t.column("notes", .text)
                        t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                        t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    }
                    // Create donor indexes
                    try db.create(index: "idx_donor_name", on: "donor", columns: ["last_name", "first_name", "company"])
                    try db.create(index: "idx_donor_email", on: "donor", columns: ["email"])
                    try db.create(index: "idx_donor_uuid", on: "donor", columns: ["uuid"])
                    // Create update trigger for donor timestamps
                    try db.execute(sql: """
                        CREATE TRIGGER IF NOT EXISTS update_donor_timestamp 
                        AFTER UPDATE ON donor
                        BEGIN
                            UPDATE donor SET updated_at = CURRENT_TIMESTAMP 
                            WHERE id = NEW.id;
                        END;
                    """)
                    print("Donor table created successfully")
                } else {
                    print("Donor table already exists")
                }
                
                let campaignTableExists = try db.tableExists("campaign")
                if !campaignTableExists {
                    // Create campaigns table
                    try db.create(table: "campaign") { t in
                        t.autoIncrementedPrimaryKey("id")
                        t.column("uuid", .text).notNull().unique()
                        t.column("campaign_code", .text).notNull().unique()
                        t.column("name", .text).notNull()
                        t.column("description", .text)
                        t.column("start_date", .date)
                        t.column("end_date", .date)
                        t.column("status", .text).notNull().defaults(to: "DRAFT")
                        t.column("goal", .double)
                        t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                        t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    }
                    
                    // Create campaign indexes
                    try db.create(index: "idx_campaign_code", on: "campaign", columns: ["campaign_code"])
                    try db.create(index: "idx_campaign_status", on: "campaign", columns: ["status"])
                    try db.create(index: "idx_campaign_dates", on: "campaign", columns: ["start_date", "end_date"])
                } else {
                    print("Campaign table already exists")
                }

                let incentiveTableExists = try db.tableExists("donation_incentive")
                if !incentiveTableExists {
                    // Create donation_incentive table
                    try db.create(table: "donation_incentive") { t in
                        t.autoIncrementedPrimaryKey("id")
                        t.column("uuid", .text).notNull().unique()
                        t.column("name", .text).notNull()
                        t.column("description", .text)
                        t.column("dollar_amount", .double).notNull()
                        t.column("status", .text).notNull().defaults(to: "ACTIVE")
                        t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                        t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    }
                    
                    // Create indexes
                    try db.create(index: "idx_incentive_name", on: "donation_incentive", columns: ["name"])
                    try db.create(index: "idx_incentive_status", on: "donation_incentive", columns: ["status"])
                    try db.create(index: "idx_incentive_amount", on: "donation_incentive", columns: ["dollar_amount"])

                    // Create update trigger for timestamps
                    try db.execute(sql: """
                        CREATE TRIGGER IF NOT EXISTS update_donation_incentive_timestamp 
                        AFTER UPDATE ON donation_incentive
                        BEGIN
                            UPDATE donation_incentive SET updated_at = CURRENT_TIMESTAMP 
                            WHERE id = NEW.id;
                        END;
                    """)
                    print("DonationIncentive table created successfully")
                } else {
                    print("DonationIncentive table already exists")
                }
                
                // Check if donation table exists
                let donationTableExists = try db.tableExists("donation")
                if !donationTableExists {
                    print("Donation table does not exist. Creating...")
                    // Create donations table
                    try db.create(table: "donation") { t in
                        t.autoIncrementedPrimaryKey("id")
                        t.column("uuid", .text).notNull().unique()
                        t.column("donor_id", .integer)
                        t.column("campaign_id", .integer)
                        t.column("donation_incentive_id", .integer)
                        t.column("amount", .double).notNull()
                        t.column("donation_type", .text).notNull()
                        t.column("payment_status", .text).notNull()
                        t.column("receipt_status", .text).notNull().defaults(to: "NOT_REQUESTED")  // Add this line
                        t.column("transaction_number", .text)
                        t.column("receipt_number", .text)
                        t.column("payment_processor_info", .text)
                        t.column("request_email_receipt", .boolean).notNull().defaults(to: false)
                        t.column("request_printed_receipt", .boolean).notNull().defaults(to: false)
                        t.column("notes", .text)
                        t.column("is_anonymous", .boolean).notNull().defaults(to: false)
                        t.column("donation_date", .datetime).notNull()
                        t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                        t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                            // Foreign key constraint
                        t.foreignKey(["donor_id"], references: "donor", columns: ["id"], onDelete: .restrict)
                        t.foreignKey(["campaign_id"], references: "campaign", columns: ["id"], onDelete: .restrict)
                        t.foreignKey(["donation_incentive_id"], references: "donation_incentive", columns: ["id"], onDelete: .restrict)

                    }
                    // Create donation indexes
                    try db.create(index: "idx_donation_donor", on: "donation", columns: ["donor_id"])
                    try db.create(index: "idx_donation_campaign", on: "donation", columns: ["campaign_id"])
                    try db.create(index: "idx_donation_date", on: "donation", columns: ["donation_date"])
                    try db.create(index: "idx_donation_uuid", on: "donation", columns: ["uuid"])
                    // Create update trigger for donation timestamps
                    try db.execute(sql: """
                        CREATE TRIGGER IF NOT EXISTS update_donation_timestamp 
                        AFTER UPDATE ON donation
                        BEGIN
                            UPDATE donation SET updated_at = CURRENT_TIMESTAMP 
                            WHERE id = NEW.id;
                        END;
                    """)
                    print("Donation table created successfully")
                } else {
                    print("Donation table already exists")
                }
                

                
            }
        }
    }
extension DatabaseManager {
    func updateDonationTableForReceipts() throws {
        try dbPool.write { db in
            let receiptStatusExists = try db.columns(in: "donation").contains { column in
                column.name == "receipt_status"
            }
            
            if !receiptStatusExists {
                try db.alter(table: "donation") { t in
                    t.add(column: "receipt_status", .text).notNull().defaults(to: "NOT_REQUESTED")
                }
                // Also update existing rows where requestPrintedReceipt is true
//                try db.execute(sql: """
//                    UPDATE donation
//                    SET receipt_status = 'REQUESTED'
//                    WHERE request_printed_receipt = 1
//                    """)
            }
        }
    }
}
