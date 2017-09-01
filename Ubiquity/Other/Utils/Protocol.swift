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


protocol ControllerDisplayable: class {
    
    func controller(_ controller: ControllerDisplayable, container: Container, willAuthorization source: Source)
    func controller(_ controller: ControllerDisplayable, container: Container, didAuthorization source: Source, error: Error?)
    
    func controller(_ controller: ControllerDisplayable, container: Container, willDisplay source: Source)
    func controller(_ controller: ControllerDisplayable, container: Container, didDisplay source: Source, error: Error?)
}


internal class ControllerContainerView: UIView, UIGestureRecognizerDelegate {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        _setup()
    }
    
    // disable all other pan gesture recognizer
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func update(_ error: Error?, animated: Bool) {
        
        guard let error = error as? RequestError else {
            _info?.removeFromSuperview()
            _info = nil
            return
        }
        
        let info = _info ?? ErrorView(frame: bounds)
        
        info.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        switch error {
        case .notData:
            info.title = "No Photos or Videos"
            info.subtitle = "You can sync photos and videos onto your iPhone using iTunes."
            
        case .denied,
             .restricted:
            info.title = "No Access Permissions"
            info.subtitle = "" // 此应用程序没有权限访问您的照片\n在\"设置-隐私-图片\"中开启后即可查看
        }
        
        _info = info
        
        addSubview(info)
    }
    
    private func _setup() {
        
        // adds a pan gesture recognizer to intercept UIScrollView pan events
        let tap = UIPanGestureRecognizer()
        tap.delegate = self
        addGestureRecognizer(tap)
    }
    
    private var _info: ErrorView?
}

extension ControllerDisplayable where Self: UIViewController {
    
    /// Setup controller with source
    func setup(with container: Container, source: Source, loadData: @escaping (((Error?) -> Void) -> Void)) {
        logger.trace?.write()
        
        // prepare the UI for authorization
        controller(self, container: container, willAuthorization: source)
        
        // if request permission for library an error occurs, return the non nil.
        container.library.requestAuthorization { error in
            // authorization callback may not be in the main thread.
            DispatchQueue.main.async {
                // processing for authorization issues.
                self.controller(self, container: container, didAuthorization: source, error: error)
                
                // authorization is success?
                guard error == nil else {
                    return
                }
                
                // prepare the UI for load.
                self.controller(self, container: container, willDisplay: source)
                
                // if request data for library an error occurs, retunr the non nil
                loadData { error in
                    // processing for data load issues.
                    self.controller(self, container: container, didDisplay: source, error: error)
                }
            }
        }
    }
    
    
    func controller(_ controller: ControllerDisplayable, container: Container, willAuthorization source: Source) {
        logger.trace?.write()
        
        // when requesting permissions, need to add a mask layer
        let containerView = ControllerContainerView(frame: view.bounds)
        
        // in mask, it is empty view
        containerView.update(nil, animated: false)
        
        // install container view to self
        _containerView = containerView
    }
    
    func controller(_ controller: ControllerDisplayable, container: Container, didAuthorization source: Source, error: Error?) {
        logger.trace?.write(error?.localizedDescription ?? "")
        
        // when requesting permissions complete, need to add a error layer
        _containerView?.update(error, animated: true)
    }
    
    
    func controller(_ controller: ControllerDisplayable, container: Container, willDisplay source: Source) {
        logger.trace?.write()
        
        // nothing
    }
    
    func controller(_ controller: ControllerDisplayable, container: Container, didDisplay source: Source, error: Error?) {
        logger.trace?.write(error?.localizedDescription ?? "")
        
        if error == nil {
            // no error, show content view
            guard let containerView = _containerView else {
                // is hidden, ignore
                return
            }
            
            // add disappear animation
            UIView.animate(withDuration: 0.25, animations: {
                
                containerView.alpha = 0
                containerView.update(nil, animated: true)
                
            }, completion: { _ in
                
                // uninstall container view from self
                self._containerView = nil
            })
            
        } else {
            // has error, show error view
            if let containerView = _containerView {
                // is showed, ignore
                containerView.update(error, animated: true)
                return
            }
            
            // generate a tips container view
            let containerView = ControllerContainerView(frame: view.bounds)
            
            // configure
            containerView.alpha = 0
            containerView.update(error, animated: false)
            
            // install container view to self
            _containerView = containerView
            
            // add appear animation
            UIView.animate(withDuration: 0.25, animations: {
                
                containerView.alpha = 1
                
            }, completion: nil)
        }
    }
    
    
    /// Tips container view
    private var _containerView: ControllerContainerView? {
        set {
            // container view has any change?
            guard _containerView != newValue else {
                return
            }
            
            // uninstall container view
            if let containerView = _containerView {
                // remove from self.view
                // constraints should automatic remove
                containerView.removeFromSuperview()
            }
            
            // save container view for runtime
            objc_setAssociatedObject(self, &_UIViewController_containerView, newValue, .OBJC_ASSOCIATION_RETAIN)
            
            // install container view
            if let containerView = newValue  {
                // adjust the view to the top level, which prevents the display from being covered after addSubview
                containerView.layer.zPosition = 100_000_000
                containerView.layer.masksToBounds = true
                
                // the default color is white
                containerView.backgroundColor = .white
                containerView.translatesAutoresizingMaskIntoConstraints = false
                
                view.addSubview(containerView)
                
                // in scroll view, if you set the left and right constraints, it will get the wrong width
                view.addConstraint(.ub_make(containerView, .left, .equal, view, .left))
                view.addConstraint(.ub_make(containerView, .width, .equal, view, .width))
                view.addConstraint(.ub_make(containerView, .height, .equal, view, .height))
                
                guard view is UIScrollView else {
                    // in scroll view, container view must align to topLayoutGuide.bottom
                    // in other view, container view must align to view.top
                    return view.addConstraint(.ub_make(containerView, .top, .equal, view, .top))
                }
                
                // multiplier must be negative, because in scroll view, bounds.origin(0, 0) is bounds.origin(contentInset.left, contentInset.top)
                view.addConstraint(.ub_make(containerView, .top, .equal, topLayoutGuide, .bottom, multiplier: -1))
            }
        }
        get {
            // read container view for runtime
            return objc_getAssociatedObject(self, &_UIViewController_containerView) as? ControllerContainerView
        }
    }
}

private var _UIViewController_containerView: String = "_containerView"
