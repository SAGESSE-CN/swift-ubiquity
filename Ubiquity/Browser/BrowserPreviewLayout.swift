//
//  BrowserPreviewLayout.swift
//  Ubiquity
//
//  Created by SAGESSE on 11/22/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserPreviewLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        self.scrollDirection = .horizontal
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepare() {
        self.collectionView.map {
            self.estimatedItemSize = .init(width: $0.frame.height, height: $0.frame.height)
        }
        super.prepare()
    }
}
