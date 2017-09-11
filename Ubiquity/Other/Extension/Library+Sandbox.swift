//
//  Library+Sandbox.swift
//  Ubiquity
//
//  Created by sagesse on 29/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

// MARK: - define Locally strong.

open class UHLocalAsset: NSObject {
    
    /// Generate a local asset
    public init(identifier: String) {
        self.identifier = identifier
        super.init()
    }
    
    /// The localized title of the asset.
    open var title: String?
    /// The localized subtitle of the asset.
    open var subtitle: String?
    /// A unique string that persistently identifies the object.
    open let identifier: String
    
    /// The version of the asset, identifying asset change.
    open var version: Int = 0
    
    /// The width, in pixels, of the asset’s image or video data.
    open var pixelWidth: Int = 0
    /// The height, in pixels, of the asset’s image or video data.
    open var pixelHeight: Int = 0
    
    /// The duration, in seconds, of the video asset.
    /// For photo assets, the duration is always zero.
    open var duration: TimeInterval = 0
    
    /// The asset allows play operation
    open var allowsPlay: Bool = false
    
    /// The type of the asset, such as video or audio.
    open var type: AssetType = .unknown
    /// The subtypes of the asset, identifying special kinds of assets such as panoramic photo or high-framerate video.
    open var subtype: AssetSubtype = []
}
open class UHLocalAssetCollection: NSObject {
    
    /// Generate a local asset collection
    public init(identifier: String) {
        self.identifier = identifier
        super.init()
    }
    
    /// The localized title of the collection.
    open var title: String?
    /// The localized subtitle of the collection.
    open var subtitle: String?
    /// A unique string that persistently identifies the object.
    open let identifier: String
    
    /// The type of the asset collection, such as an album or a moment.
    open var collectionType: CollectionType = .regular
    /// The subtype of the asset collection.
    open var collectionSubtype: CollectionSubtype = .smartAlbumGeneric
    
    /// The number of assets in the asset collection.
    open var count: Int {
        return 0
    }
    /// The number of assets in the asset collection.
    open func count(with type: AssetType) -> Int {
        return 0
    }
    
    /// Retrieves assets from the specified asset collection.
    open func asset(at index: Int) -> UHLocalAsset {
        fatalError()
    }
    
    /// Compare the change
    open func changeDetails(for change: UHLocalAssetChange) -> ChangeDetails? {
        return nil
    }
}
open class UHLocalAssetCollectionList: NSObject {
    
    /// Generate a local asset collection list
    public init(collectionType: CollectionType) {
        self.identifier = UUID().uuidString
        self.collectionType = collectionType
        super.init()
    }
    /// Generate a local asset collection list
    public init(identifier: String, collectionType: CollectionType) {
        self.identifier = identifier
        self.collectionType = collectionType
        super.init()
    }
    
    /// A unique string that persistently identifies the object.
    open let identifier: String
    
    /// The type of the asset collection, such as an album or a moment.
    open var collectionType: CollectionType
    
    /// The number of collection in the collection list.
    open var count: Int {
        return 0
    }
    /// Retrieves collection from the specified collection list.
    open func collection(at index: Int) -> UHLocalAssetCollection {
        fatalError()
    }
    
    /// Compare the change
    open func changeDetails(for change: UHLocalAssetChange) -> ChangeDetails? {
        return nil
    }
}

open class UHLocalAssetChange: NSObject {
}
open class UHLocalAssetRequest: NSObject {
}
open class UHLocalAssetResponse: NSObject {
    
    /// An error that occurred when Photos attempted to load the image.
    open var error: Error?
    
    /// The result image is a low-quality substitute for the requested image.
    open var isDegraded: Bool = false
    /// The image request was canceled.
    open var isCancelled: Bool = false
    /// The photo asset data is stored on the local device or must be downloaded from remote servicer
    open var isDownloading: Bool = false
}

open class UHLocalAssetLibrary: NSObject {
    
    /// Check asset exists
    open func exists(forItem asset: UHLocalAsset) -> Bool {
        return true
    }
    
    /// Get collections with type
    open func request(forCollection type: CollectionType) -> UHLocalAssetCollectionList {
        fatalError()
    }
    
    /// Requests an image representation for the specified asset.
    open func request(forImage asset: UHLocalAsset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, UHLocalAssetResponse) -> ()) -> UHLocalAssetRequest? {
        fatalError()
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    open func request(forItem asset: UHLocalAsset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, UHLocalAssetResponse) -> ()) -> UHLocalAssetRequest? {
        fatalError()
    }
    
    /// Cancels an asynchronous request
    func cancel(with request: UHLocalAssetRequest) {
        fatalError()
    }
    
    /// A Boolean value that determines whether the image manager prepares high-quality images.
    open var allowsCachingHighQualityImages: Bool = false
    
    /// All change observers
    open var observers: WSet<ChangeObserver> = []
    
    /// Allows maximum one-time loading image bytes
    open static var maximumLoadBytes: Int = 100 * 1024 * 1024 // 100MiB
}


// MARK: - bridging Locally to Ubiquity.


extension UHLocalAsset: Asset {
    
    /// The localized title of the asset.
    public var ub_title: String? {
        return title
    }
    /// The localized subtitle of the asset.
    public var ub_subtitle: String? {
        return subtitle
    }
    /// A unique string that persistently identifies the object.
    public var ub_identifier: String {
        return identifier
    }
    /// The version of the asset, identifying asset change.
    public var ub_version: Int {
        return version
    }
    
    /// The width, in pixels, of the asset’s image or video data.
    public var ub_pixelWidth: Int {
        return pixelWidth
    }
    
    /// The height, in pixels, of the asset’s image or video data.
    public var ub_pixelHeight: Int {
        return pixelHeight
    }
    
