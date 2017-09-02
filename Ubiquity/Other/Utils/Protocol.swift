//
//  Protocol.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


/// item rotation delegate
internal protocol DetailControllerItemRotationDelegate: class {
    
    /// item should rotation
    func detailController(_ detailController: Any, shouldBeginRotationing asset: Asset) -> Bool
    
    /// item did rotation
    func detailController(_ detailController: Any, didEndRotationing asset: Asset, at orientation: UIImageOrientation)
}

/// item update delegate
internal protocol DetailControllerItemUpdateDelegate: class {
    
    // item will show
    func detailController(_ detailController: Any, willShowItem indexPath: IndexPath)
    
    // item did show
    func detailController(_ detailController: Any, didShowItem indexPath: IndexPath)
}


// If controller implements the protocol, it will receive the change automatically
internal protocol SelectionStatusUpdateDelegate: class {
    
    func selectionStatus(_ selectionStatus: SelectionStatus, didSelectItem asset: Asset, sender: AnyObject)
    func selectionStatus(_ selectionStatus: SelectionStatus, didDeselectItem status: Asset, sender: AnyObject)
}


