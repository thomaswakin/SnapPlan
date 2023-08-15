//
//  TaskListView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI
import Foundation

struct TaskListView: View {
    var task: SnapPlanTask
    
    var body: some View {
        HStack {
            // Display task photo if available
            if let data = task.rawPhotoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
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
