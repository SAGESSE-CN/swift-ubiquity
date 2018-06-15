//
//  Selection.swift
//  Ubiquity
//
//  Created by sagesse on 2018/5/17.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import Foundation


internal enum Selection {
    /// Select all
    case all
    
    /// select a asset.
    case single(Asset)
    
    /// select multiple assets.
    case multiple(Array<Asset>)
    
    /// Select all asset in collection.
    case collection(Collection)
}

internal enum SelectionStyle {
    
    /// Don't display icon when selected.
    case none
    
    /// Only display image when selected.
    case image
    
    /// Only display number when selected items is calculatable.
    case number
    
    /// Display number when selected item less 100.
    /// Display image when selected item than 100 or items is incalculable.
    case auto
}

internal class SelectionController: Logport {
    
    internal weak var delegate: SelectionControllerDelegate?
    
    
    /// Returns the number of selected assets, count is invalid when assets is incalculable.
    internal var count: Int {
        return _selectedAssets.count
    }
    
    /// If select all asset or select some colleciton, the asset count is incalculable
    internal var incalculable: Bool {
        // If all collections selected, assets count is incalculable.
        guard !_selectingAll else {
            return true
        }
        
        // If has any collection selected, assets count is incalculable.
        guard _selectedCollections.isEmpty else {
            return true
        }
        
        return false
    }
    
    
    /// Returns whether the asset has been selected.
    internal func contains(_ asset: Asset) -> Bool {
        // Asset check priority: _selectedAssets > _deselectedAssets > _selectedCollections > _deselectedCollections > _selectingAll
        
        // User require selected this asset.
        if !_selectedAssets.isEmpty && _selectedAssets[asset.ub_identifier] != nil {
            return true
        }
        
        // User require deselected this asset.
        if !_deselectedAssets.isEmpty && _deselectedAssets[asset.ub_identifier] != nil {
            return false
        }
        
        // Infer the asset has been selected in selected collection.
        if _selectedCollections.contains(where: { $1.ub_contains(asset) }) {
            return true
        }
        
        // Infer the asset has been deselected in deselected collection.
        if _deselectedCollections.contains(where: { $1.ub_contains(asset) }) {
            return false
        }
        
        // If you select all, this asset is of course selected.
        return _selectingAll
    }
    
    /// Returns selection status with asset.
    internal func status(_ asset: Asset) -> SelectionItem2? {
        // Asset check priority: _selectedAssets > _deselectedAssets > _selectedCollections > _deselectedCollections > _selectingAll

        // User require selected this asset.
        if !_selectedAssets.isEmpty, let item = _selectedAssets[asset.ub_identifier] {
            return item
        }

        // User require deselected this asset.
        if !_deselectedAssets.isEmpty && _deselectedAssets[asset.ub_identifier] != nil {
            return nil
        }

        // Infer the asset has been selected in selected collection.
        if _selectedCollections.contains(where: { $1.ub_contains(asset) }) {
            // .. status in collection
            return nil
        }

        // Infer the asset has been deselected in deselected collection.
        if _deselectedCollections.contains(where: { $1.ub_contains(asset) }) {
            return nil
        }

        // If you select all, this asset is of course selected.
        if _selectingAll {
            // .. status in all
            return nil
        }
        
        return nil
    }
    
    
    /// Select some assets with selection.
    internal func select(_ selection: Selection) {
        // If you return to false, it means that the request is intercepted.
        guard delegate?.selectionController(self, shouldSelectItem: selection) ?? true else {
            return
        }
        
        _select(selection)
        _notify()
        
        // Callback delegate selected items is did change.
        delegate?.selectionController(self, didSelectItem: selection)
    }

    /// Deselect some assets with selection.
    internal func deselect(_ selection: Selection) {
        // If you return to false, it means that the request is intercepted.
        guard delegate?.selectionController(self, shouldDeselectItem: selection) ?? true else {
            return
        }

        _deselect(selection)
        _notify()
        
        // Callback delegate selected items is did change.
        delegate?.selectionController(self, didDeselectItem: selection)
    }
    
    
    // MARK: -
    
