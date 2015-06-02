//
//  FlickerConstants.swift
//  On The Map
//
//  Created by nacho on 5/13/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation

extension FlickerClient {
 
    struct Constants {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
    }
    
    struct ParameterKeys {
        static let METHOD = "method"
        static let API_KEY = "api_key"
        static let BBOX = "bbox"
        static let SAFE_SEARCH = "safe_search"
        static let EXTRAS = "extras"
        static let FORMAT = "format"
        static let NO_JSON_CALLBACK = "nojsoncallback"
    }
    
    struct Methods {
        static let SEARCH = "flickr.photos.search"
        
    }
}