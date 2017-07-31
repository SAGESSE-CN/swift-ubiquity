//
//  Picker.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// A media picker
public class Picker: Browser {
    
    /// Create a media picker
    public override init(library: Library) {
        super.init(library: library)
        
        // setup albums
        factory(with: .albums).flatMap {
            $0.cell = PickerAlbumCell.self
            $0.controller = PickerAlbumController.self
        }
    }
    
    func select(with asset: Asset) {
    }
    
    func deselect(with asset: Asset) {
    }
    
    func isSelected(with asset: Asset) -> Bool {
        return false
    }
    
}
