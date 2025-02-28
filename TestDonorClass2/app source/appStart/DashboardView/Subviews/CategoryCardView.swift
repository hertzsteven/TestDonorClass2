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
    private let cardSize = CGSize(width: 200, height: 100)
    private let iconSize: CGFloat = 40
    private let imageSize: CGFloat = 20
    private let cornerRadius: CGFloat = 12
    
    
    
    var body: some View {
            cardBackground
                .overlay(
                    HStack(spacing: 15) {
                        categoryIcon()
                            .padding(.leading, 20)
                        
                        Text(category.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                        
                    }
                )
    }
}

extension CategoryCardView {
    // MARK: - Component Views
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray6))
            .frame(width: cardSize.width, height: cardSize.height)
            .shadow(radius: 5)
    }
    
    private func categoryIcon() -> some View {
        ZStack {
            Circle()
                .fill(category.color)
                .frame(width: iconSize, height: iconSize)
            
            category.image
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .foregroundColor(.white)
        }
    }
}
