//
//  PickerPreviewController.swift
//  Ubiquity
//
//  Created by sagesse on 22/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerPreviewController: BrowserPreviewController {
    
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        // forword change event to visable cells
        collectionView?.visibleCells.forEach {
            // only process `PickerPreviewCell`
            guard let cell = $0 as? PickerPreviewCell else {
                return
            }
            cell.contentOffsetDidChange()
        }
    }
    
}
