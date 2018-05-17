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
        guard !selectedItemView.isHidden, view === contentView, UIEdgeInsetsInsetRect(selectedItemView.frame, UIEdgeInsetsMake(-8, -8, -8, -8)).contains(point) else {
            return view
        }
        
        return selectedItemView
    }
    
    /// Update selection status for animate
    private func setStatus(_ status: SelectionItem?, animated: Bool) {
        
        selectedItemView.update(status, animated: false)
        selectedForegroundView.isHidden = !selectedItemView.isSelected
        
        // need add animation?
        guard animated else {
            return
        }
        
        let ani = CAKeyframeAnimation(keyPath: "transform.scale")
        
        ani.values = [0.8, 1.2, 1]
        ani.duration = 0.25
        ani.calculationMode = kCAAnimationCubic
        
        selectedItemView.layer.add(ani, forKey: "selected")
    }
    
    override func willDisplay(_ container: Container, orientation: UIImageOrientation) {
        super.willDisplay(container, orientation: orientation)
        
        // if it is not picker, ignore
        guard let asset = asset, let picker = container as? Picker else {
            return
        }

        // update cell selection status
        setStatus(picker.statusOfItem(with: asset), animated: false)

        // update options for picker
        selectedItemView.isHidden = !picker.allowsSelection
        selectedForegroundView.isHidden = !picker.allowsSelection || !selectedItemView.isSelected
    }
    
    // MARK: Options change
    
    func ub_container(_ container: Container, options: String, didChange value: Any?) {
        // if it is not picker, ignore
        guard let picker = container as? Picker, options == "allowsSelection" else {
            return
        }
        // the selection of whether to support the cell
        selectedItemView.isHidden = !picker.allowsSelection
        selectedForegroundView.isHidden = !picker.allowsSelection || !selectedItemView.isSelected
    }
    
    @objc private dynamic func _select(_ sender: Any) {
        // the asset must be set
        // if it is not picker, ignore
        guard let asset = asset, let picker = container as? Picker else {
            return
        }
        
        // check old status
        if status == nil {
            // select asset
            setStatus(picker.selectItem(with: asset, sender: self), animated: true)
            
        } else {
            // deselect asset
            setStatus(picker.deselectItem(with: asset, sender: self), animated: true)
        }
    }
    
    // Init UI
    private func _configure() {
        
        // setup selected view
        selectedItemView.frame = .init(x: bounds.width - contentInset.right - 24, y: contentInset.top, width: 24, height: 24)
        selectedItemView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        selectedItemView.addTarget(self, action: #selector(_select(_:)), for: .touchUpInside)
        
        // setup selected background view
        selectedForegroundView.frame = bounds
        selectedForegroundView.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        selectedForegroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        selectedForegroundView.isUserInteractionEnabled = false
        selectedForegroundView.isHidden = true
        
        // enable user interaction
        contentView.isUserInteractionEnabled = true
        
        // add subview
        contentView.addSubview(selectedItemView)
        contentView.insertSubview(selectedForegroundView, at: 0)
    }
    
    // MARK: Property
    
    /// The picker selection background view.
    lazy var selectedForegroundView: UIView = UIView()
    
    /// The picker selection status view.
    lazy var selectedItemView: SelectionItemView = SelectionItemView()
    
    /// The asset selection status
    var status: SelectionItem? {
        set { return selectedItemView.update(newValue, animated: false) }
        get { return selectedItemView.item }
    }
}
