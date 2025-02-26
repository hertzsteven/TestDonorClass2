//
//  Dashboard.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/26/25.
//

import SwiftUI

struct Category: Identifiable, Hashable {
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID().uuidString
    let name: String
    let color: Color
    let image: Image
    let count: Int
}

struct CategoryView: View {

    let category: Category

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(width: 150, height: 80)
                .shadow(radius: 5)
                .overlay(

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    ZStack {
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

                    Text(category.name)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.secondary)
//
//                        .font(.body)
//                        .bold()
//                        .foregroundColor(.secondary)
                }
                .padding([.leading],4)
                
                Spacer()
                
                VStack {
                    Text("\(category.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .padding([.top], 4)
                        .padding([.trailing], 18)
                        .hidden() // rmmove to show the number
                    Spacer()
                }
            }
            .padding(.leading, 10)
            )
        }
    }
}

struct Dashboard: View {
    
    let categories = [
        Category(name: "Devices", color: .blue, image: Image(systemName: "ipad.and.iphone"), count: 5),
        Category(name: "Categories", color: .green, image: Image(systemName: "folder.fill"), count: 12),
        Category(name: "Apps", color: .red, image: Image(systemName: "apps.ipad"), count: 3),
        Category(name: "NavigateToStudentAppProfile", color: .purple, image: Image(systemName: "person.3.sequence.fill"), count: 8),
        Category(name: "Classes", color: .orange, image: Image(systemName: "person.3.sequence.fill"), count: 2),
        Category(name: "Students", color: .yellow, image: Image(systemName: "person.crop.square"), count: 6)
    ]

    
    @State var path = NavigationPath()

    var backGroundView: some View {
        Color(.systemGray6)
            .opacity(0.8)
            .ignoresSafeArea()
    }
    
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                backGroundView
                gridOfCategoriesView(categories: categories)
            }
        }
        .background(.ultraThinMaterial)
        
                
            
    }
}

struct MyHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.bottom, 8)
            .padding(.top, 50)
            .font(.title2)
            .fontWeight(.bold)
    }
}

extension View {
    func myHeaderStyle() -> some View {
        self.modifier(MyHeaderStyle())
    }
}

struct MyButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.large)
            .buttonBorderShape(.capsule)
            .disabled(false)
    }
}


extension View {
    func myButtonModifier() ->  some View {
        self.modifier(MyButtonModifier())
    }
}


#Preview {
    Dashboard()
}

struct gridOfCategoriesView: View {
    let categories: [Category]
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            Section(header: Text("Device Management")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading,20)
                .padding(.bottom,12)
                .font(.title2)
                .fontWeight(.bold)) {
                    ForEach(categories.prefix(2)) { category in
                        NavigationLink(value: category) {
                            CategoryView(category: category)
                            //                                .padding()
                            //                                .background(category.color.opacity(0.2))
                            //                                .cornerRadius(10)
                        }
                    }
                }
            
            Section(header: Text("Application Management")
                .myHeaderStyle()) {
                    ForEach(Array(categories.dropFirst(2).prefix(2))) { category in
                        NavigationLink(value: category) {
                            CategoryView(category: category)
                                .padding()
                                .background(category.color.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }
            
            Section(header: Text("User Management")
                .myHeaderStyle()) {
                    ForEach(Array(categories.dropFirst(4))) { category in
                        NavigationLink(value: category) {
                            CategoryView(category: category)
                                .padding()
                                .background(category.color.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }
        }
        .padding()
        .navigationTitle("United Tiberias: Dashboard")
    }
}
