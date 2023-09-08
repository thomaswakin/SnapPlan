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
    
    @State private var showCelebration = false
    @State private var celebrationPhrase = ""
    @State private var celebrationSymbol = ""
    
    // Add these new state variables to your MainView struct
    @State private var showSimpleAnimation = false
    @State private var showComplexAnimation = false
    @State private var simpleAnimationType = 0 // 0 for slide, 1 for rotate, etc.
    @State private var complexAnimationType = 0 // 0 for Fireworks, 1 for Screen Sparkle, etc.

    
    let taskCardWidth = (UIScreen.main.bounds.width / 3) - 10
    let taskListHeight = (UIScreen.main.bounds.height / 13)
    let taskListWidth = UIScreen.main.bounds.width - 2
    
    init(viewModel: TaskViewModel) {
        self.viewModel = viewModel
        NotificationCenter.default.addObserver(forName: NSNotification.Name("refreshTasks"), object: nil, queue: .main) { _ in
            viewModel.fetchTasks()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func applyFilter(_ filterName: String) {
        if filterName == "Today" {
            viewModel.searchText = "Today"
        } else {
            viewModel.searchText = filterName
        }
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
                    }
                }
 
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
                VStack{
                    GeometryReader { geometry in
                        if viewModel.isTaskCardView {
                            let todoTasks = Array(viewModel.filteredTasks.filter { $0.state == "Todo" }.prefix(3))
                            let doingTasks = Array(viewModel.filteredTasks.filter { $0.state == "Doing" }.prefix(3))
                            let focusTasks = todoTasks + doingTasks
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: taskCardWidth - 1), spacing: 0)]) {
                                    ForEach(viewModel.isFocusMode ? focusTasks : viewModel.filteredTasks, id: \.id) { task in
                                        ZStack {
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
                                        .highPriorityGesture(DragGesture().onChanged { _ in })
                                    }
                                }
                            }
                        } else {
                            let todoTasks = Array(viewModel.filteredTasks.filter { $0.state == "Todo" }.prefix(3))
                            let doingTasks = Array(viewModel.filteredTasks.filter { $0.state == "Doing" }.prefix(3))
                            let focusTasks = todoTasks + doingTasks
                            
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: taskListWidth), spacing: 1)]) {
                                    ForEach(viewModel.isFocusMode ? focusTasks : viewModel.filteredTasks, id: \.id) { task in
                                        ZStack {
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
                                        .highPriorityGesture(DragGesture().onChanged { _ in })
                                    }
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
                                    .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 8)) // Smaller font size
                                    .foregroundColor(.blue) // Blue font color
                                    .background(Color.clear) // Clear background
                                }
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                
                // Fifth Row: Priority Slider, Display Toggle, and Settings Gear
                HStack {
                    VStack(alignment: .center, spacing: 0) {
                        Picker("Priority Filter", selection: $viewModel.priorityFilter) {
                            ForEach(1...10, id: \.self) { i in
                                Text("\(i)").tag(Double(i))
                                    .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 6))
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 50, height: 75, alignment: .center)
                        .clipped()
                        .onChange(of: viewModel.priorityFilter) { _ in
                            viewModel.fetchTasks()
                            viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                        }
                        
                    }

                    VStack(alignment: .center, spacing: 0) {
                        if viewModel.sortByDueDate {
                            Text("Date Sort")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 6))
                                .opacity(sortTextOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        sortTextOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        } else {
                            Text("Priority Sort")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 6))
                                .opacity(sortTextOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        sortTextOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        }
                        Toggle("", isOn: $viewModel.sortByDueDate)
                            .labelsHidden()
                            .scaleEffect(0.7)
                            .onChange(of: viewModel.sortByDueDate) { _ in
                                viewModel.fetchTasks()
                                viewModel.applyFilters(showTodo: showTodo, showDoing: showDoing, showDone: showDone)
                                sortTextOpacity = 1
                            }
                        Text(" Sort")
                            .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 8))
                    }
                    VStack(spacing: 0) {
                        if viewModel.isTaskCardView {
                            Text("Cards")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 6))
                                .opacity(textOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        textOpacity = 0
                                    }
                                }
                        } else {
                            Text("List")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 6))
                                .opacity(textOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        textOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        }
                        Toggle("", isOn: $viewModel.isTaskCardView)
                            .labelsHidden()
                            .scaleEffect(0.7)
                            .onChange(of: viewModel.isTaskCardView) { _ in
                                textOpacity = 1 // Reset text opacity when toggle changes
                            }
                        Text(" View")
                            .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 8))
                    }
                    .frame(alignment: .trailing)
                    // Add the Focus toggle button next to the gear button
                    VStack(spacing: 0) {
                        if viewModel.isFocusMode {
                            Text("Focus On")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 6))
                                .opacity(focusOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        focusOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        } else {
                            Text("Focus Off")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 6))
                                .opacity(focusOpacity)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
                                        focusOpacity = 0 // Fade out the text after 1 second
                                    }
                                }
                        }
                        Toggle("", isOn: $viewModel.isFocusMode)
                            .labelsHidden()
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
                        Text(" Focus")
                            .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 8))
                        
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
            
            // This part is for the celebration and animations
            if viewModel.showCelebration {
                VStack {
                    // Check for simple animation
                    if showSimpleAnimation {
                        if simpleAnimationType == 0 {
                            // Slide animation
                            Text(viewModel.currentCelebrationPhrase)
                                .font(.largeTitle)
                                .foregroundColor(.green)
                                .offset(x: showSimpleAnimation ? 0 : -100)
                                .animation(.easeInOut)
                        } else {
                            // Rotate animation
                            Text(viewModel.currentCelebrationPhrase)
                                .font(.largeTitle)
                                .foregroundColor(.green)
                                .rotationEffect(.degrees(showSimpleAnimation ? 0 : 180))
                                .animation(.easeInOut)
                        }
                    } else {
                        Text(viewModel.currentCelebrationPhrase)
                            .font(.largeTitle)
                            .foregroundColor(.green)
                    }
                    
                    // Check for complex animation
                    if showComplexAnimation {
                        switch complexAnimationType {
                        case 0:
                            Firework() // Your Firework animation
                        case 1:
                            ForEach(0..<20) { _ in
                                Sparkle()
                            }
                        case 2:
                            Confetti() // Your Confetti animation
                        case 3:
                            AnimatedText(viewModel: viewModel) // Your Animated Text
                        default:
                            EmptyView()
                        }
                    }
                }
                .onAppear() {
                    // Reset all flags
                    viewModel.showCelebration = false
                    showSimpleAnimation = false
                    showComplexAnimation = false
                    
                    // Check for celebration
                    let celebrationChance = Int.random(in: 1...100)
                    if celebrationChance <= 50 {
                        viewModel.showCelebration = true
                        
                        // Check for simple animation
                        let simpleAnimationChance = Int.random(in: 1...100)
                        if simpleAnimationChance <= 50 {
                            showSimpleAnimation = true
                            simpleAnimationType = Int.random(in: 0...1)
                            
                            // Check for complex animation
                            let complexAnimationChance = Int.random(in: 1...100)
                            if complexAnimationChance <= 50 {
                                showComplexAnimation = true
                                complexAnimationType = Int.random(in: 0...3)
                            }
                        }
                    }
                }
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
            
            if showCelebration {
                VStack {
                    Text(celebrationPhrase)
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Image(systemName: celebrationSymbol)
                        .font(.largeTitle)
                        .foregroundColor(.blue)
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

func randomColor() -> Color {
    let red = Double.random(in: 0...1)
    let green = Double.random(in: 0...1)
    let blue = Double.random(in: 0...1)
    return Color(red: red, green: green, blue: blue)
}

struct Firework: View {
    @State private var expand = false
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Circle()
                    .frame(width: expand ? 100 : 10, height: expand ? 100 : 10)
                    .foregroundColor(.red)
                    .opacity(expand ? 0 : 1)
                    .offset(x: expand ? CGFloat(cos(Double.pi / 4 * Double(i)) * 50) : 0,
                            y: expand ? CGFloat(sin(Double.pi / 4 * Double(i)) * 50) : 0)
            }
        }
        .onAppear() {
            withAnimation(Animation.easeOut(duration: 1).repeatForever(autoreverses: false)) {
                expand.toggle()
            }
        }
    }
}

