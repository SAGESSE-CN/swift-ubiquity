//
//  Library+Photos.swift
//  Ubiquity
//
//  Created by SAGESSE on 8/6/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import Photos

// MARK: - define photos utils strong.

public typealias UHAsset = PHAsset
public typealias UHAssetChange = PHChange

public class UHAssetCollection: NSObject {
    
    // Generate a collection for Photos.
    public init(collection: PHAssetCollection, collectionType: CollectionType) {
        self.collection = collection
        self.collectionType = collectionType
    }
    
    /// Returns a Boolean value that indicates whether the receiver and a given object are equal.
    public override func isEqual(_ object: Any?) -> Bool {
        // compare collection type
        if let object = object as? UHAssetCollection {
            return collection === object.collection
                || ub_identifier == object.ub_identifier
        }
        
        // compare to other types
        return super.isEqual(object)
    }
    /// Returns a Boolean value that indicates whether the receiver and a given object are equal.
    public func isEquals(_ other: UHAssetCollection) -> Bool {
        // if the memory is the same
        // then all attributes must be the same
        guard other.collection !== collection else {
            return true
        }
        
        // validate all properties
        return !type(of: self).validates.contains {
            // fetch value for key path
            let lhs = collection.value(forKeyPath: $0) as AnyObject?
            let rhs = other.collection.value(forKeyPath: $0) as AnyObject?
            
            // compare
            return !(lhs === rhs || lhs?.isEqual(rhs) ?? false)
        }
    }
    
    /// The collection hash value.
    public override var hash: Int {
        return ub_identifier.hashValue
    }
    
    /// The associated fetch result
    internal var fetchResult: PHFetchResult<UHAsset>?
    internal var fetchResultLoaded: PHFetchResult<UHAsset> {
        // hit cache
        if let fetchResult = fetchResult {
            return fetchResult
        }
        // the fetch result will strong references collection
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let result = UHAsset.fetchAssets(in: collection, options: nil)
        self.fetchResult = result
        return result
    }
    
    /// The collection type
    public var collectionType: CollectionType
    
    /// The mapping the collection
    public let collection: PHAssetCollection
    
    /// Need to validate the properties
    internal static let validates = [
        // PHObject
        #keyPath(PHObject.localIdentifier),
        
        // PHCollection
        #keyPath(PHCollection.canContainAssets),
        #keyPath(PHCollection.canContainCollections),
        #keyPath(PHCollection.localizedTitle),
        
        // PHAssetCollection
        //#keyPath(PHAssetCollection.approximateLocation), // does not support compare
        #keyPath(PHAssetCollection.localizedLocationNames),
        #keyPath(PHAssetCollection.assetCollectionType),
        #keyPath(PHAssetCollection.assetCollectionSubtype),
        #keyPath(PHAssetCollection.estimatedAssetCount),
        #keyPath(PHAssetCollection.startDate),
        #keyPath(PHAssetCollection.endDate),
    ]
}
public class UHAssetCollectionList: NSObject {
    
    /// Generate a collection list with collectoin type
    public convenience init(collectionType: CollectionType) {
        self.init(identifier: UUID().uuidString, collectionType: collectionType)
    }
    /// Generate a collection list with identifier and collectoin type
    public init(identifier: String, collectionType: CollectionType) {
        self.identifier = identifier
        self.collectionType = collectionType
        self.collections = UHAssetCollectionList._collections(with: collectionType)
        super.init()
    }
    
