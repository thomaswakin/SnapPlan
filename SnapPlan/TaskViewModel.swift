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
    @Published var isTaskDone: Bool = false
    @EnvironmentObject var settings: Settings
    @Published var showCelebration: Bool = false
    @Published var currentCelebrationPhrase: String = ""
    @Published var currentCelebrationSymbol: String = ""
    @NSManaged public var previousState: String?
    @Published var previousTaskStates: [UUID: String] = [:]
    
    private var taskObservers: [NSKeyValueObservation] = []
    private var viewContext: NSManagedObjectContext
    
    @Published var celebrationSymbols: [String] = [   "checkmark", "checkmark.circle", "checkmark.circle.fill", "star", "star.fill", "star.circle", "star.circle.fill", "staroflife", "staroflife.fill", "star.lefthalf.fill", "sparkles", "sparkle", "crown", "crown.fill", "rosette", "gift", "gift.fill", "gift.circle", "gift.circle.fill", "tortoise.fill", "hare.fill", "flame", "flame.fill", "bolt", "bolt.fill", "bolt.circle", "bolt.circle.fill", "bolt.badge.a", "bolt.badge.a.fill", "bolt.heart","bolt.heart.fill", "hand.thumbsup", "hand.thumbsup.fill", "hand.thumbsup.circle", "hand.thumbsup.circle.fill", "smiley", "smiley.fill", "heart", "heart.fill", "heart.circle","heart.circle.fill", "bell", "bell.fill", "bell.circle", "bell.circle.fill", "flag", "flag.fill", "flag.circle", "flag.circle.fill", "pencil", "pencil.circle", "pencil.circle.fill", "pencil.and.outline", "pencil.tip", "pencil.tip.crop.circle", "pencil.tip.crop.circle.badge.plus", "pencil.tip.crop.circle.badge.minus", "pencil.tip.crop.circle.badge.arrow.forward", "pencil.tip.crop.circle.badge.arrow.backward" ]
        
    @Published var celebrationPhrases: [String] = [
        "Well Done!",
        "Fantastic Effort!",
        "You Nailed It!",
        "Bravo!",
        "Keep It Up!",
        "Excellent Execution!",
        "You're Crushing It!",
        "Outstanding Work!",
        "You're on a Roll!",
        "Superb!",
        "Impressive!",
        "You're a Trailblazer!",
        "You're Unstoppable!",
        "You're a Dynamo!",
        "You're a Whiz!",
        "You're an Ace!",
        "You're a Virtuoso!",
        "You're a Maestro!",
        "You're a Phenom!",
        "Legendary!",
        "You're a Titan!",
        "You're a Prodigy!",
        "Mastermind Level!",
        "Go Guru! Go Guru",
        "A Marvel!",
        "Genius!",
        "Pro Level",
        "Hero Work!",
        "Spectacular",
        "Kudos!",
        "Yes!",
        "Win!",
        "Epic!",
        "Wow!",
        "Yay!",
        "A+!",
        "Top!",
        "Ace!",
        "Gold!",
        "Boom!",
        "Nice!",
        "Zing!",
        "Bingo!",
        "Woot!",
        "Hooray!",
        "Score!",
        "Nailed it!",
        "On Point!",
        "Get It Done."
    ]
    
    
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
            
            for task in tasks {
                previousTaskStates[task.id!] = task.state
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
        let isTodayFilterActive = searchText == "Today"
        let currentDate = Date()
        
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
            
            for task in tasks {
                let previousState = previousTaskStates[task.id!]
                if task.state == "Done" && previousState != "Done" {
                    isTaskDone = true
                    showCelebration = true

                    // Pick a random celebration phrase and symbol
                    currentCelebrationPhrase = celebrationPhrases.randomElement() ?? "Well Done!"
                    currentCelebrationSymbol = celebrationSymbols.randomElement() ?? "star.fill"

                    // Hide the celebration after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                        self?.showCelebration = false
                    }
                }
                // Update the previous state for this task
                previousTaskStates[task.id!] = task.state
            }
            let isDueToday = Calendar.current.isDate((task.dueDate ?? currentDate) as Date, inSameDayAs: currentDate)
            
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
