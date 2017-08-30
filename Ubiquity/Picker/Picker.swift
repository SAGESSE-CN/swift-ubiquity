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
    
    // MARK: Library Change
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    open override func library(_ library: Library, didChange change: Change) {
        super.library(library, didChange: change)
        
        // if event is ignoring, don't clear the selected item
        guard !isIgnoringChangeEvents else {
            return
        }
        
        // clear deleted items
        let deletedItems = _selectedItems.filter { !library.exists(forItem: $1.asset) }
        guard !deletedItems.isEmpty else {
            return
        }
        
        // There are UI update, which must be on the main thread
        DispatchQueue.main.async {
            // find the smallest one, and then update all index
            let numbers = deletedItems.map { key, value -> Int in
                // remove the item from select dequeue
                self._selectedItems.removeValue(forKey: key)
                
                // return current index
                return value.number
            }.sorted()
            
            // update selecting index
            self._selectedItems.forEach { key, value in
                // get the status number change
                let offset = numbers.index(where: { value.number < $0 }) ?? numbers.count
                guard offset > 0 else {
                    return
                }
                value.number -= offset
            }
        }
    }
    
    // MARK: Selection Item
    
    /// Select a item
    @discardableResult
    func selectItem(with asset: Asset, sender: Any) -> SelectionStatus? {
        // the asset has been selected?
        if let status = _selectedItems[asset.identifier] {
            return status
        }
        
        // generate a selection info
        let status = SelectionStatus(asset: asset, number: _selectedItems.count + 1)
        _selectedItems[asset.identifier] = status
        return status
    }
    
    /// Deselect a item
    @discardableResult
    func deselectItem(with asset: Asset, sender: Any) -> SelectionStatus? {
        // the asset has been selected?
        if let status = _selectedItems.removeValue(forKey: asset.identifier) {
            // the all number is smaller than the deleted item and needs to be updated 
            _selectedItems.forEach {
                // meet the conditions? 
                guard $1.number > status.number else {
                    return
                }
                $1.number -= 1
            }
        }
        return nil
    }
    
    /// Returns a item select status
    func statusOfItem(with asset: Asset) -> SelectionStatus? {
        return _selectedItems[asset.identifier]
    }
    
    
    // MARK: Ivar
    
    private lazy var _selectedItems: [String: SelectionStatus] = [:]
}
