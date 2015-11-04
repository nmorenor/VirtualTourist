//
//  VirtualTouristGalleryViewController.swift
//  Virtual Tourist
//
//  Created by nacho on 5/30/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class VirtualTouristGalleryViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, FlickerDelegate, ImageLoadDelegate {
    
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    var annotation:MapPinAnnotation!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var shouldFetch:Bool = false
    var activityView:VTActivityViewController?
    var recognizer:UILongPressGestureRecognizer!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noPhotosLabel.hidden = true
        if FlickerPhotoDelegate.sharedInstance().isLoading(annotation.location!) {
            self.shouldFetch = true
            self.updateToolBar(false)
            FlickerPhotoDelegate.sharedInstance().addDelegate(annotation.location!, delegate: self)
            self.collectionView.hidden = true
            self.activityView = VTActivityViewController()
            self.activityView?.show(self, text: "Processing...")
        } else {        
            self.performFetch()
            if self.annotation.location!.isDownloading() {
                for next in annotation.location!.photos {
                    if let downloadWorker = PendingPhotoDownloads.sharedInstance().downloadsInProgress[next.description.hashValue] as? PhotoDownloadWorker {
                        downloadWorker.imageLoadDelegate.append(self)
                    }
                }
            } else {
                self.updateToolBar(annotation.location!.photos.count > 0)
            }
            
        }
        
        if let details = self.annotation.location!.details {
            self.navigationItem.title = details.locality
        }
        
        self.recognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        self.collectionView.addGestureRecognizer(self.recognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotation(self.annotation)
        
        self.navigationItem.backBarButtonItem?.title = "Back"
        
        let region:MKCoordinateRegion = MKCoordinateRegion(center: self.annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
        self.mapView.setRegion(region, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.collectionViewLayout = getCollectionLayout()
    }
    
    //MARK: - Controller
    
    func handleLongPress(recognizer:UILongPressGestureRecognizer) {
        if (recognizer.state != UIGestureRecognizerState.Ended) {
            return
        }
        
        let point = recognizer.locationInView(self.collectionView)
        if let indexPath = self.collectionView.indexPathForItemAtPoint(point) {
            if let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as? PhotoCell {
                let photo = cell.photo
                photo.pinLocation = nil
                self.sharedContext.deleteObject(photo)
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
    }
    
    func getCollectionLayout() -> UICollectionViewFlowLayout {
        let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        return layout
    }
    
    func didSearchLocationImages(success:Bool, location:PinLocation, photos:[Photo]?, errorString:String?) {
        for next in annotation.location!.photos {
            if let downloadWorker = PendingPhotoDownloads.sharedInstance().downloadsInProgress[next.description.hashValue] as? PhotoDownloadWorker {
                downloadWorker.imageLoadDelegate.append(self)
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            let noPhotos = self.annotation.location!.photos.count == 0
            self.noPhotosLabel.hidden = !noPhotos
            self.activityView?.closeView()
            self.activityView = nil
            self.collectionView.hidden = false
            if (self.shouldFetch) {
                self.shouldFetch = false
                self.performFetch()
            }
            
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.view.layoutIfNeeded()
            if (photos?.count > 0) {
                UIView.animateWithDuration(1.0, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
        
    }
    
    func updateToolBar(enabled:Bool) {
        self.newCollectionButton.enabled = enabled
    }
    
    @IBAction func newCollection(sender: UIBarButtonItem) {
        for photo in self.annotation.location!.photos {
            photo.pinLocation = nil
            //clean images from disk
            photo.image = nil
            self.sharedContext.deleteObject(photo)
        }
        self.searchPhotosForLocation()
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    func searchPhotosForLocation() {
        FlickerPhotoDelegate.sharedInstance().searchPhotos(self.annotation.location!)
        self.collectionView.hidden = true
        self.newCollectionButton.enabled = false;
        self.view.layoutIfNeeded()
        self.updateToolBar(false)
        FlickerPhotoDelegate.sharedInstance().addDelegate(annotation.location!, delegate: self)
        self.activityView = VTActivityViewController()
        self.activityView?.show(self, text: "Processing...")
        
    }
    
    //MARK: - Image Load Delegate
    
    func progress(progress:CGFloat) {
        //do nothings
    }
    
    func didFinishLoad() {
        let downloading = self.annotation.location!.isDownloading()
        dispatch_async(dispatch_get_main_queue()) {
            self.updateToolBar(!downloading)
        }
    }
    
    //MARK: - Configure Cell
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath:NSIndexPath) {
        let photo = self.fetchedResultsViewController.objectAtIndexPath(indexPath) as! Photo
        
        cell.photo = photo
    }
    
    //MARK: - CoreData
    
    lazy var fetchedResultsViewController:NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imagePath", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pinLocation == %@", self.annotation.location!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: "photos")
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    lazy var sharedContext:NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().dataStack.managedObjectContext
    }()
    
    private func performFetch() {
        var error:NSError?
        NSFetchedResultsController.deleteCacheWithName("photos")
        do {
            try self.fetchedResultsViewController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        if let _ = error {
            print("Error performing initial fetch")
        }
        let sectionInfo = self.fetchedResultsViewController.sections!.first!
        if sectionInfo.numberOfObjects == 0 {
            noPhotosLabel.hidden = self.activityView == nil ? false : true
            collectionView.hidden = true
        } else {
            noPhotosLabel.hidden = true
            collectionView.hidden = false
        }
    }
    
    //MARK: - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsViewController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsViewController.sections![section] 
        
        if let photos = self.annotation!.location?.photos where photos.count == 0 && self.isViewLoaded() && self.view.window != nil && self.newCollectionButton.enabled && !FlickerPhotoDelegate.sharedInstance().isLoading(annotation.location!) {
            noPhotosLabel.hidden = false
            collectionView.hidden = true
            dispatch_async(dispatch_get_main_queue()) {
                self.searchPhotosForLocation()
            }
        }
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        self.configureCell(cell, atIndexPath: indexPath)
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            self.insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            self.deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            self.updatedIndexPaths.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.collectionView.performBatchUpdates({() -> Void in
            
            if self.insertedIndexPaths.count > 0 {
                self.collectionView.insertItemsAtIndexPaths(self.insertedIndexPaths)
            }
            
            if self.deletedIndexPaths.count > 0 {
                self.collectionView.deleteItemsAtIndexPaths(self.deletedIndexPaths)
            }
            
            if self.updatedIndexPaths.count > 0 {
                self.collectionView.reloadItemsAtIndexPaths(self.updatedIndexPaths)
            }
            
            }, completion: nil)
    }
}
