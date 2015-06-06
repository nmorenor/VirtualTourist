//
//  Photo.swift
//  Virtual Tourist
//
//  Created by nacho on 5/30/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Photo)

public class Photo : NSManagedObject, Equatable {
    
    @NSManaged public var imagePath:String
    @NSManaged public var flickrURL:NSURL
    @NSManaged public var pinLocation:PinLocation?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.listenForDelete(context)
        if self.image == nil {
            PhotoDownloadWorker(photo: self)
        }
    }
    
    init(location:PinLocation, imageURL:NSURL, context:NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.flickrURL = imageURL
        self.imagePath = self.flickrURL.lastPathComponent!
        self.pinLocation = location
        
        self.listenForDelete(context)
        
        PhotoDownloadWorker(photo: self)
    }
    
    private func listenForDelete(context:NSManagedObjectContext?) {
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: context, queue: NSOperationQueue.mainQueue()) { notification in
            if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? NSSet {
                if deletedObjects.containsObject(self) && self.image != nil {
                    self.image = nil
                }
            }
        }
    }
    
    var image:UIImage? {
        get {
            return ImageCache.sharedInstance().imageWithIdentifier("\(self.imagePath)")
        }
        
        set {
            ImageCache.sharedInstance().storeImage(newValue, withIdentifier: "\(self.imagePath)")
        }
    }
}

public func ==(lhs:Photo, rhs:Photo) -> Bool {
    return lhs.flickrURL.isEqual(rhs) && lhs.pinLocation == rhs.pinLocation
}