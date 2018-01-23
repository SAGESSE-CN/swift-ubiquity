//
//  Collection.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// Major distinctions between kinds of asset collections
@objc
public enum CollectionType : Int {
    
    /// All albums except moment.
    case regular = 1
    
    /// A moment album.
    case moment = 3
    
    /// A smart album whose contents update dynamically.
    case recentlyAdded = 2
}


/// Minor distinctions between kinds of asset collections
@objc
public enum CollectionSubtype : Int {

    /// A smart album of no more specific subtype.
    ///
    /// This subtype applies to smart albums synced to the device from iPhoto.
    case smartAlbumGeneric = 200

    /// A smart album that groups all panorama photos in the photo library.
    case smartAlbumPanoramas = 201
    /// A smart album that groups all video assets in the photo library.
    case smartAlbumVideos = 202
    /// A smart album that groups all assets that the user has marked as favorites.
    case smartAlbumFavorites = 203
    /// A smart album that groups all time-lapse videos in the photo library.
    case smartAlbumTimelapses = 204
    /// A smart album that groups all assets hidden from the Moments view in the Photos app.
    case smartAlbumAllHidden = 205
    /// A smart album that groups assets that were recently added to the photo library.
    case smartAlbumRecentlyAdded = 206
    /// A smart album that groups all burst photo sequences in the photo library.
    case smartAlbumBursts = 207
    /// A smart album that groups all Slow-Mo videos in the photo library.
    case smartAlbumSlomoVideos = 208

    /// A smart album that groups all assets that originate in the user’s own library (as opposed to assets from iCloud Shared Albums).
    case smartAlbumUserLibrary = 209
    /// A smart album that groups all photos and videos captured using the device’s front-facing camera.
    case smartAlbumSelfPortraits = 210
    /// A smart album that groups all images captured using the device’s screenshot function.
    case smartAlbumScreenshots = 211
}


/// The abstract superclass for Photos asset collections.
@objc
public protocol Collection: NSObjectProtocol {
    
    /// The localized title of the collection.
    var ub_title: String? { get }
    /// The localized subtitle of the collection.
    var ub_subtitle: String? { get }
    /// A unique string that persistently identifies the object.
    var ub_identifier: String { get }
    
    /// The type of the asset collection, such as an album or a moment.
    var ub_collectionType: CollectionType { get }
    /// The subtype of the asset collection.
    var ub_collectionSubtype: CollectionSubtype { get }
    
    /// The number of assets in the asset collection.
    var ub_count: Int { get }
    /// The number of assets in the asset collection.
    func ub_count(with type: AssetType) -> Int
    /// Retrieves assets from the specified asset collection.
    func ub_asset(at index: Int) -> Asset
    
    /// Returns whether the specified object is present in the fetch result.
    func ub_contains(_ asset: Asset) -> Bool
}

/// The abstract superclass for Photos asset collection lists.
@objc
public protocol CollectionList: NSObjectProtocol {
    
    /// The localized title of the collection list.
    var ub_title: String? { get }
    /// The localized subtitle of the collection list.
    var ub_subtitle: String? { get }
    /// A unique string that persistently identifies the object.
    var ub_identifier: String { get }
    
    /// The type of the asset collection, such as an album or a moment.
    var ub_collectionType: CollectionType { get }
    
    /// The number of collection in the collection list.
    var ub_count: Int { get }
    /// Retrieves collection from the specified collection list.
    func ub_collection(at index: Int) -> Collection
}

