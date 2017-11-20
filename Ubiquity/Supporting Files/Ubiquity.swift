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
    
    
    static let downloading  = __ub_badgeItem(named: "ubiquity_badge_downloading", render: .alwaysOriginal)
    
    static let burst        = __ub_badgeItem(named: "ubiquity_badge_burst")
    static let favorites    = __ub_badgeItem(named: "ubiquity_badge_favorites")
    static let panorama     = __ub_badgeItem(named: "ubiquity_badge_panorama")
    static let screenshots  = __ub_badgeItem(named: "ubiquity_badge_screenshots")
    static let selfies      = __ub_badgeItem(named: "ubiquity_badge_selfies")
    static let slomo        = __ub_badgeItem(named: "ubiquity_badge_slomo")
    static let timelapse    = __ub_badgeItem(named: "ubiquity_badge_timelapse")
    static let video        = __ub_badgeItem(named: "ubiquity_badge_video")
    
    static let recently     = __ub_badgeItem(named: "ubiquity_badge_recently")
    static let lastImport   = __ub_badgeItem(named: "ubiquity_badge_lastImport")


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
private func __ub_badgeItem(named: String, render: UIImageRenderingMode = .alwaysTemplate) -> BadgeItem {
    let icon = ub_image(named: named)?.withRenderingMode(render)
    return .image(icon)
}
