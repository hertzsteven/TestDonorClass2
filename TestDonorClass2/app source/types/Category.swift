//
//  Category.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/27/25.
//



import SwiftUI

struct Category: Identifiable, Hashable {

    var id = UUID().uuidString
    let name: String
    let color: Color
    let image: Image
    let count: Int
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
