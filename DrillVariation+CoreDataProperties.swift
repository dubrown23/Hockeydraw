//
//  DrillVariation+CoreDataProperties.swift
//  Hockey Draw
//
//  Created by Dustin Brown on 6/11/25.
//
//

import Foundation
import CoreData


extension DrillVariation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrillVariation> {
        return NSFetchRequest<DrillVariation>(entityName: "DrillVariation")
    }

    @NSManaged public var name: String?
    @NSManaged public var id: UUID?
    @NSManaged public var variations: NSSet?
    @NSManaged public var parentDrill: Drill?

}

// MARK: Generated accessors for variations
extension DrillVariation {

    @objc(addVariationsObject:)
    @NSManaged public func addToVariations(_ value: DrillVariation)

    @objc(removeVariationsObject:)
    @NSManaged public func removeFromVariations(_ value: DrillVariation)

    @objc(addVariations:)
    @NSManaged public func addToVariations(_ values: NSSet)

    @objc(removeVariations:)
    @NSManaged public func removeFromVariations(_ values: NSSet)

}

extension DrillVariation : Identifiable {

}
