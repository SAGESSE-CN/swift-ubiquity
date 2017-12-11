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
}
