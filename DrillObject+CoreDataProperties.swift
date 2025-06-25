//
//  DrillObject+CoreDataProperties.swift
//  Hockey Draw
//
//  Created by Dustin Brown on 6/11/25.
//
//

import Foundation
import CoreData


extension DrillObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrillObject> {
        return NSFetchRequest<DrillObject>(entityName: "DrillObject")
    }

    @NSManaged public var hasPuck: Bool
    @NSManaged public var teamColor: NSObject?
    @NSManaged public var startPosition: NSObject?
    @NSManaged public var positionLabel: String?
    @NSManaged public var type: String?
    @NSManaged public var id: UUID?
    @NSManaged public var drill: Drill?
    @NSManaged public var paths: NSSet?
    @NSManaged public var incomingPaths: DrillPath?

}

// MARK: Generated accessors for paths
extension DrillObject {

    @objc(addPathsObject:)
    @NSManaged public func addToPaths(_ value: DrillPath)

    @objc(removePathsObject:)
    @NSManaged public func removeFromPaths(_ value: DrillPath)

    @objc(addPaths:)
    @NSManaged public func addToPaths(_ values: NSSet)

    @objc(removePaths:)
    @NSManaged public func removeFromPaths(_ values: NSSet)

}

extension DrillObject : Identifiable {

}
