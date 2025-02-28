//
//  GridOfCategoriesSubView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/27/25.
//


import SwiftUI


struct GridOfCategoriesSubView: View {
    let categories: [Category]
    let sections: [DashboardSection]
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    let gridSpacing: CGFloat = 20
    
    var body: some View {
        //        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 170), spacing: 15)], spacing: 20) {
        LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(sections) { section in
                headerViewFunc(section)
            }
        }
        .padding()
    }
}


extension GridOfCategoriesSubView {
    
    fileprivate func getSectionCategories(_ section: DashboardSection) -> [Category] {
        return Array(categories[section.startIndex..<(section.startIndex + section.count)])
    }
    
    fileprivate func headerViewFunc(_ section: DashboardSection) -> some View {
        return
        Section(header: Text(section.title)
            .myHeaderStyle()) {
                let sectionCategories = getSectionCategories(section)
                ForEach(sectionCategories) { category in
                    categoryViewFunc(category)
                }
            }
    }
    
    fileprivate func categoryViewFunc(_ category: Category) -> NavigationLink<some View, Never> {
        return
        NavigationLink(value: category) {
            CategoryCardView(category: category)
                .padding()
                .background(category.color.opacity(0.2))
                .cornerRadius(10)
        }
    }
    
}
