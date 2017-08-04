//
//  BrowserAlbumView.swift
//  Ubiquity
//
//  Created by sagesse on 04/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumView: UICollectionView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // the hit in this view?
        guard let view = super.hitTest(point, with: event) else {
            return nil
        }
        
        // extra check, first subview
        guard let subview = subviews.first as? BrowserAlbumHeader else {
            return view
        }
        
        // hit to header view?
        return subview.hitTest(convert(point, to: subview), with: event) ?? view
    }
}
