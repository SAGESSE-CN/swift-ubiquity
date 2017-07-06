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
internal extension BadgeView.Item {
    // create item with collection sub type
    static func ub_init(subtype: CollectionSubtype) -> BadgeView.Item? {
        // check the collection sub type
        switch subtype {
            
        case .smartAlbumBursts: return .burst
        case .smartAlbumPanoramas: return .panorama
        case .smartAlbumScreenshots: return .screenshots
            
        case .smartAlbumSlomoVideos: return .slomo
        case .smartAlbumTimelapses: return .timelapse
        case .smartAlbumVideos: return .video
            
        case .smartAlbumSelfPortraits: return .selfies
        case .smartAlbumFavorites: return .favorites
            
        case .smartAlbumRecentlyAdded: return .recently
            
        case .smartAlbumGeneric: return nil
        case .smartAlbumAllHidden: return nil
        case .smartAlbumUserLibrary: return nil
        }
    }
}

