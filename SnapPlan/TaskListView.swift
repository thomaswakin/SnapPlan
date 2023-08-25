//
//  TaskListView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI
import Foundation

struct TaskListView: View {
    @ObservedObject var task: SnapPlanTask
    @EnvironmentObject var taskFormatter: TaskFormatter
    @State private var showStickyNoteView: Bool = false
    let taskListHeight = (UIScreen.main.bounds.width / 10) - 5

    var body: some View {
        HStack {
            // Display task photo if available
            if let data = task.rawPhotoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: taskListHeight, height: taskListHeight)
            } else {
                StickyNoteView(color: TaskFormatter.shared.stateColor(task: task))
            }
            
            VStack(alignment: .leading) {
                Text(task.state ?? "Todo")
                Text(task.dueDate != nil ? TaskFormatter.shared.dateFormatter.string(from: task.dueDate!) : "--")
                Text(task.note ?? "")
            }
        }
        .padding()
    }
}