    private static func _collections(with collectionType: PHAssetCollectionType, _ collectionSubtype: PHAssetCollectionSubtype, _ omittingEmptySubsequences: Bool) -> Array<UHAssetCollection> {
        // fetch collection with type
        let result = PHAssetCollection.fetchAssetCollections(with: collectionType, subtype: collectionSubtype, options: nil)
        
        // convert to `_PHCollection`
        return (0 ..< result.count).flatMap { index in
            return .init(collection: result.object(at: index), collectionType: .regular)
        }
    }
    private static func _collections(with collectionType: CollectionType) -> Array<UHAssetCollection> {
        // process moment
        if collectionType == .moment {
            // fetch collection with type
            let result = PHAssetCollection.fetchMoments(with: nil)
            
            // merge to result
            return (0 ..< result.count).flatMap { index in
                return .init(collection: result.object(at: index), collectionType: .moment)
            }
        }
        
        // process recently added
        if collectionType == .recentlyAdded {
            // smart album -> recently
            return _collections(with: .smartAlbum, .smartAlbumRecentlyAdded, true).map {
                $0.collectionType = .recentlyAdded
                return $0
            }
        }
        
        // the new collections
        var collections: Array<UHAssetCollection> = []
        
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
    
    /// A unique string that persistently identifies the object.
    public let identifier: String
    
    public var collections: Array<UHAssetCollection>
    public var collectionType: CollectionType
}

internal class UHAssetRequest: NSObject {
    
    /// Generate a asset request.
    internal init(targetSize: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .default) {
        self.targetSize = targetSize
        self.contentMode = contentMode
        super.init()
    }
    
    /// The request of image.
    internal var image: PHImageRequestID?
    
    /// The request of video.
    internal var video: PHImageRequestID?
    
    /// The request of data.
    internal var data: PHImageRequestID?
    
    /// The request of target size.
    internal var targetSize: CGSize
    internal var contentMode: PHImageContentMode = .default
}
internal class UHAssetResponse: NSObject {
    
    /// Generate response for Photos.
    internal init(_ responseObject: [AnyHashable: Any]?) {
        error = responseObject?[PHImageErrorKey] as? NSError
        isDegraded = responseObject?[PHImageResultIsDegradedKey] as? Bool ?? false
        isCancelled = responseObject?[PHImageCancelledKey] as? Bool ?? false
        isDownloading = responseObject?[PHImageResultIsInCloudKey] as? Bool ?? false
    }
    
    /// An error that occurred when Photos attempted to load the image.
    open var error: Error?
    
    /// The result image is a low-quality substitute for the requested image.
    open var isDegraded: Bool = false
    /// The image request was canceled.
    open var isCancelled: Bool = false
    /// The photo asset data is stored on the local device or must be downloaded from remote servicer
    open var isDownloading: Bool = false
}

public class UHAssetLibrary: NSObject, Photos.PHPhotoLibraryChangeObserver {
    
    /// Create a library
    public override init() {
        super.init()
        
        logger.trace?.write()
    }
    deinit {
        logger.trace?.write()

        // remove change observer
        _library?.unregisterChangeObserver(self)
    }
    
    /// This callback is invoked on an arbitrary serial queue. If you need this to be handled on a specific queue, you should redispatch appropriately
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        logger.debug?.write(changeInstance)
        
        // notify all observer
        observers.forEach {
            $0.library(self, didChange: changeInstance)
        }
    }
    
    /// Warning: if the user does not have the `Photos` access permission, create `the PHCachingImageManager` object will Carsh.
    internal var cache: PHCachingImageManager {
        if let cache = _cache {
            return cache
        }
        let cache = PHCachingImageManager()
        _cache = cache
        return cache
    }
    internal var library: PHPhotoLibrary {
        if let library = _library {
            return library
        }
        let library = PHPhotoLibrary.shared()
        _library = library
        library.register(self)
        return library
    }
    
    internal lazy var observers: WSet<ChangeObserver> = []
    
    private var _cache: PHCachingImageManager?
    private var _library: PHPhotoLibrary?
}


// MARK: - bridging Photos to Ubiquity.


