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
    
    /// Will display the asset
    override func willDisplay(with asset: Asset, container: Container, orientation: UIImageOrientation) {
        super.willDisplay(with: asset, container: container, orientation: orientation)
        
        // if it is not picker, ignore
        guard let picker = container as? Picker else {
            return
        }

        // update cell selection status
        _updateStatus(picker.statusOfItem(with: asset), animated: false)

        // update options for picker
        _selectedView.isHidden = !picker.allowsSelection
        _selectedBackgroundView.isHidden = !picker.allowsSelection || !_selectedView.isSelected
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // check responser for super
        guard let view = super.hitTest(point, with: event) else {
            return nil
        }
        
        // extend response region
        guard !_selectedView.isHidden, view === contentView, UIEdgeInsetsInsetRect(_selectedView.frame, UIEdgeInsetsMake(-8, -8, -8, -8)).contains(point) else {
            return view
        }
        
        return _selectedView
    }
    
    // MARK: Options change
    
    func ub_container(_ container: Container, options: String, didChange value: Any?) {
        // if it is not picker, ignore
        guard let picker = container as? Picker, options == "allowsSelection" else {
            return
        }
        // the selection of whether to support the cell
        _selectedView.isHidden = !picker.allowsSelection
        _selectedBackgroundView.isHidden = !picker.allowsSelection || !_selectedView.isSelected
    }
    
    private dynamic func _select(_ sender: Any) {
        // the asset must be set
        // if it is not picker, ignore
        guard let asset = asset, let picker = container as? Picker else {
            return
        }
        
        // check old status
        if status == nil {
            // select asset
            _updateStatus(picker.selectItem(with: asset, sender: self), animated: true)
            
        } else {
            // deselect asset
            _updateStatus(picker.deselectItem(with: asset, sender: self), animated: true)
        }
    }
    
    /// Update selection status for animate
    private func _updateStatus(_ status: SelectionStatus?, animated: Bool) {
    
        _selectedView.status = status
        _selectedBackgroundView.isHidden = !_selectedView.isSelected
        
        // need add animation?
        guard animated else {
            return
        }
        
        let ani = CAKeyframeAnimation(keyPath: "transform.scale")
        
        ani.values = [0.8, 1.2, 1]
        ani.duration = 0.25
        ani.calculationMode = kCAAnimationCubic
        
        _selectedView.layer.add(ani, forKey: "selected")
    }
    
    // Init UI
    private func _configure() {
        
        // setup selected view
        _selectedView.frame = .init(x: bounds.width - _inset.right - 24, y: _inset.top, width: 24, height: 24)
        _selectedView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        _selectedView.addTarget(self, action: #selector(_select(_:)), for: .touchUpInside)
        
        // setup selected background view
        _selectedBackgroundView.frame = bounds
        _selectedBackgroundView.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        _selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _selectedBackgroundView.isUserInteractionEnabled = false
        _selectedBackgroundView.isHidden = true
        
        // enable user interaction
        contentView.isUserInteractionEnabled = true
        
        // add subview
        contentView.addSubview(_selectedView)
        contentView.insertSubview(_selectedBackgroundView, at: 0)
    }
    
    // MARK: Property
    
    /// The asset selection status
    var status: SelectionStatus? {
        set { return _updateStatus(newValue, animated: false) }
        get { return _selectedView.status }
    }
    
    // MARK: Ivar
    
    private lazy var _inset: UIEdgeInsets = .init(top: 4.5, left: 4.5, bottom: 4.5, right: 4.5)
    
    private lazy var _selectedView: SelectionStatusView = .init()
    private lazy var _selectedBackgroundView: UIView = .init()
    
}
