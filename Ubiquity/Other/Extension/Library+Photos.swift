//
//  Library+Photos.swift
//  Ubiquity
//
//  Created by SAGESSE on 8/6/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import Photos

/// bridge Photos

extension PHAsset: Asset {
    
    /// The localized title of the asset.
    public var ub_title: String? {
        // the asset has modification date or creation date?
        guard let date = creationDate ?? modificationDate else {
            return nil
        }
        // generate title for date
        return ub_string(for: date)
    }
    /// The localized subtitle of the asset.
    public var ub_subtitle: String? {
        // the asset has modification date or creation date?
        guard let date = creationDate ?? modificationDate else {
            return nil
        }
        // generate title for time
        return ub_string(for: date.timeIntervalSince1970)
    }
    /// A unique string that persistently identifies the object.
    public var ub_identifier: String {
        return localIdentifier
    }
    /// The version of the asset, identifying asset change.
    public var ub_version: Int {
        return Int(modificationDate?.timeIntervalSince1970 ?? 0 * 1000)
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
        return mediaType == .video
    }
    
    /// The type of the asset, such as video or audio.
    public var ub_type: AssetType {
        switch mediaType {
        case .audio: return .audio
        case .image: return .image
        case .video: return .video
        case .unknown: return .unknown
        }
    }
    /// The subtypes of the asset, an option of type `AssetSubtype`
    public var ub_subtype: UInt {
        var subtype: AssetSubtype = []
        
        // is photo
        if mediaType == .image {
            // is HDR photo.
            if mediaSubtypes.contains(.photoHDR) {
                subtype.insert(.photoHDR)
            }
            // is panorama photo.
            if mediaSubtypes.contains(.photoPanorama) {
                subtype.insert(.photoPanorama)
            }
            // is screenshot.
            if #available(iOS 9.0, *) {
                if mediaSubtypes.contains(.photoScreenshot) {
                    subtype.insert(.photoScreenshot)
                }
            }
            // is gif photo.
            if filename?.hasSuffix("GIF") ?? false {
                subtype.insert(.photoGIF)
            }
        }
        
        // is vidoe
        if mediaType == .video {
            // is hight frame rate video.
            if mediaSubtypes.contains(.videoHighFrameRate) {
                subtype.insert(.videoHighFrameRate)
            }
            // is timelapse video.
            if mediaSubtypes.contains(.videoTimelapse) {
                subtype.insert(.videoTimelapse)
            }
            // is streamed video.
            if mediaSubtypes.contains(.videoStreamed) {
                subtype.insert(.videoStreamed)
            }
        }
        
        return subtype.rawValue
    }
    
    /// The asset filename
    @NSManaged internal var filename: String?
}

extension PHAssetCollection: Collection {
    
    /// The localized title of the collection.
    public var ub_title: String? {
        // if have title, display it
        if let title = localizedTitle {
            return title
        }
        
        // if have date, display it
        guard let date = startDate else {
            return nil
        }
        
        // generate title for date
        return ub_string(for: date)
    }
    /// The localized subtitle of the collection.
    public var ub_subtitle: String? {
        // if not have title, only display the date
        if localizedTitle == nil {
            return nil
        }
        
        // the subtitle need cat
        var subtitle = ""
        
        // if have date, display it
        if let date = startDate {
            subtitle = ub_string(for: date)
        }
        
        // get current location
        let names = localizedLocationNames
        if let name = names.first {
            subtitle += " · " + name
        }
        
        return subtitle
    }
    
    /// A unique string that persistently identifies the object.
    public var ub_identifier: String {
       return localIdentifier
    }
    
    /// The type of the asset collection, such as an album or a moment.
    public var ub_collectionType: CollectionType {
        return .regular
    }
    
    /// The subtype of the asset collection.
    public var ub_collectionSubtype: CollectionSubtype {
        return CollectionSubtype(rawValue: assetCollectionSubtype.rawValue) ?? .smartAlbumGeneric
    }
    
