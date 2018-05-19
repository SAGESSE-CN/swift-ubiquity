//
//  Container.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation


/// The base container
open class Container: NSObject, ChangeObserver {
    
    /// Create a media browser
    /// This init method is not public
    internal init(library: Library) {
        self.library = Caching.warp(library)
        super.init()
        
        // add change observer
        self.library.ub_addChangeObserver(self)
        
        logger.trace?.write()
    }
    deinit {
        logger.trace?.write()

        // remove change observer
        self.library.ub_removeChangeObserver(self)
    }
    
    // MARK: Observer

    /// Registers an object to receive messages when objects in the photo library change.
    internal func addChangeObserver(_ observer: ChangeObserver) {
        observers.insert(observer)
    }
    /// Unregisters an object so that it no longer receives change messages.
    internal func removeChangeObserver(_ observer: ChangeObserver) {
        observers.remove(observer)
    }
    
    // MARK: Library Change
    
    /// The library is ignoring change events
    open var isIgnoringChangeEvents: Bool {
        return _dispatch != nil
    }
    /// Tells the receiver to suspend the handling of library change events.
    open func beginIgnoringChangeEvents() {
        // ignoring is begin?
        guard !isIgnoringChangeEvents else {
            return
        }
        _semaphore = DispatchSemaphore(value: 0)
        _dispatch = DispatchQueue(label: "ubiquity-dispatch-wait")
        _dispatch?.async { [_semaphore] in
            _semaphore?.wait()
        }
    }
    /// Tells the receiver to resume the handling of library change events.
    open func endIgnoringChangeEvents() {
        // ignoring is begin?
        guard isIgnoringChangeEvents else {
            return
        }
        // clear
        _dispatch = nil
        _semaphore?.signal()
        _semaphore = nil
    }
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    open func library(_ library: Library, didChange change: Change) {
        // Ignoring is begin?
        guard _dispatch == nil else {
            _dispatch?.async {
                self.library(library, didChange: change)
            }
            return
        }
        
        // Make a new change
        let newChange = Caching.warp(change)
        
        // Update cache for library change
        (self.library as? ChangeObserver)?.library(self.library, didChange: newChange)
        
        // Notifity all observers
        self.observers.forEach {
            $0.library(self.library, didChange: newChange)
        }
    }
    
    // MARK: Content
    
    /// Create the view controller with controller type
    open func instantiateViewController(with type: ControllerType, source: Source, parameter: Any? = nil) -> UIViewController {
        logger.trace?.write(type)
        
        // create a controlelr
        guard let controller = factory(with: type).instantiateViewController(with: self, source: source, parameter: parameter) else {
            logger.fatal?.write("The controller creation failed. This is an unknown error!")
            fatalError("The controller creation failed. This is an unknown error!")
        }
        
        // the controller need warp protection
        controller.ub_warp = true
        controller.ub_transitioningDelegate = nil
        
        return controller
    }
    
    /// Register exception display page
    open func register(_ exceptionViewClass: ExceptionDisplayable.Type) {
        // must king of `UIView`
        guard exceptionViewClass is UIView.Type else {
            logger.fatal?.write("The exception view must king of `UIView`")
            fatalError("The exception view must king of `UIView`")
        }
        
        _exceptionViewClass = exceptionViewClass
    }
    
    open func factory(with page: ControllerType) -> Factory {
        // The factory hit cache?
        if let factory = _factorys[page] {
            return factory
        }
        
        // Create a new factory.
        let factory = Factory(identifier: "factorys.\(page)")
        _factorys[page] = factory
        return factory
    }
    
    /// Generate a exception display page
    internal func exceptionView(with error: Error, sender: AnyObject) -> ExceptionDisplayable {
        return _exceptionViewClass.init(container: self, error: error, sender: sender)
    }
    
    /// The current the library
    open var library: Library
    
    // cache
//    private(set) var cacher: Cacher
    private(set) var observers: WSet<ChangeObserver> = []
    

    // lock
    private var _dispatch: DispatchQueue?
    private var _semaphore: DispatchSemaphore?
    
    // class provder
    private lazy var _factorys: Dictionary<ControllerType, Factory> = [:]
    private lazy var _exceptionViewClass: ExceptionDisplayable.Type = ExceptionView.self
    
    private var _debug: Bool = false
}