extension UHAsset: Asset {
    
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
            if filename?.uppercased().hasSuffix("GIF") ?? false {
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
extension UHAssetCollection: Collection {
    
    /// The localized title of the collection.
    public var ub_title: String? {
        // if have title, display it
        if let title = collection.localizedTitle {
            return title
        }
        
        // if have date, display it
        guard let date = collection.startDate else {
            return nil
        }
        
        // generate title for date
        return ub_string(for: date)
    }
    /// The localized subtitle of the collection.
    public var ub_subtitle: String? {
        // if not have title, only display the date
        if collection.localizedTitle == nil {
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
        
        return subtitle
    }
    
    /// A unique string that persistently identifies the object.
    public var ub_identifier: String {
       return collection.localIdentifier
    }
    
    /// The type of the asset collection, such as an album or a moment.
    public var ub_collectionType: CollectionType {
        return collectionType
    }
    
    /// The subtype of the asset collection.
    public var ub_collectionSubtype: CollectionSubtype {
        return CollectionSubtype(rawValue: collection.assetCollectionSubtype.rawValue) ?? .smartAlbumGeneric
    }
    
    /// The number of assets in the asset collection.
    public var ub_count: Int {
        return fetchResultLoaded.count
    }
    /// The number of assets in the asset collection.
    public func ub_count(with type: AssetType) -> Int {
        return fetchResultLoaded.countOfAssets(with: PHAssetMediaType(rawValue: type.rawValue) ?? .unknown)
    }
    /// Retrieves assets from the specified asset collection.
    public func ub_asset(at index: Int) -> Asset {
        return fetchResultLoaded.object(at: index)
    }
}
extension UHAssetCollectionList: CollectionList {
    
    /// The localized title of the collection list.
    open var ub_title: String? {
        return ub_defaultTitle(with: ub_collectionType)
    }
    /// The localized subtitle of the collection list.
    open var ub_subtitle: String? {
        return nil
    }
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
        return collections.count
    }
    
    /// Retrieves collection from the specified collection list.
    public func ub_collection(at index: Int) -> Collection {
        return collections[index]
    }
}

extension UHAssetChange: Change {

    /// Returns detailed change information for the specified collection.
    public func ub_changeDetails(forCollection collection: Collection) -> ChangeDetails? {
        // collection must king of `PHAssetCollection`
        guard let collection = collection as? UHAssetCollection else {
            return nil
        }
        
        // if the result is not loaded, no any changes
        guard let result = collection.fetchResult else {
            return nil
        }
        
        // Check for changes to the list of assets (insertions, deletions, moves, or updates).
        let assets = changeDetails(for: result)
        
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        let contents = changeDetails(for: collection.collection)
        
        // `assets` is nil the collection count no any change
        // `contents` is nil the collection property no any chnage
        guard assets != nil || contents != nil else {
            return nil
        }
        
        // merge collection and result
        // must be create a new collection, otherwise the cache cannot be updated in time
        let newResult = assets?.fetchResultAfterChanges ?? result
        let newCollection = UHAssetCollection(collection: contents?.objectAfterChanges ?? collection.collection, collectionType: collection.collectionType)
        
        // if only the contents change,
        // check new collection and collection is eqqual, if true ignore the changes
        if assets == nil && collection.isEquals(newCollection) {
            return nil
        }
        
        // if colleciton is change, save new result
        if newCollection !== collection {
            newCollection.fetchResult = newResult
        }
        
        // generate new chagne details for collection
        let newDetails = ChangeDetails(before: collection, after: newCollection)
        
        // if after is nil, the collection is deleted
        if let contents = contents, contents.objectAfterChanges == nil {
            newDetails.after = nil
        }
        
        // update option info
        newDetails.hasItemChanges = assets != nil
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
        
        logger.debug?.write(newDetails)
        
        return newDetails
    }
    
    /// Returns detailed change information for the specified colleciotn list.
    public func ub_changeDetails(forCollectionList collectionList: CollectionList) -> ChangeDetails? {
        // collection must king of `UHAssetCollectionList`
        guard let collectionList = collectionList as? UHAssetCollectionList else {
            return nil
        }
        
        // generate new collection list.
        let newCollectionList = UHAssetCollectionList(identifier: collectionList.identifier, collectionType: collectionList.ub_collectionType)
        
        // compare difference
        var diffs = diff(collectionList.collections, dest: newCollectionList.collections)
        
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
            guard let collection = details.after as? UHAssetCollection else {
                return
            }
            newCollectionList.collections[$0] = collection
        }
        
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
        details.hasItemChanges = true
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
        
        // check status
        details.hasMoves = !(details.movedIndexes?.isEmpty ?? true)
        
        // output detail info
        logger.debug?.write(details)
        
        return details
    }
}
extension UHAssetRequest: Request {
}
extension UHAssetResponse: Response {
    
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

extension UHAssetLibrary: Library {

