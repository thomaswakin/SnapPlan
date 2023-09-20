//
//  SnapPlanApp.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI
import CoreData

@main
struct SnapPlanApp: App {
    @StateObject var settings = Settings()
    @StateObject var taskFormatter = TaskFormatter()
    
    let persistenceController = PersistenceController.shared
    
    let viewModel = TaskViewModel(context: PersistenceController.shared.container.viewContext)

    init() {
        migrateTaskPriorities()
    }

    // Migrate old priority (1-50, or 1-10 to new 1,2,3)
    func migrateTaskPriorities() {
        let viewContext = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<SnapPlanTask> = SnapPlanTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "priorityScore > 3")
        
        do {
            let tasks = try viewContext.fetch(fetchRequest)
            
            // Only proceed if there are tasks with priority greater than 3
            if tasks.isEmpty {
                return
            }
            
            for task in tasks {
                let priority = task.priorityScore
                if priority >= 1 && priority <= 15 {
                    task.priorityScore = 1
                } else if priority >= 16 && priority <= 30 {
                    task.priorityScore = 2
                } else if priority >= 31 {
                    task.priorityScore = 3
                }
            }
            try viewContext.save()
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }

    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(Settings.shared)
        }
    }
}
