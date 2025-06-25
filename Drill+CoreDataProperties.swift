//
//  Drill+CoreDataProperties.swift
//  Hockey Draw
//
//  Created by Dustin Brown on 6/11/25.
//
//

import Foundation
import CoreData


extension Drill {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Drill> {
        return NSFetchRequest<Drill>(entityName: "Drill")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var tags: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var duration: Double
    @NSManaged public var objects: NSSet?
    @NSManaged public var paths: NSSet?
    @NSManaged public var variations: NSSet?

}

// MARK: Generated accessors for objects
extension Drill {

    @objc(addObjectsObject:)
    @NSManaged public func addToObjects(_ value: DrillObject)

    @objc(removeObjectsObject:)
    @NSManaged public func removeFromObjects(_ value: DrillObject)

    @objc(addObjects:)
    @NSManaged public func addToObjects(_ values: NSSet)

    @objc(removeObjects:)
    @NSManaged public func removeFromObjects(_ values: NSSet)

}

// MARK: Generated accessors for paths
extension Drill {

    @objc(addPathsObject:)
    @NSManaged public func addToPaths(_ value: DrillPath)

    @objc(removePathsObject:)
    @NSManaged public func removeFromPaths(_ value: DrillPath)

    @objc(addPaths:)
    @NSManaged public func addToPaths(_ values: NSSet)

    @objc(removePaths:)
    @NSManaged public func removeFromPaths(_ values: NSSet)

}

// MARK: Generated accessors for variations
extension Drill {

    @objc(addVariationsObject:)
    @NSManaged public func addToVariations(_ value: DrillVariation)

    @objc(removeVariationsObject:)
    @NSManaged public func removeFromVariations(_ value: DrillVariation)

    @objc(addVariations:)
    @NSManaged public func addToVariations(_ values: NSSet)

    @objc(removeVariations:)
    @NSManaged public func removeFromVariations(_ values: NSSet)

}

extension Drill : Identifiable {

}
