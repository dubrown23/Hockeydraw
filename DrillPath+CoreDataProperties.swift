//
//  DrillPath+CoreDataProperties.swift
//  Hockey Draw
//
//  Created by Dustin Brown on 6/11/25.
//
//

import Foundation
import CoreData


extension DrillPath {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrillPath> {
        return NSFetchRequest<DrillPath>(entityName: "DrillPath")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var pathData: NSObject?
    @NSManaged public var skatingType: String?
    @NSManaged public var startTime: Double
    @NSManaged public var duration: Double
    @NSManaged public var drill: Drill?
    @NSManaged public var startObject: DrillObject?
    @NSManaged public var endObject: DrillObject?

}

extension DrillPath : Identifiable {

}
