//
//  TaskCardView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI

struct TaskCardView: View {
    @ObservedObject var task: SnapPlanTask
    @EnvironmentObject var taskFormatter: TaskFormatter
    @EnvironmentObject var settings: Settings
    @State private var showStickyNoteView: Bool = false
    @State private var forceRedraw: Bool = false
    let taskCardWidth = (UIScreen.main.bounds.width / 3) - 10
    
    
    var body: some View {
        ZStack {
            // Display task photo if available
            if let data = task.rawPhotoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: taskCardWidth, height: taskCardWidth)
                    .clipped()
                    //.scaledToFit()
            } else {
                StickyNoteView(color: TaskFormatter.shared.stateColor(task: task))
                ZStack {
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
            }
            // Top Capsule with State and Due Date
            HStack {
                Text(task.state ?? "Todo")
                    .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
                    .font(.system(size: 16)) // Adjust the font size as needed
                    .bold()
                Spacer()
                if settings.dueDateDisplay == 0 { // Show Due Dates
                    Text(TaskFormatter.shared.formattedDueDate(for: task, showDueDates: true)) // Assuming this function exists
                    .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
                    .font(.system(size: 16)) // Adjust the font size as needed
                    .bold()
                } else { // Show Days Until Due
                    Text(TaskFormatter.shared.daysUntilDue(for: task))
                        .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
                        .font(.system(size: 16)) // Adjust the font size as needed
                        .bold()
                }
            }
            .padding(.horizontal, 8) // Adjust the horizontal padding as needed
            .frame(height: 20) // Set the height of the capsule
            //.background(TaskFormatter.shared.stateColor(task: task).opacity(0.7))
            .background(TaskFormatter.shared.stateColor(task: task))
            .clipShape(Capsule())
            .padding(.top, -55) // Adjust as needed
            .frame(width: taskCardWidth - 5)
            .edgesIgnoringSafeArea(.all)

            ZStack {
                Circle()
                    .fill(Color(hex: "#af0808")).opacity(0.9)
                    .frame(width: 20, height: 20) // Adjust the size of the circle as needed

                //Text("\(task.priorityScore)") // Converts Int16 to String
                Text(String(repeating: "⭐", count: Int(task.priorityScore)))
                    .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 8))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(2)
        }
        //.padding(.top)
        .frame(width: taskCardWidth, height: taskCardWidth)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        
        //.cornerRadius(10)
        //.shadow(radius: 5)
    }
}
