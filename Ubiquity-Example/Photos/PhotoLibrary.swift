//
//  PhotoLibrary.swift
//  Ubiquity-Example
//
//  Created by SAGESSE on 5/23/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import Photos
import Ubiquity

internal class PhotoLibrary: NSObject, Ubiquity.Library {
    
    override init() {
        _library = PHPhotoLibrary.shared()
        _manager = PHCachingImageManager.default() as! PHCachingImageManager
        super.init()
    }
    
    
    
    // MARK: Authorization
    
    
    /// Returns information about your app’s authorization for accessing the library.
    func authorizationStatus() -> Ubiquity.AuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus().authorizationStatus
    }
    
    /// Requests the user’s permission, if needed, for accessing the library.
    func requestAuthorization(_ handler: @escaping (Ubiquity.AuthorizationStatus) -> Swift.Void) {
        // convert authorization status
        PHPhotoLibrary.requestAuthorization {
            handler($0.authorizationStatus)
        }
    }
    
    
    // MARK: Change
    
    
    /// Registers an object to receive messages when objects in the photo library change.
    func register(_ observer: Ubiquity.ChangeObserver) {
        
        // the observer is added?
        guard !_observers.contains(where: { $0.observer === observer }) else {
            return
        }
        // no, add a observer
        _observers.append(.init(observer: observer))
        
        // if count is 1, need to listen for system notifications
        guard _observers.count == 1 else {
            return
        }
        // no, add to system
        _library.register(self)
    }
    
    /// Unregisters an object so that it no longer receives change messages.
    func unregisterObserver(_ observer: Ubiquity.ChangeObserver) {
        
        // clear all invaild observers
        _observers = _observers.filter {
            return $0.observer != nil
                && $0.observer !== observer
        }
        
        // if count is 0, need remove
        guard _observers.count == 0 else {
            return
        }
        // no, cancel listen
        _library.unregisterChangeObserver(self)
    }
    
    
    // MARK: Fetch
    
    
    /// Get collections with type
    func request(forCollection type: Ubiquity.CollectionType) -> Array<Ubiquity.Collection> {
        return _fetchCollections()
    }
    
    /// Requests an image representation for the specified asset.
    func request(forImage asset: Ubiquity.Asset, size: CGSize, mode: Ubiquity.RequestContentMode, options: Ubiquity.RequestOptions?, resultHandler: @escaping (UIImage?, Ubiquity.Response) -> ()) -> Ubiquity.Request? {
        // must with Asset
        guard let asset = asset as? Asset else {
            return nil
        }
        
        let newMode = PHImageContentMode(mode: mode)
        let newOptions = PHImageRequestOptions(options: options)
        
        // send image request
        return _manager.requestImage(for: asset.asset, targetSize: size, contentMode: newMode, options: newOptions) { image, info in
            // convert result info to response
            let response = Response(info: info)
            
            // if the image is empty and the image is degraded, it need download
            if response.degraded && image == nil {
                response.downloading = true
            }
            
            // callback
            resultHandler(image, response)
        }
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    func request(forItem asset: Ubiquity.Asset, options: Ubiquity.RequestOptions?, resultHandler: @escaping (AnyObject?, Ubiquity.Response) -> ()) -> Ubiquity.Request? {
        // must with Asset
        guard let asset = asset as? Asset else {
            return nil
        }
        
        let newOptions = PHVideoRequestOptions(options: options)
        
        // send player item request
        return _manager.requestPlayerItem(forVideo: asset.asset, options: newOptions) { item, info in
            // convert result info to response
            let response = Response(info: info)
            // callback
            resultHandler(item, response)
        }
    }
    
    /// Cancels an asynchronous request
    func cancel(with request: Ubiquity.Request) {
        // must is PHImageRequestID
        guard let request = request as? PHImageRequestID else {
            return
        }
        _manager.cancelImageRequest(request)
    }
    
    
    // MARK: Cache
    
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    var allowsCachingHighQualityImages: Bool {
        set { return _manager.allowsCachingHighQualityImages = newValue }
        get { return _manager.allowsCachingHighQualityImages }
    }
    
    
    /// Prepares image representations of the specified assets for later use.
    func startCachingImages(for assets: Array<Ubiquity.Asset>, size: CGSize, mode: Ubiquity.RequestContentMode, options: Ubiquity.RequestOptions?) {
        // must with Asset
        guard let assets = assets as? [Asset] else {
            return
        }
        let newMode = PHImageContentMode(mode: mode)
        let newOptions = PHImageRequestOptions(options: options)
        
        // forward
        _manager.startCachingImages(for: assets.map { $0.asset }, targetSize: size, contentMode: newMode, options: newOptions)
    }
    
    /// Cancels image preparation for the specified assets and options.
    func stopCachingImages(for assets: Array<Ubiquity.Asset>, size: CGSize, mode: Ubiquity.RequestContentMode, options: Ubiquity.RequestOptions?) {
        // must with Asset
        guard let assets = assets as? [Asset] else {
            return
        }
        let newMode = PHImageContentMode(mode: mode)
        let newOptions = PHImageRequestOptions(options: options)
        
        // forward
        _manager.stopCachingImages(for: assets.map { $0.asset }, targetSize: size, contentMode: newMode, options: newOptions)
    }
    
    /// Cancels all image preparation that is currently in progress.
    func stopCachingImagesForAllAssets() {
        // forward
        _manager.stopCachingImagesForAllAssets()
    }
    
    
    private func _fetchCollections() -> Array<Ubiquity.Collection> {
        
        var types = [(PHAssetCollectionType, PHAssetCollectionSubtype, Bool)]()

        // smart album -> user
        types.append((.smartAlbum, .smartAlbumUserLibrary, true))
        types.append((.smartAlbum, .smartAlbumFavorites, false))
        types.append((.smartAlbum, .smartAlbumGeneric, false))
            
        // smart album -> recently
        //types.append((.smartAlbum, .smartAlbumRecentlyAdded, false))
            
        // smart album -> video
        types.append((.smartAlbum, .smartAlbumPanoramas, false))
        types.append((.smartAlbum, .smartAlbumVideos, false))
        types.append((.smartAlbum, .smartAlbumSlomoVideos, false))
        types.append((.smartAlbum, .smartAlbumTimelapses, false))
        
        // smart album -> screenshots
        if #available(iOS 9.0, *) { 
            types.append((.smartAlbum, .smartAlbumScreenshots, false))
            //types.append((.smartAlbum, .smartAlbumSelfPortraits))
        }
        
        // album -> share
        types.append((.album, .albumMyPhotoStream, false))
        types.append((.album, .albumCloudShared, false))
        
        // album -> user
        types.append((.album, .albumRegular, true))
        types.append((.album, .albumSyncedAlbum, false))
        types.append((.album, .albumImported, false))
        types.append((.album, .albumSyncedFaces, false))
        
        return types.reduce([]) {
            $0 + _fetchCollections(with: $1.0, subtype: $1.1, canEmpty: $1.2)
        }
    }
    private func _fetchCollections(with type: PHAssetCollectionType, subtype: PHAssetCollectionSubtype, options: PHFetchOptions? = nil, canEmpty: Bool = true) -> Array<Collection> {
        var albums: [Collection] = []
        PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: nil).enumerateObjects({
            //let album = SAPAlbum(collection: $0.0)
            guard canEmpty || $0.0.canContainAssets else {
                return
            }
            albums.append(Collection(collection:$0.0))
        })
        return albums
    }
    
    fileprivate var _manager: PHCachingImageManager
    fileprivate var _library: PHPhotoLibrary
    
    fileprivate var _observers: Array<ChangeObserver> = []
}

