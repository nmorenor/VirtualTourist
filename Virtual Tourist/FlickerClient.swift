//
//  FlickerClient.swift
//  On The Map
//
//  Created by nacho on 5/13/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import CoreData

let FLICKR_API_KEY = "8c97222cbce046fd94f0c1a6fc17a022"

public class FlickerClient: NSObject, HTTPClientProtocol {
    
    var httpClient:HTTPClient?
    var temporaryContext:NSManagedObjectContext!
    
    override init() {
        super.init()
        self.httpClient = HTTPClient(delegate: self)
    }
    
    public func getBaseURLSecure() -> String {
        return FlickerClient.Constants.BASE_URL
    }
    
    public func addRequestHeaders(request: NSMutableURLRequest) {
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    public func processJsonBody(jsonBody: [String : AnyObject]) -> [String : AnyObject] {
        return jsonBody
    }
    
    public func processResponse(data: NSData) -> NSData {
        return data
    }
    
    lazy var sharedModelContext:NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedModelObjectContext!
    }()
    
    // MARK: - Shared Instance
    
    public class func sharedInstance() -> FlickerClient {
        
        struct Singleton {
            static var sharedInstance = FlickerClient()
        }
        
        return Singleton.sharedInstance
    }
}