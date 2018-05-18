//
//  Container.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation


/// A protocol you can implement to be notified of changes that occur in the Photos library.
public protocol ContainerObserver: class {
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func container(_ container: Container, didChange change: Change)
}


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
    
//    // MARK: Observer
//
//    /// Registers an object to receive messages when objects in the photo library change.
//    internal func addChangeObserver(_ observer: ContainerObserver) {
//        observers.insert(observer)
//    }
//    /// Unregisters an object so that it no longer receives change messages.
//    internal func removeChangeObserver(_ observer: ContainerObserver) {
//        observers.remove(observer)
//    }
//
//    // MARK: Fetch
//
//    ///A Boolean value that determines whether the image manager prepares high-quality images.
//    open var allowsCachingHighQualityImages: Bool {
//        set { return library.ub_allowsCachingHighQualityImages = newValue }
//        get { return library.ub_allowsCachingHighQualityImages }
//    }
//
//    /// Returns collections with collectoin type
//    open func request(forCollectionList type: CollectionType) -> CollectionList {
//        fatalError()
////        return cacher.request(forCollectionList: type)
//    }
//    /// Requests an image representation for the specified asset.
//    open func request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
//        #if DEBUG
//        guard !_debug else {
//            return nil
//        }
//        #endif
//        fatalError()
////        return cacher.request(forImage: asset, targetSize: size, contentMode: mode, options: options, resultHandler: resultHandler)
//    }
//
//    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
//    open func request(forVideo asset: Asset, options: RequestOptions, resultHandler: @escaping (AVPlayerItem?, Response) -> ()) -> Request? {
//        #if DEBUG
//        guard !_debug else {
//            return nil
//        }
//        #endif
//        fatalError()
////        return library.ub_request?(forVideo: asset, options: options, resultHandler: resultHandler)
//    }
//
//    /// Cancels an asynchronous request
//    open func cancel(with request: Request) {
//        #if DEBUG
//        guard !_debug else {
//            return
//        }
//        #endif
//        fatalError()
////        return cacher.cancel(with: request)
//    }
//
//    // MARK: Cacher
//
//    /// Prepares image representations of the specified assets for later use.
//    open func startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
//        #if DEBUG
//        guard !_debug else {
//            return
//        }
//        #endif
//        fatalError()
////        return cacher.startCachingImages(for: assets, size: size, mode: mode, options: options)
//    }
//    /// Cancels image preparation for the specified assets and options.
//    open func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
//        #if DEBUG
//        guard !_debug else {
//            return
//        }
//        #endif
//        fatalError()
////        return cacher.stopCachingImages(for: assets, size: size, mode: mode, options: options)
//    }
//
//    /// Cancels all image preparation that is currently in progress.
//    open func stopCachingImagesForAllAssets() {
//        #if DEBUG
//        guard !_debug else {
//            return
//        }
//        #endif
//        fatalError()
////        return cacher.stopCachingImagesForAllAssets()
//    }
    
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
        // ignoring is begin?
        guard _dispatch == nil else {
            _dispatch?.async {
                self.library(library, didChange: change)
            }
            return
        }
        
        // update cache for library change
//        self.cacher.ub_library(library, didChange: change)
        
        // notifity all observers
        self.observers.forEach {
            $0.container(self, didChange: change)
        }
    }
    
    // MARK: Pre-configuration
    
    
    
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
    private(set) var observers: WSet<ContainerObserver> = []
    

    // lock
    private var _dispatch: DispatchQueue?
    private var _semaphore: DispatchSemaphore?
    
    // class provder
    private lazy var _factorys: Dictionary<ControllerType, Factory> = [:]
    private lazy var _exceptionViewClass: ExceptionDisplayable.Type = ExceptionView.self
    
    private var _debug: Bool = false
}