internal extension PhotoLibrary {
    
    class ChangeObserver {
        init(observer: Ubiquity.ChangeObserver) {
            self.observer = observer
        }
        weak var observer: Ubiquity.ChangeObserver?
    }
    
    class Response: Ubiquity.Response {
        
        init(info: [AnyHashable: Any]?) {
            error = info?[PHImageErrorKey] as? NSError
            degraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            cancelled = info?[PHImageCancelledKey] as? Bool ?? false
            downloading = info?[PHImageResultIsInCloudKey] as? Bool ?? false
        }
        
        /// An error that occurred when Photos attempted to load the image.
        var error: Error?
        
        /// The result image is a low-quality substitute for the requested image.
        var degraded: Bool
        /// The image request was canceled. 
        var cancelled: Bool
        /// The photo asset data is stored on the local device or must be downloaded from remote servicer
        var downloading: Bool
    }
    
    class Asset: Ubiquity.Asset {
        
        init(asset: PHAsset) {
            self.asset = asset
        }
        
        let asset: PHAsset
        
        var identifier: String {
            if let localIdentifier = _localIdentifier {
                return localIdentifier
            }
            let localIdentifier = asset.localIdentifier
            _localIdentifier = localIdentifier
            return localIdentifier
        }
        
        var pixelWidth: Int {
            return asset.pixelWidth
        }
        var pixelHeight: Int {
            return asset.pixelHeight
        }
        