struct Sparkle: View {
    @State private var opacity = 0.0
    let x: CGFloat
    let y: CGFloat
    
    init() {
        self.x = CGFloat.random(in: -100...100)
        self.y = CGFloat.random(in: -100...100)
    }
    
    var body: some View {
        Image(systemName: "star.fill")
            .resizable()
            .frame(width: 10, height: 10)
            .foregroundColor(.yellow)
            .opacity(opacity)
            .offset(x: x, y: y)
            .onAppear() {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    opacity = 1
                }
            }
    }
}

struct Confetti: View {
    @State private var offset = CGSize.zero
    var body: some View {
        Rectangle()
            .frame(width: 10, height: 10)
            .foregroundColor(randomColor())
            .offset(offset)
            .onAppear() {
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                    offset = CGSize(width: CGFloat.random(in: -50...50), height: 600)
                }
            }
    }
}

struct AnimatedText: View {
    @State private var scale: CGFloat = 1.0
    @State private var selectedPhrase: String
    let viewModel: TaskViewModel
    
    init(viewModel: TaskViewModel) {
        self.viewModel = viewModel
        self._selectedPhrase = State(initialValue: viewModel.celebrationPhrases.randomElement() ?? "Awesome!")
    }
    
    var body: some View {
        Text(selectedPhrase)
            .font(.largeTitle)
            .scaleEffect(scale)
            .onAppear() {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    scale = 1.5
                }
            }
    }
}

