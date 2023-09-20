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
                VStack {
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
                    Spacer()
                    Text(String(repeating: "⭐", count: Int(task.priorityScore)))
                        .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 12))
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                }
                
            }
            .frame(alignment: .top)
            // Show Due Date
            VStack(alignment: .leading) {
                Text(TaskFormatter.shared.formattedDueDate(for: task, showDueDates: true))
                    .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
                    .font(.system(size: 16)) // Adjust the font size as needed
                    .bold()

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
    
