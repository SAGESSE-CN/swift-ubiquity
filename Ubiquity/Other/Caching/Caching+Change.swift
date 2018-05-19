//
//  Caching+Change.swift
//  Ubiquity
//
//  Created by sagesse on 2018/5/18.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import Foundation

/// A change info
private class Cacher<T>: Caching<Change>, Change  {

    /// Returns detailed change information for the specified collection.
    public func ub_changeDetails(_ change: Change, collection: Collection) -> ChangeDetails? {
        // Hit collection cache?
        if let details = _collectionCaches[collection.ub_identifier] {
            return details
        }
        
        // Make change details and cache
        let details = ref.ub_changeDetails(change, collection: Caching.unwarp(collection))
        _collectionCaches[collection.ub_identifier] = details
        return details
    }

    /// Returns detailed change information for the specified colleciotn list.
    public func ub_changeDetails(_ change: Change, collectionList: CollectionList) -> ChangeDetails? {
        // Hit collection cache?
        if let details = _collectionListCaches[collectionList.ub_collectionType] {
            return details
        }
        
        // Make change details and cache
        let details = ref.ub_changeDetails(change, collectionList: Caching.unwarp(collectionList))
        _collectionListCaches[collectionList.ub_collectionType] = details
        return details
    }
    
    // MARK: -
    
    private var _collectionCaches: Dictionary<String, ChangeDetails?> = [:]
    private var _collectionListCaches: Dictionary<CollectionType, ChangeDetails?> = [:]
}

extension Caching where T == Change {
    
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



