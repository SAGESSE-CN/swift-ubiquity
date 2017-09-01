//
//  PickerDetailController.swift
//  Ubiquity
//
//  Created by sagesse on 30/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerDetailController: BrowserDetailController, SelectionStatusUpdateDelegate {

    override func loadView() {
        super.loadView()
        
        // setup selection view
        _selectedView.addTarget(self, action: #selector(_select(_:)), for: .touchUpInside)
        
        // setup right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: _selectedView)
    }
    
    // MARK: Item change
    
    override func detailController(_ detailController: Any, didShowItem indexPath: IndexPath) {
        super.detailController(detailController, didShowItem: indexPath)
        
        // fetch current displayed asset item
        guard let asset = displayedItem else {
            return
        }
        
        // update current asset selection status
        _selectedView.setStatus((container as? Picker)?.statusOfItem(with: asset), animated: true)
    }
    
    // MARK: Selection change
    
    
    func selectionStatus(_ selectionStatus: SelectionStatus, didSelectItem asset: Asset, sender: AnyObject) {
        // ignore the events that itself sent
        // ignores events other than the currently displayed asset 
        guard sender !== self, asset.identifier == displayedItem?.identifier else {
            return
        }
        logger.debug?.write()
        
        // update selection status
        _selectedView.status = selectionStatus
    }
    
    func selectionStatus(_ selectionStatus: SelectionStatus, didDeselectItem asset: Asset, sender: AnyObject) {
        // ignore the events that itself sent
        // ignores events other than the currently displayed asset 
        guard sender !== self, asset.identifier == displayedItem?.identifier else {
            return
        }
        logger.debug?.write()
        
        // clear selection status
        _selectedView.status = nil
    }
    
    // MARK: Events
    
    // select or deselect item
    private dynamic func _select(_ sender: Any) {
        // fetch current displayed asset item
        guard let asset = displayedItem else {
            return
        }
        
        // check old status
        if _selectedView.status == nil {
            // select asset
            _selectedView.status = (container as? Picker)?.selectItem(with: asset, sender: self)
            
        } else {
            // deselect asset
            _selectedView.status = (container as? Picker)?.deselectItem(with: asset, sender: self)
            
        }
        
        // add animation
        let ani = CAKeyframeAnimation(keyPath: "transform.scale")
        
        ani.values = [0.8, 1.2, 1]
        ani.duration = 0.25
        ani.calculationMode = kCAAnimationCubic
        
        _selectedView.layer.add(ani, forKey: "selected")
    }
    
    // selection view
    private lazy var _selectedView: SelectionStatusView = .init(frame: .init(x: 0, y: 0, width: 24, height: 24))
}
