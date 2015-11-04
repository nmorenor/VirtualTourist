//
//  PhotoDownloadWorker.swift
//  Virtual Tourist
//
//  Created by nacho on 6/2/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

public class PhotoDownloadWorker:NSOperation, NSURLSessionDataDelegate {
    
    var imageLoadDelegate:[ImageLoadDelegate] = [ImageLoadDelegate]()
    private var imageData:NSMutableData?
    private var totalBytes:Int = 0
    private var receivedBytes:Int = 0
    var photo:Photo
    var session:NSURLSession!
    
    public override var hashValue: Int {
        get {
            return self.photo.flickrURL.path!.hashValue
        }
    }
    
    init(photo:Photo) {
        self.photo = photo
        super.init()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: PendingPhotoDownloads.sharedInstance().downloadQueue)
        
        PendingPhotoDownloads.sharedInstance().downloadsInProgress[self.photo.description.hashValue] = self
        
        objc_sync_enter( PendingPhotoDownloads.sharedInstance().downloadWorkers)
        PendingPhotoDownloads.sharedInstance().downloadWorkers.insert(self)
        objc_sync_exit( PendingPhotoDownloads.sharedInstance().downloadWorkers)
        
        if PendingPhotoDownloads.sharedInstance().downloadWorkers.count <= PendingPhotoDownloads.sharedInstance().downloadQueue.maxConcurrentOperationCount {
            PendingPhotoDownloads.sharedInstance().downloadQueue.addOperation(self)
        }
    }
    
    public override func main() {
        self.download()
    }
    
    public func isDownloading() -> Bool {
        return PendingPhotoDownloads.sharedInstance().downloadsInProgress.indexForKey(self.photo.description.hashValue) != nil
    }
    
    func fireProgressDelegate(progress:CGFloat) {
        for next in imageLoadDelegate {
            dispatch_async(dispatch_get_main_queue()) {
                next.progress(progress)
            }
        }
    }
    
    func fireLoadFinish() {
        
        objc_sync_enter( PendingPhotoDownloads.sharedInstance().downloadWorkers)
        PendingPhotoDownloads.sharedInstance().downloadWorkers.remove(self)
        let pendingWorkers = PendingPhotoDownloads.sharedInstance().downloadWorkers.filter { !$0.finished && !$0.executing}
        if let worker = pendingWorkers.first {
            PendingPhotoDownloads.sharedInstance().downloadWorkers.insert(worker)
            PendingPhotoDownloads.sharedInstance().downloadQueue.addOperation(worker)
        }
        objc_sync_exit( PendingPhotoDownloads.sharedInstance().downloadWorkers)
        
        for next in imageLoadDelegate {
            dispatch_async(dispatch_get_main_queue()) {
                next.didFinishLoad()
            }
        }
    }
    
    override public func cancel() {
        super.cancel()
        self.imageLoadDelegate.removeAll(keepCapacity: false)
        self.totalBytes = 0
        self.receivedBytes = 0
        self.imageData = nil
        self.session = nil
        PendingPhotoDownloads.sharedInstance().downloadsInProgress.removeValueForKey(self.photo.description.hashValue)
    }
    
    private func download() {
        let request = NSURLRequest(URL: self.photo.flickrURL)
        let dataTask = self.session.dataTaskWithRequest(request)
        
        dataTask.resume()
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        if self.cancelled {
            return;
        }
        
        self.receivedBytes = 0
        self.totalBytes = Int(response.expectedContentLength);
        self.imageData = NSMutableData(capacity: self.totalBytes)
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if self.cancelled {
            return;
        }
        
        self.imageData?.appendData(data)
        self.receivedBytes += data.length
        
        let progress = CGFloat((Float(self.receivedBytes) / Float(self.totalBytes)))
        self.fireProgressDelegate(progress)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        PendingPhotoDownloads.sharedInstance().downloadsInProgress.removeValueForKey(self.photo.description.hashValue)
        if let error = error {
            print("Error downloading photo \(error)")
        }
        if let imageData = self.imageData {
            let image = UIImage(data: imageData)
            self.photo.image = image
        }
        self.fireLoadFinish()
        self.imageLoadDelegate.removeAll(keepCapacity: false)
        self.totalBytes = 0
        self.receivedBytes = 0
        self.imageData = nil
        self.session = nil
    }
}

public func ==(lhs:PhotoDownloadWorker, rhs:PhotoDownloadWorker) -> Bool {
    return lhs.photo.flickrURL.path! == rhs.photo.flickrURL.path!
}
