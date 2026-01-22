//
//  ContentView.swift
//  ScalsRenderer
//
//  Main app view with tabs for Examples and JSON Playground.
//

import ScalsExamples
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScalsExamplesView()
                .tabItem {
                    Label("Examples", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            JSONPlaygroundView()
                .tabItem {
                    Label("Playground", systemImage: "curlybraces")
                }
                .tag(1)
        }
    }
}
