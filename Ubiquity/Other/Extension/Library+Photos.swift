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

private class _PHAsset: Asset {
    
    /// Create a asset for Photos
    init(asset: PHAsset) {
        self.asset = asset
        self.version = Int(asset.modificationDate?.timeIntervalSince1970 ?? 0 * 1000)
    }
    
    /// The associated photots asset
    let asset: PHAsset
    
    /// The localized title of the asset.
    var title: String? {
        return "Title"
    }
    /// The localized subtitle of the asset.
    var subtitle: String? {
        return "Subtitle"
    }
    
    /// A unique string that persistently identifies the object.
    var identifier: String {
        // hit cache?
        if let localIdentifier = _localIdentifier {
            return localIdentifier
        }
        
        // get and cache
        let localIdentifier = asset.localIdentifier
        _localIdentifier = localIdentifier
        return localIdentifier
    }
    /// The version of the asset, identifying asset change.
    var version: Int 
    
    /// The width, in pixels, of the asset’s image or video data.
    var pixelWidth: Int {
        return asset.pixelWidth
    }
    
    /// The height, in pixels, of the asset’s image or video data.
    var pixelHeight: Int {
        return asset.pixelHeight
    }
    
    /// The duration, in seconds, of the video asset.
    /// For photo assets, the duration is always zero.
    var duration: TimeInterval {
        return asset.duration
    }
    
    /// The asset allows play operation
    var allowsPlay: Bool {
        return asset.mediaType == .video
    }
    
    /// The type of the asset, such as video or audio.
    var mediaType: AssetMediaType {
        return AssetMediaType(rawValue: asset.mediaType.rawValue) ?? .unknown
    }
    
    /// The subtypes of the asset, identifying special kinds of assets such as panoramic photo or high-framerate video.
    var mediaSubtypes: AssetMediaSubtype {
        //        // the media is gif?
        //        if filename?.hasSuffix("GIF") ?? false {
        //            print("it is gif")
        //        }
        //        
        return AssetMediaSubtype(rawValue: asset.mediaSubtypes.rawValue)
    }
    
    /// The asset filename
    dynamic var filename: String? {
        // the `PHAsset` support filename?
        guard asset.responds(to: #selector(getter: self.filename)) else {
            return nil
        }
        
        // get filename for `PHAsset`
        return asset.value(forKey: #keyPath(filename)) as? String
    }
    
    private var _localIdentifier: String?
}
private class _PHCollection: Collection, Hashable {
    
    /// Create an collection for Photots
    init(collection: PHAssetCollection) {
        _collection = collection
    }
    
    /// Create an collection for Photots change
    init(collection: PHAssetCollection, result: PHFetchResult<PHAsset>) {
        _collection = collection
        _result = result
    }
    
    /// The associated photots collection
    var collection: PHAssetCollection {
        return _collection
    }
    
    /// The associated fetch result
    var result: PHFetchResult<PHAsset> {
        if let result = _result {
            return result
        }
        let result = PHAsset.fetchAssets(in: collection, options: nil)
        _result = result
        _assets = Array(repeating: nil, count: result.count)
        return result
    }
    
    
    /// The localized title of the collection.
    var title: String? {
        // hit cache?
        if let title = _localizedTitle {
            return title
        }
        
        // if have title, display it
        if let title = collection.localizedTitle {
            _localizedTitle = title
            return title
        }
        
        // if have date, display it
        guard let date = collection.startDate else {
            _localizedTitle = nil
            return nil
        }
        
        // generate title for date
        let title = ub_string(for: date)
        _localizedTitle = title
        return title
    }
    /// The localized subtitle of the collection.
    var subtitle: String? {
        // hit cache?
        if let subtitle = _localizedSubtitle {
            return subtitle
        }
        
        // if not have title, only display the date
        if collection.localizedTitle == nil {
            _localizedSubtitle = nil
            return nil
        }
        
        // the subtitle need cat
        var subtitle = ""
        
        // if have date, display it
        if let date = collection.startDate {
            subtitle = ub_string(for: date)
        }
        
        // get current location
        let names = collection.localizedLocationNames
        if let name = names.first {
            subtitle += " · " + name
        }
        
        // cache
        _localizedSubtitle = subtitle
        return subtitle
    }
    