    /// The number of assets in the asset collection.
    public var ub_count: Int {
        return ub_fetchResultLoaded.count
    }
    /// The number of assets in the asset collection.
    public func ub_count(with type: AssetType) -> Int {
        return ub_fetchResultLoaded.countOfAssets(with: PHAssetMediaType(rawValue: type.rawValue) ?? .unknown)
    }
    /// Retrieves assets from the specified asset collection.
    public func ub_asset(at index: Int) -> Asset {
        return ub_fetchResultLoaded.object(at: index)
    }
    
    /// The associated fetch result
    internal var ub_fetchResult: PHFetchResult<PHAsset>? {
        set { return objc_setAssociatedObject(self, UnsafeRawPointer(bitPattern: #selector(getter: self.ub_fetchResult).hashValue), newValue, .OBJC_ASSOCIATION_RETAIN) }
        get { return objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: #selector(getter: self.ub_fetchResult).hashValue)) as? PHFetchResult<PHAsset> }
    }
    internal var ub_fetchResultLoaded: PHFetchResult<PHAsset> {
        // hit cache
        if let fetchResult = ub_fetchResult {
            return fetchResult
        }
        // the fetch result will strong references collection, it can't use self directly
        // copying a new collection can avoid this problem
        // but it should be noted that if the replication fails, a blank fetch result is displayed
        let result = (ub_deepCopy() as? PHAssetCollection).flatMap { PHAsset.fetchAssets(in: $0, options: nil) } ?? PHAsset.fetchAssets(withLocalIdentifiers: [], options: nil)
        self.ub_fetchResult = result
        return result
    }
}

extension PHChange: Change {

    /// Returns detailed change information for the specified collection.
    public func ub_changeDetails(forCollection collection: Collection) -> ChangeDetails? {
        // collection must king of `PHAssetCollection`
        guard let collection = collection as? PHAssetCollection else {
            return nil
        }
        
        // if the result is not loaded, no any changes
        guard let result = collection.ub_fetchResult else {
            return nil
        }
        
        // Check for changes to the list of assets (insertions, deletions, moves, or updates).
        let assets = changeDetails(for: result)
        
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        let contents = changeDetails(for: collection)
        
        // `assets` is nil the collection count no any change
        // `contents` is nil the collection property no any chnage
        guard assets != nil || contents?.objectBeforeChanges !== contents?.objectAfterChanges else {
            return nil
        }
        
        // merge collection and result
        // must be create a new collection, otherwise the cache cannot be updated in time
        let newResult = assets?.fetchResultAfterChanges ?? result
        let newCollection = (contents?.objectAfterChanges ?? collection).ub_deepCopy() as? PHAssetCollection ?? collection
        
        // if colleciton is change, save new result
        if newCollection !== collection {
            newCollection.ub_fetchResult = newResult
        }
        
        // generate new chagne details for collection
        let newDetails = ChangeDetails(before: collection, after: newCollection)
        
        // if after is nil, the collection is deleted
        if let contents = contents, contents.objectAfterChanges == nil {
            newDetails.after = nil
        }
        
        // update option info
        newDetails.hasAssetChanges = assets != nil
        newDetails.hasIncrementalChanges = assets?.hasIncrementalChanges ?? false
        newDetails.hasMoves = assets?.hasMoves ?? false
        
        // update change indexes info
        newDetails.removedIndexes = assets?.removedIndexes
        newDetails.insertedIndexes = assets?.insertedIndexes
        assets?.enumerateMoves { from, to in
            // must create
            if newDetails.movedIndexes == nil {
                newDetails.movedIndexes = []
            }
            newDetails.movedIndexes?.append((from, to))
        }
        
        // filter preloading
        newDetails.changedIndexes = assets?.changedObjects.reduce(IndexSet()) {
            // fetch asset index
            let index = result.index(of: $1)
            guard index != NSNotFound else {
                return $0
            }
            let rhs = $1
            let lhs = result.object(at: index)
            // has any change?
            guard lhs.localIdentifier != rhs.localIdentifier || lhs.modificationDate != rhs.modificationDate else {
                return $0
            }
            
            // merge
            return $0.union(.init(integer: index))
        }
        
        // if all is empty, ignore the event
        let allIsEmpty = ![newDetails.removedIndexes?.isEmpty, newDetails.insertedIndexes?.isEmpty, newDetails.changedIndexes?.isEmpty, newDetails.movedIndexes?.isEmpty].contains { !($0 ?? true) }
        if allIsEmpty && contents == nil && collection.ub_count == newCollection.ub_count {
            return nil
        }
        
        return newDetails
    }
    
    /// Returns detailed change information for the specified colleciotn list.
    public func ub_changeDetails(forCollectionList collectionList: CollectionList) -> ChangeDetails? {
        // collection must king of `_PHCollectionList`
        guard let collectionList = collectionList as? _PHCollectionList else {
            return nil
        }
        
        // generate new collection list.
        let newCollectionList = _PHCollectionList(type: collectionList.ub_collectionType)
        
        // compare difference
        var diffs = ub_diff(collectionList.collections, dest: newCollectionList.collections)
        
        // check collection the change
        (0 ..< newCollectionList.ub_count).forEach {
            // find the elements of change
            guard let index = collectionList.collections.index(of: newCollectionList.collections[$0]) else {
                return
            }
            
            // if collection is has any change
            guard let details = ub_changeDetails(forCollection: collectionList.collections[index]) else {
                // no change, reset collection
                newCollectionList.collections[$0] = collectionList.collections[index]
                return
            }
            
            // has any change, apply change
            diffs.append(.update(from: index, to: $0))
            
            // merge collection
            guard let collection = details.after as? PHAssetCollection else {
                return
            }
            newCollectionList.collections[$0] = collection
        }
        
        logger.debug?.write("\(self) \(diffs)")
        
        // has any chagne?
        guard !diffs.isEmpty else {
            return nil
        }
        
        // generate new chagne details for collection list
        let details = ChangeDetails(before: collectionList, after: newCollectionList)
        
        // update change details
        details.removedIndexes = IndexSet()
        details.insertedIndexes = IndexSet()
        details.changedIndexes = IndexSet()
        details.movedIndexes = []
        
        // always requires incremental change
        details.hasMoves = true
        details.hasAssetChanges = true
        details.hasIncrementalChanges = true
        
        // process
        diffs.forEach { diff in
            switch diff {
            case .move(let from, let to):
                // in move case, must has to arg
                details.movedIndexes?.append((from, to))
                
            case .insert(_, let to):
                // in insert case, from is -1
                details.insertedIndexes?.update(with: to)
                
            case .update(let from, _):
                // in update case, to may can not find
                details.changedIndexes?.update(with: from)
                
            case .remove(let from, _):
                // in remove case, to is -1
                details.removedIndexes?.update(with: from)
            }
        }
        
        return details
    }
}


private class _PHCollectionList: NSObject, CollectionList {
    
    init(type: CollectionType) {
        self.collectionType = type
        self.collections = _PHCollectionList._collections(with: type)
        super.init()
    }
    
    /// The type of the asset collection, such as an album or a moment.
    var ub_collectionType: CollectionType {
        return collectionType
    }
    
    /// The number of collection in the collection list.
    var ub_count: Int {
        return collections.count
    }
    
    /// Retrieves collection from the specified collection list.
    func ub_collection(at index: Int) -> Collection {
        return collections[index]
    }
    
    private static func _collections(with collectionType: PHAssetCollectionType, _ collectionSubtype: PHAssetCollectionSubtype, _ omittingEmptySubsequences: Bool) -> Array<PHAssetCollection> {
        // fetch collection with type
        let result = PHAssetCollection.fetchAssetCollections(with: collectionType, subtype: collectionSubtype, options: nil)
        
        // convert to `_PHCollection`
        return (0 ..< result.count).flatMap { index in
            return result.object(at: index)
        }
    }
    private static func _collections(with collectionType: CollectionType) -> Array<PHAssetCollection> {
        // process moment
        if collectionType == .moment {
            // fetch collection with type
            let result = PHAssetCollection.fetchMoments(with: nil)
            
            // merge to result
            return (0 ..< result.count).flatMap { index in
                return result.object(at: index)
            }
        }
        
        // process recently added
        if collectionType == .recentlyAdded {
            // smart album -> recently
            return _collections(with: .smartAlbum, .smartAlbumRecentlyAdded, true)
        }
        
        // the new collections
        var collections: Array<PHAssetCollection> = []
        
        // smart album -> user
        collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumUserLibrary, true))
        collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumFavorites, false))
        collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumGeneric, false))
        
        // smart album -> recently
        collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumRecentlyAdded, false))
        
        // smart album -> video
        collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumPanoramas, false))
        collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumVideos, false))
        collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumSlomoVideos, false))
        collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumTimelapses, false))
        
        // smart album -> screenshots
        if #available(iOS 9.0, *) {
            collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumScreenshots, false))
            //collections.append(contentsOf: _collections(with: .smartAlbum, .smartAlbumSelfPortraits, false))
        }
        
        // album -> share
        collections.append(contentsOf: _collections(with: .album, .albumMyPhotoStream, false))
        collections.append(contentsOf: _collections(with: .album, .albumCloudShared, false))
        
        // album -> user
        collections.append(contentsOf: _collections(with: .album, .albumRegular, true))
        collections.append(contentsOf: _collections(with: .album, .albumSyncedAlbum, false))
        collections.append(contentsOf: _collections(with: .album, .albumImported, false))
        collections.append(contentsOf: _collections(with: .album, .albumSyncedFaces, false))
        
        return collections
    }
    
    internal var collections: Array<PHAssetCollection>
    internal var collectionType: CollectionType
}

