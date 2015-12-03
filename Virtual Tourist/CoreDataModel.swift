//
//  CoreDataModel.swift
//  Virtual Tourist
//
//  Created by nacho on 6/8/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import CoreData

public typealias ContextSaveResult = (success: Bool, error: NSError?)

public struct CoreDataModel: CustomStringConvertible {
    
    public let name:String
    public let bundle:NSBundle
    public let storeDirectoryURL:NSURL
    
    public var storeURL: NSURL {
        get {
            return storeDirectoryURL.URLByAppendingPathComponent(databaseFileName)
        }
    }
    
    public var modelURL:NSURL {
        get {
            let url = bundle.URLForResource(name, withExtension: "momd")
            return url!
        }
    }
    
    public var databaseFileName: String {
        get {
            return name + ".sqlite"
        }
    }
    
    public var managedObjectModel : NSManagedObjectModel {
        get {
            let model = NSManagedObjectModel(contentsOfURL: modelURL)
            return model!
        }
    }
    
    public var modelStoreNeedsMigration:Bool {
        get {
            do {
                let sourceMetaData = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(nil, URL: storeURL)
                return !managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: sourceMetaData)
            } catch {
                print("*** \(String(CoreDataModel.self)) ERROR: [\(__LINE__)] \(__FUNCTION__) Failure checking persistent store coordinator meta data: \(error)")
            }
            
            return false
        }
    }
    
    public init(name:String, bundle:NSBundle = NSBundle.mainBundle(), storeDirectoryURL: NSURL = documentsDirectoryURL()) {
        self.name = name
        self.bundle = bundle
        self.storeDirectoryURL = storeDirectoryURL
    }
    
    public func removeExistingModelStore() -> (success:Bool, error:NSError?) {
        let fileManager = NSFileManager.defaultManager()
        
        if let storePath = storeURL.path {
            if fileManager.fileExistsAtPath(storePath) {
                do {
                    try fileManager.removeItemAtURL(storeURL)
                    return (true, nil)
                } catch {
                    print("*** \(String(CoreDataModel.self)) ERROR: [\(__LINE__)] \(__FUNCTION__) Could not remove model store at url: \(error)")
                    return (false, error as NSError)
                }
            }
        }
        
        return (false, nil)
    }
    
    public var description:String {
        get {
            return "<\(String(CoreDataModel.self)): name=\(name), needsMigration=\(modelStoreNeedsMigration), databaseFileName=\(databaseFileName), modelURL=\(modelURL), storeURL=\(storeURL)>"
        }
    }
}

public func saveContext(context: NSManagedObjectContext, completion: (ContextSaveResult) -> Void) {
    if !context.hasChanges {
        completion((true, nil))
        return
    }
    
    context.performBlock { () -> Void in

        do {
            try context.save()
            completion((true, nil))
        } catch {
            print("*** ERROR: [\(__LINE__)] \(__FUNCTION__) Could not save managed object context: \(error)")
            completion((true, error as NSError))
        }
        
        
    }
}

// MARK: Private

private func documentsDirectoryURL() -> NSURL {
    let url: NSURL?
    do {
        url = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
    } catch  {
        Swift.print("*** Error finding documents directory: \(error)")
        fatalError()
    }
    return url!
}
