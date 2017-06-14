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
    
    private func _setup() {
        
        // setup selected view
        _selectedView.frame = .init(x: bounds.width - _inset.right - 23, y: _inset.top, width: 23, height: 23)
        _selectedView.backgroundColor = .random
        _selectedView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        
        // setup selected background view
        _selectedBackgroundView.frame = bounds
        _selectedBackgroundView.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        _selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // add subview
        contentView.addSubview(_selectedView)
        contentView.insertSubview(_selectedBackgroundView, at: 0)
    }
    
    private var _inset: UIEdgeInsets = .init(top: 4.5, left: 4.5, bottom: 4.5, right: 4.5)
    
    private var _selectedView: UIButton = .init()
    private var _selectedBackgroundView: UIView = .init()
}
