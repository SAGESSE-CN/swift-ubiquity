//
//  Caching+CollectionList.swift
//  Ubiquity
//
//  Created by sagesse on 2018/5/18.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import Foundation


/// The abstract superclass for Photos asset collection lists.
private class Cacher<T>: Caching<CollectionList>, CollectionList  {
    
    /// The localized title of the collection list.
    var ub_title: String? {
        return lazy(with: \Cacher._title, newValue: ref.ub_title)
    }
    /// The localized subtitle of the collection list.
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
    
    /// The number of collection in the collection list.
    var ub_count: Int {
        return lazy(with: \Cacher._count, newValue: ref.ub_count)
    }
    /// Retrieves collection from the specified collection list.
    func ub_collection(at index: Int) -> Collection {
        // collection is cached?
        if let collection = _colltions?[index] {
            return collection
        }
        
        // if there is no cache at once, initialize
        if _colltions == nil {
            _colltions = Array(repeating: nil, count: ub_count)
        }
        
        // fetch collection and bridging and cache
        let collection = Caching.warp(ref.ub_collection(at: index))
        _colltions?[index] = collection
        return collection
    }
    
    // MARK: -
    
    private var _title: String??
    private var _subtitle: String??
    private var _identifier: String?
    
    private var _count: Int?
    private var _colltions: [Collection?]?
}

extension Caching where T == CollectionList {
    
    static func unwarp(_ value: CollectionList) -> CollectionList {
        if let value = value as? Cacher<CollectionList> {
            return value.ref
        }
        return value
    }

    static func warp(_ value: CollectionList) -> CollectionList {
        if let value = value as? Cacher<CollectionList> {
            return value
        }
        return Cacher<CollectionList>(value)
    }
}

