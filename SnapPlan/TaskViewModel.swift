//
//  TaskViewModel.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import Foundation
import SwiftUI
import CoreData

class TaskViewModel: ObservableObject {
    @Published var tasks: [SnapPlanTask] = []
    @Published var filteredTasks: [SnapPlanTask] = []
    @Published var searchText: String = ""
    @Published var selectedTab: Int = 0
    @Published var priorityFilter: Double = 0
    @Published var isTaskCardView: Bool = true
    @Published var needsRefresh: Bool = false
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchTasks()
    }
    
    func fetchTasks() {
        let request: NSFetchRequest<SnapPlanTask> = SnapPlanTask.fetchRequest()
        do {
            tasks = try viewContext.fetch(request)
            applyFilters()
        } catch {
            print("Failed to fetch tasks:", error)
        }
    }
    
    func applyFilters() {
        filteredTasks = tasks.filter { task in
            // Apply text filter
            let matchesTextFilter = searchText.isEmpty || task.note?.contains(searchText) == true || (task.dueDate as Date?)?.description.contains(searchText) == true
            
            // Apply state filter
            let matchesStateFilter: Bool
            switch selectedTab {
            case 0: matchesStateFilter = task.state == "Todo"
            case 1: matchesStateFilter = task.state == "Doing"
            case 2: matchesStateFilter = task.state == "Done"
            default: matchesStateFilter = true
            }
            
            // Apply priority filter
            let matchesPriorityFilter = task.priorityScore >= Int16(priorityFilter)
            
            return matchesTextFilter && matchesStateFilter && matchesPriorityFilter
        }
    }
    
    func addTask() {
        let newTask = SnapPlanTask(context: viewContext)
        newTask.id = UUID()
        newTask.state = "Todo"
        newTask.dueDate = Date()
        newTask.priorityScore = 50
        newTask.note = ""
        
        do {
            try viewContext.save()
            fetchTasks()
        } catch {
            print("Failed to save new task:", error)
        }
    }
    
    func forceRefresh() {
        needsRefresh.toggle()
    }
    
}
