//
//  Container.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

public enum Position {
    case thumbnail
    case detail
}

/// The base container
open class Container: NSObject, ChangeObserver {
    
    /// Create a media browser
    internal init(library: Library) {
        self.cacher = .init(library: library)
        self.library = library
        super.init()
    }
    
    // MARK: Observer
    
    /// Registers an object to receive messages when objects in the photo library change.
    func addChangeObserver(_ observer: ChangeObserver) {
        // this observer is added?
        guard !observers.contains(where: { $0.some === observer }) else {
            return
        }
        
        // add to observers
        observers.append(.init(observer))
        
        // if count is 1, need add to library
        guard observers.count == 1 else {
            return
        }
        library.addChangeObserver(self)
    }
    /// Unregisters an object so that it no longer receives change messages.
    func removeChangeObserver(_ observer: ChangeObserver) {
        // clear all invaild observers
        observers = observers.filter {
            return $0.some != nil && $0.some !== observer
        }
        
        // if count is 0, need remove from library
        guard observers.count == 0 else {
            return
        }
        library.removeChangeObserver(self)
    }
    
    // MARK: Fetch
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    open var allowsCachingHighQualityImages: Bool {
        set { return library.allowsCachingHighQualityImages = newValue }
        get { return library.allowsCachingHighQualityImages }
    }
    
    /// Returns collections with collectoin type
    open func request(forCollection type: CollectionType) -> CollectionList {
        return cacher.request(forCollection: type)
    }
    /// Requests an image representation for the specified asset.
    open func request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
        #if DEBUG
        guard !_debug else {
            return nil
        }
        #endif
        return cacher.request(forImage: asset, size: size, mode: mode, options: options, resultHandler: resultHandler)
    }
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    open func request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request? {
        #if DEBUG
        guard !_debug else {
            return nil
        }
        #endif
        return library.request(forItem: asset, options: options, resultHandler: resultHandler)
    }
    
    /// Cancels an asynchronous request
    open func cancel(with request: Request) {
        #if DEBUG
        guard !_debug else {
            return
        }
        #endif
        return cacher.cancel(with: request)
    }
    
    // MARK: Cacher
    
    /// Prepares image representations of the specified assets for later use.
    open func startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        #if DEBUG
        guard !_debug else {
            return
        }
        #endif
        return cacher.startCachingImages(for: assets, size: size, mode: mode, options: options)
    }
    /// Cancels image preparation for the specified assets and options.
    open func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        #if DEBUG
        guard !_debug else {
            return
        }
        #endif
        return cacher.stopCachingImages(for: assets, size: size, mode: mode, options: options)
    }
    
    /// Cancels all image preparation that is currently in progress.
    open func stopCachingImagesForAllAssets() {
        #if DEBUG
        guard !_debug else {
            return
        }
        #endif
        return cacher.stopCachingImagesForAllAssets()
    }
    
    // MARK: Library Change
    
    /// Tells the receiver to suspend the handling of library change events.
    open func beginIgnoringChangeEvents() {
        // ignoring is begin?
        guard _dispatch == nil else {
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
        guard _dispatch != nil else {
            return
        }
        // clear
        _semaphore?.signal()
        _semaphore = nil
        _dispatch = nil
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
        self.cacher.library(library, didChange: change)
        
        // notifity all observers
        self.observers.forEach {
            $0.some?.library(library, didChange: change)
        }
    }
    
    // MARK: Pre-configuration
    
    
    /// Container allowed to displayed collection types. Default is nil
    open var allowsCollectionTypes: [CollectionType]?
    
    
    // MARK: Content
    
    
    /// Generate the initialized controller
    open func initialViewController(with type: ControllerType) -> UIViewController {
        // Try generate a controlelr
        guard let controller = controller(with: type, source: .init(collectionType: .regular), sender: self) else {
            logger.fatal?.write("The controller creation failed. This is an unknown error!")
            fatalError("The controller creation failed. This is an unknown error!")
        }
        
        // the controller need warp protection
        controller.ub_warp = true
        controller.ub_transitioningDelegate = nil
        
        
        return controller
    }
    
    
    /// Register a controller class for controller type
    open func register(_ controllerClass: AnyClass, for type: ControllerType) {
        logger.debug?.write()
        
    }
    
    // Register a content view class for media in controller
    open func register(_ contentViewClass: AnyClass, for media: AssetMediaType, type: ControllerType) {
        logger.debug?.write()
    }
    
    
    
    func factory(with page: ControllerType) -> Factory? {
        // hit cache?
        if let factory = _factorys[page] {
            return factory
        }
        
        // create factory
        switch page {
        case .albums:
            let factory = FactoryAlbums()
            _factorys[page] = factory
            return factory
            
        case .albumsList:
            let factory = FactoryAlbumsList()
            _factorys[page] = factory
            return factory
            
        case .detail:
            let factory = FactoryDetail()
            _factorys[page] = factory
            return factory
        }
    }
    
    /// Generate a controller for factory
    internal func controller(with type: ControllerType, source: Source, sender: Any) -> UIViewController? {
        // if factory is nil, no provider
        guard let factory = factory(with: type) else {
            return nil
        }
        
        // create controller for page
        return factory.controller.init(container: self, factory: factory, source: source, sender: sender) as? UIViewController
    }
    
    /// The current the library
    open var library: Library
    
    // cache
    private(set) var cacher: Cacher
    private(set) var observers: Array<Weak<ChangeObserver>> = []
    
    // lock
    private var _dispatch: DispatchQueue?
    private var _semaphore: DispatchSemaphore?
    
    // class provder
    private lazy var _factorys: Dictionary<ControllerType, Factory> = [:]
    
    private var _debug: Bool = false
}
