//
//  Asset.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// Constants identifying the general type of an asset, such as image or video.
@objc
public enum AssetType: Int, CustomStringConvertible {
    
    /// The asset’s type is unknown.
    case unknown = 0
    
    /// The asset is a photo or other static image.
    case image = 1
    
    /// The asset is a video file.
    case video = 2
    
    /// The asset is an audio file.
    case audio = 3

    
    /// A textual representation of this instance.
    public var description: String {
        switch self {
        case .image:   return "image"
        case .audio:   return "audio"
        case .video:   return "video"
        case .unknown: return "unknown"
        }
    }
}

/// Constants identifying specific variations of asset media, such as panorama or screenshot photos and time lapse or high frame rate video.
public struct AssetSubtype: OptionSet {
    
    // Photo subtypes
    
    /// The asset is a large-format panorama photo.
    public static var photoPanorama: AssetSubtype      = .init(rawValue: 1 << 0)
    /// The asset is a High Dynamic Range photo.
    public static var photoHDR: AssetSubtype           = .init(rawValue: 1 << 1)
    /// The asset is an image captured with the device’s screenshot feature.
    public static var photoScreenshot: AssetSubtype    = .init(rawValue: 1 << 2)
    /// The asset is a Graphics Interchange Format photo.
    public static var photoGIF: AssetSubtype           = .init(rawValue: 1 << 3)
    
    // Video subtypes
    
    /// The asset is a video whose contents are always streamed over a network connection.
    public static var videoStreamed: AssetSubtype      = .init(rawValue: 1 << 16)
    /// The asset is a high-frame-rate video.
    public static var videoHighFrameRate: AssetSubtype = .init(rawValue: 1 << 17)
    /// The asset is a time-lapse video.
    public static var videoTimelapse: AssetSubtype     = .init(rawValue: 1 << 18)
    
    /// The element type of the option set.
    public let rawValue: UInt
    
    /// Creates a new option set from the given raw value.
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

/// A representation of an image, video
@objc
public protocol Asset: class {
    
    /// The localized title of the asset.
    var ub_title: String? { get }
    /// The localized subtitle of the asset.
    var ub_subtitle: String? { get }
    /// A unique string that persistently identifies the object.
    var ub_identifier: String { get }
    
    /// The version of the asset, identifying asset change.
    var ub_version: Int { get }
    
    /// The width, in pixels, of the asset’s image or video data.
    var ub_pixelWidth: Int { get }
    /// The height, in pixels, of the asset’s image or video data.
    var ub_pixelHeight: Int { get }
    
    /// The duration, in seconds, of the video asset.
    /// For photo assets, the duration is always zero.
    var ub_duration: TimeInterval { get }
    
    /// The asset allows play operation
    var ub_allowsPlay: Bool { get }
    
    /// The type of the asset, such as video or audio.
    var ub_type: AssetType { get }
    /// The subtypes of the asset, an option of type `AssetSubtype`
    var ub_subtype: UInt { get }
}


