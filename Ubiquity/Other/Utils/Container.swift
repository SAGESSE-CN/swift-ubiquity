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
open class Container: NSObject {
    
    /// Create a media browser
    internal init(library: Library) {
        self.cacher = .init(library: library)
        self.library = library
        self.factorys = [:]
        super.init()
    }
    
    // MARK: Fetch
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    open var allowsCachingHighQualityImages: Bool {
        set { return library.allowsCachingHighQualityImages = newValue }
        get { return library.allowsCachingHighQualityImages }
    }
    
    /// Get collections with type
    open func request(forCollection type: CollectionType) -> CollectionList {
        return library.request(forCollection: type)
    }
    /// Requests an image representation for the specified asset.
    open func request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
        #if DEBUG
        guard !debug else {
            return nil
        }
        #endif
        return cacher.request(forImage: asset, size: size, mode: mode, options: options, resultHandler: resultHandler)
    }
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    open func request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request? {
        #if DEBUG
        guard !debug else {
            return nil
        }
        #endif
        return library.request(forItem: asset, options: options, resultHandler: resultHandler)
    }
    
    /// Cancels an asynchronous request
    open func cancel(with request: Request) {
        #if DEBUG
        guard !debug else {
            return
        }
        #endif
        return cacher.cancel(with: request)
    }
    
    // MARK: Cacher
    
    /// Prepares image representations of the specified assets for later use.
    open func startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        #if DEBUG
        guard !debug else {
            return
        }
        #endif
        return cacher.startCachingImages(for: assets, size: size, mode: mode, options: options)
    }
    /// Cancels image preparation for the specified assets and options.
    open func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        #if DEBUG
        guard !debug else {
            return
        }
        #endif
        return cacher.stopCachingImages(for: assets, size: size, mode: mode, options: options)
    }
    
    /// Cancels all image preparation that is currently in progress.
    open func stopCachingImagesForAllAssets() {
        #if DEBUG
        guard !debug else {
            return
        }
        #endif
        return cacher.stopCachingImagesForAllAssets()
    }
    
    // MARK: Content
    
    func register(_ cellClass: AnyClass?, in position: Position) {
    }
    
    func register(_ contentClass: AnyClass?, in posistion: Position, mediaType: AssetMediaType) {
    }
    
    
    func view(with page: Page, source: DataSource, sender: Any) -> UIView? {
        return nil
    }
    func viewController(wit page: Page, source: DataSource, sender: Any) -> UIViewController? {
        // if factory is nil, no provider
        guard let factory = factorys[page] else {
            return nil
        }
        
        // create controller for page
        let controller = factory.controller.init(container: self, factory: factory, source: source, sender: sender)
        
        // can't convert to `UIViewController`?
        return controller as? UIViewController
    }
    
    /// The current the library
    open var library: Library
    
    /// The current cache
    internal var cacher: Cacher
    internal var factorys: Dictionary<Page, Factory>
    
    #if DEBUG
    internal var debug: Bool = false
    #endif
}
