//
//  TaskFormatter.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/15/23.
//

import Foundation
import SwiftUI

class TaskFormatter {
    static let shared = TaskFormatter()
    
    public let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YY/MM/DD"
        return formatter
    }()
    
    func formattedDueDate(for task: SnapPlanTask, showDueDates: Bool) -> String {
        guard let dueDate = task.dueDate else { return "--" }
        
        if showDueDates {
            return dateFormatter.string(from: dueDate)
        } else {
            let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            return daysDifference < 0 ? "-\(daysDifference)" : "\(daysDifference)"
        }
    }
        
    func stateColor(task: SnapPlanTask) -> Color {
        if task.state == "Done"{
            return Color.doneColor
        } else if task.state == "Todo" {
            return Color.todoColor
        } else if task.state == "Doing" {
            return Color.doingColor
        } else {
            return Color.primary
        }
    }
    
    func dueDateColor(for date: Date, task: SnapPlanTask) -> Color {
        let today = Calendar.current.startOfDay(for: Date())
        let dueDate = Calendar.current.startOfDay(for: date)

        if task.state == "Done" {
            return Color.doneFontColor
        } else if dueDate < today {
            return Color.pastDueFontColor
        } else if task.state == "Todo" && Calendar.current.isDateInToday(dueDate) {
            return Color.todoDueTodayFontColor
        } else if task.state == "Doing" && Calendar.current.isDateInToday(dueDate) {
            return Color.doingDueTodayFontColor
        } else if task.state == "Todo" && dueDate > today {
            return Color.todoFutureDueFontColor
        } else if task.state == "Doing" && dueDate > today {
            return Color.doingFutureDueFontColor
        } else {
            return Color.primary
        }
    }
}

extension Color {
    static let todoColor = Color(hex: "#FEC601")
    static let doingColor = Color(hex: "#3DA5D9")
    static let doneColor = Color(hex: "#73BFB8")
    static let pastDueFontColor = Color(hex: "#af0808")
    static let todoDueTodayFontColor = Color(hex: "#EA7317")
    static let doingDueTodayFontColor = Color(hex: "#A85413")
    static let todoFutureDueFontColor = Color(hex: "#F4F4EC")
    static let doingFutureDueFontColor = Color(hex: "#E5E4E2")
    static let doneFontColor = Color(hex: "#4F5933")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Default Image for Initialization
extension UIImage {
    static var defaultImage: UIImage {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!

        context.setFillColor(UIColor.systemYellow.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return image
    }
}


