//
//  Picker.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// Picker delegate events
@objc public protocol PickerDelegate: class {
    
    // Check whether item can select
    @objc optional func picker(_ picker: Picker, shouldSelectItem asset: Asset) -> Bool
    @objc optional func picker(_ picker: Picker, didSelectItem asset: Asset)
    @objc optional func picker(_ picker: Picker, didDeselectItem asset: Asset)
}

/// A media picker
@objc open class Picker: Browser {
    
    /// Create a media picker
    public override init(library: Library) {
        super.init(library: library)
        
        // Setup albums
        factory(with: .albums).configure {
            $0.setClass(PickerAlbumCell.self, for: .cell)
            $0.setClass(PickerAlbumController.self, for: .controller)
        }
        
        // Setup details
        factory(with: .detail).configure {
            $0.setClass(PickerDetailCell.self, for: .cell)
            $0.setClass(PickerDetailController.self, for: .controller)
        }
        
        // Setup popover
        factory(with: .popover).configure {
            $0.setClass(PickerPreviewCell.self, for: .cell)
            $0.setClass(PickerPreviewController.self, for: .controller)
        }
    }
    
    /// The picker delegate
    open weak var delegate: PickerDelegate?
    
    /// default is YES. Controls whether a asset can be selected
    open var allowsSelection: Bool = true {
        didSet {
            guard oldValue != allowsSelection else {
                return
            }
            // tell all observers in options did change
            _forEach(ContainerOptionsDelegate.self) {
                $0.ub_container(self, options: "allowsSelection", didChange: allowsSelection)
            }
        }
    }
    
    open var allowsSelectionGestureRecognizer: Bool = true

    /// default is YES. Controls whether multiple assets can be selected simultaneously
    open var allowsMultipleSelection: Bool = true {
        didSet {
            guard oldValue != allowsMultipleSelection else {
                return
            }
            // tell all observers in options did change
            _forEach(ContainerOptionsDelegate.self) {
                $0.ub_container(self, options: "allowsMultipleSelection", didChange: allowsMultipleSelection)
            }
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
        let deletedItems = _selectedItems.filter { !library.ub_exists(forItem: $1.asset) }
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
    
    
//    /// Select items with selection.
//    func select(_ selection: Selection, animated: Bool) {
//    }
//    
//    /// Deselect items with selection.
//    func deselect(_ selection: Selection, animated: Bool) {
//    }
    
    /// Select a item
    @discardableResult
    func selectItem(with asset: Asset, sender: AnyObject) -> SelectionStatus? {
        // the asset has been selected?
        if let status = _selectedItems[asset.ub_identifier] {
            return status
        }
        
        // generate a selection info
        let status = SelectionStatus(asset: asset, number: _selectedItems.count + 1)
        
        // ask the library the asset is allowed to be select?
        guard _item(shouldSelectItem: asset, status: status, sender: sender) else {
            return nil
        }
        
        // add to selection
        _selectedItems[asset.ub_identifier] = status
        
        // notify all observers
        _item(didSelectItem: asset, status: status, sender: sender)
        
        return status
    }
    
    /// Deselect a item
    @discardableResult
    func deselectItem(with asset: Asset, sender: AnyObject) -> SelectionStatus? {
        // the asset has been selected?
        if let status = _selectedItems.removeValue(forKey: asset.ub_identifier) {
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
        if !_selectedItems.isEmpty  {
            return _selectedItems[asset.ub_identifier]
        }
        return nil
    }
    
    
    private func _item(shouldSelectItem asset: Asset, status: SelectionStatus, sender: AnyObject) -> Bool {
        // ask the user if the asset is allowed to be select
        return delegate?.picker?(self, shouldSelectItem: asset) ?? true
    }
    private func _item(didSelectItem asset: Asset, status: SelectionStatus, sender: AnyObject) {
        
        // tell the user that the asset is already selected
        delegate?.picker?(self, didSelectItem: asset)
        
        // tell all observers
        _forEach(SelectionStatusUpdateDelegate.self) {
            $0.selectionStatus(status, didSelectItem: asset, sender: sender)
        }
    }
    private func _item(didDeselect asset: Asset, status: SelectionStatus, sender: AnyObject) {
        
        // tell the user that the asset is already selected
        delegate?.picker?(self, didDeselectItem: asset)
        
        // tell all observers
        _forEach(SelectionStatusUpdateDelegate.self) {
            $0.selectionStatus(status, didDeselectItem: asset, sender: sender)
        }
    }
    
    private func _forEach<T>(_ _: T.Type, _ body: (T) -> Void) {
        observers.forEach {
            ($0 as? T).map(body)
        }
    }
    
    // MARK: Ivar
    
    private lazy var _selectedItems: [String: SelectionStatus] = [:]
}