    private func _select(_ selection: Selection) {
        switch selection {
        case .all:
            // Selected all assets and collections.
            _selectingAll = true
            
            // There will be no single select.
            _selectedAssets.removeAll()
            _selectedCollections.removeAll()
            
            // There will be no single deselect.
            _deselectedAssets.removeAll()
            _deselectedCollections.removeAll()
            
        case .single(let asset):
            // If _deselectedAssets has been this asset must be remove.
            _deselectedAssets.removeValue(forKey: asset.ub_identifier)
            
            // If is selected all assets, all reselect will be ignore.
            if _selectingAll {
                logger.debug?.write("Ignore select asset \"\(asset.ub_identifier)\", because all assets is selected.")
                return 
            }
            
            // If the asset is inside of selected collection, ignore it.
            if _selectedCollections.values.contains(where: { $0.ub_identifier == asset.ub_collection?.ub_identifier }) {
                logger.debug?.write("Ignore select asset \"\(asset.ub_identifier)\", because asset inside of selected collection.")
                return
            }
            
            // If the asset has been selected, ignore it.
            if let item = _selectedAssets[asset.ub_identifier] {
                logger.debug?.write("Ignore select asset \"\(asset.ub_identifier)\", because the asset has been selected.")
                _ = item
                return //item
            }
            
            // If it is not contains in _selectedCollections, this is an additional asset.
            _selectedAssets[asset.ub_identifier] = .init(asset, index: _selectedAssets.count)
            
        case .multiple(let assets):
            // Execute multiple select, but do not notify
            for asset in assets {
                _select(.single(asset))
            }
            
        case .collection(let collection):
            // If _selectedAssets or _deselectedAssets has been asset in collection must be remove.
            _selectedAssets = _selectedAssets.ub_filter { $1.asset.ub_collection?.ub_identifier != collection.ub_identifier }
            _deselectedAssets = _deselectedAssets.ub_filter { $1.ub_collection?.ub_identifier != collection.ub_identifier }

            // If _deselectedCollections has been collection must be remove.
            _deselectedCollections.removeValue(forKey: collection.ub_identifier)
            
            // If is selected all assets, all reselect will be ignore.
            if _selectingAll {
                logger.debug?.write("Ignore select collection \"\(collection.ub_identifier)\", because all assets is selected.")
                return
            }
            
            // If the colleciton has been selected, ignore it.
            if _selectedCollections[collection.ub_identifier] != nil {
                logger.debug?.write("Ignore select collection \"\(collection.ub_identifier)\", because the collection has been selected.")
                return
            }
            
            // Select all assets in colleciton.
            _selectedCollections[collection.ub_identifier] = collection
        }
    }
    
    private func _deselect(_ selection: Selection) {
        switch selection {
        case .all:
            // Deselect all asset and collections.
            _selectingAll = false
            
            // There will be no single deselect.
            _selectedAssets.removeAll()
            _selectedCollections.removeAll()
            
            // There will be no single deselect.
            _deselectedAssets.removeAll()
            _deselectedCollections.removeAll()
            
        case .single(let asset):
            // If _selectedAssets has been this asset must be remove.
            _selectedAssets.removeValue(forKey: asset.ub_identifier)
            
            // If there is no selecting the collection, ignore it.
            if !_selectingAll && _selectedCollections.isEmpty {
                return
            }
            
            // If the asset is inside of deselected collection, ignore it.
            if _deselectedCollections.values.contains(where: { $0.ub_identifier == asset.ub_collection?.ub_identifier }) {
                logger.debug?.write("Ignore deselect asset \"\(asset.ub_identifier)\", because asset inside of deselected collection.")
                return
            }
            
            // If the asset has been deselected, ignore it.
            if _deselectedAssets[asset.ub_identifier] != nil {
                logger.debug?.write("Ignore deselect asset \"\(asset.ub_identifier)\", because the asset has been deselected.")
                return
            }
            
            // If it is not contains in _deselectedCollections, this is an additional asset.
            _deselectedAssets[asset.ub_identifier] = asset
            
        case .multiple(let assets):
            // Execute multiple deselect, but do not notify
            for asset in assets {
                _deselect(.single(asset))
            }
            
        case .collection(let collection):
            // If _selectedAssets or _deselectedAssets has been asset in collection must be remove.
            _selectedAssets = _selectedAssets.ub_filter { $1.asset.ub_collection?.ub_identifier != collection.ub_identifier }
            _deselectedAssets = _deselectedAssets.ub_filter { $1.ub_collection?.ub_identifier != collection.ub_identifier }

            // If _selectedCollections has been collection must be remove.
            _selectedCollections.removeValue(forKey: collection.ub_identifier)
        
            // If you do not selected all asset, not need to use _deselectedCollections to deselect.
            if !_selectingAll {
                logger.debug?.write("Ignore deselect collection \"\(collection.ub_identifier)\", because does not have any assets selected.")
                return
            }
            
            // If the colleciton has been deselected, ignore it.
            if _deselectedCollections[collection.ub_identifier] != nil {
                logger.debug?.write("Ignore deselect collection \"\(collection.ub_identifier)\", because the collection has been deselected.")
                return
            }
            
            // Deselect all assets in colleciton.
            _deselectedCollections[collection.ub_identifier] = collection
        }
    }
    
    private func _notify() {
    }
    
    /// Indicates whether all collections has been selected.
    private var _selectingAll: Bool = false
    
    /// The current selected all assets of non-collection.
    private var _selectedAssets: Dictionary<String, SelectionItem2> = [:]
    /// The current selected all collecitons.
    private var _selectedCollections: Dictionary<String, Collection> = [:]
    
    /// The current selected all assets of non-collection.
    private var _deselectedAssets: Dictionary<String, Asset> = [:]
    /// The current selected all collecitons.
    private var _deselectedCollections: Dictionary<String, Collection> = [:]
}

internal protocol SelectionControllerDelegate: class {
    
    func selectionController(_ selectionController: SelectionController, shouldSelectItem selection: Selection) -> Bool
    func selectionController(_ selectionController: SelectionController, didSelectItem selection: Selection)
    
    func selectionController(_ selectionController: SelectionController, shouldDeselectItem selection: Selection) -> Bool
    func selectionController(_ selectionController: SelectionController, didDeselectItem selection: Selection)
}