    /// Requests the user’s permission, if needed, for accessing the library.
    public func ub_requestAuthorization(_ handler: @escaping (Error?) -> Void) {
        // convert authorization status
        PHPhotoLibrary.requestAuthorization { status in
            // check authorization status
            switch status {
            case .authorized:
                handler(nil)
                
                // load image manager(lazy load)
                _ = self.library
                _ = self.cache

            case .denied,
                 .notDetermined:
                handler(Exception.denied)
                
            case .restricted:
                handler(Exception.restricted)
            }
        }
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
        return UHAsset.fetchAssets(withLocalIdentifiers: [asset.ub_identifier], options: nil).count != 0
    }
    
    /// Get collections with type
    public func ub_request(forCollectionList type: CollectionType) -> CollectionList {
        let collectionList = UHAssetCollectionList(collectionType: type)
        return collectionList
    }
    
    /// Requests an image representation for the specified asset.
    public func ub_request(forImage asset: Asset, targetSize: CGSize, contentMode: RequestContentMode, options: RequestOptions, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
        // must king of UHAsset
        guard let asset = asset as? UHAsset else {
            return nil
        }
        
        let option = _convert(forImage: options)
        let request = UHAssetRequest(targetSize: targetSize, contentMode: _convert(forMode: contentMode))
        
        // special processing is required when loading larger images
        if targetSize == UHAssetLibrary.ub_requestMaximumSize {
            
            // estimate the memory space required for an image
            let width = (asset.pixelWidth + min(.init(targetSize.width), asset.pixelWidth) + 1) % (asset.pixelWidth + 1)
            let height = (asset.pixelHeight + min(.init(targetSize.height), asset.pixelHeight) + 1) % (asset.pixelHeight + 1)
            let bytes = width * height * 4
            
            // the requested image size has exceeded the limit size?
            if bytes >= Image.largeImageMinimumBytes {
                // exceeds preset maximun bytes
                logger.info?.write("request HD/SD image, decode bytes is \(Float(bytes) / 1024 / 1024)MiB")
                
                // send data requestf
                request.targetSize = UIScreen.main.bounds.size
                request.contentMode = .aspectFill
                request.data = cache.requestImageData(for: asset, options: option) { imageData, dataUTI, orientation, responseObject in
                    
                    let response = UHAssetResponse(responseObject)
                    
                    let image = imageData.map { Image(data: $0) } ?? nil
                    image?.generateLargeImage { _ in
                        resultHandler(image, response)
                    }
                }
            }
            
            // for GIF special loading methods are required
            if request.data == nil && asset.ub_subtype & AssetSubtype.photoGIF.rawValue != 0 {
                // the image is GIF.
                logger.info?.write("request GIF image")
                
                // send data request
//                request.data = cache.requestImageData(for: asset, options: option) { imageData, dataUTI, orientation, responseObject in
//                    
//                }
            }
        }
        
        // send image request
        request.image = cache.requestImage(for: asset, targetSize: request.targetSize, contentMode: request.contentMode, options: option) { image, responseObject in
            // convert result info to response
            let response = UHAssetResponse(responseObject)
            
            
            // if the image is empty and the image is degraded, it need download
            if response.isDegraded && image == nil {
                response.isDownloading = true
            }
            
            // update request result 
            resultHandler(image, response)
        }
        
        // the request has been sent successfully
        return request
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    public func ub_request(forVideo asset: Asset, options: RequestOptions, resultHandler: @escaping (AVPlayerItem?, Response) -> ()) -> Request? {
        // Must king of UHAsset
        guard let asset = asset as? UHAsset else {
            return nil
        }
        
        let option = _convert(forVideo: options)
        let request = UHAssetRequest()
        
        // send player item request
        request.video = cache.requestPlayerItem(forVideo: asset, options: option) { item, responseObject in
            // convert result info to response
            let response = UHAssetResponse(responseObject)
            
            // update request result
            resultHandler(item, response)
        }
        
        // the request has been sent successfully 
        return request
    }
    
    /// Requests full-sized image data for the specified asset.
    public func ub_request(forData asset: Asset, options: RequestOptions, resultHandler: @escaping (Data?, Response) -> ()) -> Request? {
        return nil
    }
    
    /// Cancels an asynchronous request
    public func ub_cancel(with request: Request) {
        // must is PHImageRequestID
        guard let request = request as? UHAssetRequest else {
            return
        }
        
        // cancel all requests.
        request.data.map { cache.cancelImageRequest($0) }
        request.image.map { cache.cancelImageRequest($0) }
        request.video.map { cache.cancelImageRequest($0) }
    }
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    public var ub_allowsCachingHighQualityImages: Bool {
        set { return cache.allowsCachingHighQualityImages = newValue }
        get { return cache.allowsCachingHighQualityImages }
    }
    
    /// Prepares image representations of the specified assets for later use.
    public func ub_startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // must king of UHAsset
        guard let assets = assets as? [UHAsset] else {
            return
        }
        let newMode = _convert(forMode: mode)
        let newOptions = _convert(forImage: options)
        
        // forward
        cache.startCachingImages(for: assets, targetSize: size, contentMode: newMode, options: newOptions)
    }
    
