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

public class PhotoDownloadWorker:NSOperation, NSURLSessionDataDelegate  {
    
    var imageLoadDelegate:[ImageLoadDelegate] = [ImageLoadDelegate]()
    private var imageData:NSMutableData?
    private var totalBytes:Int = 0
    private var receivedBytes:Int = 0
    var photo:Photo!
    var session:NSURLSession!
    
    convenience init(photo:Photo) {
        self.init()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: PendingPhotoDownloads.sharedInstance().downloadQueue)
        self.photo = photo
        PendingPhotoDownloads.sharedInstance().downloadsInProgress[self.photo] = self
        PendingPhotoDownloads.sharedInstance().downloadQueue.addOperation(self)
    }
    
    public override func main() {
        self.download()
    }
    
    public func isDownloading() -> Bool {
        return PendingPhotoDownloads.sharedInstance().downloadsInProgress.indexForKey(self.photo) != nil
    }
    
    func fireProgressDelegate(progress:CGFloat) {
        for next in imageLoadDelegate {
            dispatch_async(dispatch_get_main_queue()) {
                next.progress(progress)
            }
        }
    }
    
    func fireLoadFinish() {
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

        PendingPhotoDownloads.sharedInstance().downloadsInProgress.removeValueForKey(self.photo)
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
        
        var progress = CGFloat((Float(self.receivedBytes) / Float(self.totalBytes)))
        self.fireProgressDelegate(progress)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        PendingPhotoDownloads.sharedInstance().downloadsInProgress.removeValueForKey(self.photo)
        if let error = error {
            println("Error downloading photo \(error)")
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
    }
}