    /// A unique string that persistently identifies the object.
    var identifier: String {
        // hit cache?
        if let localIdentifier = _localIdentifier {
            return localIdentifier
        }
        
        // get and cache
        let localIdentifier = collection.localIdentifier
        _localIdentifier = localIdentifier
        return localIdentifier
    }
    
    /// The type of the asset collection, such as an album or a moment.
    var collectionType: CollectionType = .regular
    
    /// The subtype of the asset collection.
    var collectionSubtype: CollectionSubtype {
        return CollectionSubtype(rawValue: collection.assetCollectionSubtype.rawValue) ?? .smartAlbumGeneric
    }
    
    /// The number of assets in the asset collection.
    var count: Int {
        return _assets?.count ?? result.count
    }
    /// The number of assets in the asset collection.
    func count(with type: AssetMediaType) -> Int {
        // hit cache?
        if let count = _cachedCount[type] {
            return count
        }
        let count = result.countOfAssets(with: PHAssetMediaType(rawValue: type.rawValue) ?? .unknown)
        _cachedCount[type] = count
        return count
    }
    
    /// Retrieves assets from the specified asset collection.
    subscript(index: Int) -> Asset {
        
        if let asset = _assets?[index] {
            return asset
        }
        
        let asset = _PHAsset(asset: result.object(at: index))
        _assets?[index] = asset
        return asset
    }
    
    
    /// Compare the change
    func changeDetails(for change: Change) -> _PHChangeDetails? {
        // change must king of `_PHChange`
        guard let change = (change as? _PHChange)?.change else {
            return nil
        }
        // if the result is not used, no any changes
        guard let result = _result else {
            return nil
        }
        
        // Check for changes to the list of assets (insertions, deletions, moves, or updates).
        let assets = change.changeDetails(for: result)
        
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        let content = change.changeDetails(for: collection)
        
        // `assets` is nil the collection count no any change
        // `content` is nil the collection property no any chnage
        guard assets != nil || content != nil else {
            return nil
        }
        
        
        // merge collection and result
        let newResult = assets?.fetchResultAfterChanges ?? result
        let newCollection = _PHCollection(collection: content?.objectAfterChanges as? PHAssetCollection ?? collection, result: newResult)
        
        // generate new chagne details for collection
        let details = _PHChangeDetails(before: self, after: newCollection)
        
        // if after is nil, the collection is deleted
        if let content = content, content.objectAfterChanges == nil {
            details.after = nil
        }
        
        // update option info
        details.hasAssetChanges = assets != nil
        details.hasIncrementalChanges = assets?.hasIncrementalChanges ?? false
        details.hasMoves = assets?.hasMoves ?? false
        
        // update change indexes info
        details.removedIndexes = assets?.removedIndexes
        details.insertedIndexes = assets?.insertedIndexes
        details.enumerateMoves { from, to in
            // must create
            if details.movedIndexes == nil {
                details.movedIndexes = []
            }
            details.movedIndexes?.append((from, to))
        }
        
        // filter preloading
        details.changedIndexes = assets?.changedObjects.reduce(IndexSet()) {
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
        let allIsEmpty = ![details.removedIndexes?.isEmpty, details.insertedIndexes?.isEmpty, details.changedIndexes?.isEmpty, details.movedIndexes?.isEmpty].contains { !($0 ?? true) }
        if allIsEmpty && content == nil && count == newCollection.count {
            return nil
        }
        
        return details
    }
    
    /// The hash value.
    var hashValue: Int {
        return _collection.hashValue
    }
    /// Returns a Boolean value indicating whether two values are equal.
    static func ==(lhs: _PHCollection, rhs: _PHCollection) -> Bool {
        // if the memory, the same value must be the same
        guard lhs !== rhs else {
            return true
        }
        return lhs._collection == rhs._collection
    }
    
    
    /// Cached assets
    private var _assets: [_PHAsset?]?
    
    /// Cached associated Photots object
    private var _result: PHFetchResult<PHAsset>?
    private var _collection: PHAssetCollection
    private var _cachedCount: Dictionary<AssetMediaType, Int> = [:]
    
    private var _localIdentifier: String?
    
    private var _localizedTitle: String??
    private var _localizedSubtitle: String??
}
private class _PHCollectionList: CollectionList {
    
