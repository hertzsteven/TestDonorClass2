//
//  StubPersonView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/9/25.
//


    //
    //  ContentView.swift
    //  LearnIpadNavigation02
    //
    //  Created by Steven Hertz on 1/9/25.
    //

import SwiftUI

struct StubPersonView: View {
    @State private var selection: Person?
    let people: [Person] = [
        Person(id: 1, name: "Steven", age: 30),
        Person(id: 2, name: "John", age: 20),
        Person(id: 3, name: "Jane", age: 25),
    ]
    var body: some View {
        NavigationSplitView {
            List(people, selection: $selection) {  person in
                    NavigationLink(value: person) {
                        Text(person.name)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("clear")
                        selection = nil
                    }) {
                        Text("Clear")
                    }
                    .buttonStyle(.plain)
                }
            }
        } detail: {
            if let person = selection {
                PersonDetailView(person: selection!)
            } else {
                Text("Select a person")
            }
        }
        .navigationDestination(for: Person.self, destination: { person in
            PersonDetailView(person: person)
        })
    }
}
struct Person: Identifiable, Hashable {
    let id: Int
    let name: String
    let age: Int
}

struct PersonDetailView: View {
    let person: Person
    var body: some View {
        Text("Hello, \(person.name)! I'm \(person.age) years old")
    }
}
//
#Preview {
    StubPersonView()
}
