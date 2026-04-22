//
//  ContentView.swift
//  SocialMediaFeedApp
//
//  Created by Prince Lunagariya on 21/04/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)

            CreatePostView()
                .tabItem {
                    Label("New Post", systemImage: "plus.circle.fill")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocationManager())
}
