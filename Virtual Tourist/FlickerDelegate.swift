//
//  FlickerDelegate.swift
//  On The Map
//
//  Created by nacho on 5/13/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation

public protocol FlickerDelegate {
    
    func didSearchLocationImages(success:Bool, location:PinLocation, photos:[Photo]?, errorString:String?)
}
