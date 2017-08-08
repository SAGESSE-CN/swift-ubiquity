//
//  Library.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// information about your app’s authorization to access the user’s library
public enum AuthorizationStatus : Int {
    
    /// User has not yet made a choice with regards to this application
    case notDetermined = 0
    /// This application is not authorized to access photo data.
    case restricted = 1
    /// User has explicitly denied this application access to photos data.
    case denied = 2
    /// User has authorized this application to access photos data.
    case authorized = 3
}

/// Provides methods for retrieving or generating preview thumbnails and full-size image or video data associated with Photos assets.
public protocol Library {
    
    // MARK: Authorization
    
    /// Returns information about your app’s authorization for accessing the library.
    func authorizationStatus() -> AuthorizationStatus
    /// Requests the user’s permission, if needed, for accessing the library.
    func requestAuthorization(_ handler: @escaping (AuthorizationStatus) -> Swift.Void)
    
    // MARK: Change
    
    /// Registers an object to receive messages when objects in the photo library change.
    func addChangeObserver(_ observer: ChangeObserver)
    /// Unregisters an object so that it no longer receives change messages.
    func removeChangeObserver(_ observer: ChangeObserver)
    
    // MARK: Check
    
    /// Check asset exists
    func exists(forItem asset: Asset) -> Bool
    
    // MARK: Fetch
    
    /// Get collections with type
    func request(forCollection type: CollectionType) -> CollectionList
    /// Requests an image representation for the specified asset.
    func request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request?
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    func request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request?
    
    /// Cancels an asynchronous request
    func cancel(with request: Request)
    
    // MARK: Cacher
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    var allowsCachingHighQualityImages: Bool { set get }
    
    /// Prepares image representations of the specified assets for later use.
    func startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?)
    /// Cancels image preparation for the specified assets and options.
    func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?)
    
    /// Cancels all image preparation that is currently in progress.
    func stopCachingImagesForAllAssets()
}

