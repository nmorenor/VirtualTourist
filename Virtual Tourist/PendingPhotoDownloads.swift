//
//  PendingPhotoDownloads.swift
//  Virtual Tourist
//
//  Created by nacho on 6/6/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation

class PendingPhotoDownloads: NSObject {
    
    class func sharedInstance() -> PendingPhotoDownloads {
        struct Static {
            static let instance = PendingPhotoDownloads()
        }
        return Static.instance
    }
    
    var downloadsInProgress:[Int:AnyObject] = [Int:AnyObject]()
    var downloadQueue:NSOperationQueue
    var downloadWorkers:Set<PhotoDownloadWorker> = Set()
    
    override init() {
        downloadQueue = NSOperationQueue()
        downloadQueue.name = "Download Queue"
        downloadQueue.maxConcurrentOperationCount = 6
        super.init()
    }
    
    
}
