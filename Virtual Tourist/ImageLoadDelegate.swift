//
//  ImageLoadDelegate.swift
//  Virtual Tourist
//
//  Created by nacho on 6/1/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import QuartzCore

protocol ImageLoadDelegate {
    
    func progress(progress:CGFloat)

    func didFinishLoad()
}
