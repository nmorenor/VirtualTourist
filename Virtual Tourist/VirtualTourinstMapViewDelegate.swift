//
//  VirtualTourinstMapViewDelegate.swift
//  Virtual Tourist
//
//  Created by nacho on 5/27/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import MapKit
import UIKit

extension VirtualTouristMapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let annotation = annotation as? MapPinAnnotation {
            let identifier = "pin"
            var view:MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if self.editMode {
            if let pinAnnotation = view as? MKPinAnnotationView {
                let annotation = pinAnnotation.annotation as! MapPinAnnotation
                //do not allow delete while fetching photos
                if annotation.location!.canBeDeleted() {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.sharedContext.deleteObject(annotation.location!)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
        } else {
            self.selectedPin = view.annotation as? MapPinAnnotation
            self.performSegueWithIdentifier("galerySegue", sender: self)
        }
    }
}
