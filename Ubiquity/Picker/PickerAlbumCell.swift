//
//  PickerAlbumCell.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerAlbumCell: BrowserAlbumCell, SelectionStatusObserver {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    deinit {
        // clear status
        _updateStatus(nil, animated: false)
    }
    
    /// Will display the asset
    override func willDisplay(with asset: Asset, container: Container, orientation: UIImageOrientation) {
        super.willDisplay(with: asset, container: container, orientation: orientation)
        
        // update cell selection status
        status = (container as? Picker)?.statusOfItem(with: asset)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // check responser for super
        guard let view = super.hitTest(point, with: event) else {
            return nil
        }
        
        // extend response region
        guard view === contentView, UIEdgeInsetsInsetRect(_selectedView.frame, UIEdgeInsetsMake(-8, -8, -8, -8)).contains(point) else {
            return view
        }
        
        // hit
        return _selectedView
    }
    
    /// Selection status did change
    func selectionStatus(_ selectionStatus: SelectionStatus, didChange index: Int) {
        _selectedView.setTitle("\(selectionStatus.number)", for: .selected)
    }
    
    private dynamic func _select(_ sender: Any) {
        // the asset must be set
        guard let asset = asset else {
            return
        }
        
        // check old status
        if status == nil {
            // select asset
            _updateStatus((container as? Picker)?.selectItem(with: asset, sender: self), animated: true)
            
        } else {
            // deselect asset
            _updateStatus((container as? Picker)?.deselectItem(with: asset, sender: self), animated: true)
        }
    }
    
    
    /// Update selection status for animate
    private func _updateStatus(_ status: SelectionStatus?, animated: Bool) {
        // status is change?
        guard _status !== status else {
            return
        }
        // update data
        _status?.removeObserver(self)
        _status = status
        _status?.addObserver(self)
        
        // update state
        isSelected = status != nil

        if let status = status  {
            _selectedView.setTitle("\(status.number)", for: .selected)
        }
        
        // update ui
        _selectedView.isSelected = isSelected
        _selectedBackgroundView.isHidden = !isSelected
        
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
    private func _setup() {
        
        // setup selected view
        _selectedView.frame = .init(x: bounds.width - _inset.right - 24, y: _inset.top, width: 24, height: 24)
        _selectedView.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        _selectedView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        _selectedView.setBackgroundImage(ub_image(named: "ubiquity_checkbox_normal"), for: [.normal])
        _selectedView.setBackgroundImage(ub_image(named: "ubiquity_checkbox_normal"), for: [.highlighted])
        _selectedView.setBackgroundImage(ub_image(named: "ubiquity_checkbox_selected"), for: [.selected, .normal])
        _selectedView.setBackgroundImage(ub_image(named: "ubiquity_checkbox_selected"), for: [.selected, .highlighted])
        _selectedView.setTitle("1", for: .selected)
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
        get { return _status }
    }
    
    // MARK: Ivar
    
    /// selection status
    private var _status: SelectionStatus?
    
    private var _inset: UIEdgeInsets = .init(top: 4.5, left: 4.5, bottom: 4.5, right: 4.5)
    
    private var _selectedView: UIButton = .init()
    private var _selectedBackgroundView: UIView = .init()
    
}