        var allowsPlay: Bool {
            return asset.mediaType == .video
        }
        var duration: TimeInterval {
            return asset.duration
        }
        
        var mediaType: Ubiquity.AssetMediaType {
            return Ubiquity.AssetMediaType(rawValue: asset.mediaType.rawValue) ?? .unknown
        }
        var mediaSubtypes: Ubiquity.AssetMediaSubtype {
            return Ubiquity.AssetMediaSubtype(rawValue: asset.mediaSubtypes.rawValue)
        }
        
        private var _localIdentifier: String?
    }
    class Collection: Ubiquity.Collection {
        
        init(collection: PHAssetCollection) {
            _collection = collection
        }
        
        public var identifier: String {
            return _collection.localIdentifier
        }
        public var title: String? {
            return _collection.localizedTitle
        }
        
        public var collectionType: Ubiquity.CollectionType {
            return .regular
        }
        public var collectionSubtype: Ubiquity.CollectionSubtype {
            return Ubiquity.CollectionSubtype(rawValue: _collection.assetCollectionSubtype.rawValue) ?? .smartAlbumGeneric
        }
        
        public var assetCount: Int {
            return _result.count
        }
        public func asset(at index: Int) -> Ubiquity.Asset? {
            
            if let asset = _assets?[index] {
                return asset
            }
            let asset = Asset(asset: _result.object(at: index))
            _assets?[index] = asset
            return asset
        }
        
        private var __result: PHFetchResult<PHAsset>?
        private var _result: PHFetchResult<PHAsset> {
            if let result = __result {
                return result
            }
            let result = PHAsset.fetchAssets(in: _collection, options: nil)
            __result = result
            _assets = Array(repeating: nil, count: result.count)
            return result
        }
        
        private var _assets: [Asset?]?
        private var _collection: PHAssetCollection
    }
}

extension PHAuthorizationStatus {
    
    var authorizationStatus: Ubiquity.AuthorizationStatus {
        switch self {
        case .authorized: return .authorized
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        }
    }
}

extension PHImageRequestID: Ubiquity.Request {
}

extension PHImageContentMode {
    
    init(mode: Ubiquity.RequestContentMode) {
        switch mode {
        case .aspectFill: self = .aspectFill
        case .aspectFit: self = .aspectFit
        }
    }
    
}
extension PHImageRequestOptions {
    
    convenience init?(options: Ubiquity.RequestOptions?) {
        // if the option is nil, create a failure
        guard let options = options else {
            return nil
        }
        self.init()
        self.isNetworkAccessAllowed = options.isNetworkAccessAllowed
        guard let progressHandler = options.progressHandler else {
            return
        }
        self.progressHandler = { progress, _, _, info in
            // convert result info to response
            let response = PhotoLibrary.Response(info: info)
            // callback
            progressHandler(progress, response)
        }
    }
}
extension PHVideoRequestOptions {
    
    convenience init?(options: Ubiquity.RequestOptions?) {
        // if the option is nil, create a failure
        guard let options = options else {
            return nil
        }
        self.init()
        self.isNetworkAccessAllowed = options.isNetworkAccessAllowed
        guard let progressHandler = options.progressHandler else {
            return
        }
        self.progressHandler = { progress, _, _, info in
            // convert result info to response
            let response = PhotoLibrary.Response(info: info)
            // callback
            progressHandler(progress, response)
        }
    }
}
extension PHChange: Ubiquity.Change {
}

extension PhotoLibrary: PHPhotoLibraryChangeObserver {

    // This callback is invoked on an arbitrary serial queue. If you need this to be handled on a specific queue, you should redispatch appropriately
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        _observers.forEach {
            $0.observer?.library(self, didChange: changeInstance)
        }
    }
}
