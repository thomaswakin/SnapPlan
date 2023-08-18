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
    @Published var showTodo: Bool = false
    @Published var showDoing: Bool = false
    @Published var showDone: Bool = false
    @EnvironmentObject var settings: Settings
    
    private var taskObservers: [NSKeyValueObservation] = []
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchTasks()
    }
    
    func fetchTasks() {
        let request: NSFetchRequest<SnapPlanTask> = SnapPlanTask.fetchRequest()
        do {
            tasks = try viewContext.fetch(request)
            
            // Clear any existing observers
            taskObservers.forEach { $0.invalidate() }
            taskObservers.removeAll()
            
            // Observe changes to the tasks
            taskObservers = tasks.map { task in
                task.observe(\.state, options: [.new]) { [weak self] _, _ in
                    self?.applyFilters(showTodo: self?.showTodo ?? false,
                                       showDoing: self?.showDoing ?? false,
                                       showDone: self?.showDone ?? false)
                }
            }

            applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
        } catch {
            print("Failed to fetch tasks:", error)
        }
    }

    
    func applyFilters(showTodo: Bool, showDoing: Bool, showDone: Bool) {
        filteredTasks = tasks.filter { task in
            // Apply text filter
            let matchesTextFilter = searchText.isEmpty ||
                                    task.note?.lowercased().contains(searchText.lowercased()) == true ||
                                    (task.dueDate as Date?)?.description.lowercased().contains(searchText.lowercased()) == true
            
            // Apply state filter
            let matchesStateFilter = (showTodo && task.state == "Todo") ||
                                     (showDoing && task.state == "Doing") ||
                                     (showDone && task.state == "Done")
            //let matchesStateFilter: Bool
            //switch selectedTab {
            //case 0: matchesStateFilter = task.state == "Todo"
            //case 1: matchesStateFilter = task.state == "Doing"
            //case 2: matchesStateFilter = task.state == "Done"
            //default: matchesStateFilter = true
            //}
            
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
