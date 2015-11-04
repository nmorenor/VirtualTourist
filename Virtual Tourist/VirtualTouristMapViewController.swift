//
//  VirtualTouristMapViewController.swift
//  Virtual Tourist
//
//  Created by nacho on 5/27/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class VirtualTouristMapViewController: UIViewController, NSFetchedResultsControllerDelegate {

    //MARK: - LifeCycle
    
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    var longPressRecognizer:UILongPressGestureRecognizer!
    var currentAnnotation:MapPinAnnotation? = nil
    var selectedPin:MapPinAnnotation? = nil
    var editMode:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        
        self.mapView.addGestureRecognizer(longPressRecognizer)
        self.mapView.delegate = self
        
        do {
            try self.fetchedResutlsController.performFetch()
        } catch _ {
        }
        self.fetchedResutlsController.delegate = self
        if let fetched = self.fetchedResutlsController.fetchedObjects as? [PinLocation] {
            for annotation in fetched {
                let toAdd = MapPinAnnotation(latitude: annotation.latitude as Double, longitude: annotation.longitude as Double)
                toAdd.location = annotation
                self.mapView.addAnnotation(toAdd)
            }
        }
        self.updateConstrainstsForMode()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.selectedPin = nil
    }
    
    //MARK: - CoreData
    
    lazy var fetchedResutlsController:NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "PinLocation")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    var sharedContext:NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().dataStack.managedObjectContext
    }
    
    //MARK: - NSFetchedResultsControllerDelegate
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch(type) {
        case NSFetchedResultsChangeType.Insert :
            if let location:PinLocation = anObject as? PinLocation {
                let annotation = MapPinAnnotation(latitude: location.latitude as Double, longitude: location.longitude as Double)
                annotation.location = location
                self.mapView.removeAnnotation(annotation)
                self.mapView.addAnnotation(annotation)
            }
            break
        case NSFetchedResultsChangeType.Delete :
            if let location:PinLocation = anObject as? PinLocation {
                for annotation in self.mapView.annotations {
                    if let pin:MapPinAnnotation = annotation as? MapPinAnnotation {
                        if pin.coordinate.latitude == location.latitude && pin.coordinate.longitude == location.longitude {
                            self.mapView.removeAnnotation(pin)
                        }
                    }
                }
            }
            break
        default:
            break
        }
    }
    
    func createLocationDetail() {
        dispatch_async(dispatch_get_main_queue()) {
            let coordinate = self.currentAnnotation!.coordinate
            let location = PinLocation(latitude: coordinate.latitude, longitude: coordinate.longitude, context: self.sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            self.currentAnnotation!.location = location
            FlickerPhotoDelegate.sharedInstance().searchPhotos(location)
            let clocation = CLLocation(latitude: self.currentAnnotation!.coordinate.latitude, longitude: self.currentAnnotation!.coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(clocation) { placemarks, error in
                if error != nil {
                    print("Reverse geocoder failed with error" + error!.localizedDescription)
                    return
                }
                
                if placemarks!.count > 0 {
                    let pm = placemarks![0]
                    
                    if pm.locality != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            _ = PinLocationDetail(location: location, locality: pm.locality!, context: self.sharedContext)
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                }
            }
            self.currentAnnotation = nil
        }
    }
    
    func createPinAnnotation(recognizer:UIGestureRecognizer) {
        let touchPoint = recognizer.locationInView(self.mapView)
        let touchMapCoordinate = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
        
        self.currentAnnotation = MapPinAnnotation(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude)
        self.mapView.addAnnotation(self.currentAnnotation!)
    }
    
    func changePinLocationForDrag(recognizer:UIGestureRecognizer) {
        let touchPoint = recognizer.locationInView(self.mapView)
        let touchMapCoordinate = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
        
        self.mapView.removeAnnotation(self.currentAnnotation!)
        self.currentAnnotation?.coordinate = touchMapCoordinate
        self.mapView.addAnnotation(self.currentAnnotation!)
    }
    
    //MARK: - Controller
    
    func handleLongPress(recognizer:UIGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.Ended) {
            if self.editMode {
                return
            }
            self.createLocationDetail()
            return
        } else if (recognizer.state == UIGestureRecognizerState.Changed) {
            self.changePinLocationForDrag(recognizer)
        } else {
            self.createPinAnnotation(recognizer)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "galerySegue" {
            if let viewController = segue.destinationViewController as? VirtualTouristGalleryViewController {
                viewController.annotation = self.selectedPin
            }
        }
    }
    
    @IBAction func onEdit(sender: UIBarButtonItem) {
        if self.editMode {
            self.editButton.title = "Edit"
        } else {
            self.editButton.title = "Done"
        }
        self.editMode = !self.editMode
        
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(1.0, animations: {
            self.updateConstrainstsForMode()
            self.view.layoutIfNeeded()
        })
    }
    
    func updateConstrainstsForMode () {
        if self.editMode {
            self.deleteViewTopConstraint.constant = -71
            self.mapViewBottomConstraint.constant = 0
            self.mapViewBottomConstraint.priority = 750+1
        } else {
            self.deleteViewTopConstraint.constant = 0
            self.mapViewBottomConstraint.constant = -71
            self.mapViewBottomConstraint.priority = 750-1
        }
    }
}
