//
//  TaskListView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI

struct TaskListView: View {
    var task: SnapTask
    
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
                Text(task.dueDate as Date?, format: .dateTime)
                Text(task.note ?? "")
            }
        }
        .padding()
    }
}
