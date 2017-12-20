//
//  BrowserPreviewCell.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/4/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserPreviewCell: BrowserAlbumCell {
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let newLayoutAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        asset.map {
            let width = CGFloat($0.ub_pixelWidth)
            let height = CGFloat($0.ub_pixelHeight)
            let scale = layoutAttributes.bounds.height / max(height, 1)

            newLayoutAttributes.bounds.size.width = width * scale
        }
        return newLayoutAttributes
    }
}
