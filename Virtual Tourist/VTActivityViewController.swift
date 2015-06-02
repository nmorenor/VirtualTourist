//
//  VTActivityViewController.swift
//  On The Map
//
//  Created by nacho on 5/10/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import UIKit

public class VTActivityViewController: UIViewController {
    
    var containerView:UIView!
    var activityBackgroundView:UIView!
    var rootViewController:UIViewController!
    var activity:UIActivityIndicatorView!
    var processingLabel:UILabel!
    
    let padding:CGFloat = 20.0
    var viewWidth:CGFloat?
    var viewHeight:CGFloat?
    var fontName = "Helvetica"
    
    var baseColor = UIColor(red: 242.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1)
    
    var isOpen:Bool = false
    
    public class OnTheMapActivityViewResponder {
        
        let activityView:VTActivityViewController
        
        init(activityView:VTActivityViewController) {
            self.activityView = activityView
        }
        
        public func close() {
            self.activityView.closeView()
        }
    }
    
    public init() {
        super.init(nibName:nil, bundle:nil)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = UIScreen.mainScreen().bounds.size
        self.viewWidth = size.width
        self.viewHeight = size.height
        
        var yPos:CGFloat = 35.0
        var contentWidth:CGFloat = 100 - (self.padding*2)
        
        let processingString = processingLabel.text! as NSString
        let processingAttr = [NSFontAttributeName:processingLabel.font]
        let processingSize = CGSize(width: contentWidth, height: 90)
        let processingRect = processingString.boundingRectWithSize(processingSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: processingAttr, context: nil)
        yPos += padding
        self.processingLabel.frame = CGRect(x: self.padding, y: yPos, width: 100 - (self.padding*2), height: ceil(processingRect.size.height))
        yPos += ceil(processingRect.size.height) + 8
        
        // size the background view
        self.activityBackgroundView.frame = CGRect(x: 0, y: 0, width: 100, height: yPos)
        
        // size the container that holds everything together
        self.containerView.frame = CGRect(x: (self.viewWidth!-100)/2, y: (self.viewHeight! - yPos)/2, width: 25, height: yPos)
        
        self.activity.frame.origin = CGPoint(x: self.containerView.bounds.origin.x + 38, y: self.containerView.bounds.origin.y + self.padding)
    }
    
    public func show(viewController: UIViewController, text:String) -> OnTheMapActivityViewResponder {
        self.rootViewController = viewController
        self.rootViewController.addChildViewController(self)
        self.rootViewController.view.addSubview(view)
        
        self.view.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.7)
        
        let sz = UIScreen.mainScreen().bounds.size
        self.viewWidth = sz.width
        self.viewHeight = sz.height
        
        // Container for the entire alert modal contents
        self.containerView = UIView()
        self.containerView.layer.shadowOffset = CGSizeMake(3, 3)
        self.containerView.layer.shadowOpacity = 0.8
        self.containerView.layer.shadowRadius = 2
        self.view.addSubview(self.containerView!)
        
        // Background view/main color
        self.activityBackgroundView = UIView()
        activityBackgroundView.backgroundColor = baseColor
        activityBackgroundView.layer.cornerRadius = 4
        activityBackgroundView.layer.masksToBounds = true
        self.containerView.addSubview(activityBackgroundView!)
        
        self.activity = UIActivityIndicatorView(frame: CGRectMake(0, 0, 25, 25))
        self.activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        self.containerView.addSubview(self.activity)
        self.activity.startAnimating()
        self.activity.hidden = false
        
        self.processingLabel = UILabel()
        self.processingLabel.textColor = UIColor.blackColor()
        self.processingLabel.numberOfLines = 1
        self.processingLabel.textAlignment = .Center
        self.processingLabel.font = UIFont(name: self.fontName, size: 9)
        self.processingLabel.text = text
        self.containerView.addSubview(self.processingLabel)
        
        // Animate it in
        self.view.alpha = 0
        UIView.animateWithDuration(0.2, animations: {
            self.view.alpha = 1
        })
        self.containerView.frame.origin.x = self.rootViewController.view.center.x
        self.containerView.center.y = -500
        UIView.animateWithDuration(0.5, delay: 0.05, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: nil, animations: {
            self.containerView.center = self.rootViewController.view.center
            }, completion: { finished in
                
        })
        
        isOpen = true
        
        return OnTheMapActivityViewResponder(activityView: self)
    }
    
    public func closeView() {
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: nil, animations: {
            self.containerView.center.y = -(self.viewHeight! + 10)
            }, completion: { finished in
                UIView.animateWithDuration(0.1, animations: {
                    self.view.alpha = 0
                    }, completion: { finished in
                        self.removeView()
                })
                
        })
    }
    
    func removeView() {
        isOpen = false
        self.view.removeFromSuperview()
    }
}