    /// Cancels image preparation for the specified assets and options.
    public func ub_stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // must king of UHAsset
        guard let assets = assets as? [UHAsset] else {
            return
        }
        let newMode = _convert(forMode: mode)
        let newOptions = _convert(forImage: options)
        
        // forward
        cache.stopCachingImages(for: assets, targetSize: size, contentMode: newMode, options: newOptions)
    }
    
    /// Cancels all image preparation that is currently in progress.
    public func ub_stopCachingImagesForAllAssets() {
        // forward
        cache.stopCachingImagesForAllAssets()
    }
    
    /// Predefined size of the original request
    public static var ub_requestMaximumSize: CGSize {
        return PHImageManagerMaximumSize
    }
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
    let newOptions = PHImageRequestOptions()
    
    // need request from remote service?
    newOptions.isNetworkAccessAllowed = options?.isNetworkAccessAllowed ?? true
    
    // if you provide the progress query handler
    if let progressHandler = options?.progressHandler {
        // convert result info to response
        newOptions.progressHandler = { progress, _, _, responseObject in
            progressHandler(progress, UHAssetResponse(responseObject))
        }
    }
    
    return newOptions
}

/// covnert `RequestOptions` to `PHVideoRequestOptions`
private func _convert(forVideo options: RequestOptions?) -> PHVideoRequestOptions? {
    let newOptions = PHVideoRequestOptions()
    
    // need request from remote service?
    newOptions.isNetworkAccessAllowed = options?.isNetworkAccessAllowed ?? true
    
    // if you provide the progress query handler
    if let progressHandler = options?.progressHandler {
        // convert result info to response
        newOptions.progressHandler = { progress, _, _, responseObject in
            progressHandler(progress, UHAssetResponse(responseObject))
        }
    }
    
    return newOptions
}



