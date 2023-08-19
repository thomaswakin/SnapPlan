//
//  MainView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI
import CoreData
import AVFoundation
import Photos


struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var taskFormatter: TaskFormatter
    @ObservedObject var viewModel: TaskViewModel
    @State private var selectedTask: SnapPlanTask?
    @State private var showSettings: Bool = false
    @State private var forceRedraw: Bool = false
    @State private var showStickyNoteView = false
    
    @State private var showTodo = true
    @State private var showDoing = false
    @State private var showDone = false
    
    @State private var isImagePickerPresented: Bool = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    @State private var isPermissionAlertPresented: Bool = false
    @State private var permissionAlertMessage: String = ""
    
    init(viewModel: TaskViewModel) {
        self.viewModel = viewModel
    }
    
    func addNewTaskShowView() {
        viewModel.addTask()
        // Set selectedTask to the newly added task
        selectedTask = viewModel.tasks.last
        ShowAndEditView(task: $selectedTask)
    }
    
    func createTask(withImage image: UIImage) {
        let newTask = SnapPlanTask(context: viewContext)
        newTask.rawPhotoData = image.pngData()
        selectedTask = newTask
        do {
            try viewContext.save()
        } catch {
            print("Failed to save new task:", error)
        }
    }
    
    var body: some View {
        VStack {
            // Top Row: Task Filter and Add Task Button
            HStack {
                TextField("Task Filter", text: $viewModel.searchText)
                    .onChange(of: viewModel.searchText) { _ in
                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                    }
                Button(action: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        requestCameraPermission { granted in
                            if granted {
                                print("Button:CameraGranted:", sourceType.rawValue)
                                sourceType = .camera
                                isImagePickerPresented = true
                            } else {
                                print("Button:CameraNotGranted:", sourceType.rawValue)
                                permissionAlertMessage = "Camera permission is required to take photos."
                                isPermissionAlertPresented = true
                            }
                        }
                    } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                        requestPhotoLibraryPermission { granted in
                            if granted {
                                print("Button:PhotoGranted:", sourceType.rawValue)
                                sourceType = .photoLibrary
                                print("Button:PhotoGranted:setSourceType", sourceType.rawValue)
                                isImagePickerPresented = true
                            } else {
                                print("Button:PhotoNotGranted:", sourceType.rawValue)
                                permissionAlertMessage = "Photo library permission is required to select photos."
                                isPermissionAlertPresented = true
                            }
                        }
                    } else {
                        print("Buttton:NotCameraOrPhoto:", sourceType.rawValue)
                        permissionAlertMessage = "Camera and/or Photo Album access required to use images for tasks"
                        isPermissionAlertPresented = true
                    }
                    
                }) {
                    Image(systemName: "camera")
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
            .alert(isPresented: $isPermissionAlertPresented) {
                Alert(title: Text("Permission Required"), message: Text(permissionAlertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(item: $selectedTask) { task in
                ShowAndEditView(task: $selectedTask)
                    .onDisappear {
                        // Reapply the filters based on the current toggles
                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                    }
                
            }
            .sheet(isPresented: $showStickyNoteView) {
                ShowAndEditView(task: $selectedTask)
                    .onDisappear {
                        // Reapply the filters based on the current toggles
                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                    }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage, showStickyNoteView: $showStickyNoteView, selectedTask: $selectedTask, sourceType: sourceType, viewContext: viewContext)
            }
            //if showStickyNoteView {
            //    addNewTaskShowView()
            //}
            
            
            // Second Row: Navigation Tabs
            HStack(spacing: 10) { // Evenly space the buttons
                Button("Todo") {
                    showTodo.toggle()
                    viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                }
                .buttonStyle(ToggleButtonStyle(isSelected: showTodo))

                Button("Doing") {
                    showDoing.toggle()
                    viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                }
                .buttonStyle(ToggleButtonStyle(isSelected: showDoing))

                Button("Done") {
                    showDone.toggle()
                    viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                }
                .buttonStyle(ToggleButtonStyle(isSelected: showDone))
            }
            .padding(.horizontal)
            //Picker("", selection: $viewModel.selectedTab) {
            //    Text("Todo").tag(0)
            //    Text("Doing").tag(1)
            //    Text("Done").tag(2)
            //    Text("All").tag(3)
            //}
            //.pickerStyle(SegmentedPickerStyle())
            //.onChange(of: viewModel.selectedTab) { _ in
            //    viewModel.applyFilters()
            //}
            
            // Third Row: Task Display (Placeholder)
            ScrollView {
                if viewModel.isTaskCardView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 120), spacing: 0)]) {
                    //LazyVGrid(columns: [GridItem(.fixed(125))]) {
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
                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
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
                .onDisappear {
                    forceRedraw.toggle()
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
}

struct ToggleButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.gray : Color.white)
            .foregroundColor(isSelected ? Color.white : Color.black)
            .cornerRadius(8)
            .shadow(radius: 2)
            .font(.system(size: isSelected ? 14 : 12)) // Scale font size based on selection

    }
}

func requestCameraPermission(completion: @escaping (Bool) -> Void) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
        completion(granted)
    }
}

func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        completion(status == .authorized)
    }
}


