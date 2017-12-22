//
//  Ubiquity.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 sagesse. All rights reserved.
//

import UIKit
import AVFoundation


/// Provide the collection icons support
internal extension BadgeItem {
    
    
    static let downloading  = __badgeItem(named: "ubiquity_badge_downloading", render: .alwaysOriginal)
    
    static let burst        = __badgeItem(named: "ubiquity_badge_burst")
    static let favorites    = __badgeItem(named: "ubiquity_badge_favorites")
    static let panorama     = __badgeItem(named: "ubiquity_badge_panorama")
    static let screenshots  = __badgeItem(named: "ubiquity_badge_screenshots")
    static let selfies      = __badgeItem(named: "ubiquity_badge_selfies")
    static let slomo        = __badgeItem(named: "ubiquity_badge_slomo")
    static let timelapse    = __badgeItem(named: "ubiquity_badge_timelapse")
    static let video        = __badgeItem(named: "ubiquity_badge_video")
    
    static let recently     = __badgeItem(named: "ubiquity_badge_recently")
    static let lastImport   = __badgeItem(named: "ubiquity_badge_lastImport")


    // create item with collection sub type
    internal init?(subtype: CollectionSubtype) {
        switch subtype {
            
        case .smartAlbumBursts: self = .burst
        case .smartAlbumPanoramas: self = .panorama
        case .smartAlbumScreenshots: self = .screenshots
            
        case .smartAlbumSlomoVideos: self = .slomo
        case .smartAlbumTimelapses: self = .timelapse
        case .smartAlbumVideos: self = .video
            
        case .smartAlbumSelfPortraits: self = .selfies
        case .smartAlbumFavorites: self = .favorites
            
        case .smartAlbumRecentlyAdded: return nil
            
        case .smartAlbumGeneric: return nil
        case .smartAlbumAllHidden: return nil
        case .smartAlbumUserLibrary: return nil
        }
    }
}

/// Make a system badge items
private func __badgeItem(named: String, render: UIImageRenderingMode = .alwaysTemplate) -> BadgeItem {
    let icon = ub_image(named: named)?.withRenderingMode(render)
    icon?.accessibilityIdentifier = named
    return .image(icon)
}


internal func ub_reuseIdentifier(with asset: Asset?) -> String {
    return ub_identifier(with: asset?.ub_type ?? .unknown)
}


internal func ub_makeEmptyAlbum(_ size: CGSize) -> UIImage? {

    UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)

    let tintColor = UIColor.ub_init(hex: 0xb4b3b9)
    let backgroundColor = UIColor.ub_init(hex: 0xF0EFF5)
    
    // set the background color
    backgroundColor.setFill()
    UIRectFill(.init(origin: .zero, size: size))
    
    // draw icon
    if let image = R.image("ubiquity_icon_empty_album") {
        // generate tint image with tint color
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        
        tintColor.setFill()
        context?.fill(.init(origin: .zero, size: image.size))
        image.draw(at: .zero, blendMode: .destinationIn, alpha: 1)
        
        let image2 = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // draw to main context
        image2?.draw(at: .init(x: size.width / 2 - image.size.width / 2, y: size.height / 2 - image.size.height / 2))
    }

    let image = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    return image
}