extension PHImageRequestID: Request {
}

private class _PHResponse: Response {
    
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

private class _PHLibrary: NSObject, Library, Photos.PHPhotoLibraryChangeObserver {
    
    /// Create a library
    override init() {
        
        _library = PHPhotoLibrary.shared()
        _cache = PHCachingImageManager()
        
        super.init()
        
        // add change observer
        _library.register(self)
    }
    deinit {
        // remove change observer
        _library.unregisterChangeObserver(self)
    }
    
    // MARK: Authorization
    

    /// Requests the user’s permission, if needed, for accessing the library.
    func requestAuthorization(_ handler: @escaping (Error?) -> Void) {
        // convert authorization status
        PHPhotoLibrary.requestAuthorization { status in
            // check authorization status
            switch status {
            case .authorized:
                handler(nil)
                
            case .denied,
                 .notDetermined:
                handler(Exception.denied)
                
            case .restricted:
                handler(Exception.restricted)
            }
            
            // load image manager(lazy load)
            self._cache.allowsCachingHighQualityImages = true
        }
    }
    
    // MARK: Change
    
    /// Registers an object to receive messages when objects in the photo library change.
    func addChangeObserver(_ observer: ChangeObserver) {
        _observers.insert(observer)
    }
    
    /// Unregisters an object so that it no longer receives change messages.
    func removeChangeObserver(_ observer: ChangeObserver) {
        _observers.remove(observer)
    }
    
