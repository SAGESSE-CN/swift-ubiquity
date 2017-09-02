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
        _setup()
        
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
            subtitle = "" // 此应用程序没有权限访问您的照片\n在\"设置-隐私-图片\"中开启后即可查看
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
    
    private func _setup() {
        
        let view = UIView()
        
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        
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
            .ub_make(view, .left, .equal, self, .left, 20),
            .ub_make(view, .right, .equal, self, .right, -20),
            .ub_make(view, .centerY, .equal, self, .centerY),
        ])
    }
    
    private lazy var _titleLabel = UILabel()
    private lazy var _subtitleLabel = UILabel()
}

/// Exception default display container view
internal class ExceptionContainerView: UIView, UIGestureRecognizerDelegate {
    
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
    
    private func _setup() {
        
        // adds a pan gesture recognizer to intercept UIScrollView pan events
        let tap = UIPanGestureRecognizer()
        tap.delegate = self
        addGestureRecognizer(tap)
    }
    
    // content view
    private var _contentView: ExceptionDisplayable?
}

/// Exception processing default implementation
internal protocol ExceptionDefaultImplementation: class {
    
    func controller(_ controller: UIViewController, container: Container, willAuthorization source: Source)
    func controller(_ controller: UIViewController, container: Container, didAuthorization source: Source, error: Error?)
    
    func controller(_ controller: UIViewController, container: Container, willDisplay source: Source)
    func controller(_ controller: UIViewController, container: Container, didDisplay source: Source, error: Error?)
}

/// Exception processing default implementation
internal extension ExceptionDefaultImplementation where Self: UIViewController {
    
    /// Setup controller with source
    func setup(with container: Container, source: Source, loadData: @escaping (((Error?) -> Void) -> Void)) {
        logger.trace?.write()
        
        // delay exec, order to prevent the view not initialized
        DispatchQueue.main.async {
            // prepare the UI for authorization
            self.controller(self, container: container, willAuthorization: source)
            
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
    }
    
    
    func controller(_ controller: UIViewController, container: Container, willAuthorization source: Source) {
        logger.trace?.write()
        
        // when requesting permissions, need to add a mask layer
        let containerView = ExceptionContainerView(frame: view.bounds)
        
        // in mask, it is empty view
        containerView.update(nil, container: container, sender: self, animated: false)
        
        // install container view to self
        _containerView = containerView
    }
    
    func controller(_ controller: UIViewController, container: Container, didAuthorization source: Source, error: Error?) {
        logger.trace?.write(error?.localizedDescription ?? "")
        
        // when requesting permissions complete, need to add a error layer
        _containerView?.update(error, container: container, sender: self, animated: true)
    }
    
    
    func controller(_ controller: UIViewController, container: Container, willDisplay source: Source) {
        logger.trace?.write()
        
        // nothing
    }
    
    func controller(_ controller: UIViewController, container: Container, didDisplay source: Source, error: Error?) {
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
                containerView.update(nil, container: container, sender: self, animated: true)
                
            }, completion: { _ in
                
                // uninstall container view from self
                self._containerView = nil
            })
            
        } else {
            // has error, show error view
            if let containerView = _containerView {
                // is showed, ignore
                containerView.update(error, container: container, sender: self, animated: true)
                return
            }
            
            // generate a tips container view
            let containerView = ExceptionContainerView(frame: view.bounds)
            
            // configure
            containerView.alpha = 0
            containerView.update(error, container: container, sender: self, animated: false)
            
            // install container view to self
            _containerView = containerView
            
            // add appear animation
            UIView.animate(withDuration: 0.25, animations: {
                
                containerView.alpha = 1
                
            }, completion: nil)
        }
    }
    
    
    /// Tips container view
    private var _containerView: ExceptionContainerView? {
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
                
                // the background color same from self.view
                containerView.backgroundColor = view.backgroundColor
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
                
                // multiplier must be negative, because in scroll view, bounds.origin(0, 0) is bounds.origin(contentInset.left, contentInset.top)
                view.addConstraint(.ub_make(containerView, .top, .equal, topLayoutGuide, .bottom, multiplier: -1))
            }
        }
        get {
            // read container view for runtime
            return objc_getAssociatedObject(self, &_UIViewController_containerView) as? ExceptionContainerView
        }
    }
}

private var _UIViewController_containerView: String = "_containerView"

