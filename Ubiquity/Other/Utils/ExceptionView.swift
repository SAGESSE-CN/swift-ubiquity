//
//  ExceptionView.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/24/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// Exception default display view
internal class ExceptionView: UIView, ExceptionDisplayable {
    
    /// Generate an exception display container
    ///
    /// - Parameters:
    ///   - container: The current use of the container
    ///   - error: The error message
    ///   - sender: Triggering errors of the sender
    required init(container: Container, error: Error, sender: AnyObject) {
        super.init(frame: .zero)
        
        // init UI
        _configure()
        
        guard let error = error as? Exception else {
            return
        }
        
        // update error info
        switch error {
        case .notData:
            title = "No Photos or Videos"
            subtitle = "You can sync photos and videos onto your iPhone using iTunes."
            
        case .denied,
             .restricted:
            title = "No Access Permissions"
            subtitle = "Application does not have permission to access your photo." // 此应用程序没有权限访问您的照片\n在\"设置-隐私-图片\"中开启后即可查看
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var title: String? {
        set { return _titleLabel.text = newValue }
        get { return _titleLabel.text }
    }
    
    var subtitle: String? {
        set { return _subtitleLabel.text = newValue }
        get { return _subtitleLabel.text }
    }
    
    private func _configure() {
        
        let view = UIView()
        
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        
        _titleLabel.font = UIFont.systemFont(ofSize: 28)
        _titleLabel.textColor = .lightGray
        _titleLabel.textAlignment = .center
        _titleLabel.numberOfLines = 0
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false
        _titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        _titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        
        _subtitleLabel.font = UIFont.systemFont(ofSize: 17)
        _subtitleLabel.textColor = .lightGray
        _subtitleLabel.textAlignment = .center
        _subtitleLabel.numberOfLines = 0
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // setup content view
        view.addSubview(_titleLabel)
        view.addSubview(_subtitleLabel)
        view.addConstraints([
            .ub_make(_titleLabel, .top, .equal, view, .top),
            .ub_make(_titleLabel, .width, .lessThanOrEqual, view, .width),
            .ub_make(_titleLabel, .centerX, .equal, view, .centerX),
            
            .ub_make(_subtitleLabel, .top, .equal, _titleLabel, .bottom, 16),
            
            .ub_make(_subtitleLabel, .left, .equal, view, .left),
            .ub_make(_subtitleLabel, .right, .equal, view, .right),
            .ub_make(_subtitleLabel, .bottom, .equal, view, .bottom),
        ])
        
        // setup subview
        addSubview(view)
        addConstraints([
            .ub_make(view, .left, .equal, self, .leftMargin),
            .ub_make(view, .right, .equal, self, .rightMargin),
            .ub_make(view, .centerY, .equal, self, .centerY),
        ])
        
        // setup accessibility
        isAccessibilityElement = true
        accessibilityIdentifier = "ExceptionView"
    }
    
    private lazy var _titleLabel = UILabel()
    private lazy var _subtitleLabel = UILabel()
}

/// Exception default display container view
internal class ExceptionContainerView: UIView, UIGestureRecognizerDelegate {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        _configure()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        _configure()
    }
    
    /// Marks the currently actived version
    /// if the version is different, the animation is invalid
    var version: Int = 0
    
    // disable all other pan gesture recognizer
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    // update error info
    func update(_ error: Error?, container: Container, sender: AnyObject, animated: Bool) {
        
        // remove the old error view
        if let contentView = _contentView as? UIView {
            // if there is no produce animation, the completion will be called directly
            UIView.animate(withDuration: 0.25, animations: {
                
                // add disappear animation if need
                if animated {
                    contentView.alpha = 0
                }
                
            }, completion: { finsihed in
                
                // remove from container view
                contentView.removeFromSuperview()
            })
        }
        
        // need display error ?
        guard let error = error else {
            return
        }
        
        // save the exception view
        _contentView = container.exceptionView(with: error, sender: sender)
        
        // add to container view
        if let contentView = _contentView as? UIView {
            
            addSubview(contentView)
            
            // setup layout
            contentView.frame = bounds
            contentView.alpha = 1
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // only need animation changed to 0 to 1
            if animated {
                contentView.alpha = 0
            }
            
            UIView.animate(withDuration: 0.25, animations: {
                
                // must be displayed
                contentView.alpha = 1
                
            }, completion: nil)
        }
    }
    
    private func _configure() {
        
        // adds a pan gesture recognizer to intercept UIScrollView pan events
        let tap = UIPanGestureRecognizer()
        tap.delegate = self
        addGestureRecognizer(tap)
        backgroundColor = .clear
    }
    
    // content view
    private var _contentView: ExceptionDisplayable?
}

/// Exception handling implementation
internal protocol ExceptionHandling: class {
    
    /// Call before request authorization
    func controller(_ container: Container, willAuthorization source: Source)
    /// Call after completion of request authorization
    func controller(_ container: Container, didAuthorization source: Source, error: Error?)
    
    /// Call before request load
    func controller(_ container: Container, willLoad source: Source)
    /// Call after completion of load
    func controller(_ container: Container, didLoad source: Source, error: Error?)
    
}

/// Exception handling implementation
internal extension ExceptionHandling where Self: UIViewController {
    
