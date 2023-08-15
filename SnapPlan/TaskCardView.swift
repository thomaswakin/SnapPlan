//
//  TaskCardView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//

import SwiftUI

struct TaskCardView: View {
    var task: SnapTask
    
    var body: some View {
        VStack {
            // Display task photo if available
            if let data = task.rawPhotoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            Text(task.state ?? "Todo")
            Text(task.dueDate as Date?, format: .dateTime)
            Text(task.note ?? "")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
