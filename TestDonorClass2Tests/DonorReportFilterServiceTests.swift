//
//  DonorReportFilterServiceTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct DonorReportFilterServiceTests {

    private let service = DonorReportFilterService()
    private let calendar = Calendar(identifier: .gregorian)

    // Fixed "now": Wednesday 2026-08-05 15:30 local (calendar-day math ignores time).
    private var now: Date {
        date(year: 2026, month: 8, day: 5, hour: 15, minute: 30)
    }

    // MARK: - Date presets

    @Test func todayExcludesYesterday() {
        let todayDonor = makeDonor(id: 1, created: date(year: 2026, month: 8, day: 5, hour: 9))
        let yesterdayDonor = makeDonor(id: 2, created: date(year: 2026, month: 8, day: 4, hour: 23))

        var criteria = DonorFilterCriteria()
        criteria.addedRange.preset = .today

        let result = service.filter(
            donors: [todayDonor, yesterdayDonor],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(result.map(\.id) == [1])
    }

    @Test func last2DaysIncludesYesterdayButNotThreeDaysAgo() {
        let todayDonor = makeDonor(id: 1, created: date(year: 2026, month: 8, day: 5, hour: 10))
        let yesterdayDonor = makeDonor(id: 2, created: date(year: 2026, month: 8, day: 4, hour: 8))
        let threeDaysAgo = makeDonor(id: 3, created: date(year: 2026, month: 8, day: 3, hour: 12))

        var criteria = DonorFilterCriteria()
        criteria.addedRange.preset = .last2Days

        let result = service.filter(
            donors: [todayDonor, yesterdayDonor, threeDaysAgo],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(Set(result.compactMap(\.id)) == Set([1, 2]))
    }

    @Test func customRangeIncludesBothEndpointDays() {
        let from = date(year: 2026, month: 8, day: 1)
        let to = date(year: 2026, month: 8, day: 3)

        let before = makeDonor(id: 1, created: date(year: 2026, month: 7, day: 31, hour: 23))
        let onStart = makeDonor(id: 2, created: date(year: 2026, month: 8, day: 1, hour: 0))
        let middle = makeDonor(id: 3, created: date(year: 2026, month: 8, day: 2, hour: 12))
        let onEnd = makeDonor(id: 4, created: date(year: 2026, month: 8, day: 3, hour: 23, minute: 59))
        let after = makeDonor(id: 5, created: date(year: 2026, month: 8, day: 4, hour: 0))

        var criteria = DonorFilterCriteria()
        criteria.addedRange.preset = .custom
        criteria.addedRange.customFrom = from
        criteria.addedRange.customTo = to

        let result = service.filter(
            donors: [before, onStart, middle, onEnd, after],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(Set(result.compactMap(\.id)) == Set([2, 3, 4]))
    }

    // MARK: - Field presence

    @Test func emailPresentRejectsNilAndWhitespaceOnly() {
        let withEmail = makeDonor(id: 1, email: "a@b.com")
        let nilEmail = makeDonor(id: 2, email: nil)
        let blankEmail = makeDonor(id: 3, email: "   ")

        var criteria = DonorFilterCriteria()
        criteria.emailPresence = .present

        let result = service.filter(
            donors: [withEmail, nilEmail, blankEmail],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(result.map(\.id) == [1])
    }

    @Test func emailMissingIncludesNilAndWhitespaceOnly() {
        let withEmail = makeDonor(id: 1, email: "a@b.com")
        let nilEmail = makeDonor(id: 2, email: nil)
        let blankEmail = makeDonor(id: 3, email: "   ")

        var criteria = DonorFilterCriteria()
        criteria.emailPresence = .missing

        let result = service.filter(
            donors: [withEmail, nilEmail, blankEmail],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(Set(result.compactMap(\.id)) == Set([2, 3]))
    }

    @Test func addressMissingCatchesDonorWithAllPostalFieldsNil() {
        let noAddress = makeDonor(id: 1)
        let withStreet = makeDonor(id: 2, address: "123 Main")
        let withCityOnly = makeDonor(id: 3, city: "Brooklyn")

        var criteria = DonorFilterCriteria()
        criteria.addressPresence = .missing

        let result = service.filter(
            donors: [noAddress, withStreet, withCityOnly],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(result.map(\.id) == [1])
    }

    // MARK: - Sorting

    @Test func sortByNameAscendingOrdersByLastThenFirst() {
        let charlie = makeDonor(id: 1, firstName: "Charlie", lastName: "Adams")
        let alice = makeDonor(id: 2, firstName: "Alice", lastName: "Brown")
        let bob = makeDonor(id: 3, firstName: "Bob", lastName: "Adams")

        var criteria = DonorFilterCriteria()
        criteria.sortOption = .nameAscending

        let result = service.filter(
            donors: [charlie, alice, bob],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(result.compactMap(\.id) == [3, 1, 2])
    }

    @Test func sortByNewestAddedOrdersByCreatedAtDescending() {
        let older = makeDonor(id: 1, created: date(year: 2026, month: 8, day: 1))
        let newer = makeDonor(id: 2, created: date(year: 2026, month: 8, day: 4))
        let newest = makeDonor(id: 3, created: date(year: 2026, month: 8, day: 5))

        var criteria = DonorFilterCriteria()
        criteria.sortOption = .newestAdded

        let result = service.filter(
            donors: [older, newer, newest],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(result.compactMap(\.id) == [3, 2, 1])
    }

    @Test func sortByRecentlyUpdatedOrdersByUpdatedAtDescending() {
        let older = makeDonor(id: 1, updated: date(year: 2026, month: 8, day: 1))
        let newer = makeDonor(id: 2, updated: date(year: 2026, month: 8, day: 4))
        let newest = makeDonor(id: 3, updated: date(year: 2026, month: 8, day: 5))

        var criteria = DonorFilterCriteria()
        criteria.sortOption = .recentlyUpdated

        let result = service.filter(
            donors: [older, newer, newest],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(result.compactMap(\.id) == [3, 2, 1])
    }

    // MARK: - Combined filters

    @Test func addedAndUpdatedFiltersAndTogether() {
        // Added today AND updated today
        let both = makeDonor(
            id: 1,
            created: date(year: 2026, month: 8, day: 5, hour: 10),
            updated: date(year: 2026, month: 8, day: 5, hour: 11)
        )
        // Added today but updated yesterday
        let addedOnly = makeDonor(
            id: 2,
            created: date(year: 2026, month: 8, day: 5, hour: 9),
            updated: date(year: 2026, month: 8, day: 4, hour: 9)
        )
        // Updated today but added yesterday
        let updatedOnly = makeDonor(
            id: 3,
            created: date(year: 2026, month: 8, day: 4, hour: 9),
            updated: date(year: 2026, month: 8, day: 5, hour: 9)
        )

        var criteria = DonorFilterCriteria()
        criteria.addedRange.preset = .today
        criteria.updatedRange.preset = .today

        let result = service.filter(
            donors: [both, addedOnly, updatedOnly],
            criteria: criteria,
            now: now,
            calendar: calendar
        )

        #expect(result.map(\.id) == [1])
    }

    // MARK: - Helpers

    private func makeDonor(
        id: Int,
        firstName: String? = "Test",
        lastName: String? = "Donor",
        email: String? = nil,
        address: String? = nil,
        city: String? = nil,
        created: Date? = nil,
        updated: Date? = nil
    ) -> Donor {
        var donor = Donor(
            firstName: firstName,
            lastName: lastName,
            address: address,
            city: city,
            email: email,
            createdAt: created ?? now,
            updatedAt: updated ?? created ?? now
        )
        donor.id = id
        return donor
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}
