//
//  CoffeeTeaApp.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import SwiftUI
import SwiftData

@main
struct CoffeeTeaApp: App {
    // 菜单栏常驻配置
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BeverageRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // 使用 Settings 场景替代 WindowGroup
        Settings {
            EmptyView()
        }
        .modelContainer(sharedModelContainer)
    }
}
