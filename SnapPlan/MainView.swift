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

enum ActiveSheet: Identifiable {
    case showAndEditTask, showStickyNoteView, imagePicker

    var id: Int {
        hashValue
    }
}

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: FilterEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \FilterEntity.order, ascending: true)])
    private var filterEntities: FetchedResults<FilterEntity>
    @EnvironmentObject var taskFormatter: TaskFormatter
    @ObservedObject var viewModel: TaskViewModel
    @State private var activeSheet: ActiveSheet?
    @State private var selectedTask: SnapPlanTask?
    @State private var showNotePopup: Bool = false
    @State private var selectedNote: String?
    @State private var showSettings: Bool = false
    @State private var forceRedraw: Bool = false
    @State private var showStickyNoteView = false
    @State private var showCircle = false
    @State private var timer: Timer? = nil
    
    @State private var showTodo = true
    @State private var showDoing = false
    @State private var showDone = false
    @State private var textOpacity: Double = 1
    @State private var sortTextOpacity: Double = 1
    @State private var focusOpacity: Double = 1
    @State private var showTaskCard: Bool = true
    @State private var isEditing: Bool = false
    @State private var longPressedTask: SnapPlanTask?

    @State private var isImagePickerPresented: Bool = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    @State private var isPermissionAlertPresented: Bool = false
    @State private var permissionAlertMessage: String = ""
    
    let taskCardWidth = (UIScreen.main.bounds.width / 3) - 10
    let taskListHeight = (UIScreen.main.bounds.height / 13)
    let taskListWidth = UIScreen.main.bounds.width - 2
    
    init(viewModel: TaskViewModel) {
        self.viewModel = viewModel
        NotificationCenter.default.addObserver(forName: NSNotification.Name("refreshTasks"), object: nil, queue: .main) { _ in
            viewModel.fetchTasks()
        }
    }
    
    func applyFilter(_ filterName: String) {
        viewModel.searchText = filterName
        viewModel.fetchTasks()
        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
    }
    
    func createTask(withImage image: UIImage) -> SnapPlanTask? {
        let newTask = SnapPlanTask(context: viewContext)
        newTask.id = UUID()
        newTask.rawPhotoData = image.pngData()
        newTask.note = ""  // Initialize to empty
        newTask.dueDate = nil  // Initialize to nil
        newTask.priorityScore = Int16(5)
        // Initialize other properties...
        do {
            try viewContext.save()
            return newTask
        } catch {
            print("Failed to save new task:", error)
            return nil
        }
    }
    
    func onLongPress(_ task: SnapPlanTask) {
        self.longPressedTask = task
    }
    
    // Add this closure property to MainView
    //var createTaskClosure: (UIImage) -> Void {
    //    return { image in
    //        createTask(withImage: image)
    //    }
    //}
    
    var body: some View {
        ZStack {
            VStack {
                // Top Row: Task Filter and Add Task Button
                HStack {
                    TextField("Task Filter", text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _ in
                            viewModel.fetchTasks()
                            viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                        }
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                            viewModel.fetchTasks()
                            viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            requestCameraPermission { granted in
                                if granted {
                                    print("Button:CameraGranted:", sourceType.rawValue)
                                    sourceType = .camera
                                    isImagePickerPresented = true
                                    activeSheet = .imagePicker
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
                                    activeSheet = .imagePicker
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
                        // Photo Library action
                        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                            requestPhotoLibraryPermission { granted in
                                if granted {
                                    sourceType = .photoLibrary
                                    isImagePickerPresented = true
                                    activeSheet = .imagePicker
                                } else {
                                    permissionAlertMessage = "Photo library permission is required to select photos."
                                    isPermissionAlertPresented = true
                                }
                            }
                        } else {
                            permissionAlertMessage = "Photo Album access required to use images for tasks"
                            isPermissionAlertPresented = true
                        }
                    }) {
                        Image(systemName: "photo")
                    }
                    Button(action: {
                        let thisNewTask = viewModel.addTask()
                        // Set selectedTask to the newly added task
                        selectedTask = thisNewTask
                    }) {
                        Image(systemName: "plus")
                    }
                }
                .padding()
                .alert(isPresented: $isPermissionAlertPresented) {
                    Alert(title: Text("Permission Required"), message: Text(permissionAlertMessage), dismissButton: .default(Text("OK")))
                }
                .sheet(item: $activeSheet) { item in
                    switch item {
                    case .showAndEditTask:
                        ShowAndEditView(task: $selectedTask)
                            .onDisappear {
                                viewModel.fetchTasks()
                                viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                            }
                    case .showStickyNoteView:
                        ShowAndEditView(task: $selectedTask)
                            .onDisappear {
                                viewModel.fetchTasks()
                                viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                            }
                    case .imagePicker:
                        ImagePicker(selectedImage: $selectedImage, showStickyNoteView: $showStickyNoteView, selectedTask: $selectedTask, isEditing: $isEditing, sourceType: sourceType, viewContext: viewContext)
                        //                        .onDisappear {
                        //                            viewModel.fetchTasks()
                        //                            viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                        //                        }
                    }
                }
                //            .sheet(item: $selectedTask) { task in
                //                ShowAndEditView(task: $selectedTask)
                //                    .onDisappear {
                //                        // Reapply the filters based on the current toggles
                //                        viewModel.fetchTasks()
                //                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                //                    }
                //
                //            }
                //            .sheet(isPresented: $showStickyNoteView) {
                //                ShowAndEditView(task: $selectedTask)
                //                    .onDisappear {
                //                        // Reapply the filters based on the current toggles
                //                        viewModel.fetchTasks()
                //                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                //                    }
                //            }
                //            .sheet(isPresented: $isImagePickerPresented) {
                //                ImagePicker(selectedImage: $selectedImage, showStickyNoteView: $showStickyNoteView, selectedTask: $selectedTask, createTaskClosure: createTaskClosure, sourceType: sourceType, viewContext: viewContext)
                //                    .onDisappear {
                //                        // Reapply the filters based on the current toggles
                //                        viewModel.fetchTasks()
                //                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                //                    }
                //            }
                
                
                // Second Row: Navigation Tabs
                HStack(spacing: 10) { // Evenly space the buttons
                    Button("Todo") {
                        showTodo.toggle()
                        viewModel.fetchTasks()
                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                        
                    }
                    .buttonStyle(ToggleButtonStyle(isSelected: viewModel.isFocusMode ? true : showTodo))
                    
                    Button("Doing") {
                        showDoing.toggle()
                        viewModel.fetchTasks()
                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                        
                    }
                    .buttonStyle(ToggleButtonStyle(isSelected: viewModel.isFocusMode ? true : showDoing))
                    
                    Button("Done") {
                        showDone.toggle()
                        viewModel.fetchTasks()
                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                    }
                    .buttonStyle(ToggleButtonStyle(isSelected: viewModel.isFocusMode ? false : showDone))
                }
                .padding(.horizontal)
                //.frame(width: UIScreen.main.bounds.width * 2/3)
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
                        let todoTasks = Array(viewModel.filteredTasks.filter { $0.state == "Todo" }.prefix(3))
                        let doingTasks = Array(viewModel.filteredTasks.filter { $0.state == "Doing" }.prefix(3))
                        let focusTasks = todoTasks + doingTasks
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: taskCardWidth - 1), spacing: 0)]) {
                            ForEach(viewModel.isFocusMode ? focusTasks : viewModel.filteredTasks, id: \.id) { task in
                                TaskCardView(task: task)
                                    .frame(width: taskCardWidth - 2) // Set the width for each task card
                                    .gesture(
                                        TapGesture(count: 2).onEnded {
                                            selectedNote = task.note ?? ""
                                            showNotePopup = true
                                        }.exclusively(before: TapGesture(count: 1).onEnded {
                                            selectedTask = task
                                        })
                                    )
                                    .simultaneousGesture(
                                        LongPressGesture().onEnded { _ in
                                            self.onLongPress(task)
                                        }
                                    )
                                    .onChange(of: task) { _ in
                                        viewModel.fetchTasks()
                                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                                    }
                            }
                            
                        }
                    } else {
                        let todoTasks = Array(viewModel.filteredTasks.filter { $0.state == "Todo" }.prefix(3))
                        let doingTasks = Array(viewModel.filteredTasks.filter { $0.state == "Doing" }.prefix(3))
                        let focusTasks = todoTasks + doingTasks
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: taskListWidth), spacing: 1)]) {
                            ForEach(viewModel.isFocusMode ? focusTasks : viewModel.filteredTasks, id: \.id) { task in
                                TaskListView(task: task)
                                    .frame(maxWidth: .infinity)
                                    .gesture(
                                        TapGesture(count: 2).onEnded {
                                            selectedNote = task.note ?? ""
                                            showNotePopup = true
                                        }.exclusively(before: TapGesture(count: 1).onEnded {
                                            selectedTask = task
                                        })
                                    )
                                    .simultaneousGesture(
                                        LongPressGesture().onEnded { _ in
                                            self.onLongPress(task)
                                        }
                                    )
                                    .onChange(of: task) { _ in
                                        viewModel.fetchTasks()
                                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                                    }
                            }
                        }
                    }
                }
                // Fourth Row to have predefined filters
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(filterEntities, id: \.self) { filterEntity in
                                if let filterName = filterEntity.name {
                                    Button(filterName) {
                                        applyFilter(filterName)
                                    }
                                    .padding(5) // Smaller padding to make it thin
                                    .font(.system(size: 12)) // Smaller font size
                                    .foregroundColor(.blue) // Blue font color
                                    .background(Color.clear) // Clear background
                                }
                            }
                        }
                    }
                }
                
                // Fifth Row: Priority Slider, Display Toggle, and Settings Gear
                HStack {
                    ZStack {
                        Slider(value: $viewModel.priorityFilter, in: 1...10)
                            .scaleEffect(x: 0.7, y: 0.7, anchor: .center) // Reduce the size of the slider circle
                            .onChange(of: viewModel.priorityFilter) { _ in
                                viewModel.fetchTasks()
                                viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                                showCircle = true
                                timer?.invalidate() // Invalidate the previous timer
                                timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                                    showCircle = false
                                }
                            }
                            .frame(alignment: .leading)
                        
                        if showCircle {
                            Circle()
                                .fill(Color(hex: "#af0808")).opacity(0.9)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("\(Int(viewModel.priorityFilter))")
                                        .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 8))
                                        .foregroundColor(.white)
                                )
                                .offset(y: -20) // Adjust this value to position the circle above the slider
                        }
                    }
                    Spacer()
                    VStack {
                        if viewModel.isTaskCardView {
                            Text("TaskCards")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
                                .opacity(textOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        textOpacity = 0
                                    }
                                }
                        } else {
                            Text("TaskList")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
                                .opacity(textOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        textOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        }
                        Toggle("", isOn: $viewModel.isTaskCardView)
                            .scaleEffect(0.7)
                            .onChange(of: viewModel.isTaskCardView) { _ in
                                textOpacity = 1 // Reset text opacity when toggle changes
                            }
                    }
                    .frame(alignment: .trailing)
                    VStack {
                        if viewModel.sortByDueDate {
                            Text("Date Sort")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
                                .opacity(sortTextOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        sortTextOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        } else {
                            Text("Priority Sort")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
                                .opacity(sortTextOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        sortTextOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        }
                        Toggle("", isOn: $viewModel.sortByDueDate)
                            .scaleEffect(0.7)
                            .onChange(of: viewModel.sortByDueDate) { _ in
                                viewModel.fetchTasks()
                                viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                                sortTextOpacity = 1
                            }
                    }
                    
                    // Add the Focus toggle button next to the gear button
                    VStack {
                        if viewModel.isFocusMode {
                            Text("Focus On")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
                                .opacity(focusOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        focusOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        } else {
                            Text("Focus Off")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
                                .opacity(focusOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        focusOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        }
                        Toggle("", isOn: $viewModel.isFocusMode)
                            .scaleEffect(0.7)
                            .onChange(of: viewModel.isFocusMode) { newValue in
                                if newValue {
                                    showTodo = true
                                    showDoing = true
                                    showDone = false
                                }
                                focusOpacity = 1
                                viewModel.fetchTasks()
                                viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                            }
                    }

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
                        viewModel.fetchTasks()
                        viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                    }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            if let task = longPressedTask {
                VStack {
                    Text("Change State")
                    Picker("State", selection: Binding(
                        get: { longPressedTask?.state ?? "Todo" },
                        set: { newValue in
                            longPressedTask?.state = newValue
                            do {
                                try viewContext.save()
                            } catch {
                                print("Failed to save task status:", error)
                            }
                        }
                    )) {
                        Text("Todo").tag("Todo")
                        Text("Doing").tag("Doing")
                        Text("Done").tag("Done")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Button("Done") {
                        longPressedTask = nil
                        do {
                            try viewContext.save()
                            viewModel.fetchTasks()
                            viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)

                        } catch {
                            print("Failed to save task status:", error)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
            }

            if showNotePopup {
                ZStack {
                    // Background dimmer
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { showNotePopup = false }

                    // Note Pop-Up
                    VStack(alignment: .leading) {
                        ScrollView {
                            Text(selectedNote ?? "")
                        }
                        .padding()
                        .frame(maxWidth: UIScreen.main.bounds.width * 2 / 3, maxHeight: UIScreen.main.bounds.height / 3)
                        .background(Color.white)
                        .foregroundColor(Color.black)
                        .cornerRadius(10)
                        .overlay(
                            Button("Dismiss") {
                                showNotePopup = false
                                selectedNote = ""
                            }
                            .padding(),
                            alignment: .bottomTrailing
                        )
                    }
                }
            }
        }
    }
}

struct ToggleButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? Color.gray : Color.white)
            .background(isSelected ? Color.white : Color.black)
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


