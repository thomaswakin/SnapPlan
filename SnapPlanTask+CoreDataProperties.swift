//
//  SnapPlanTask+CoreDataProperties.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/14/23.
//
//

import Foundation
import CoreData


extension SnapPlanTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SnapPlanTask> {
        return NSFetchRequest<SnapPlanTask>(entityName: "SnapPlanTask")
    }

    @NSManaged public var dueDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var note: String?
    @NSManaged public var priorityScore: Int16
    @NSManaged public var rawPhotoData: Data?
    @NSManaged public var state: String?

}

extension SnapPlanTask : Identifiable {

}
