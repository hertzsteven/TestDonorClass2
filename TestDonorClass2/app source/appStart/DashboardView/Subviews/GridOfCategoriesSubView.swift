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
    @State private var hoveredCategory: Category?
    
    private let cardSpacing: CGFloat = 25
    private let sectionSpacing: CGFloat = 40
    private let cardHeight: CGFloat = 120
    private let minCardWidth: CGFloat = 200
    
    var body: some View {
        ScrollView {
            VStack(spacing: sectionSpacing) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        let cats = getSectionCategories(section)
                        HStack(alignment: .center, spacing: 0) {
                            Text(section.title)
                                .myHeaderStyle()
                            if let first = cats.first {
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: first.color.opacity(0.8), location: 0),
                                        .init(color: first.color.opacity(0.4), location: 0.3),
                                        .init(color: .clear, location: 1)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(1)
                                .padding(.leading, 8)
                                .padding(.bottom, 2)
                            }
                        }
                        .padding(.leading, 5)
                        
                        sectionLayout(categories: cats)
                    }
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
        }
    }
}

extension GridOfCategoriesSubView {
    private func sectionLayout(categories: [Category]) -> some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let cardWidth = max(minCardWidth, (availableWidth - (cardSpacing * CGFloat(categories.count - 1))) / CGFloat(categories.count))
            
            HStack(spacing: cardSpacing) {
                ForEach(categories) { category in
                    categoryViewFunc(category)
                        .frame(width: cardWidth)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: cardHeight)
    }
    
    fileprivate func getSectionCategories(_ section: DashboardSection) -> [Category] {
        return Array(categories[section.startIndex..<(section.startIndex + section.count)])
    }
    
    fileprivate func categoryViewFunc(_ category: Category) -> NavigationLink<some View, Never> {
        NavigationLink(value: category) {
            CategoryCardView(category: category)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(category.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .scaleEffect(hoveredCategory == category ? 1.03 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoveredCategory)
                .onHover { isHovered in
                    hoveredCategory = isHovered ? category : nil
                }
        }
    }
}

#Preview {
    GridOfCategoriesSubView(
        categories: [
            Category(name: "Test 1", color: .blue, image: Image(systemName: "star")),
            Category(name: "Test 2", color: .green, image: Image(systemName: "heart")),
            Category(name: "Test 3", color: .red, image: Image(systemName: "cloud"))
        ],
        sections: [
            DashboardSection(title: "Two Items", startIndex: 0, count: 2),
            DashboardSection(title: "Three Items", startIndex: 0, count: 3)
        ]
    )
    .preferredColorScheme(.light)
}
