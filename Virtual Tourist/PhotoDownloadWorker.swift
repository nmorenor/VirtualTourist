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

public class PhotoDownloadWorker:NSObject, NSURLConnectionDataDelegate {
    
    var imageLoadDelegate:[ImageLoadDelegate] = [ImageLoadDelegate]()
    private var connection:NSURLConnection?
    private var imageData:NSMutableData?
    private var totalBytes:Int = 0
    private var receivedBytes:Int = 0
    var photo:Photo!
    
    override init() {
        super.init()
    }
    
    convenience init(photo:Photo) {
        self.init()
        self.photo = photo
        self.download()
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
            self.photo.image = image
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
    
    func cancel() {
        if let conn = self.connection {
            conn.cancel()
            self.imageLoadDelegate.removeAll(keepCapacity: false)
            self.totalBytes = 0
            self.receivedBytes = 0
            self.imageData = nil
        }
    }
    
    private func download() {
        let request = NSURLRequest(URL: self.photo.flickrURL)
        self.connection = NSURLConnection(request: request, delegate: self, startImmediately:false)
        self.connection!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self.connection!.start()
    }
}
