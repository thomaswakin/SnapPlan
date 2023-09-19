//
//  TaskListView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI
import Foundation

import SwiftUI

struct TaskListView: View {
    @ObservedObject var task: SnapPlanTask
    @EnvironmentObject var taskFormatter: TaskFormatter
    @State private var showStickyNoteView: Bool = false
    @State private var forceRedraw: Bool = false
    let taskCardWidth = (UIScreen.main.bounds.width / 3) - 10
    let taskListHeight = (UIScreen.main.bounds.height / 13)
    let taskListWidth = UIScreen.main.bounds.width - 2
    
    
    var body:some View {
        HStack() {
            ZStack(alignment: .top) {
                // Show Image
                if let data = task.rawPhotoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: taskListHeight)
                        .frame(height: taskListHeight)
                        .frame(alignment: .leading)
                        .clipped()
                        .cornerRadius(5)
                        .shadow(radius: 5)
                } else {
                    StickyNoteViewList(color: TaskFormatter.shared.stateColor(task: task))
                        .frame(maxWidth: taskListHeight)
                        .frame(alignment: .leading)
                        .shadow(radius: 5)
                        .cornerRadius(5)
                }
                // Show Todo
                Text(task.state ?? "Todo")
                    .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
                    .font(.system(size: 12)) // Adjust the font size as needed
                    .bold()
                    .padding(.horizontal, 4) // Adjust the horizontal padding as needed
                    .frame(width: taskListHeight - 5, height: 16, alignment: .top) // Set the height of the capsule
                    //.background(TaskFormatter.shared.stateColor(task: task).opacity(0.7))
                    .background(TaskFormatter.shared.stateColor(task: task))
                    .clipShape(Capsule())
                    .padding(.top, 5) // Adjust as needed
                    //.frame(width: taskCardWidth - 5, alignment: .top)
            }
            .frame(alignment: .top)
            // Show Due Date
            VStack(alignment: .leading) {
                Text(TaskFormatter.shared.formattedDueDate(for: task, showDueDates: true))
                    .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
                    .font(.system(size: 16)) // Adjust the font size as needed
                    .bold()
                // Show Priority
                ZStack {
                    Circle()
                        .fill(Color(hex: "#af0808")).opacity(0.9)
                        .frame(width: 18, height: 18) // Adjust the size of the circle as needed
                    
                    //Text("\(task.priorityScore)") // Converts Int16 to String
                    Text(String(repeating: "⭐", count: Int(task.priorityScore)))
                        .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 7))
                        .foregroundColor(.white)
                }
                .frame(alignment: .topLeading)
                // Show Note

            }

            HStack(alignment: .top) {
                if let note = task.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack {
                        HStack {
                            Text(note)
                                .lineLimit(3) // Limit to three lines
                                .truncationMode(.tail) // Add ellipsis if the text is truncated
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
                                .padding(5)
                            //.background(Color.black.opacity(0.5))
                                .foregroundColor(Color.black)
                                .monospaced()
                            //.padding(.horizontal, -10.0)
                                .frame(alignment: .leading) // Align to the bottom left
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: taskListHeight, alignment: .leading)
            .background(Color.white)
        }
        .border(Color.gray.opacity(0.5))
        .contentShape(Rectangle())
        .background(TaskFormatter.shared.stateColor(task: task))
    }
}
    
//    var body: some View {
//        HStack {
//            ZStack {
//                // Display task photo if available
//                if let data = task.rawPhotoData, let image = UIImage(data: data) {
//                    Image(uiImage: image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: taskListWidth, height: taskListWidth)
//                        .clipped()
//                    //.scaledToFit()
//                } else {
//                    StickyNoteView(color: TaskFormatter.shared.stateColor(task: task))
//                    //                ZStack {
//                    //                    if let note = task.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                    //                        VStack {
//                    //                            HStack {
//                    //                                Text(note)
//                    //                                    .lineLimit(3) // Limit to three lines
//                    //                                    .truncationMode(.tail) // Add ellipsis if the text is truncated
//                    //                                    .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
//                    //                                    .padding(5)
//                    //                                    //.background(Color.black.opacity(0.5))
//                    //                                    .foregroundColor(Color.black)
//                    //                                    .monospaced()
//                    //                                //.padding(.horizontal, -10.0)
//                    //                                    .frame(alignment: .leading) // Align to the bottom left
//                    //                            }
//                    //                        }
//                    //                    }
//                    //                }
//                }
//                // Top Capsule with State and Due Date
//                ZStack {
//                    VStack {
//                        Text(task.state ?? "Todo")
//                            .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
//                            .font(.system(size: 16)) // Adjust the font size as needed
//                            .bold()
//                        Spacer()
//                        Text(TaskFormatter.shared.formattedDueDate(for: task, showDueDates: true))
//                            .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
//                            .font(.system(size: 16)) // Adjust the font size as needed
//                            .bold()
//                        ZStack {
//                            Circle()
//                                .fill(Color(hex: "#af0808")).opacity(0.5)
//                                .frame(width: 25, height: 25) // Adjust the size of the circle as needed
//
//                            Text("\(task.priorityScore)") // Converts Int16 to String
//                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 8))
//                                .foregroundColor(.white)
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
//                        .padding(2)
//                    }
//                }
//                .padding(.horizontal, 8) // Adjust the horizontal padding as needed
//                //.frame(height: 20) // Set the height of the capsule
//                //.background(TaskFormatter.shared.stateColor(task: task).opacity(0.7))
//                .background(TaskFormatter.shared.stateColor(task: task))
//                //.clipShape(Capsule())
//                //.padding(.top, -55) // Adjust as needed
//                //.frame(width: taskListWidth - 5)
//                //.edgesIgnoringSafeArea(.all)
//
//                VStack {
//                    Circle()
//                        .fill(Color(hex: "#af0808")).opacity(0.5)
//                        .frame(width: 25, height: 25) // Adjust the size of the circle as needed
//
//                    Text("\(task.priorityScore)") // Converts Int16 to String
//                        .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 8))
//                        .foregroundColor(.white)
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
//                .padding(2)
//            }
//            //.padding(.top)
//            .frame(width: taskListWidth, height: taskListHeight)
//            .background(Color.white)
//            .edgesIgnoringSafeArea(.all)
//            //.cornerRadius(10)
//            //.shadow(radius: 5)
//            ZStack {
//                if let note = task.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                    VStack {
//                        HStack {
//                            Text(note)
//                                .lineLimit(3) // Limit to three lines
//                                .truncationMode(.tail) // Add ellipsis if the text is truncated
//                                .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 4))
//                                .padding(5)
//                            //.background(Color.black.opacity(0.5))
//                                .foregroundColor(Color.black)
//                                .monospaced()
//                            //.padding(.horizontal, -10.0)
//                                .frame(alignment: .leading) // Align to the bottom left
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