    // MARK: Check
    
    /// Check asset exists
    func exists(forItem asset: Asset) -> Bool {
        return PHAsset.fetchAssets(withLocalIdentifiers: [asset.ub_identifier], options: nil).count != 0
    }
    
    // MARK: Fetch
    
    /// Get collections with type
    func request(forCollectionList type: CollectionType) -> CollectionList {
        return _PHCollectionList(type: type)
    }
    
    /// Requests an image representation for the specified asset.
    func request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
        // must king of PHAsset
        guard let asset = asset as? PHAsset else {
            return nil
        }
        
        let newMode = _convert(forMode: mode)
        let newOptions = _convert(forImage: options)
        
        // send image request
        return _cache.requestImage(for: asset, targetSize: size, contentMode: newMode, options: newOptions) { image, info in
            // convert result info to response
            let response = _PHResponse(info: info)
            
            // if the image is empty and the image is degraded, it need download
            if response.degraded && image == nil {
                response.downloading = true
            }
            
            // callback
            resultHandler(image, response)
        }
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    func request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request? {
        // must king of PHAsset
        guard let asset = asset as? PHAsset else {
            return nil
        }
        
        let newOptions = _convert(forVideo: options)
        
        // send player item request
        return _cache.requestPlayerItem(forVideo: asset, options: newOptions) { item, info in
            // convert result info to response
            let response = _PHResponse(info: info)
            
            // callback
            resultHandler(item, response)
        }
    }
    
