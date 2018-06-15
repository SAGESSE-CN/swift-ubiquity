//
//  PickerPreviewCell.swift
//  Ubiquity
//
//  Created by sagesse on 22/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerPreviewCell: PickerAlbumCell {
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // bounds is change, update layout
        contentOffsetDidChange()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        // superview is change, update layout
        contentOffsetDidChange()
    }
    
    func contentOffsetDidChange() {
        // if superview is empty, update layout after waiting for `willMove(toSuperview:)`
        guard let superview = superview else {
            return
        }
        
        let nbounds = UIEdgeInsetsInsetRect(superview.bounds, contentInset)
        let nframe = UIEdgeInsetsInsetRect(frame, contentInset)
        
        let x = max(nframe.minX, min(nbounds.maxX, nframe.maxX) - selectionItemView.frame.width)
        let y = min(max(nframe.minY, nbounds.minY), nbounds.maxY - selectionItemView.frame.height)
     
        let origin = convert(.init(x: x, y: y), from: superview)
        
        // has the position changed?
        if selectionItemView.frame.origin != origin {
            selectionItemView.frame.origin = origin
        }
    }
}
