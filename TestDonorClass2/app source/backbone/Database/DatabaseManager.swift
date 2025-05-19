//
//  DatabaseManager.swift
//  Understanding Passing into mvvm
//
//  Created by Steven Hertz on 12/17/24.
//
import GRDB
import Foundation

// MARK: - Database Errors
enum DatabaseError: LocalizedError {
    case notConnected
    case migrationFailed(String)
    case databaseSetupFailed(String)
    case connectionError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Database connection not established"
        case .migrationFailed(let reason):
            return "Database migration failed: \(reason)"
        case .databaseSetupFailed(let reason):
            return "Database setup failed: \(reason)"
        case .connectionError(let reason):
            return "Database connection error: \(reason)"
        }
    }
}

// MARK: - DatabaseManager
final class DatabaseManager {
    // MARK: - Properties
    private(set) var dbName: String = "donations_db.sqlite"
//    let dbName: String = "donations_db.sqlite"
    static let shared = DatabaseManager()
    private var dbPool: DatabasePool?
    
    // MARK: - Initialization
    private init() {
        do {
            try connectToDB()
        } catch {
            fatalError("Failed to initialize database: \(error.localizedDescription)")
        }
    }
//    func setDatabaseURL(_ dbname: String) throws {
//        // Close any old connection
//        if let oldPool = dbPool {
//            try oldPool.close()
//            dbPool = nil
//        }
//        self.dbName = dbname.appending(".sqlite")
//
//    }
    
    // MARK: - Public Methods
    func connectToDB() throws {
        let fileManager = FileManager.default
        let databaseURL: URL
        
        do {
            databaseURL = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent(ApplicationData.shared.selectedDatabase!)
            
            guard let bundleURL = Bundle.main.url(forResource: "donations_db", withExtension: "sqlite") else {
                throw DatabaseError.databaseSetupFailed("Could not find database file in bundle")
            }
            
            if !fileManager.fileExists(atPath: databaseURL.path) {
                print("DB file not found in Application Support, copying from bundle.")
                try fileManager.copyItem(at: bundleURL, to: databaseURL)
            } else {
                print("DB file found in Application Support.")
                print(databaseURL.path)
            }
            
            dbPool = try DatabasePool(path: databaseURL.path)
            
            try dbPool?.write { db in
                try db.execute(sql: "PRAGMA foreign_keys = ON;")
            }
            
            guard let pool = dbPool else {
                throw DatabaseError.notConnected
            }
            
            try migrator.migrate(pool)
            print("Database migrations completed successfully")
            checkMigrationStatus()
            
        } catch {
            throw DatabaseError.databaseSetupFailed(error.localizedDescription)
        }
    }
    
    func getDbPool() throws -> DatabasePool {
        guard let pool = dbPool else {
            throw DatabaseError.notConnected
        }
        return pool
    }
    
    func closeConnections() throws {
        guard let pool = dbPool else { return }
        do {
            try pool.close()
            dbPool = nil
        } catch {
            throw DatabaseError.connectionError("Failed to close database: \(error.localizedDescription)")
        }
    }
    
