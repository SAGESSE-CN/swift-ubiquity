//
//  Library.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// A asset request object
public protocol Request {
}

/// A asset response object
public protocol Response {
    
    /// An error that occurred when Photos attempted to load the image.
    var ub_error: Error? { get }
    
    /// The result image is a low-quality substitute for the requested image.
    var ub_degraded: Bool { get }
    
    /// The image request was canceled.
    var ub_cancelled: Bool { get }
    
    /// The photo asset data is stored on the local device or must be downloaded from remote server
    var ub_downloading: Bool { get }
}

/// Options for fitting an image's aspect ratio to a requested size
public enum RequestContentMode: Int {
    
    /// Scales the image so that its larger dimension fits the target size.
    ///
    /// Use this option when you want the entire image to be visible, such as when presenting it in a view with the scaleAspectFit content mode.
    case aspectFit = 0

    /// Scales the image so that it completely fills the target size.
    ///
    /// Use this option when you want the image to completely fill an area, such as when presenting it in a view with the scaleAspectFill content mode.
    case aspectFill = 1
 
    /// Fits the image to the requested size using the default option, aspectFit.
    ///
    /// Use this content mode when requesting a full-sized image using the PHImageManagerMaximumSize value for the target size. In this case, the image manager does not scale or crop the image.
    static var `default`: RequestContentMode = .aspectFill
}

/// Options for delivering requested image data, used by the deliveryMode property.
public enum RequestDeliveryMode : Int {
    
    /// client may get several image results when the call is asynchronous or will get one result when the call is synchronous
    case opportunistic
    
    /// client will get one result only and it will be as asked or better than asked (sync requests are automatically processed this way regardless of the specified mode)
    case highQualityFormat 
    
    /// client will get one result only and it may be degraded
    case fastFormat 
}

/// A set of options affecting the delivery of still image representations of Photos assets you request from an image manager.
public class RequestOptions: NSObject {
    
    /// if necessary will download the image from reomte, Defaults to true
    public var isNetworkAccessAllowed: Bool = true
    
    // return only a single result, blocking until available (or failure). Defaults to false
    public var isSynchronous: Bool = false
    
    // delivery mode. Defaults to opportunistic
    public var deliveryMode: RequestDeliveryMode = .opportunistic
    
    /// provide caller a way to be told how much progress has been made prior to delivering the data when it comes from remote server.
    public var progressHandler: ((Double, Response) -> ())?
}

/// Provides methods for retrieving or generating preview thumbnails and full-size image or video data associated with Photos assets.
public protocol Library {
    
    // MARK: Authorization
    
    /// Requests the user’s permission, if needed, for accessing the library.
    func ub_requestAuthorization(_ handler: @escaping (Error?) -> Swift.Void)
    
    // MARK: Change
    
    /// Registers an object to receive messages when objects in the photo library change.
    func ub_addChangeObserver(_ observer: ChangeObserver)
    /// Unregisters an object so that it no longer receives change messages.
    func ub_removeChangeObserver(_ observer: ChangeObserver)
    
    // MARK: Check
    
    /// Check asset exists
    func ub_exists(forItem asset: Asset) -> Bool
    
    // MARK: Fetch
    
    /// Get collections with type
    func ub_request(forCollectionList type: CollectionType) -> CollectionList
    /// Requests an image representation for the specified asset.
    func ub_request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request?
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    func ub_request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request?
    
    /// Cancels an asynchronous request
    func ub_cancel(with request: Request)
    
    // MARK: Cacher
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    var ub_allowsCachingHighQualityImages: Bool { set get }
    
    /// Prepares image representations of the specified assets for later use.
    func ub_startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?)
    /// Cancels image preparation for the specified assets and options.
    func ub_stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?)
    
    /// Cancels all image preparation that is currently in progress.
    func ub_stopCachingImagesForAllAssets()
    
    // MARK: Configure

    /// Predefined size of the original request
    static var ub_requestMaximumSize: CGSize { get }
}