    private typealias _FetchResult = PHFetchResult<PHAssetCollection>
    private typealias _FetchResultChangeDetails = PHFetchResultChangeDetails<PHAssetCollection>
    
    init(type: CollectionType) {
        _type = type
        _collections = _collections(with: type)
    }
    
    /// The type of the asset collection, such as an album or a moment.
    var collectionType: CollectionType {
        return _type
    }
    
    /// The number of collection in the collection list.
    var count: Int {
        return _collections.count
    }
    
    /// Retrieves collection from the specified collection list.
    subscript(index: Int) -> Collection {
        return _collections[index]
    }
    
    /// Compare the change
    public func changeDetails(for change: Change) -> _PHChangeDetails? {
        
        // generate new collection list.
        let collectionList = _PHCollectionList(type: _type)
        // compare difference
        var diffs = _diff(_collections, dest: collectionList._collections)
        
        // check collection the change
        (0 ..< collectionList.count).forEach {
            // find the elements of change
            guard let index = _collections.index(of: collectionList._collections[$0]) else {
                return
            }
            
            // if collection is has any change
            guard let details = change.changeDetails(for: _collections[index]) else {
                // no change, reset collection
                collectionList._collections[$0] = _collections[index]
                return
            }
            
            // has any change, apply change
            diffs.append(.update(from: index, to: $0))
            
            // merge collection
            guard let collection = details.after as? _PHCollection else {
                return
            }
            collectionList._collections[$0] = collection
        }
        
        // has any chagne?
        guard !diffs.isEmpty else {
            return nil
        }
        
        // generate new chagne details for collection list
        let details = _PHChangeDetails(before: self, after: collectionList)
        
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
        
        
        // clean invailds 
        if details.removedIndexes?.isEmpty ?? false {
            details.removedIndexes = nil
        }
        if details.insertedIndexes?.isEmpty ?? false {
            details.insertedIndexes = nil
        }
        if details.changedIndexes?.isEmpty ?? false {
            details.changedIndexes = nil
        }
        if details.movedIndexes?.isEmpty ?? true {
            details.movedIndexes = nil
            details.hasMoves = false
        }
        
        return details
    }
    
    private func _types(with collectionType: CollectionType) -> Array<(PHAssetCollectionType, PHAssetCollectionSubtype, Bool)> {
        // create temp
        var types: Array<(PHAssetCollectionType, PHAssetCollectionSubtype, Bool)> = []
        
        switch collectionType {
        case .regular: // all albums
            
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
            
            return types
            
        case .moment: // moment
            
            // moment -> any
            types.append((.moment, .any, true))
            
        case .recentlyAdded: // recently
            
            // smart album -> recently
            types.append((.smartAlbum, .smartAlbumRecentlyAdded, true))
        }
        
        return types
    }
    private func _collections(with collectionType: CollectionType) -> Array<_PHCollection> {
        
        if collectionType == .moment {
            // fetch collection with type
            let result = PHAssetCollection.fetchMoments(with: nil)
            
            // merge
            return (0 ..< result.count).flatMap { index in
                return _PHCollection(collection: result.object(at: index))
            }
        }
        
        return _types(with: collectionType).flatMap { type, subtype, allowsEmpty -> Array<_PHCollection> in
            // fetch collection with type
            let result = PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: nil)
            
            // merge
            return (0 ..< result.count).flatMap { index in
                return _PHCollection(collection: result.object(at: index))
            }
        }
    }
    
    private var _type: CollectionType
    private var _collections: Array<_PHCollection> = []
}
private class _PHChange: Change {
    
    /// Create a change for Photots
    init(change: PHChange) {
        self.change = change
    }
    
