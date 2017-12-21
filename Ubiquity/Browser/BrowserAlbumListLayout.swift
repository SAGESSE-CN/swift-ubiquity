//
//  BrowserAlbumListLayout.swift
//  Ubiquity
//
//  Created by sagesse on 21/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumListLayout: UICollectionViewFlowLayout {

    override func prepare() {
        self.collectionView.map {
            self.itemSize = .init(width: $0.frame.width / 2, height: 88)
            
            self.minimumLineSpacing = 0
            self.minimumInteritemSpacing = 0
        }
        super.prepare()
    }
}
