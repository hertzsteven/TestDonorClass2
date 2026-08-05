//
//  NCOAFileParserError.swift
//  TestDonorClass2
//

import Foundation

enum NCOAFileParserError: LocalizedError, Equatable {
    case unreadableFile(String)
    case missingColumns([String])
    case noUsableRows

    /// The file is a valid NCOA file of the other kind. Reported rather than
    /// processed, because the delete file's columns are a subset of the update
    /// file's and would otherwise be accepted by the delete importer.
    case wrongFileType(expected: String, found: String)

    var errorDescription: String? {
        switch self {
        case .unreadableFile(let reason):
            "The file could not be read. \(reason)"
        case .missingColumns(let columns):
            "The file is missing required columns: \(columns.joined(separator: ", "))."
        case .noUsableRows:
            "The file contained no rows with a donor id and a new address."
        case .wrongFileType(let expected, let found):
            "This looks like the \(found), not the \(expected). Import it from the \(found) screen instead."
        }
    }
}
