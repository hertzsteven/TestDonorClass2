//
//  MyHeaderStyle.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/27/25.
//


import SwiftUI

struct MyHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.bottom, 8)
            .padding(.top, 15) // Reduced from 50 for better spacing
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary) // Add to ensure visibility
        
        //            .frame(maxWidth: .infinity, alignment: .leading)
        //            .padding(.leading, 20)
        //            .padding(.bottom, 8)
        //            .padding(.top, 50)
        //            .font(.title2)
        //            .fontWeight(.bold)
    }
}

extension View {
    func myHeaderStyle() -> some View {
        self.modifier(MyHeaderStyle())
    }
}
