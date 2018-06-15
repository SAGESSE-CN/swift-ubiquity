//
//  PickerAlbumCell.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerAlbumCell: BrowserAlbumCell, ContainerOptionsDelegate {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _configure()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // check responser for super
        guard let view = super.hitTest(point, with: event) else {
            return nil
        }
        
        // extend response region
        guard !selectionItemView.isHidden, view === contentView, UIEdgeInsetsInsetRect(selectionItemView.frame, UIEdgeInsetsMake(-8, -8, -8, -8)).contains(point) else {
            return view
        }
        
        return selectionItemView
    }
    
    /// Update selection status for animate
    func updateSelectionItem(_ selectionItem: SelectionItem?, animated: Bool) {
        
//        selectedItemView.update(status, animated: false)
//        selectedForegroundView.isHidden = !selectedItemView.isSelected
//        
//        // need add animation?
//        guard animated else {
//            return
//        }
//        
//        let ani = CAKeyframeAnimation(keyPath: "transform.scale")
//        
//        ani.values = [0.8, 1.2, 1]
//        ani.duration = 0.25
//        ani.calculationMode = kCAAnimationCubic
//        
//        selectedItemView.layer.add(ani, forKey: "selected")
    }
    
    
    override func willDisplay(_ container: Container, orientation: UIImageOrientation) {
        super.willDisplay(container, orientation: orientation)
        
        // The asset must be set.
        // The container must is king of Picker.
        guard let asset = asset, let picker = container as? Picker else {
            return
        }
        
//        // Connect selection item to container with asset.
//        selectionItem.connect(asset, in: picker)
        
//
//        // update cell selection status
//        setStatus(picker.statusOfItem(with: asset), animated: false)
//
//        // update options for picker
//        selectedItemView.isHidden = !picker.allowsSelection
//        selectedForegroundView.isHidden = !picker.allowsSelection || !selectedItemView.isSelected
    }
    
    // MARK: Options change
    
    func ub_container(_ container: Container, options: String, didChange value: Any?) {
        // if it is not picker, ignore
        guard let picker = container as? Picker, options == "allowsSelection" else {
            return
        }
        // the selection of whether to support the cell
        selectionItemView.isHidden = !picker.allowsSelection
        selectionItemForegroundView.isHidden = !picker.allowsSelection || !selectionItemView.isSelected
    }
    
    @objc private func _handle(_ sender: Any) {
        // The asset must be set.
        // The container must is king of Picker.
        guard let asset = asset, let picker = container as? Picker else {
            return
        }
        
        switch selectionItem {            
        case .none:
            // Select a item with asset for picker.
            picker.selectionController.select(.single(asset))

        case .some:
            // Deselect a item with asset for picker.
            picker.selectionController.deselect(.single(asset))
        }
    }
    
    // Init UI
    private func _configure() {
        
        // Setup selection item.
        selectionItemView.isSelected = false
        
        // Setup selection item view.
        selectionItemView.frame = .init(x: bounds.width - contentInset.right - 24, y: contentInset.top, width: 24, height: 24)
        selectionItemView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        selectionItemView.addTarget(self, action: #selector(_handle(_:)), for: .touchUpInside)
        
        // Setup selection item foreground view.
        selectionItemForegroundView.frame = bounds
        selectionItemForegroundView.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        selectionItemForegroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        selectionItemForegroundView.isUserInteractionEnabled = false
        selectionItemForegroundView.isHidden = true
        
        // Enable user interaction.
        contentView.isUserInteractionEnabled = true
        
        contentView.addSubview(selectionItemView)
        contentView.insertSubview(selectionItemForegroundView, belowSubview: selectionItemView)
    }
    
    // MARK: Property
    
    var selectionItemForegroundView: UIView = .init()
    
    var selectionItemView: SelectionItemView = .init()
    
    var selectionItem: SelectionItem? {
        return selectionItemView.selectionItem 
    }
}
