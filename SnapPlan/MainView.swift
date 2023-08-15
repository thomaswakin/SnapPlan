//
//  MainView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: TaskViewModel
    @State private var selectedTask: SnapPlanTask?
    @State private var showSettings: Bool = false
    
    init() {
        viewModel = TaskViewModel(context: viewContext)
    }
    
    var body: some View {
        VStack {
            // Top Row: Task Filter and Add Task Button
            HStack {
                TextField("Task Filter", text: $viewModel.searchText)
                    .onChange(of: viewModel.searchText) { _ in
                        viewModel.applyFilters()
                    }
                Button(action: {
                    viewModel.addTask()
                    // Set selectedTask to the newly added task
                    selectedTask = viewModel.tasks.last
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
            .sheet(item: $selectedTask) { task in
                ShowAndEditView(task: $selectedTask)
            }
            
            // Second Row: Navigation Tabs
            Picker("", selection: $viewModel.selectedTab) {
                Text("Todo").tag(0)
                Text("Doing").tag(1)
                Text("Done").tag(2)
                Text("All").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.selectedTab) { _ in
                viewModel.applyFilters()
            }
            
            // Third Row: Task Display (Placeholder)
            ScrollView {
                if viewModel.isTaskCardView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                        ForEach(viewModel.filteredTasks, id: \.id) { task in
                            TaskCardView(task: task)
                                .onTapGesture {
                                    selectedTask = task
                                }
                        }
                    }
                } else {
                    List(viewModel.filteredTasks, id: \.id) { task in
                        TaskListView(task: task)
                            .onTapGesture {
                                selectedTask = task
                            }
                    }
                }
            }
            
            // Fourth Row: Priority Slider, Display Toggle, and Settings Gear
            HStack {
                Slider(value: $viewModel.priorityFilter, in: 0...100)
                    .onChange(of: viewModel.priorityFilter) { _ in
                        viewModel.applyFilters()
                    }
                Toggle("", isOn: $viewModel.isTaskCardView)
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gear")
                }
            }
        }
        .padding()
        .sheet(item: $selectedTask) { task in
            ShowAndEditView(task: $selectedTask)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
}


@available(iOS 15.0, *)
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
