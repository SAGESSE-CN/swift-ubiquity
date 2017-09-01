//
//  Picker.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// Picker delegate events
public protocol PickerDelegate: class {
    
    // Check whether item can select
    func picker(_ picker: Picker, shouldSelectItem asset: Asset) -> Bool
    func picker(_ picker: Picker, didSelectItem asset: Asset)
    func picker(_ picker: Picker, didDeselectItem asset: Asset)
}

public extension PickerDelegate {
    
    func picker(_ picker: Picker, shouldSelectItem asset: Asset) -> Bool {
        return true
    }
    
    func picker(_ picker: Picker, didSelectItem asset: Asset) {
    }
    
    func picker(_ picker: Picker, didDeselectItem asset: Asset) {
    }
}

/// A media picker
open class Picker: Browser {
    
    /// Create a media picker
    public override init(library: Library) {
        super.init(library: library)
        
        // setup albums
        register(PickerAlbumCell.self, forCell: .albums)
        register(PickerAlbumController.self, forController: .albums)
        
        // setup details
        register(PickerDetailCell.self, forCell: .detail)
        register(PickerDetailController.self, forController: .detail)
    }
    
    /// The picker delegate
    open weak var delegate: PickerDelegate?
    
    
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
            
            // notify all observers
            deletedItems.forEach {
                self._item(didDeselect: $1.asset, status: $1, sender: library as AnyObject)
            }
        }
    }
    
    // MARK: Selection Item
    
    /// Select a item
    @discardableResult
    func selectItem(with asset: Asset, sender: AnyObject) -> SelectionStatus? {
        // the asset has been selected?
        if let status = _selectedItems[asset.identifier] {
            return status
        }
        
        // generate a selection info
        let status = SelectionStatus(asset: asset, number: _selectedItems.count + 1)
        
        // ask the library the asset is allowed to be select?
        guard _item(shouldSelectItem: asset, status: status, sender: sender) else {
            return nil
        }
        
        // add to selection
        _selectedItems[asset.identifier] = status
        
        // notify all observers
        _item(didSelectItem: asset, status: status, sender: sender)
        
        return status
    }
    
    /// Deselect a item
    @discardableResult
    func deselectItem(with asset: Asset, sender: AnyObject) -> SelectionStatus? {
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
            
            // notify all observers
            _item(didDeselect: asset, status: status, sender: sender)
        }
        return nil
    }
    
    /// Returns a item select status
    func statusOfItem(with asset: Asset) -> SelectionStatus? {
        return _selectedItems[asset.identifier]
    }
    
    
    private func _item(shouldSelectItem asset: Asset, status: SelectionStatus, sender: AnyObject) -> Bool {
        // ask the user if the asset is allowed to be select
        return delegate?.picker(self, shouldSelectItem: asset) ?? true
    }
    private func _item(didSelectItem asset: Asset, status: SelectionStatus, sender: AnyObject) {
        
        // tell the user that the asset is already selected
        delegate?.picker(self, didSelectItem: asset)
        
        // tell all observers
        observers.forEach {
            ($0 as? SelectionStatusUpdateDelegate)?.selectionStatus(status, didSelectItem: asset, sender: sender)
        }
    }
    private func _item(didDeselect asset: Asset, status: SelectionStatus, sender: AnyObject) {
        
        // tell the user that the asset is already selected
        delegate?.picker(self, didDeselectItem: asset)
        
        // tell all observers
        observers.forEach {
            ($0 as? SelectionStatusUpdateDelegate)?.selectionStatus(status, didDeselectItem: asset, sender: sender)
        }
    }
    
    // MARK: Ivar
    
    private lazy var _selectedItems: [String: SelectionStatus] = [:]
}
