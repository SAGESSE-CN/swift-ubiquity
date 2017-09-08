//
//  Container.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


/// The base container
@objc open class Container: NSObject, ChangeObserver {
    
    /// Create a media browser
    /// This init method is not public
    internal init(library: Library) {
        self.cacher = .init(library: library)
        self.library = library
        super.init()
        
        // add change observer
        self.library.ub_addChangeObserver(self)
    }
    deinit {
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
    
    // MARK: Fetch
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    open var allowsCachingHighQualityImages: Bool {
        set { return library.ub_allowsCachingHighQualityImages = newValue }
        get { return library.ub_allowsCachingHighQualityImages }
    }
    
    /// Returns collections with collectoin type
    open func request(forCollectionList type: CollectionType) -> CollectionList {
        return cacher.request(forCollectionList: type)
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
        return library.ub_request(forItem: asset, options: options, resultHandler: resultHandler)
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
        self.cacher.library(library, didChange: change)
        
        // notifity all observers
        self.observers.forEach {
            $0.library(library, didChange: change)
        }
    }
    
    // MARK: Pre-configuration
    
    
    
    // MARK: Content
    
    /// Create the view controller with controller type
    open func instantiateViewController(with type: ControllerType, source: UHSource, sender: Any? = nil) -> UIViewController {
        logger.trace?.write(type)
        
        // create a controlelr
        guard let controller = factory(with: type).controller.init(container: self, source: source, sender: sender) as? UIViewController else {
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
    
    // Register a content view class for media in controller
    open func register(_ contentViewClass: Displayable.Type, forContentView media: AssetType, in type: ControllerType) {
        // must king of `UIView`
        guard let contentViewClass = contentViewClass as? UIView.Type else {
            logger.fatal?.write("The exception view must king of `UIView`")
            fatalError("The content must king of `UIView`")
        }
        
        // register content view in factory
        factory(with: type).register(contentViewClass, for: media)
    }
    
    /// Register a controller class for controller type
    open func register(_ controllerClass: UIViewController.Type, forController type: ControllerType) {
        // must king of `Controller`
        guard let controller = controllerClass as? Controller.Type else {
            logger.fatal?.write("The content must king of `UIViewController`")
            fatalError("The content must king of `UIViewController`")
        }
        
        // register controller in factory
        factory(with: type).controller = controller
    }
    
    // Register a cell class for controller type
    open func register(_ cellClass: Displayable.Type, forCell type: ControllerType) {
        // must king of `UIView`
        guard let cellClass = cellClass as? UIView.Type else {
            logger.fatal?.write("The cellClass must king of `UITableViewCell` or `UICollectionViewCell`")
            fatalError("The cellClass must king of `UITableViewCell` or `UICollectionViewCell`")
        }
        
        // register cell in factory
        factory(with: type).cell = cellClass
    }
    
    
    func factory(with page: ControllerType) -> Factory {
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
    
    /// Generate a exception display page
    internal func exceptionView(with error: Error, sender: AnyObject) -> ExceptionDisplayable {
        return _exceptionViewClass.init(container: self, error: error, sender: sender)
    }
    
    /// The current the library
    open var library: Library
    
    // cache
    private(set) var cacher: Cacher
    private(set) var observers: WSet<ChangeObserver> = []
    
    // lock
    private var _dispatch: DispatchQueue?
    private var _semaphore: DispatchSemaphore?
    
    // class provder
    private lazy var _factorys: Dictionary<ControllerType, Factory> = [:]
    private lazy var _exceptionViewClass: ExceptionDisplayable.Type = ExceptionView.self
    
    private var _debug: Bool = false
}