    /// Returns detailed change information for the specified  collection.
    func changeDetails(for collection: Collection) -> ChangeDetails? {
        // must king of `_PHCollection`
        guard let collection = collection as? _PHCollection else {
            return nil
        }
        
        // hit collection cache?
        if let details = collectionCaches[collection.identifier] {
            return details
        }
        
        // make change details and cache
        let details = collection.changeDetails(for: self)
        collectionCaches[collection.identifier] = details
        return details
    }
    
    /// Returns detailed change information for the specified colleciotn list.
    func changeDetails(for collectionList: CollectionList) -> ChangeDetails? {
        // must king of `_PHCollectionList`
        guard let collectionList = collectionList as? _PHCollectionList else {
            return nil
        }
        
        // hit collection cache?
        if let details = collectionListCaches[collectionList.collectionType] {
            return details
        }
        
        // make change details and cache
        let details = collectionList.changeDetails(for: self)
        collectionListCaches[collectionList.collectionType] = details
        return details
    }
    
    /// The associated photots change object
    let change: PHChange
    
    /// Cached change details
    lazy var collectionCaches: Dictionary<String, _PHChangeDetails?> = [:]
    lazy var collectionListCaches: Dictionary<CollectionType, _PHChangeDetails?> = [:]
}
private class _PHChangeDetails: ChangeDetails {
    
    /// Create an change detail
    init(before: Any, after: Any?) {
        self.before = before
        self.after = after
    }
    
    // the object in the state before this change
    var before: Any
    // the object in the state after this change
    var after: Any?
    
    /// A Boolean value that indicates whether objects have been rearranged in the fetch result.
    var hasMoves: Bool = false
    
    /// A Boolean value that indicates whether objects have been any change in result.
    var hasAssetChanges: Bool = false
    
    /// A Boolean value that indicates whether changes to the fetch result can be described incrementally.
    var hasIncrementalChanges: Bool = false
    
    /// The indexes of objects in the fetch result whose content or metadata have been updated.
    var changedIndexes: IndexSet?
    
    /// The indexes from which objects have been removed from the fetch result.
    var removedIndexes: IndexSet? 
    
    /// The indexes where new objects have been inserted in the fetch result.
    var insertedIndexes: IndexSet? 
    
    /// Runs the specified block for each case where an object has moved from one index to another in the fetch result.
    func enumerateMoves(_ handler: @escaping (Int, Int) -> Swift.Void) {
        movedIndexes?.forEach(handler)
    }
    
    /// The indexs where new object have move
    var movedIndexes: [(Int, Int)]?
}
private class _PHRequest: Request {
    init(_ request: PHImageRequestID) {
        self.request = request
    }
    var request: PHImageRequestID
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
        super.init()
    }
    
    // MARK: Authorization
    
    /// Returns information about your app’s authorization for accessing the library.
    func authorizationStatus() -> AuthorizationStatus {
        return _convert(forStatus: PHPhotoLibrary.authorizationStatus())
    }
    
    /// Requests the user’s permission, if needed, for accessing the library.
    func requestAuthorization(_ handler: @escaping (AuthorizationStatus) -> Swift.Void) {
        // convert authorization status
        PHPhotoLibrary.requestAuthorization {
            // load image manager
            self._cache.allowsCachingHighQualityImages = true
            // authorization complete
            handler(_convert(forStatus: $0))
        }
    }
    
    // MARK: Change
    
    /// Registers an object to receive messages when objects in the photo library change.
    func addChangeObserver(_ observer: ChangeObserver) {
        // the observer is added?
        guard !_observers.contains(where: { $0.some === observer }) else {
            return
        }
        // no, add a observer
        _observers.append(.init(observer))
        
        // if count is 1, need to listen for system notifications
        guard _observers.count == 1 else {
            return
        }
        
        // no, add observer to photos
        _library.register(self)
    }
    
    /// Unregisters an object so that it no longer receives change messages.
    func removeChangeObserver(_ observer: ChangeObserver) {
        // clear all invaild observers
        _observers = _observers.filter {
            return $0.some != nil && $0.some !== observer
        }
        
        // if count is 0, need remove
        guard _observers.count == 0 else {
            return
        }
        
        // no, remove observer from photos
        _library.unregisterChangeObserver(self)
    }
    
    // MARK: Check
    
