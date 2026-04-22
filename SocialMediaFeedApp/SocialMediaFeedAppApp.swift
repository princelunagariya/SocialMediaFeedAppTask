//
//  SocialMediaFeedAppApp.swift
//  SocialMediaFeedApp
//
//  Created by Prince Lunagariya on 21/04/26.
//

import SwiftUI
import CoreData

@main
struct SocialMediaFeedAppApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(locationManager)
        }
    }
}