    /// Initialize controller with container and source
    func ub_initialize(with container: Container, source: Source) {
        logger.trace?.write()
        
        // prepare the UI for authorization
        self.controller(container, willAuthorization: source)
        self.ub_execptionContainerView = {
            // when requesting permissions, need to add a mask layer
            let containerView = ExceptionContainerView(frame: view.bounds)
            
            // in mask, it is empty view
            containerView.update(nil, container: container, sender: self, animated: false)
            
            // link to screen
            return containerView
        }()
        
        // sent data authorization request
        container.library.ub_requestAuthorization { error in
            // callback may not be in the main thread.
            DispatchQueue.main.async {
                // processing for authorization issues.
                self.ub_execptionContainerView?.update(error, container: container, sender: self, animated: true)
                self.controller(container, didAuthorization: source, error: error)
                
                // authorization is success?
                guard error == nil else {
                    return
                }
                
                // if request data for library an error occurs, retunr the non nil
                self.controller(container, willLoad: source)
                self.ub_execptionContainerView?.update(nil, container: container, sender: self, animated: true)
                
                // sent data loading request
                source.loadData(with: container) { error in
                    // callback may not be in the main thread.
                    DispatchQueue.main.async {
                        // processing for load issue.
                        self.ub_execption(with: container, source: source, error: error, animated: true)
                        self.controller(container, didLoad: source, error: error)
                    }
                }
            }
        }
    }
    
    /// Displays or hides an exception
    func ub_execption(with container: Container, source: Source, error: Error?, animated: Bool) {
        logger.trace?.write()
        
        if error == nil {
            // no error, show content view
            guard let containerView = ub_execptionContainerView else {
                // is hidden, ignore
                return
            }
            
            let version = containerView.version + 1
            
            // add disappear animation
            UIView.animate(withDuration: 0.25, animations: {
                
                containerView.alpha = 0
                containerView.version = version
                containerView.update(nil, container: container, sender: self, animated: true)
                
            }, completion: { _ in
                
                // the version has been changed
                // the operation is ignored
                guard version == containerView.version else {
                    return
                }
                
                // uninstall container view from self
                self.ub_execptionContainerView = nil
            })
            
        } else {
            // has error, show error view
            if let containerView = ub_execptionContainerView {
                // is showed, ignore
                containerView.alpha = 1
                containerView.version += 1
                containerView.update(error, container: container, sender: self, animated: true)
                return
            }
            
            // generate a tips container view
            let containerView = ExceptionContainerView(frame: view.bounds)
            
            // configure
            containerView.alpha = 0
            containerView.update(error, container: container, sender: self, animated: false)
            
            // install container view to self
            self.ub_execptionContainerView = containerView
            
            // add appear animation
            UIView.animate(withDuration: 0.25, animations: {
                
                containerView.alpha = 1

            }, completion: nil)
        }
    }
    
    /// Tips container view
    private var ub_execptionContainerView: ExceptionContainerView? {
        set {
            // container view has any change?
            guard ub_execptionContainerView != newValue else {
                return
            }
            
            // uninstall container view
            if let containerView = ub_execptionContainerView {
                // remove from self.view
                // constraints should automatic remove
                containerView.removeFromSuperview()
            }
            
            // save container view for runtime
            objc_setAssociatedObject(self, &_UIViewController_execptionContainerView, newValue, .OBJC_ASSOCIATION_RETAIN)
            
            // install container view
            if let containerView = newValue  {
                // adjust the view to the top level, which prevents the display from being covered after addSubview
                containerView.layer.zPosition = 100_000_000
                containerView.layer.masksToBounds = true
                
                // the background color same from self.view
                containerView.backgroundColor = .clear
                containerView.translatesAutoresizingMaskIntoConstraints = false
                
                // as to prevent affect other views, the need to insert to the second position
                view.insertSubview(containerView, at: min(1, view.subviews.count))
                
                // in scroll view, if you set the left and right constraints, it will get the wrong width
                view.addConstraint(.ub_make(containerView, .left, .equal, view, .left))
                view.addConstraint(.ub_make(containerView, .width, .equal, view, .width))
                view.addConstraint(.ub_make(containerView, .height, .equal, view, .height))
                
                guard view is UIScrollView else {
                    // in scroll view, container view must align to topLayoutGuide.bottom
                    // in other view, container view must align to view.top
                    return view.addConstraint(.ub_make(containerView, .top, .equal, view, .top))
                }
                
                if #available(iOS 11.0, *) {
                    // in iOS 11+, `topLayoutGuide` is deprecated
                    view.addConstraint(.ub_make(containerView, .top, .equal, topLayoutGuide, .top, multiplier: 1))
                } else {
                    // multiplier must be negative, because in scroll view, bounds.origin(0, 0) is bounds.origin(contentInset.left, contentInset.top)
                    view.addConstraint(.ub_make(containerView, .top, .equal, topLayoutGuide, .bottom, multiplier: -1))
                }
            }
        }
        get {
            // read container view for runtime
            return objc_getAssociatedObject(self, &_UIViewController_execptionContainerView) as? ExceptionContainerView
        }
    }
}

private var _UIViewController_execptionContainerView: String = "execptionContainerView"

