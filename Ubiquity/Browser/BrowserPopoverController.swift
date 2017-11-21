//
//  BrowserPopoverController.swift
//  Ubiquity
//
//  Created by sagesse on 21/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserPopoverController: SourceController, Controller, UICollectionViewDelegateFlowLayout {
    
    required init(container: Container, source: Source, sender: Any?) {
        super.init(container: container, source: source, factory: container.factory(with: .popover))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        // the collectionView must king of `BrowserAlbumView`
        object_setClass(collectionView, BrowserAlbumView.self)
        
        collectionView?.alwaysBounceHorizontal = true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let asset = source.asset(at: indexPath) else {
            return .zero
        }
        
        let width = CGFloat(asset.ub_pixelWidth)
        let height = CGFloat(asset.ub_pixelHeight)
        let scale = view.frame.height / max(height, 1)
        
        return CGSize(width: width * scale, height: view.frame.height)
    }
}
