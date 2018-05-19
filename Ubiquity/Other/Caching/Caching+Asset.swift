//
//  Caching+Asset.swift
//  Ubiquity
//
//  Created by sagesse on 2018/5/18.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import Foundation

/// A representation of an image, video
private class Cacher<T>: Caching<Asset>, Asset  {
    
    /// The localized title of the asset.
    var ub_title: String? {
        return lazy(with: \Cacher._title, newValue: ref.ub_title)
    }
    /// The localized subtitle of the asset.
    var ub_subtitle: String? {
        return lazy(with: \Cacher._subtitle, newValue: ref.ub_subtitle)
    }
    /// A unique string that persistently identifies the object.
    var ub_identifier: String {
        return lazy(with: \Cacher._identifier, newValue: ref.ub_identifier)
    }
    
    /// The version of the asset, identifying asset change.
    var ub_version: Int {
        return ref.ub_version
    }
    
    /// The width, in pixels, of the asset’s image or video data.
    var ub_pixelWidth: Int {
        return ref.ub_pixelWidth
    }
    /// The height, in pixels, of the asset’s image or video data.
    var ub_pixelHeight: Int {
        return ref.ub_pixelHeight
    }
    
    /// The duration, in seconds, of the video asset.
    /// For photo assets, the duration is always zero.
    var ub_duration: TimeInterval {
        return ref.ub_duration
    }
    
    /// The asset allows play operation
    var ub_allowsPlay: Bool {
        return ref.ub_allowsPlay
    }
    
    /// The type of the asset, such as video or audio.
    var ub_type: AssetType {
        return lazy(with: \Cacher._type, newValue: ref.ub_type)
    }
    /// The subtypes of the asset, an option of type `AssetSubtype`
    var ub_subtype: AssetSubtype {
        return lazy(with: \Cacher._subtype, newValue: ref.ub_subtype)
    }
    
    /// The collection in which asset is located.
    var ub_collection: Collection? {
        set { return _collection = newValue }
        get { return _collection }
    }
    
    // MARK: -
    
    private var _title: String??
    private var _subtitle: String??
    private var _identifier: String?
    
    private var _type: AssetType?
    private var _subtype: AssetSubtype?
    
    private weak var _collection: Collection?
}

extension Caching where T == Asset {
    
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