    /// Check asset exists
    func exists(forItem asset: Asset) -> Bool {
        return PHAsset.fetchAssets(withLocalIdentifiers: [asset.identifier], options: nil).count != 0
    }
    
    // MARK: Fetch
    
    /// Get collections with type
    func request(forCollection type: CollectionType) -> CollectionList {
        // hit cache?
        if let collectionList = _collectionLists[type] {
            return collectionList
        }
        
        // create collection list and cache
        let collectionList = _PHCollectionList(type: type)
        _collectionLists[type] = collectionList
        return collectionList
    }
    
    /// Requests an image representation for the specified asset.
    func request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
        // must king of _PHAsset
        guard let asset = asset as? _PHAsset else {
            return nil
        }
        
        let newMode = _convert(forMode: mode)
        let newOptions = _convert(forImage: options)
        
        // send image request
        return _PHRequest(_cache.requestImage(for: asset.asset, targetSize: size, contentMode: newMode, options: newOptions) { image, info in
            // convert result info to response
            let response = _PHResponse(info: info)
            
            // if the image is empty and the image is degraded, it need download
            if response.degraded && image == nil {
                response.downloading = true
            }
            
            // callback
            resultHandler(image, response)
        })
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    func request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request? {
        // must king of _PHAsset
        guard let asset = asset as? _PHAsset else {
            return nil
        }
        
        let newOptions = _convert(forVideo: options)
        
        // send player item request
        return _PHRequest(_cache.requestPlayerItem(forVideo: asset.asset, options: newOptions) { item, info in
            // convert result info to response
            let response = _PHResponse(info: info)
            
            // callback
            resultHandler(item, response)
        })
    }
    
    /// Cancels an asynchronous request
    func cancel(with request: Request) {
        // must is PHImageRequestID
        guard let request = (request as? _PHRequest)?.request else {
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
        // must king of _PHAsset
        guard let assets = assets as? [_PHAsset] else {
            return
        }
        let newMode = _convert(forMode: mode)
        let newOptions = _convert(forImage: options)
        
        // forward
        _cache.startCachingImages(for: assets.map { $0.asset }, targetSize: size, contentMode: newMode, options: newOptions)
    }
    
    /// Cancels image preparation for the specified assets and options.
    func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // must king of _PHAsset
        guard let assets = assets as? [_PHAsset] else {
            return
        }
        let newMode = _convert(forMode: mode)
        let newOptions = _convert(forImage: options)
        
        // forward
        _cache.stopCachingImages(for: assets.map { $0.asset }, targetSize: size, contentMode: newMode, options: newOptions)
    }
    
    /// Cancels all image preparation that is currently in progress.
    func stopCachingImagesForAllAssets() {
        // forward
        _cache.stopCachingImagesForAllAssets()
    }
    
    
    /// This callback is invoked on an arbitrary serial queue. If you need this to be handled on a specific queue, you should redispatch appropriately
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // create a new change, it will cache the results
        let change = _PHChange(change: changeInstance)
        
        // update all collection
        _collectionLists.forEach { type, collectionList in
            // the collection list has any change?
            guard let details = change.changeDetails(for: collectionList) else {
                return
            }
            
            // update value
            _collectionLists[type] = details.after as? _PHCollectionList
        }
        
        // notify all observer
        _observers.forEach {
            $0.some?.library(self, didChange: change)
        }
    }
    
    private var _library: PHPhotoLibrary
    
    private lazy var _cache: PHCachingImageManager = PHCachingImageManager.default() as! PHCachingImageManager
    private lazy var _observers: Array<Weak<ChangeObserver>> = []
    private lazy var _collectionLists: Dictionary<CollectionType, _PHCollectionList> = [:]
}

/// covnert `RequestContentMode` to `PHImageContentMode`
private func _convert(forMode mode: RequestContentMode) -> PHImageContentMode {
    switch mode {
    case .aspectFill: return .aspectFill
    case .aspectFit: return .aspectFit
    }
}

