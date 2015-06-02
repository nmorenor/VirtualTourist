//
//  FlickerPhotoDelegate.swift
//  Virtual Tourist
//
//  Created by nacho on 5/31/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation

public class FlickerPhotoDelegate: FlickerDelegate {

    class func sharedInstance() -> FlickerPhotoDelegate {
        struct Static {
            static let instance = FlickerPhotoDelegate()
        }
        return Static.instance
    }
    
    var onLoad:Set<PinLocation> = Set()
    var delegates:[PinLocation:FlickerDelegate] = [PinLocation:FlickerDelegate]()
    
    public func didSearchLocationImages(success:Bool, location:PinLocation, photos:[Photo]?, errorString:String?) {
        self.onLoad.remove(location)
        if let delegate = delegates[location] {
            delegate.didSearchLocationImages(success, location: location, photos: photos, errorString: errorString)
        }
        self.delegates.removeValueForKey(location)
    }
    
    public func searchPhotos(location:PinLocation) {
        self.onLoad.insert(location)
        FlickerClient.sharedInstance().getPhototosFromFlickerSearch(location, delegate: self)
    }
    
    public func isLoading(location:PinLocation) -> Bool {
        return self.onLoad.contains(location)
    }
    
    public func addDelegate(location:PinLocation, delegate:FlickerDelegate) {
        delegates[location] = delegate
    }
}
