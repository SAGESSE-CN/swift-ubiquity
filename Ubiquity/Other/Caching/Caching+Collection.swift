//
//  Caching+Collection.swift
//  Ubiquity
//
//  Created by sagesse on 2018/5/18.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import Foundation

/// The abstract superclass for Photos asset collections.
private class Cacher<T>: Caching<Collection>, Collection  {

    /// The localized title of the collection.
    var ub_title: String? {
        return lazy(with: \Cacher._title, newValue: ref.ub_title)
    }
    /// The localized subtitle of the collection.
    var ub_subtitle: String? {
        return lazy(with: \Cacher._subtitle, newValue: ref.ub_subtitle)
    }
    /// A unique string that persistently identifies the object.
    var ub_identifier: String {
        return lazy(with: \Cacher._identifier, newValue: ref.ub_identifier)
    }
    
    /// The type of the asset collection, such as an album or a moment.
    var ub_collectionType: CollectionType {
        return ref.ub_collectionType
    }
    /// The subtype of the asset collection.
    var ub_collectionSubtype: CollectionSubtype {
        return ref.ub_collectionSubtype
    }
    
    /// The number of assets in the asset collection.
    var ub_count: Int {
        return lazy(with: \Cacher._count, newValue: ref.ub_count)
    }
    /// The number of assets in the asset collection.
    func ub_count(with type: AssetType) -> Int {
        // The count is hit cache?
        if let count = _counts[type] {
            return count
        }
        
        // Get count for origin
        let count = ref.ub_count(with: type)
        _counts[type] = count
        return count
    }
    /// Retrieves assets from the specified asset collection.
    func ub_asset(at index: Int) -> Asset {
        // collection is cached?
        if let asset = _assets?[index] {
            return asset
        }
        
        // if there is no cache at once, initialize
        if _assets == nil {
            _assets = Array(repeating: nil, count: ub_count)
        }
        
        // fetch asset and bridging and cache
        let asset = Caching.warp(ref.ub_asset(at: index))
        _assets?[index] = asset
        return asset
    }
    
    /// The asset whether include is in this collection
    func ub_contains(_ asset: Asset) -> Bool {
        return ref.ub_contains(asset)
    }
    
    // MARK: -
    
    private var _title: String??
    private var _subtitle: String??
    private var _identifier: String?
    
    private var _count: Int?
    private var _counts: [AssetType: Int] = [:]
    
    private var _assets: [Asset?]?
}

extension Caching where T == Collection {
    
    static func unwarp<R>(_ value: R) -> R where R == T {
        if let value = value as? Cacher<R> {
            return value.ref
        }
        return value
    }

    static func warp<R>(_ value: R) -> R where R == T {
        if let value = value as? Cacher<R> {
            return value
        }
        return Cacher<R>(value)
    }
    
    
    static func unwarp<R>(_ value: R?) -> R? where R == T {
        if let value = value {
            return unwarp(value) as R
        }
        return value
    }
    
    static func warp<R>(_ value: R?) -> R? where R == T {
        if let value = value {
            return warp(value) as R
        }
        return value
    }
}

