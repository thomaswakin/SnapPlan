//
//  SnapPlanApp.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI

@main
struct SnapPlanApp: App {
    @StateObject var settings = Settings()
    @StateObject var taskFormatter = TaskFormatter()
    
    let persistenceController = PersistenceController.shared
    
    let viewModel = TaskViewModel(context: PersistenceController.shared.container.viewContext)

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(settings)
        }
    }
}
