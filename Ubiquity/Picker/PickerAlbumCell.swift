//
//  PickerAlbumCell.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerAlbumCell: BrowserAlbumCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    /// Will display the asset
    override func willDisplay(with asset: Asset, container: Container, orientation: UIImageOrientation) {
        // update asset select status
        if let container = container as? Picker {
            setIsSelected(false, animated: false)
        }
        
        super.willDisplay(with: asset, container: container, orientation: orientation)
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
    
    
    func setIsSelected(_ isSelected: Bool, animated: Bool) {
        
        self.isSelected = isSelected

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
    
    private dynamic func _select(_ sender: Any) {
        logger.debug?.write()
        
//        if let index = delegate?.selection(self, indexOfSelectedItemsFor: photo), index != NSNotFound {
//
//            _isSelected = true
//            _selectedView.isSelected = _isSelected
//            _hightlightLayer.isHidden = !_isSelected
//
//            _selectedView.setTitle("\(index + 1)", for: .selected)
//            
//        } else {
//            
//            _isSelected = false
//            _hightlightLayer.isHidden = !_isSelected
//        }
        
//
//        // 选中时, 加点特效
        //        if animated {
        
        setIsSelected(!_selectedView.isSelected, animated: true)
    }
    
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
    
    private var _inset: UIEdgeInsets = .init(top: 4.5, left: 4.5, bottom: 4.5, right: 4.5)
    
    private var _selectedView: UIButton = .init()
    private var _selectedBackgroundView: UIView = .init()
}
