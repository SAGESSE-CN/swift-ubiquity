//
//  Utils.swift
//  Ubiquity
//
//  Created by sagesse on 12/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


internal func ub_string(for number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.positiveFormat = "###,##0"
    return formatter.string(for: number) ?? "\(number)"
}

internal func ub_identifier(with media: AssetMediaType) -> String {
    switch media {
    case .image:   return "ASSET-IMAGE"
    case .audio:   return "ASSET-AUDIO"
    case .video:   return "ASSET-VIDEO"
    case .unknown: return "ASSET-UNKNOWN"
    }
}

internal func ub_defaultContentClasses(with page: Page) -> Dictionary<AssetMediaType, AnyClass> {
    switch page {
    case .album:
        return [.image: UIImageView.self,
                .audio: UIImageView.self,
                .video: UIImageView.self,
                .unknown: UIImageView.self]
        
    case .detail:
        return [.image: PhotoContentView.self,
                .audio: PhotoContentView.self,
                .video: VideoContentView.self,
                .unknown: PhotoContentView.self]
        
    case .edit:
        return [.image: PhotoContentView.self,
                .audio: PhotoContentView.self,
                .video: VideoContentView.self,
                .unknown: PhotoContentView.self]
    }
}

internal func ub_image(named: String) -> UIImage? {
    return UIImage(named: named, in: _bundle, compatibleWith: nil)
}

private weak var _bundle: Bundle? = Bundle(for: Container.self)
