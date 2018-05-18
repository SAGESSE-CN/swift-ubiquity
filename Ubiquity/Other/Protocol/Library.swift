//
//  Library.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation

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

/// Options for fitting an image's aspect ratio to a requested size.
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
    
    public static var image: RequestOptions {
        let options = RequestOptions()
        return options
    }
    
    public static var video: RequestOptions {
        let options = RequestOptions()
        return options
    }
    
    /// If necessary will download the image from reomte, Defaults to true
    public var isNetworkAccessAllowed: Bool = true
    
    /// Return only a single result, blocking until available (or failure). Defaults to false
    public var isSynchronous: Bool = false
    
    /// Delivery mode. Defaults to opportunistic
    public var deliveryMode: RequestDeliveryMode = .opportunistic
    
    /// Provide caller a way to be told how much progress has been made prior to delivering the data when it comes from remote server.
    public var progressHandler: ((Double, Response) -> ())?
    
    /// The User additional external data.
    public var userInfo: [String: Any]?
}

/// Provides methods for retrieving or generating preview thumbnails and full-size image or video data associated with Photos assets.
public protocol Library: class {
    
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
    
    ///
    /// Cancels an asynchronous request.
    ///
    /// When you perform an asynchronous request for image data using the [ub_request(forImage:targetSize:contentMode:options:resultHandler:)](file://) method, or for a video object using one of the methods listed in [Request](file://) object, the image manager returns a numeric identifier for the request. To cancel the request before it completes, provide this identifier when calling the [ub_cancel(with:)](file://) method.
    ///
    /// - Parameters:
    ///   - request: The asset asynchronous request.
    ///
    func ub_cancel(with request: Request)
    
    ///
    /// Requests an collection list for the specified type.
    ///
    /// - Parameter type: the specified collection list type.
    /// - Returns: The collection list for the specifed type.
    ///
    func ub_request(forCollectionList type: CollectionType) -> CollectionList

    ///
    /// Requests an image representation for the specified asset.
    ///
    /// When you call this method, Photos loads or generates an image of the asset at, or near, the size you specify. Next, it calls your resultHandler block to provide the requested image. To serve your request more quickly, Photos may provide an image that is slightly larger than the target size—either because such an image is already cached or because it can be generated more efficiently. Depending on the options you specify and the current state of the asset, Photos may download asset data from the network.
    ///
    /// By default, this method executes asynchronously. If you call it from a background thread you may change the [isSynchronous](file://) property of the options parameter to true to block the calling thread until either the requested image is ready or an error occurs, at which time Photos calls your result handler.
    ///
    /// For an asynchronous request, Photos may call your result handler block more than once. Photos first calls the block to provide a low-quality image suitable for displaying temporarily while it prepares a high-quality image. (If low-quality image data is immediately available, the first call may occur before the method returns.) When the high-quality image is ready, Photos calls your result handler again to provide it. If the image manager has already cached the requested image at full quality, Photos calls your result handler only once.
    ///
    /// - Parameters:
    ///   - asset: The asset whose image data is to be loaded.
    ///   - targetSize: The target size of image to be returned.
    ///   - contentMode: An option for how to fit the image to the aspect ratio of the requested size. For details, see [RequestContentMode](file://).
    ///   - options: Options specifying how Photos should handle the request, format the requested image, and notify your app of progress or errors. For details, see [RequestOptions](file://).
    ///   - resultHandler: A block to be called when image loading is complete, providing the requested image or information about the status of the request.
    ///
    ///     The block takes the following parameters:
    ///   - result: The requested image.
    ///   - response: A response object providing information about the status of the request. For details, see [Response](file://).
    /// - Returns:
    ///   A numeric identifier for the request. If you need to cancel the request before it completes, pass this request to the [ub_cancel(with:)](file://) method.
    ///
    func ub_request(forImage asset: Asset, targetSize: CGSize, contentMode: RequestContentMode, options: RequestOptions, resultHandler: @escaping (_ result: UIImage?, _ response: Response) -> ()) -> Request?

    ///
    /// Requests full-sized image data for the specified asset.
    ///
    /// When you call this method, Photos loads the largest available representation of the image asset, then calls your resultHandler block to provide the requested data. Depending on the options you specify and the current state of the asset, Photos may download asset data from the network.
    ///
    /// By default, this method executes asynchronously. If you call it from a background thread you may change the [isSynchronous](file://) property of the options parameter to true to block the calling thread until either the requested image is ready or an error occurs, at which time Photos calls your result handler.
    ///
    /// If the version option is set to current, Photos provides rendered image data, including the results of any edits that have been made to the asset content. Otherwise, Photos provides the originally captured image data for the asset.
    ///
    /// - Parameters:
    ///   - asset: The asset for which to load image data.
    ///   - options: Options specifying how Photos should handle the request, format the requested image, and notify your app of progress or errors. For details, see [RequestOptions](file://).
    ///   - resultHandler: A block to be called when image loading is complete, providing the requested image or information about the status of the request.
    ///
    ///   The block takes the following parameters:
    ///   - imageData: The requested image.
    ///   - response: A response object providing information about the status of the request. For details, see [Response](file://).
    /// - Returns:
    ///   A numeric identifier for the request. If you need to cancel the request before it completes, pass this request to the [ub_cancel(with:)](file://) method.
    ///
    func ub_request(forData asset: Asset, options: RequestOptions, resultHandler: @escaping (_ imageData: Data?, _ response: Response) -> ()) -> Request?
    
    ///
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    ///
    /// When you call this method, Photos downloads the video data (if necessary) and creates a player item.
    /// It then calls your resultHandler block to provide the requested video.
    ///
    /// - Parameters:
    ///   - asset: The video asset to be played back.
    ///   - options: Options specifying how Photos should handle the request and notify your app of progress or errors. For details, see [RequestOptions](file://).
    ///   - resultHandler: A block Photos calls after loading the asset’s data and preparing the player item.
    ///
    ///     The block takes the following parameters:
    ///   - playerItem: An [AVPlayerItem](file://) object that you can use for playing back the video asset.
    ///   - response: A response object providing information about the status of the request. For details, see [Response](file://).
    /// - Returns:
    ///   A numeric identifier for the request. If you need to cancel the request before it completes, pass this request to the [ub_cancel(with:)](file://) method.
    ///
    func ub_request(forVideo asset: Asset, options: RequestOptions, resultHandler: @escaping (_ playerItem: AVPlayerItem?, _ response: Response) -> ()) -> Request?
    
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
    var ub_requestMaximumSize: CGSize { get }
}


