//
//  TaskFormatter.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/15/23.
//

import Foundation
import SwiftUI

class TaskFormatter: ObservableObject {
    static let shared = TaskFormatter()
    @State private var selectedDate: Date = Date()
   
    
    public let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    func formattedDueDate(for task: SnapPlanTask, showDueDates: Bool) -> String {
        //guard let dueDate = task.dueDate else { return "--" }
        //if showDueDates {
        //    return dateFormatter.string(from: dueDate)
        //} else {
        //    let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        //    return daysDifference < 0 ? "-\(daysDifference)" : "\(daysDifference)"
        //}
        let settings = Settings.shared
        if settings.dueDateDisplay == 1, let dueDate = task.dueDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
            return "\(components.day ?? 0)"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
    
            let currentYear = Calendar.current.component(.year, from: Date())
            let targetYear = Calendar.current.component(.year, from: task.dueDate ?? Date())
        
            if currentYear == targetYear {
                formatter.dateFormat = "MM/dd"
            } else {
                formatter.dateFormat = "MM/dd/yy"
            }
                        
            return task.dueDate.map(formatter.string) ?? ""
        }
    }
    
    func daysUntilDue(for task: SnapPlanTask) -> String {
        guard let dueDate = task.dueDate else { return "N/A" }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        
        let components = calendar.dateComponents([.day], from: today, to: due)
        
        if let days = components.day {
            if days < 0 {
                return "\(days)"
            } else if days == 0 {
                return "Today"
            } else {
                return "+\(days)"
            }
        }
        return "N/A"
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
    
    func stateFontColor(task: SnapPlanTask) -> Color {
        if task.state == "Done"{
            return Color.gray
        } else if task.state == "Todo" {
            return Color.black
        } else if task.state == "Doing" {
            return Color.white
        } else {
            return Color.primary
        }
    }
    
    func dueDateColor(for date: Date, task: SnapPlanTask) -> Color {
        let today = Calendar.current.startOfDay(for: Date())
        let dueDate = Calendar.current.startOfDay(for: date)

        if task.state == "Done" {
            return Color.doneFontColor
        } else if task.state == "Todo" && dueDate < today {
            return Color.todoPastDueFontColor
        } else if task.state == "Doing" && dueDate < today {
            return Color.doingPastDueFontColor
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
    
    func getFontSize(for task: SnapPlanTask) -> CGFloat {
        return (UIFont.preferredFont(forTextStyle: .body).pointSize + 8)
    }
}

struct StickyNoteView: View {
    var color: Color
    let taskCardWidth = (UIScreen.main.bounds.width / 3) - 10
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: taskCardWidth, height: taskCardWidth)
            .cornerRadius(5)
            .shadow(radius: 5)
    }
}

struct StickyNoteViewList: View {
    var color: Color
    let taskCardWidth =  (UIScreen.main.bounds.height / 13)
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: taskCardWidth, height: taskCardWidth)
            .cornerRadius(5)
            .shadow(radius: 5)
    }
}

extension Color {
    static let todoColor = Color(hex: "#FFD700") // Bright Yellow
    static let doingColor = Color(hex: "#5ce1e6") // Bright Blue
    static let doneColor = Color(hex: "#28A745") // Bright Green

    // Font Colors (High Contrast)
    static let todoPastDueFontColor = Color(hex: "#af0808") // Dark Red
    static let todoDueTodayFontColor = Color(hex: "#af0808") // Dark Red
    static let doingDueTodayFontColor = Color(hex: "#af0808") // White
    static let doingPastDueFontColor = Color(hex: "#af0808")
    static let todoFutureDueFontColor = Color(hex: "#000000") // Black
    static let doingFutureDueFontColor = Color(hex: "#000000") // Black
    static let doneFontColor = Color(hex: "#4f5933") // White
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


