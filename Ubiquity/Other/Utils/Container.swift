//
//  Container.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// The base container
open class Container: NSObject, Library {
    
    /// Create a media browser
    public init(library: Library) {
        self.cache = .init(library: library)
        self.library = library
        super.init()
    }
    
    /// the current the library
    open var library: Library
    
    // MARK: Authorization
    
    /// Returns information about your app’s authorization for accessing the library.
    open func authorizationStatus() -> AuthorizationStatus {
        logger.trace?.write()
        
        return library.authorizationStatus()
    }
    /// Requests the user’s permission, if needed, for accessing the library.
    open func requestAuthorization(_ handler: @escaping (AuthorizationStatus) -> Swift.Void) {
        logger.trace?.write()
        
        return library.requestAuthorization(handler)
    }
    
    // MARK: Change
    
    /// Registers an object to receive messages when objects in the photo library change.
    open func register(_ observer: ChangeObserver) {
        logger.trace?.write(observer)
        
        return library.register(observer)
    }
    /// Unregisters an object so that it no longer receives change messages.
    open func unregisterObserver(_ observer: ChangeObserver) {
        logger.trace?.write(observer)
        
        return library.unregisterObserver(observer)
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
        return cache.request(forImage: asset, size: size, mode: mode, options: options, resultHandler: resultHandler)
    }
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    open func request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request? {
        return library.request(forItem: asset, options: options, resultHandler: resultHandler)
    }
    
    /// Cancels an asynchronous request
    open func cancel(with request: Request) {
        return cache.cancel(with: request)
    }
    
    // MARK: Cache
    
    /// Prepares image representations of the specified assets for later use.
    open func startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        return cache.startCachingImages(for: assets, size: size, mode: mode, options: options)
    }
    /// Cancels image preparation for the specified assets and options.
    open func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        return cache.stopCachingImages(for: assets, size: size, mode: mode, options: options)
    }
    
    /// Cancels all image preparation that is currently in progress.
    open func stopCachingImagesForAllAssets() {
        return cache.stopCachingImagesForAllAssets()
    }
    
    /// the current cache
    internal var cache: Cache
}