    func testDatabaseConnection() throws {
        // Print database path
        print("Database path: \(dbPool?.path ?? "")")
        do {
            try dbPool?.write { db in
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
    
    func checkMigrationStatus() {
        do {
            try dbPool?.read { db in
                let migrations = try Row.fetchAll(db, sql: "SELECT * FROM grdb_migrations ORDER BY identifier ASC")
                print("\n=== Applied Migrations ===")
                for migration in migrations {
                    if let identifier: String = migration["identifier"] {
                        print("- \(identifier)")
                    }
                }
                print("=======================\n")
            }
        } catch {
            print("Failed to check migrations:", error)
        }
    }
}

extension DatabaseManager {
    // MARK: - Database Migrator Definition
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
#if DEBUG
        // For development: Erase and re-migrate database on every launch.
        // Useful for quickly testing schema changes. Disable for production!
        // migrator.eraseDatabaseOnSchemaChange = true
#endif
        
        // --- Migration 1: Initial Schema Creation ---
        migrator.registerMigration("v1_initialSchema") { db in
            print("Running migration: v1_initialSchema") // Add logging
            if try !db.tableExists("donor") {
                print("Creating donor table...") // Add logging
                                                 // Create donors table
                try db.create(table: "donor") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("uuid", .text).notNull().unique()
                    t.column("company", .text)
                    t.column("salutation", .text)
                    t.column("first_name", .text)
                    t.column("last_name", .text)
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
            } else {
                print("Donor table already exists, skipping creation.")
            }
            
            // Create campaigns table
            if try !db.tableExists("campaign") {
                print("Creating campaign table...") // Add logging
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
                print("campaign  table already exists, skipping creation.")
            }
            
            if try !db.tableExists("donation_incentive") {
                print("Creating donation_incentive table...") // Add logging
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
                // Create incentive indexes
                try db.create(index: "idx_incentive_name", on: "donation_incentive", columns: ["name"])
                try db.create(index: "idx_incentive_status", on: "donation_incentive", columns: ["status"])
                try db.create(index: "idx_incentive_amount", on: "donation_incentive", columns: ["dollar_amount"])
                
            } else {
                print("donation_incentive table already exists, skipping creation.")
            }
            
            
            // Create donations table (without receipt_status initially, we'll add it later)
            if try !db.tableExists("donation") {
                try db.create(table: "donation") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("uuid", .text).notNull().unique()
                    t.column("donor_id", .integer).references("donor", onDelete: .restrict) // Changed from setNull
                    t.column("campaign_id", .integer).references("campaign", onDelete: .restrict) // Changed from setNull
                    t.column("donation_incentive_id", .integer).references("donation_incentive", onDelete: .restrict) // Added reference
                    t.column("amount", .double).notNull()
                    t.column("donation_type", .text).notNull()
                    t.column("payment_status", .text).notNull().defaults(to: "PENDING") // Added default
                                                                                        // t.column("receipt_status", .text) // <-- Leave out for now
                    t.column("transaction_number", .text)
                    t.column("receipt_number", .text)
                    t.column("payment_processor_info", .text)
                    t.column("request_email_receipt", .boolean).notNull().defaults(to: false)
                    t.column("request_printed_receipt", .boolean).notNull().defaults(to: false)
                    t.column("notes", .text)
                    t.column("is_anonymous", .boolean).notNull().defaults(to: false)
                    t.column("donation_date", .datetime).notNull() // Default set in Swift often
                    t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                }
                // Create donation indexes
                try db.create(index: "idx_donation_donor", on: "donation", columns: ["donor_id"])
                try db.create(index: "idx_donation_campaign", on: "donation", columns: ["campaign_id"])
                try db.create(index: "idx_donation_incentive", on: "donation", columns: ["donation_incentive_id"]) // Added index
                try db.create(index: "idx_donation_date", on: "donation", columns: ["donation_date"])
                try db.create(index: "idx_donation_uuid", on: "donation", columns: ["uuid"])
            } else {
                print("donation table already exists, skipping creation.")
            }
        }
        // --- Migration 2: Add Timestamp Triggers ---
        // Separating triggers can make migrations cleaner
        migrator.registerMigration("v2_addTimestampTriggers") { db in
            print("Running migration: v2_addTimestampTriggers") // Add logging
            
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS update_donor_timestamp AFTER UPDATE ON donor
                BEGIN UPDATE donor SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id; END;
            """)
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS update_donation_timestamp AFTER UPDATE ON donation
                BEGIN UPDATE donation SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id; END;
            """)
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS update_campaign_timestamp AFTER UPDATE ON campaign
                BEGIN UPDATE campaign SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id; END;
            """)
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS update_donation_incentive_timestamp AFTER UPDATE ON donation_incentive
                BEGIN UPDATE donation_incentive SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id; END;
            """)
        }
        
        // --- Migration 3: Add Receipt Status Column ---
        // This replicates what updateDonationTableForReceipts did
        migrator.registerMigration("v3_addReceiptStatus") { db in
            print("Running migration: v3_addReceiptStatus") // Add logging
            
            let receiptStatusExists = try db.columns(in: "donation").contains { column in
                column.name == "receipt_status"
            }
            
            if !receiptStatusExists {
                try db.alter(table: "donation") { t in
                    t.add(column: "receipt_status", .text).notNull().defaults(to: "NOT_REQUESTED")
                }
            } else {
                print("receipt_status column already exists, skipping addition.")
            }
            // Optionally update existing rows if needed, though likely not necessary if just adding
            // try db.execute(sql: "UPDATE donation SET receipt_status = 'REQUESTED' WHERE request_printed_receipt = 1 AND receipt_status = 'NOT_REQUESTED'")
        }
        
