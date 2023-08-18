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
    
    var body: some View {
        ZStack {
            // Display task photo if available
            if let data = task.rawPhotoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width / 3 - 15, height: UIScreen.main.bounds.width / 3 - 15)
                    .clipped()
                    //.scaledToFit()
            } else {
                StickyNoteView(color: TaskFormatter.shared.stateColor(task: task))
            }
            // Top Capsule with State and Due Date
            HStack {
                Text(task.state ?? "Todo")
                    .foregroundColor(.white)
                    .font(.system(size: 18)) // Adjust the font size as needed
                Spacer()
                Text(TaskFormatter.shared.formattedDueDate(for: task, showDueDates: true))
                    .foregroundColor(TaskFormatter.shared.dueDateColor(for: task.dueDate ?? Date(), task: task))
                    .font(.system(size: 12)) // Adjust the font size as needed
            }
            .padding(.horizontal, 8) // Adjust the horizontal padding as needed
            .frame(height: 20) // Set the height of the capsule
            .background(TaskFormatter.shared.stateColor(task: task).opacity(0.7))
            .clipShape(Capsule())
            .padding(.top, -55) // Adjust as needed
            .frame(width: UIScreen.main.bounds.width / 3 - 15, height: UIScreen.main.bounds.width / 3 - 15)
            .edgesIgnoringSafeArea(.all)
            
            // Note Capsule at Bottom Right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(task.note ?? "")
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .lineLimit(3) // Limit to three lines
                        .truncationMode(.tail) // Add ellipsis if the text is truncated
                        .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize - 2))
                        .background(
                            Capsule()
                                .fill(LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom))
                                .cornerRadius(8)
                                .padding(.horizontal, -10.0)
                        )
                }
            }
            //VStack(alignment: .leading) {
            //    Text(task.state ?? "Todo")
            //        .font(.headline)
            //        .foregroundColor(.black)
            //    Text(task.dueDate != nil ? TaskFormatter.shared.dateFormatter.string(from: task.dueDate!) : "--")
            //        .font(.subheadline)
            //        .foregroundColor(.black)
            //    Text(task.note ?? "")
            //        .font(.caption)
            //        .foregroundColor(.black)
            //}

        }
        .padding(.top)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        //.cornerRadius(10)
        //.shadow(radius: 5)
    }
}