/// covnert `PHAuthorizationStatus` to `AuthorizationStatus`
private func _convert(forStatus status: PHAuthorizationStatus) -> AuthorizationStatus {
    switch status {
    case .authorized: return .authorized
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
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

private enum _Diff: CustomStringConvertible {
    
    case move(from: Int, to: Int)
    case update(from: Int, to: Int)
    case insert(from: Int, to: Int)
    case remove(from: Int, to: Int)
    
    var from: Int {
        switch self {
        case .move(let from, _): return from
        case .insert(let from, _): return from
        case .update(let from, _): return from
        case .remove(let from, _): return from
        }
    }
    
    var description: String {
        
        func c(_ value: Int) -> String {
            guard value >= 0 else {
                return "N"
            }
            return "\(value)"
        }
        
        switch self {
        case .move(let from, let to): return "M\(c(from))/\(c(to))"
        case .insert(let from, let to): return "A\(c(from))/\(c(to))"
        case .update(let from, let to): return "R\(c(from))/\(c(to))"
        case .remove(let from, let to): return "D\(c(from))/\(c(to))"
        }
    }
}
private func _diff<Element: Hashable>(_ src: Array<Element>, dest: Array<Element>) -> Array<_Diff> {
    
    let slen = src.count
    let dlen = dest.count
    
    //
    //      a b c d
    //    0 0 0 0 0
    //  a 0 1 1 1 1
    //  d 0 1 2 2 3
    //
    // the diff result is a table
    var diffs = [[Int]](repeating: [Int](repeating: 0, count: dlen + 1), count: slen + 1)
    
    // LCS + dynamic programming
    for si in 1 ..< slen + 1 {
        for di in 1 ..< dlen + 1 {
            // comparative differences
            if src[si - 1] == dest[di - 1] {
                // equal
                diffs[si][di] = diffs[si - 1][di - 1] + 1
            } else {
                // no equal
                diffs[si][di] = max(diffs[si - 1][di], diffs[si][di - 1])
            }
        }
    }
    
    var si = slen
    var di = dlen
    
    var rms: [(from: Int, to: Int)] = []
    var adds: [(from: Int, to: Int)] = []
    
    // create the optimal path
    repeat {
        guard si != 0 else {
            // the remaining is add
            while di > 0 {
                adds.append((from: si - 1, to: di - 1))
                di -= 1
            }
            break
        }
        guard di != 0 else {
            // the remaining is remove
            while si > 0 {
                rms.append((from: si - 1, to: di - 1))
                si -= 1
            }
            break
        }
        guard src[si - 1] != dest[di - 1] else {
            // no change, ignore
            si -= 1
            di -= 1
            continue
        }
        // check the weight
        if diffs[si - 1][di] > diffs[si][di - 1] {
            // is remove
            rms.append((from: si - 1, to: di - 1))
            si -= 1
        } else {
            // is add
            adds.append((from: si - 1, to: di - 1))
            di -= 1
        }
    } while si > 0 || di > 0
    
    var results: [_Diff] = []
    
    results.reserveCapacity(rms.count + adds.count)
    
    // move(f,t): f = remove(f), t = insert(t), new move(f,t): f = remove(f), t = insert(f)
    // update(f,t): f = remove(f), t = insert(t), new update(f,t): f = remove(f), t = insert(f)
    
    // automatic merge delete and update items
    results.append(contentsOf: rms.map({ item in
        let from = item.from
        let delElement = src[from]
        // can't merge to move item?
        if let addIndex = adds.index(where: { dest[$0.to] == delElement }) {
            let addItem = adds.remove(at: addIndex)
            return .move(from: from, to: addItem.to)
        }
        // can't merge to update item?
        if let addIndex = adds.index(where: { $0.to == from }) {
            let addItem = adds[addIndex]
            //let addElement = dest[addItem.to]
            
            // if delete and add at the same time, merged to update
            adds.remove(at: addIndex)
            return .update(from: from, to: addItem.to)
        }
        return .remove(from: item.from, to: -1)
    }))
    // automatic merge insert items
    results.append(contentsOf: adds.map({ item in
        return .insert(from: -1, to: item.to)
    }))
    
    // sort
    return results.sorted { $0.from < $1.from }
}
    
/// Generate a library with `Photos.framework`
public func PHLibrary() -> Library {
    return _PHLibrary()
}