        // --- Migration 4: Create Pledge Table
        migrator.registerMigration("v4_createPledgeTable") { db in
            print("Running migration: v4_createPledgeTable")
            
            // Create pledge table
            if try !db.tableExists(Pledge.databaseTableName) {
                print("Creating \(Pledge.databaseTableName) table...")
                try db.create(table: Pledge.databaseTableName) { t in
                    t.autoIncrementedPrimaryKey(Pledge.Columns.id.name)
                    t.column(Pledge.Columns.uuid.name, .text).notNull().unique()
                    t.column(Pledge.Columns.donorId.name, .integer).references("donor", onDelete: .restrict)
                    t.column(Pledge.Columns.campaignId.name, .integer).references("campaign", onDelete: .restrict)
                    t.column(Pledge.Columns.pledgeAmount.name, .double).notNull()
                    t.column(Pledge.Columns.currentBalance.name, .double).notNull()
                    t.column(Pledge.Columns.status.name, .text).notNull() // Raw value of PledgeStatus enum
                    t.column(Pledge.Columns.expectedFulfillmentDate.name, .date).notNull()
                    t.column(Pledge.Columns.prayerNote.name, .text)
                    t.column(Pledge.Columns.notes.name, .text)
                    t.column(Pledge.Columns.createdAt.name, .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                    t.column(Pledge.Columns.updatedAt.name, .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                }
                // Create pledge indexes
                try db.create(index: "idx_pledge_donor", on: Pledge.databaseTableName, columns: [Pledge.Columns.donorId.name])
                try db.create(index: "idx_pledge_campaign", on: Pledge.databaseTableName, columns: [Pledge.Columns.campaignId.name])
                try db.create(index: "idx_pledge_status", on: Pledge.databaseTableName, columns: [Pledge.Columns.status.name])
                try db.create(index: "idx_pledge_fulfillment_date", on: Pledge.databaseTableName, columns: [Pledge.Columns.expectedFulfillmentDate.name])
                try db.create(index: "idx_pledge_uuid", on: Pledge.databaseTableName, columns: [Pledge.Columns.uuid.name])

                // Add timestamp trigger for pledge table
                try db.execute(sql: """
                    CREATE TRIGGER IF NOT EXISTS update_pledge_timestamp AFTER UPDATE ON \(Pledge.databaseTableName)
                    BEGIN UPDATE \(Pledge.databaseTableName) SET \(Pledge.Columns.updatedAt.name) = CURRENT_TIMESTAMP WHERE \(Pledge.Columns.id.name) = NEW.\(Pledge.Columns.id.name); END;
                """)
                print("\(Pledge.databaseTableName) table and trigger created.")
            } else {
                // MODIFY: If the table already exists (from a previous incorrect run of this migration), add the column
                print("\(Pledge.databaseTableName) table already exists. Checking for \(Pledge.Columns.currentBalance.name) column.")
                let columns = try db.columns(in: Pledge.databaseTableName)
                if !columns.contains(where: { $0.name == Pledge.Columns.currentBalance.name }) {
                    print("Adding column \(Pledge.Columns.currentBalance.name) to \(Pledge.databaseTableName).")
                    try db.alter(table: Pledge.databaseTableName) { t in
                        // Add with a default, assuming existing pledges should have balance = pledgeAmount initially
                        // Or handle default value population manually if more complex logic is needed.
                        // For simplicity, defaulting to 0 and requiring manual update or assuming new pledges only.
                        // A better default for existing records might be to set current_balance = pledge_amount.
                        // Let's make it NOT NULL and default to 0, and handle initialization in code.
                        // However, our model's init sets currentBalance to pledgeAmount, so the table should reflect that expectation.
                        // Defaulting to 0 is safer for ALTER TABLE if existing rows have no obvious default.
                        // It's better if this migration is run on a clean slate. If not, data integrity for existing rows
                        // for current_balance needs careful handling.
                        // For new table creation, NOT NULL is fine as init handles it.
                        // For ALTER, NOT NULL requires a DEFAULT or all rows updated.
                        // Since our model now initializes currentBalance to pledgeAmount, we can expect new inserts to be fine.
                        // For existing rows (if any were created by an older v4 migration without currentBalance),
                        // they would need manual updating.
                        // Simplest for ALTER is `ADD COLUMN current_balance DOUBLE NOT NULL DEFAULT 0` and then an UPDATE statement.
                        // Or, make it nullable and handle logic in app.
                        // Given our model `currentBalance` is non-optional and defaults to `pledgeAmount`,
                        // we'll add it as NOT NULL. If altering, a default value is necessary.
                        // `t.add(column: Pledge.Columns.currentBalance.name, .double).notNull().defaults(to: 0.0)` would work for alter.
                        // Then you might run: `UPDATE pledge SET current_balance = pledge_amount WHERE current_balance = 0;`
                        // However, since we are in the `if !db.tableExists` block for *creation*, this is fine.
                        // The `else` block handles the ALTER case.
                        t.add(column: Pledge.Columns.currentBalance.name, .double).defaults(to: 0.0) // Default for existing rows if any
                    }
                    // Update existing rows to set current_balance = pledge_amount
                    // This is crucial if the table was created by a faulty v4 migration without current_balance
                    try db.execute(sql: "UPDATE \(Pledge.databaseTableName) SET \(Pledge.Columns.currentBalance.name) = \(Pledge.Columns.pledgeAmount.name) WHERE \(Pledge.Columns.currentBalance.name) = 0.0")

                    print("Column \(Pledge.Columns.currentBalance.name) added to \(Pledge.databaseTableName). Existing rows updated.")
                } else {
                    print("Column \(Pledge.Columns.currentBalance.name) already exists in \(Pledge.databaseTableName).")
                }
            }
        }
        // --- Future Migrations ---
        // If you need to add, say, an 'email_verified' column to donor later:
        /*
        migrator.registerMigration("v5_addDonorEmailVerified") { db in
            print("Running migration: v5_addDonorEmailVerified")
            try db.alter(table: "donor") { t in
                t.add(column: "email_verified", .boolean).defaults(to: false)
            }
        }
        */
        
        return migrator
    }
}
// FIXME: - Not Used Currently
// MARK: - Record Protocols
protocol DatabaseModel: Codable {
    var id: Int { get }  // Changed from UUID to Int since we're using auto-increment
    var uuid: UUID { get }  // Added UUID as a separate requirement
}
