//
//  TaskCardView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI

struct TaskCardView: View {
    @ObservedObject var task: SnapPlanTask
    
    var body: some View {
        ZStack {
            // Display task photo if available
            if let data = task.rawPhotoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                StickyNoteView() // Default sticky note view
            }
            VStack(alignment: .leading) {
                Text(task.state ?? "Todo")
                    .font(.headline)
                    .foregroundColor(.black)
                Text(task.dueDate != nil ? TaskFormatter.shared.dateFormatter.string(from: task.dueDate!) : "--")
                    .font(.subheadline)
                    .foregroundColor(.black)
                Text(task.note ?? "")
                    .font(.caption)
                    .foregroundColor(.black)
            }

        }
        .padding()
        .background(Color.white)
        //.cornerRadius(10)
        //.shadow(radius: 5)
    }
}
