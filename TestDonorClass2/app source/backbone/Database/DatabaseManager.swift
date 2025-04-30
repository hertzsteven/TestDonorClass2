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
    let dbName: String = "donations_db.sqlite"
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
    
    // MARK: - Public Methods
    func connectToDB() throws {
        let fileManager = FileManager.default
        let databaseURL: URL
        
        do {
            databaseURL = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent(dbName)
            
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
            
            // CHANGE: Use columns(in:) to check for column existence
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
        
        // --- Future Migrations ---
        // If you need to add, say, an 'email_verified' column to donor later:
        /*
         migrator.registerMigration("v4_addDonorEmailVerified") { db in
         print("Running migration: v4_addDonorEmailVerified")
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
