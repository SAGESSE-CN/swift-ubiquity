//
//  Protocol.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


/// item rotation delegate
internal protocol DetailControllerItemRotationDelegate: class {
    
    /// item should rotation
    func detailController(_ detailController: Any, shouldBeginRotationing asset: Asset) -> Bool
    
    /// item did rotation
    func detailController(_ detailController: Any, didEndRotationing asset: Asset, at orientation: UIImageOrientation)
}

/// item update delegate
internal protocol DetailControllerItemUpdateDelegate: class {
    
    // item will show
    func detailController(_ detailController: Any, willShowItem indexPath: IndexPath)
    
    // item did show
    func detailController(_ detailController: Any, didShowItem indexPath: IndexPath)
}


//protocol ControllerDisplayable {
//    
//    func container(_ container: Container, willAuthorization source: Source)
//    func container(_ container: Container, didAuthorization source: Source, error: Error?)
//    
//    func container(_ container: Container, willDisplay source: Source)
//    func container(_ container: Container, didDisplay source: Source, error: Error?)
//}
//
//internal extension NSLayoutConstraint {
//    @inline(__always) static func ub_make(_ item: AnyObject, _ attr1: NSLayoutAttribute, _ related: NSLayoutRelation, _ toItem: AnyObject? = nil, _ attr2: NSLayoutAttribute = .notAnAttribute, _ constant: CGFloat = 0, priority: UILayoutPriority = 1000, multiplier: CGFloat = 1) -> Self {
//        let c = self.init(item: item, attribute: attr1, relatedBy: related, toItem: toItem, attribute: attr2, multiplier: multiplier, constant: constant)
//        c.priority = priority
//        return c
//    }
//}
//
//class ControllerContainerView: UIImageView, UIGestureRecognizerDelegate {
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        _setup()
//    }
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        
//        _setup()
//    }
//    
//    // disable all other pan gesture recognizer
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return false
//    }
//
//    private func _setup() {
//        
//        let tap = UIPanGestureRecognizer()
//        tap.delegate = self
//        addGestureRecognizer(tap)
//        
//        image = #imageLiteral(resourceName: "584_201703109382391")
//        contentMode = .scaleAspectFill
//        isUserInteractionEnabled = true
//    }
//    
//    
//}
//
//extension ControllerDisplayable where Self: UIViewController {
//    
//    func container(_ container: Container, willAuthorization source: Source) {
//    }
//    
//    func container(_ container: Container, didAuthorization source: Source, error: Error?) {
//        
//        let containerView = ControllerContainerView(frame: view.bounds)
//        
//        // adjust the view to the top level, which prevents the display from being covered after addSubview
//        containerView.layer.zPosition = 100_000_000
//        containerView.layer.masksToBounds = true
//        
//        // the default color is white
//        containerView.backgroundColor = .white
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(containerView)
//        
//        // in scroll view, if you set the left and right constraints, it will get the wrong width
//        view.addConstraint(.ub_make(containerView, .left, .equal, view, .left))
//        view.addConstraint(.ub_make(containerView, .width, .equal, view, .width))
//        view.addConstraint(.ub_make(containerView, .height, .equal, view, .height))
//        
//        guard view is UIScrollView else {
//            // in scroll view, container view must align to topLayoutGuide.bottom
//            // in other view, container view must align to view.top
//            return view.addConstraint(.ub_make(containerView, .top, .equal, view, .top))
//        }
//        
//        // multiplier must be negative, because in scroll view, bounds.origin(0, 0) is bounds.origin(contentInset.left, contentInset.top)
//        view.addConstraint(.ub_make(containerView, .top, .equal, topLayoutGuide, .bottom, multiplier: -1))
//    }
//    
//    func container(_ container: Container, willDisplay source: Source)  {
//    }
//    
//    func container(_ container: Container, didDisplay source: Source, error: Error?) {
//    }
//}