    /// The duration, in seconds, of the video asset.
    /// For photo assets, the duration is always zero.
    public var ub_duration: TimeInterval {
        return duration
    }
    
    /// The asset allows play operation
    public var ub_allowsPlay: Bool {
        return type == .video
    }
    
    /// The type of the asset, such as video or audio.
    public var ub_type: AssetType {
        return type
    }
    /// The subtypes of the asset, an option of type `AssetSubtype`
    public var ub_subtype: UInt {
        return subtype.rawValue
    }
}
extension UHLocalAssetCollection: Collection {
    
    /// The localized title of the collection.
    public var ub_title: String? {
        return title
    }
    /// The localized subtitle of the collection.
    public var ub_subtitle: String? {
        return subtitle
    }
    
    /// A unique string that persistently identifies the object.
    public var ub_identifier: String {
        return identifier
    }
    
    /// The type of the asset collection, such as an album or a moment.
    public var ub_collectionType: CollectionType {
        return .regular
    }
    
    /// The subtype of the asset collection.
    public var ub_collectionSubtype: CollectionSubtype {
        return .smartAlbumGeneric
    }
    
    /// The number of assets in the asset collection.
    public var ub_count: Int {
        return count
    }
    /// The number of assets in the asset collection.
    public func ub_count(with type: AssetType) -> Int {
        return count(with: type)
    }
    /// Retrieves assets from the specified asset collection.
    public func ub_asset(at index: Int) -> Asset {
        return asset(at: index)
    }
}
extension UHLocalAssetCollectionList: CollectionList {
    
    /// A unique string that persistently identifies the object.
    public var ub_identifier: String {
        return identifier
    }
    
    /// The type of the asset collection, such as an album or a moment.
    public var ub_collectionType: CollectionType {
        return collectionType
    }
    
    /// The number of collection in the collection list.
    public var ub_count: Int {
        return count
    }
    
    /// Retrieves collection from the specified collection list.
    public func ub_collection(at index: Int) -> Collection {
        return collection(at: index)
    }
}

extension UHLocalAssetChange: Change {

    /// Returns detailed change information for the specified collection.
    public func ub_changeDetails(forCollection collection: Collection) -> ChangeDetails? {
        // must king of `UHLocalAssetCollection`
        guard let collection = collection as? UHLocalAssetCollection else {
            return nil
        }
        return collection.changeDetails(for: self)
    }
    
    /// Returns detailed change information for the specified colleciotn list.
    public func ub_changeDetails(forCollectionList collectionList: CollectionList) -> ChangeDetails? {
        // must king of `UHLocalAssetCollectionList`
        guard let collectionList = collectionList as? UHLocalAssetCollectionList else {
            return nil
        }
        return collectionList.changeDetails(for: self)
    }
}
extension UHLocalAssetRequest: Request {
}
extension UHLocalAssetResponse: Response {
    
    /// An error that occurred when Photos attempted to load the image.
    public var ub_error: Error? {
        return error
    }
    
    /// The result image is a low-quality substitute for the requested image.
    public var ub_degraded: Bool {
        return isDegraded
    }
    
    /// The image request was canceled.
    public var ub_cancelled: Bool {
        return isCancelled
    }
    /// The photo asset data is stored on the local device or must be downloaded from remote servicer
    public var ub_downloading: Bool {
        return isDownloading
    }
}

extension UHLocalAssetLibrary: Library {

    /// Requests the user’s permission, if needed, for accessing the library.
    public func ub_requestAuthorization(_ handler: @escaping (Error?) -> Void) {
        handler(nil)
    }
    
    /// Registers an object to receive messages when objects in the photo library change.
    public func ub_addChangeObserver(_ observer: ChangeObserver) {
        observers.insert(observer)
    }
    
    /// Unregisters an object so that it no longer receives change messages.
    public func ub_removeChangeObserver(_ observer: ChangeObserver) {
        observers.remove(observer)
    }
    
    /// Check asset exists
    public func ub_exists(forItem asset: Asset) -> Bool {
        // asset must king of UHAsset
        guard let asset = asset as? UHLocalAsset else {
            return false
        }
        return exists(forItem: asset)
    }
    
    /// Get collections with type
    public func ub_request(forCollectionList type: CollectionType) -> CollectionList {
        return request(forCollection: type)
    }
    
    /// Requests an image representation for the specified asset.
    public func ub_request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
        // asset must king of UHAsset
        guard let asset = asset as? UHLocalAsset else {
            return nil
        }
        return request(forImage: asset, size: size, mode: mode, options: options, resultHandler: resultHandler)
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    public func ub_request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request? {
        // asset must king of UHAsset
        guard let asset = asset as? UHLocalAsset else {
            return nil
        }
        return request(forItem: asset, options: options, resultHandler: resultHandler)
    }
    
    /// Cancels an asynchronous request
    public func ub_cancel(with request: Request) {
        // request must king of UHLocalAssetRequest
        guard let request = request as? UHLocalAssetRequest else {
            return
        }
        return cancel(with: request)
    }
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    public var ub_allowsCachingHighQualityImages: Bool {
        set { return allowsCachingHighQualityImages = newValue }
        get { return allowsCachingHighQualityImages }
    }
    
    /// Prepares image representations of the specified assets for later use.
    public func ub_startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // WARNING: Unrealized, late optimVization
    }
    
    /// Cancels image preparation for the specified assets and options.
    public func ub_stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // WARNING: Unrealized, late optimVization
    }
    
    /// Cancels all image preparation that is currently in progress.
    public func ub_stopCachingImagesForAllAssets() {
        // WARNING: Unrealized, late optimVization
    }
    
    /// Predefined size of the original request
    public static var ub_requestMaximumSize: CGSize {
        return .init(width: -1, height: -1)
    }
}

