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
    @Published var showTodo: Bool = true
    @Published var showDoing: Bool = false
    @Published var showDone: Bool = false
    @Published var sortByDueDate: Bool = true
    @Published var isFocusMode: Bool = false
    @EnvironmentObject var settings: Settings
    
    @Published var isTaskDone: Bool = false
    @Published var celebrationPhrases: [String] = [
        "Excellent!", "Good Job!", "You Did It!", "Keep up the good work",
        "Fantastic!", "Outstanding!", "Bravo!", "Well Done!",
        "Superb!", "Impressive!", "Marvelous!", "Stellar!",
        "First-rate!", "Top-notch!", "A+ Work!", "Exceptional!",
        "Splendid!", "Magnificent!", "You're a Star!", "You're a Pro!",
        "You're a Genius!", "You're a Master!", "You're Unstoppable!", "You're on Fire!",
        "You're Amazing!", "You're Incredible!", "You're Awesome!", "You're Fantastic!",
        "You're a Winner!", "You're a Champion!", "You're a Hero!", "You're a Leader!",
        "You're a Trailblazer!", "You're a Pioneer!", "You're an Innovator!", "You're an Ace!",
        "You're a Virtuoso!", "You're a Maestro!", "You're a Wizard!", "You're a Guru!",
        "You're a Dynamo!", "You're a Whiz!", "You're a Prodigy!", "You're a Maven!",
        "You're a Phenom!", "You're a Legend!", "You're a Titan!", "You're a Giant!",
        "You're a Conqueror!", "You're a Gladiator!", "You're a Warrior!", "You're a Commander!",
        "You're a Captain!", "You're a Chief!", "You're a King!", "You're a Queen!",
        "You're a Boss!", "You're a Mastermind!", "You're a Virtuoso!", "You're a Maestro!",
        "You're a Genius!", "You're a Pro!", "You're a Star!", "You're a Hero!",
        "You're a Leader!", "You're a Pioneer!", "You're an Innovator!", "You're an Ace!",
        "You're a Trailblazer!", "You're a Virtuoso!", "You're a Maestro!", "You're a Wizard!",
        "You're a Guru!", "You're a Dynamo!", "You're a Whiz!", "You're a Prodigy!",
        "You're a Maven!", "You're a Phenom!", "You're a Legend!", "You're a Titan!",
        "You're a Giant!", "You're a Conqueror!", "You're a Gladiator!", "You're a Warrior!",
        "You're a Commander!", "You're a Captain!", "You're a Chief!", "You're a King!",
        "You're a Queen!", "You're a Boss!", "You're a Mastermind!"
    ]
    
    @Published var celebrationSymbols: [String] = [
        "checkmark", "checkmark.circle", "checkmark.circle.fill", "star", "star.fill",
        "star.circle", "star.circle.fill", "staroflife", "staroflife.fill", "star.lefthalf.fill",
        "sparkles", "sparkle", "crown", "crown.fill", "rosette",
        "gift", "gift.fill", "gift.circle", "gift.circle.fill", "tortoise.fill",
        "hare.fill", "flame", "flame.fill", "bolt", "bolt.fill",
        "bolt.circle", "bolt.circle.fill", "bolt.badge.a", "bolt.badge.a.fill", "bolt.heart",
        "bolt.heart.fill", "hand.thumbsup", "hand.thumbsup.fill", "hand.thumbsup.circle", "hand.thumbsup.circle.fill",
        "smiley", "smiley.fill", "heart", "heart.fill", "heart.circle",
        "heart.circle.fill", "bell", "bell.fill", "bell.circle", "bell.circle.fill",
        "flag", "flag.fill", "flag.circle", "flag.circle.fill", "pencil",
        "pencil.circle", "pencil.circle.fill", "pencil.and.outline", "pencil.tip", "pencil.tip.crop.circle",
        "pencil.tip.crop.circle.badge.plus", "pencil.tip.crop.circle.badge.minus", "pencil.tip.crop.circle.badge.arrow.forward", "pencil.tip.crop.circle.badge.arrow.backward"
    ]
    
    private var taskObservers: [NSKeyValueObservation] = []
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchTasks()
    }
    
    func fetchTasks() {
        //let request: NSFetchRequest<SnapPlanTask> = SnapPlanTask.fetchRequest()
        var sortDescriptors: [NSSortDescriptor] = []

        // Add sorting descriptors based on sortByDueDate
        if sortByDueDate {
            sortDescriptors.append(NSSortDescriptor(key: "dueDate", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "priorityScore", ascending: false))
        } else {
            sortDescriptors.append(NSSortDescriptor(key: "priorityScore", ascending: false))
            sortDescriptors.append(NSSortDescriptor(key: "dueDate", ascending: true))
        }
        
        let request: NSFetchRequest<SnapPlanTask> = SnapPlanTask.fetchRequest()
        request.sortDescriptors = sortDescriptors
        
        print("TaskViewModel:fetchTasks")
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

    func toggleSortingMode() {
        sortByDueDate.toggle()
        fetchTasks()
    }
    
    func applyFilters(showTodo: Bool, showDoing: Bool, showDone: Bool) {
        filteredTasks = tasks.filter { task in
            // Apply text filter
            print("TaskViewModel:applyFilters")
            let matchesTextFilter = searchText.isEmpty ||
                                    task.note?.lowercased().contains(searchText.lowercased()) == true ||
                                    (task.dueDate as Date?)?.description.lowercased().contains(searchText.lowercased()) == true
            
            // Apply state filter
            let matchesStateFilter = (showTodo && task.state == "Todo") ||
                                     (showDoing && task.state == "Doing") ||
                                     (showDone && task.state == "Done")

            // Apply priority filter
            let matchesPriorityFilter = task.priorityScore >= Int16(priorityFilter)
            
            if tasks.contains(where: { $0.state == "Done" }) {
                isTaskDone = true
            }
            
            return matchesTextFilter && matchesStateFilter && matchesPriorityFilter
        }
    }

    
    func addTask()  -> SnapPlanTask? {
        let newTask = SnapPlanTask(context: viewContext)
        print("TaskViewModel:addTask")
        newTask.id = UUID()
        newTask.state = "Todo"
        newTask.dueDate = Date()
        newTask.priorityScore = 5
        newTask.note = ""
        
        do {
            try viewContext.save()
            fetchTasks()  // Refresh the task list
            return newTask
        } catch {
            print("Failed to save new task:", error)
            return nil
        }
    }
    
    func forceRefresh() {
        print("TaskViewModel:forceRefresh")
        needsRefresh.toggle()
    }
    
}
