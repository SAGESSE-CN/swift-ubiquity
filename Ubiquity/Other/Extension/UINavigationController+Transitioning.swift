//
//  UINavigationController+Transitioning.swift
//  Ubiquity
//
//  Created by SAGESSE on 3/19/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// navigation controller transitioning delegate
@objc
internal protocol  UINavigationControllerTransitioningDelegate: UIViewControllerTransitioningDelegate {
    
    @objc optional func animationController(forPush pushed: UIViewController, from: UIViewController, source: UINavigationController) -> UIViewControllerAnimatedTransitioning?

    @objc optional func animationController(forPop poped: UIViewController, from: UIViewController, source: UINavigationController) -> UIViewControllerAnimatedTransitioning?

    
    @objc optional func interactionControllerForPush(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?

    @objc optional func interactionControllerForPop(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    
}

/// view controller custom transitioning support
internal extension UIViewController {
    
    var prefersTabBarHidden: Bool {
        return false
    }
    var preferredTabBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    var prefersToolbarHidden: Bool {
        return true
    }
    var preferredToolbarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    var prefersNavigationBarHidden: Bool {
        return false
    }
    var preferredNavigationBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    
    // contains the navigation controller transitioning animation
    @objc internal weak var ub_transitioningDelegate: UINavigationControllerTransitioningDelegate? {
        set { return transitioningDelegate = __ub_delegate(newValue) }
        get { return transitioningDelegate as? UINavigationControllerTransitioningDelegate }
    }
    
    /// A Boolean value that indicates whether enabled controller warp protection.
    @objc internal var ub_warp: Bool {
        set { return objc_setAssociatedObject(self, UnsafePointer(bitPattern: #selector(getter: self.ub_warp).hashValue), __ub_warp(newValue), .OBJC_ASSOCIATION_ASSIGN) }
        get { return objc_getAssociatedObject(self, UnsafePointer(bitPattern: #selector(getter: self.ub_warp).hashValue)) as? Bool ?? false }
    }
}


/// Add wrap support
fileprivate extension UIViewController {
    /// Process presetn view controller event
    fileprivate dynamic func __ub_present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // check whether the enabled warp protection
        guard viewControllerToPresent.ub_warp else {
            return __ub_present(viewControllerToPresent, animated: animated, completion: completion)
        }
        
        // generate a navgation controller
        let navgationController = NavigationController(rootViewController: viewControllerToPresent)
        
        // show
        return __ub_present(navgationController, animated: animated, completion: completion)
    }
}

/// Add custom transtion support
fileprivate extension UINavigationController {
    
    fileprivate dynamic func __ub_pushViewController(_ viewController: UIViewController, animated: Bool) {
        // if view controller need custom transitioning animation
        guard let transitioningDelegate = viewController.ub_transitioningDelegate, animated else {
            // no need, ignore
            return __ub_pushViewController(viewController, animated: animated)
        }
        // perform custom transitioning animation
        return __ub_perform(transitioning: transitioningDelegate, operation: .push) {
            return __ub_pushViewController(viewController, animated: animated)
        }
    }
    fileprivate dynamic func __ub_popViewController(animated: Bool) -> UIViewController? {
        // if view controller need custom transitioning animation
        guard let transitioningDelegate = topViewController?.ub_transitioningDelegate else {
            // no need, ignore
            return __ub_popViewController(animated: animated)
        }
        // perform custom transitioning animation
        return __ub_perform(transitioning: transitioningDelegate, operation: .pop) {
            return __ub_popViewController(animated: animated)
        }
    }
    
    fileprivate func __ub_perform<T>(transitioning: UINavigationControllerTransitioningDelegate, operation: UINavigationControllerOperation, closure: (() -> T)) -> T {
        // generated a transitioning helper
        let helper = UINavigationControllerTransitioningHelper(transitioning: transitioning)
        // setup helper
        helper.delegate = delegate
        helper.operation = operation
        // switch environment
        delegate = helper
        defer { delegate = helper.delegate }
        // perform user code
        return closure()
    }
}


fileprivate class UINavigationControllerTransitioningHelper: NSObject, UINavigationControllerDelegate {
    
    init(transitioning: UINavigationControllerTransitioningDelegate ) {
        self.transitioning = transitioning
        super.init()
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // if operation is push, check transitioning wether implement delegate method
        if operation == .push && transitioning.responds(to: #selector(transitioning.animationController(forPush:from:source:))) {
            return transitioning.interactionControllerForPush?(using: animationController)
        }
        // if operation is pop, check transitioning wether implement delegate method
        if operation == .pop && transitioning.responds(to: #selector(transitioning.animationController(forPop:from:source:))) {
            return transitioning.interactionControllerForPop?(using: animationController)
        }
        // other case, perform origin method
        return delegate?.navigationController?(navigationController, interactionControllerFor: animationController)
    }

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // if operation is push, check transitioning wether implement delegate method
        if operation == .push && transitioning.responds(to: #selector(transitioning.animationController(forPush:from:source:))) {
            return transitioning.animationController?(forPush: toVC, from: fromVC, source: navigationController)
        }
        // if operation is pop, check transitioning wether implement delegate method
        if operation == .pop && transitioning.responds(to: #selector(transitioning.animationController(forPop:from:source:))) {
            return transitioning.animationController?(forPop: fromVC, from: toVC, source: navigationController)
        }
        // other case, perform origin method
        return delegate?.navigationController?(navigationController, animationControllerFor: operation, from: fromVC, to: toVC)
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        return delegate?.responds(to: aSelector) ?? super.responds(to: aSelector)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return delegate
    }
    
    var operation: UINavigationControllerOperation = .none
    weak var delegate: UINavigationControllerDelegate?
    unowned var transitioning: UINavigationControllerTransitioningDelegate
}

private var __ub_warp = ub_once(Bool.self) {
    
    let cls = UIViewController.self
    
    let m1 = class_getInstanceMethod(cls, #selector(cls.present(_:animated:completion:)))
    let m2 = class_getInstanceMethod(cls, #selector(cls.__ub_present(_:animated:completion:)))
    
    method_exchangeImplementations(m1, m2)
}

private var __ub_delegate = ub_once(UIViewControllerTransitioningDelegate?.self) {
    
    let cls = UINavigationController.self
    
    let m11 = class_getInstanceMethod(cls, #selector(cls.pushViewController(_:animated:)))
    let m21 = class_getInstanceMethod(cls, #selector(cls.popViewController(animated:)))
    
    let m12 = class_getInstanceMethod(cls, #selector(cls.__ub_pushViewController(_:animated:)))
    let m22 = class_getInstanceMethod(cls, #selector(cls.__ub_popViewController(animated:)))
    
    method_exchangeImplementations(m11, m12)
    method_exchangeImplementations(m21, m22)
}


