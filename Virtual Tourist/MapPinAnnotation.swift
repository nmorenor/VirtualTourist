//
//  MapPinAnnotation.swift
//  Virtual Tourist
//
//  Created by nacho on 5/27/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import MapKit

public class MapPinAnnotation: NSObject, MKAnnotation {
    
    public var title:String?
    public var subtitle:String?
    public var coordinate: CLLocationCoordinate2D
    public var location:PinLocation?
    
    init(latitude: Double, longitude:Double) {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        super.init()
    }
}
