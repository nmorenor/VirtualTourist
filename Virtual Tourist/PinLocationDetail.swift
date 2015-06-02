//
//  PinLocationDetail.swift
//  Virtual Tourist
//
//  Created by nacho on 6/1/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import CoreData
import MapKit

public class PinLocationDetail: NSManagedObject {
    
    @NSManaged var locality:String
    @NSManaged var location:PinLocation
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(location:PinLocation, locality:String, context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("PinLocationDetail", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.locality = locality
        self.location = location
    }
}
