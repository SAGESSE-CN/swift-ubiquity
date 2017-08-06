//
//  Asset.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// A representation of an image, video
public protocol Asset: class {
    
    /// The localized title of the asset.
    var title: String? { get }
    /// The localized subtitle of the asset.
    var subtitle: String? { get }
    
    /// A unique string that persistently identifies the object.
    var identifier: String { get }
    
    /// The version of the asset, identifying asset change.
    var version: Int { get }
    
    /// The width, in pixels, of the asset’s image or video data.
    var pixelWidth: Int { get }
    /// The height, in pixels, of the asset’s image or video data.
    var pixelHeight: Int { get }
    
    /// The duration, in seconds, of the video asset.
    /// For photo assets, the duration is always zero.
    var duration: TimeInterval { get }
    
    /// The asset allows play operation
    var allowsPlay: Bool { get }
    
    /// The type of the asset, such as video or audio.
    var mediaType: AssetMediaType { get }
    /// The subtypes of the asset, identifying special kinds of assets such as panoramic photo or high-framerate video.
    var mediaSubtypes: AssetMediaSubtype { get }
}

/// Constants identifying the general type of an asset, such as image or video.
public enum AssetMediaType: Int {
    
    /// The asset’s type is unknown.
    case unknown = 0
    
    /// The asset is a photo or other static image.
    case image = 1
    
    /// The asset is a video file.
    case video = 2
    
    /// The asset is an audio file.
    case audio = 3
}

/// Constants identifying specific variations of asset media, such as panorama or screenshot photos and time lapse or high frame rate video.
public struct AssetMediaSubtype: OptionSet {
    
    // Photo subtypes
    
    /// The asset is a large-format panorama photo.
    public static var photoPanorama: AssetMediaSubtype      = .init(rawValue: 1 << 0)
    /// The asset is a High Dynamic Range photo.
    public static var photoHDR: AssetMediaSubtype           = .init(rawValue: 1 << 1)
    /// The asset is an image captured with the device’s screenshot feature.
    public static var photoScreenshot: AssetMediaSubtype    = .init(rawValue: 1 << 2)
    
    // Video subtypes
    
    /// The asset is a video whose contents are always streamed over a network connection.
    public static var videoStreamed: AssetMediaSubtype      = .init(rawValue: 1 << 16)
    /// The asset is a high-frame-rate video.
    public static var videoHighFrameRate: AssetMediaSubtype = .init(rawValue: 1 << 17)
    /// The asset is a time-lapse video.
    public static var videoTimelapse: AssetMediaSubtype     = .init(rawValue: 1 << 18)
    
    /// The element type of the option set.
    public let rawValue: UInt
    
    /// Creates a new option set from the given raw value.
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}
