//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by nacho on 5/31/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell: UICollectionViewCell, ImageLoadDelegate {
    
    @IBOutlet weak var placeHolderView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    var photo:Photo!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.photo.image == nil {
            self.photo.imageLoadDelegate = self
            self.configureLoadingCell()
        } else {
            self.configureCellWithPhoto()
        }
        self.placeHolderView.layer.cornerRadius = 3.0
        self.progressView.layer.cornerRadius = 3.0
    }
    
    func configureLoadingCell() {
        self.imageView.image = nil
        self.imageView.hidden = true
        self.placeHolderView.hidden = false
        self.progressView.progress = 0
        self.layoutIfNeeded()
    }
    
    func configureCellWithPhoto() {
        self.imageView.image = photo.image
        self.placeHolderView.hidden = true
        self.imageView.hidden = false
    }
    
    func progress(progress:CGFloat) {
        self.progressView.progress = Float(progress)
        self.layoutIfNeeded()
    }
    
    func didFinishLoad() {
        dispatch_async(dispatch_get_main_queue()) {
            self.configureCellWithPhoto()
        }
    }
}
