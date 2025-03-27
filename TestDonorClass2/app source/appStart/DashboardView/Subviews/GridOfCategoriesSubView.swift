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
    
    // MODIFY: Refined layout constants
    private let cardSpacing: CGFloat = 25
    private let sectionSpacing: CGFloat = 40
    private let cardHeight: CGFloat = 120
    
    var body: some View {
        ScrollView {
            VStack(spacing: sectionSpacing) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 15) {
                        // Section Header
                        Text(section.title)
                            .myHeaderStyle()
                            .padding(.leading, 5)
                        
                        // Section Content
                        let sectionCategories = getSectionCategories(section)
                        sectionLayout(categories: sectionCategories)
                    }
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

extension GridOfCategoriesSubView {
    private func sectionLayout(categories: [Category]) -> some View {
        GeometryReader { geometry in
            HStack(spacing: cardSpacing) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    categoryViewFunc(category)
                        .frame(width: calculateCardWidth(
                            totalWidth: geometry.size.width,
                            cardCount: categories.count
                        ))
                }
            }
        }
        .frame(height: cardHeight)
    }
    
    private func calculateCardWidth(totalWidth: CGFloat, cardCount: Int) -> CGFloat {
        let totalSpacing = cardSpacing * CGFloat(cardCount - 1)
        return (totalWidth - totalSpacing) / CGFloat(cardCount)
    }
    
    fileprivate func getSectionCategories(_ section: DashboardSection) -> [Category] {
        return Array(categories[section.startIndex..<(section.startIndex + section.count)])
    }
    
    fileprivate func categoryViewFunc(_ category: Category) -> NavigationLink<some View, Never> {
        NavigationLink(value: category) {
            CategoryCardView(category: category)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
                        )
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.opacity(0.1))
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: hoveredCategory == category ? 8 : 4,
                            x: 0,
                            y: hoveredCategory == category ? 4 : 2
                        )
                )
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