    /// Cancels an asynchronous request
    func cancel(with request: Request) {
        // must is PHImageRequestID
        guard let request = request as? PHImageRequestID else {
            return
        }
        _cache.cancelImageRequest(request)
    }
    
    // MARK: Cacher
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    var allowsCachingHighQualityImages: Bool {
        set { return _cache.allowsCachingHighQualityImages = newValue }
        get { return _cache.allowsCachingHighQualityImages }
    }
    
    /// Prepares image representations of the specified assets for later use.
    func startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // must king of PHAsset
        guard let assets = assets as? [PHAsset] else {
            return
        }
        let newMode = _convert(forMode: mode)
        let newOptions = _convert(forImage: options)
        
        // forward
        _cache.startCachingImages(for: assets, targetSize: size, contentMode: newMode, options: newOptions)
    }
    
    /// Cancels image preparation for the specified assets and options.
    func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // must king of PHAsset
        guard let assets = assets as? [PHAsset] else {
            return
        }
        let newMode = _convert(forMode: mode)
        let newOptions = _convert(forImage: options)
        
        // forward
        _cache.stopCachingImages(for: assets, targetSize: size, contentMode: newMode, options: newOptions)
    }
    
    /// Cancels all image preparation that is currently in progress.
    func stopCachingImagesForAllAssets() {
        // forward
        _cache.stopCachingImagesForAllAssets()
    }
    
    
    /// This callback is invoked on an arbitrary serial queue. If you need this to be handled on a specific queue, you should redispatch appropriately
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // notify all observer
        _observers.forEach {
            $0.library(self, didChange: changeInstance)
        }
    }
    
    private var _cache: PHCachingImageManager
    private var _library: PHPhotoLibrary
    
    private lazy var _observers: WSet<ChangeObserver> = []
}

/// covnert `RequestContentMode` to `PHImageContentMode`
private func _convert(forMode mode: RequestContentMode) -> PHImageContentMode {
    switch mode {
    case .aspectFill: return .aspectFill
    case .aspectFit: return .aspectFit
    }
}

/// covnert `RequestOptions` to `PHImageRequestOptions`
private func _convert(forImage options: RequestOptions?) -> PHImageRequestOptions? {
    // if the option is nil, create a failure
    guard let options = options else {
        return nil
    }
    let newOptions = PHImageRequestOptions()
    
    // need request from remote service?
    newOptions.isNetworkAccessAllowed = options.isNetworkAccessAllowed
    
    // if you provide the progress query handler
    if let progressHandler = options.progressHandler {
        // convert result info to response
        newOptions.progressHandler = { progress, _, _, info in
            progressHandler(progress, _PHResponse(info: info))
        }
    }
    
    return newOptions
}

/// covnert `RequestOptions` to `PHVideoRequestOptions`
private func _convert(forVideo options: RequestOptions?) -> PHVideoRequestOptions? {
    // if the option is nil, create a failure
    guard let options = options else {
        return nil
    }
    let newOptions = PHVideoRequestOptions()
    
    // need request from remote service?
    newOptions.isNetworkAccessAllowed = options.isNetworkAccessAllowed
    
    // if you provide the progress query handler
    if let progressHandler = options.progressHandler {
        // convert result info to response
        newOptions.progressHandler = { progress, _, _, info in
            progressHandler(progress, _PHResponse(info: info))
        }
    }
    
    return newOptions
}

/// Generate a library with `Photos.framework`
public func SystemLibrary() -> Library {
    return _PHLibrary()
}

