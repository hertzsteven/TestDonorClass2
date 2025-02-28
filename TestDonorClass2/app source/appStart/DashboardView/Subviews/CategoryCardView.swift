//
//  CategoryCardView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/27/25.
//


import SwiftUI

struct CategoryCardView: View {
    let category: Category

    // Constants for sizing and styling
    private let cardSize = CGSize(width: 150, height: 80)
    private let iconSize: CGFloat = 30
    private let imageSize: CGFloat = 15
    private let cornerRadius: CGFloat = 10
    
    
    
    var body: some View {
            cardBackground
                .overlay(
                    HStack {
                        categoryInfo()
                            .padding([.leading],4)
                        
                        Spacer()
                        
                        Text("\(category.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .padding([.top], 4)
                            .padding([.trailing], 18)
                        //                        .hidden() // rmmove to show the number
                        Spacer()
                    }
                        .padding(.leading, 10)
                )
    }
}

extension CategoryCardView {
    // MARK: - Component Views
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray6))
            .frame(width: 150, height: 80)
            .shadow(radius: 5)
    }
    
    fileprivate func categoryIcon() -> some View {
        return ZStack {
            Circle()
                .fill(category.color)
                .frame(width: 30, height: 30)
            
            category.image
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundColor(.white)
        }
        .padding([.bottom],8)
    }
    
    fileprivate func categoryInfo() -> some View {
        return VStack(alignment: .leading, spacing: 5) {
            
            categoryIcon()
            
            Text(category.name)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
        }
    }
}
