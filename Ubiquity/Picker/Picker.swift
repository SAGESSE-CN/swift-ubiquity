//
//  Picker.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// A media picker
public class Picker: Container {
    
    /// Create a media picker
    public override init(library: Library) {
        super.init(library: library)
        
        // update factory
        self.factorys = [
            .edit: .init(controller: BrowserDetailController.self, cell: BrowserDetailCell.self, contents: ub_defaultContentClasses(with: .edit)),
            .album: .init(controller: PickerAlbumController.self, cell: PickerAlbumCell.self, contents: ub_defaultContentClasses(with: .album)),
            .detail: .init(controller: BrowserDetailController.self, cell: BrowserDetailCell.self, contents: ub_defaultContentClasses(with: .detail)),
        ]
    }
    
    func select(with asset: Asset) {
    }
    func deselect(with asset: Asset) {
    }
    func isSelected(with asset: Asset) -> Bool {
        return false
    }
}
