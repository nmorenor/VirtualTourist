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

public class Photo : NSManagedObject, Equatable, NSURLConnectionDataDelegate {
    
    @NSManaged public var imagePath:String
    @NSManaged public var flickrURL:NSURL
    @NSManaged public var pinLocation:PinLocation?
    
    var imageLoadDelegate:[ImageLoadDelegate] = [ImageLoadDelegate]()
    private var connection:NSURLConnection?
    private var imageData:NSMutableData?
    private var totalBytes:Int = 0
    private var receivedBytes:Int = 0
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.listenForDelete(context)
    }
    
    init(location:PinLocation, imageURL:NSURL, context:NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.flickrURL = imageURL
        self.imagePath = self.flickrURL.lastPathComponent!
        self.pinLocation = location
        
        self.listenForDelete(context)
        
        self.download()
    }
    
    private func listenForDelete(context:NSManagedObjectContext?) {
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: context, queue: NSOperationQueue.mainQueue()) { notification in
            if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? NSSet {
                if deletedObjects.containsObject(self) && self.image != nil {
                    if let conn = self.connection {
                        conn.cancel()
                        self.imageLoadDelegate.removeAll(keepCapacity: false)
                        self.totalBytes = 0
                        self.receivedBytes = 0
                        self.imageData = nil
                    }
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
    
    public func isDownloading() -> Bool {
        return self.connection != nil
    }
    
    public func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        let httpResponse = response as! NSHTTPURLResponse
        let dictionary = httpResponse.allHeaderFields as! [String:String]
        let lengthString = dictionary["Content-Length"]
        let numberFormatter = NSNumberFormatter()
        let length:NSNumber = numberFormatter.numberFromString(lengthString!)!
        
        self.totalBytes = length as Int
        self.receivedBytes = 0
        self.imageData = NSMutableData(capacity: self.totalBytes)
    }
    
    public func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.imageData?.appendData(data)
        self.receivedBytes += data.length
        
        var progress = CGFloat((Float(self.receivedBytes) / Float(self.totalBytes)))
        self.fireProgressDelegate(progress)
    }
    
    public func connectionDidFinishLoading(connection: NSURLConnection) {
        if let imageData = self.imageData {
            let image = UIImage(data: imageData)
            self.image = image
        }
        self.connection = nil
        self.fireLoadFinish()
        self.imageLoadDelegate.removeAll(keepCapacity: false)
        self.totalBytes = 0
        self.receivedBytes = 0
        self.imageData = nil
    }
    
    func fireProgressDelegate(progress:CGFloat) {
        for next in imageLoadDelegate {
            next.progress(progress)
        }
    }
    
    func fireLoadFinish() {
        for next in imageLoadDelegate {
            next.didFinishLoad()
        }
    }
    
    private func download() {
        let request = NSURLRequest(URL: self.flickrURL)
        self.connection = NSURLConnection(request: request, delegate: self, startImmediately:false)
        self.connection!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self.connection!.start()
    }
}

public func ==(lhs:Photo, rhs:Photo) -> Bool {
    return lhs.flickrURL.isEqual(rhs) && lhs.pinLocation == rhs.pinLocation
}