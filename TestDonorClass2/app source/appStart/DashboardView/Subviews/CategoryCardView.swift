//
//  CategoryCardView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/27/25.
//

import SwiftUI

struct CategoryCardView: View {
    let category: Category

    private let iconSize: CGFloat = 40
    private let imageSize: CGFloat = 20
    private let cornerRadius: CGFloat = 12
    
    var body: some View {
        HStack(spacing: 15) {
            categoryIcon()
            Text(category.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 15)
    }
}

extension CategoryCardView {
    // MARK: - Component Views
    
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