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
            do {
                let databaseURL = try FileManager.default
                    .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent(dbName)
                dbPool = try DatabasePool(path: databaseURL.path)
                print(databaseURL.absoluteString)
                    // Add this line to ensure table exists
                     try ensureDonorTableExists()

            // Migrate database
            //                try migrator.migrate(dbPool)
            } catch {
                fatalError("Database initialization failed: \(error)")
            }
        }
        func getDbPool() -> DatabasePool {
            dbPool
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
                    t.column("first_name", .text).notNull()
                    t.column("last_name", .text).notNull()
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
            // Check if table exists
            let tableExists = try db.tableExists("donor")
            if !tableExists {
                print("Donor table does not exist. Creating...")
                // Create donors table
                try db.create(table: "donor") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("uuid", .text).notNull().unique()
                    t.column("salutation", .text)
                    t.column("first_name", .text).notNull()
                    t.column("last_name", .text).notNull()
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
                // Create update trigger for timestamps
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
        }
    }
}
    //extension DatabaseManager {
    //    func testDatabaseConnection() {
    //        do {
    //            try dbPool.write { db in
    //                    // List all tables
    //                let tables = try String.fetchAll(db, sql: """
    //                    SELECT name FROM sqlite_master
    //                    WHERE type='table'
    //                    ORDER BY name
    //                    """)
    //                print("All tables in database:", tables)
    //
    //                    // Try to read customer table
    //                let customerCount = try Customer.fetchCount(db)
    //                print("Customer table exists with \(customerCount) records")
    //
    //                    // Try to read product table
    //                let productCount = try Product.fetchCount(db)
    //                print("Product table exists with \(productCount) records")
    //
    //                    // Try to read interests table
    //                let interestCount = try CustomerProductInterest.fetchCount(db)
    //                print("CustomerProductInterest table exists with \(interestCount) records")
    //            }
    //        } catch {
    //            print("Database test failed: \(error)")
    //        }
    //    }
    //
    //    func addTestDataIfNeeded() {
    //        do {
    //            try dbPool.write { db in
    //                    // Check if we have any customers
    //                let customerCount = try Customer.fetchCount(db)
    //
    //                if customerCount == 0 {
    //                        // Add test customer
    //                    let testCustomer = Customer(id: UUID(), name: "Test User", age: 25)
    //                    try testCustomer.save(db)
    //                    print("Added test customer successfully")
    //
    //                        // Add test product
    //                    let testProduct = Product(id: UUID(), name: "Test Product", price: 99.99)
    //                    try testProduct.save(db)
    //                    print("Added test product successfully")
    //
    //                        // Test reading back the data
    //                    let customers = try Customer.fetchAll(db)
    //                    print("Retrieved customers:", customers)
    //                    let products = try Product.fetchAll(db)
    //                    print("Retrieved products:", products)
    //                }
    //            }
    //        } catch {
    //            print("Failed to add test data: \(error)")
    //        }
    //    }
    //}
    //
    //  for.swift
    //  Understanding Passing into mvvm
    //
    //  Created by Steven Hertz on 12/22/24.
    //


