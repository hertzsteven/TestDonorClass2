//
//  PostalAddressNormalizer.swift
//  TestDonorClass2
//
//  Single responsibility: reduce postal text to a canonical form used only for
//  comparison. Nothing here is ever displayed or persisted.
//

import Foundation

/// Canonicalizes postal text so two spellings of the same address compare as
/// equal. "10 Roosevelt Ave.", "10 ROOSEVELT AVENUE" and "10  Roosevelt  Ave"
/// all reduce to the same key.
enum PostalAddressNormalizer {

    /// Canonical key for a street, unit, city or state component.
    static func normalized(_ value: String?) -> String {
        guard let value else { return "" }

        let folded = value
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: nil)
            .uppercased()

        return folded
            .split { !$0.isLetter && !$0.isNumber }
            .map { canonicalForms[String($0)] ?? String($0) }
            .joined(separator: " ")
    }

    /// Canonical key for a postal code. Only the first five digits participate,
    /// so a record carrying ZIP+4 still matches the same five-digit ZIP.
    static func normalizedZip(_ value: String?) -> String {
        guard let value else { return "" }
        return String(value.filter(\.isNumber).prefix(5))
    }

    /// USPS Publication 28 forms for the suffixes, directionals and unit
    /// designators that turn up in donor records. Values already in canonical
    /// form are absent from the table and pass through untouched.
    private static let canonicalForms: [String: String] = [
        // Street suffixes
        "ALLEY": "ALY",
        "AVENUE": "AVE",
        "BOULEVARD": "BLVD",
        "BRANCH": "BR",
        "BRIDGE": "BRG",
        "CENTER": "CTR",
        "CIRCLE": "CIR",
        "COURT": "CT",
        "COVE": "CV",
        "CRESCENT": "CRES",
        "CROSSING": "XING",
        "DRIVE": "DR",
        "ESTATE": "EST",
        "ESTATES": "ESTS",
        "EXPRESSWAY": "EXPY",
        "EXTENSION": "EXT",
        "FREEWAY": "FWY",
        "GARDEN": "GDN",
        "GARDENS": "GDNS",
        "GROVE": "GRV",
        "HEIGHTS": "HTS",
        "HIGHWAY": "HWY",
        "HILL": "HL",
        "HILLS": "HLS",
        "ISLAND": "IS",
        "JUNCTION": "JCT",
        "LAKE": "LK",
        "LANDING": "LNDG",
        "LANE": "LN",
        "MANOR": "MNR",
        "MEADOW": "MDW",
        "MEADOWS": "MDWS",
        "MOUNT": "MT",
        "MOUNTAIN": "MTN",
        "PARKWAY": "PKWY",
        "PLACE": "PL",
        "PLAZA": "PLZ",
        "POINT": "PT",
        "RIDGE": "RDG",
        "RIVER": "RIV",
        "ROAD": "RD",
        "ROUTE": "RTE",
        "SPRING": "SPG",
        "SPRINGS": "SPGS",
        "SQUARE": "SQ",
        "STATION": "STA",
        "STREET": "ST",
        "SUMMIT": "SMT",
        "TERRACE": "TER",
        "TRAIL": "TRL",
        "TURNPIKE": "TPKE",
        "VALLEY": "VLY",
        "VIEW": "VW",
        "VILLAGE": "VLG",

        // "Saint" shares the Street abbreviation in USPS addressing
        "SAINT": "ST",

        // Directionals
        "NORTH": "N",
        "SOUTH": "S",
        "EAST": "E",
        "WEST": "W",
        "NORTHEAST": "NE",
        "NORTHWEST": "NW",
        "SOUTHEAST": "SE",
        "SOUTHWEST": "SW",

        // Secondary unit designators
        "APARTMENT": "APT",
        "BASEMENT": "BSMT",
        "BUILDING": "BLDG",
        "DEPARTMENT": "DEPT",
        "FLOOR": "FL",
        "PENTHOUSE": "PH",
        "ROOM": "RM",
        "SUITE": "STE"
    ]
}
