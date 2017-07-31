//
//  BrowserAlbumHeader.swift
//  Ubiquity
//
//  Created by SAGESSE on 8/1/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumHeader: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    @NSCopying var effect: UIVisualEffect? {
        willSet {
            // has any effect?
            guard let newValue = newValue else {
                
                // remove effect view
                _visualEffectView?.removeFromSuperview()
                _visualEffectView = nil
                
                // move content view to self
                addSubview(_contentView)
                
                return
            }
            
            // create view
            guard _visualEffectView == nil else {
                _visualEffectView?.effect = newValue
                return
            }
            
            let visualEffectView = UIVisualEffectView(frame: bounds)
            
            // config effect view
            visualEffectView.effect = newValue
            visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            visualEffectView.contentView.addSubview(_contentView)
            
            // move to effect view
            addSubview(visualEffectView)
            
            _visualEffectView = visualEffectView
        }
    }
    
    weak var parent: BrowserAlbumHeader?
    
    
    var contents: Collection? {
        willSet {
        }
    }
    
    var section: Int? {
        didSet {
            // section has any change?
            guard oldValue != section else {
                return
            }
            
            // remove from old
            if let oldValue = oldValue {
                parent?._headers.removeValue(forKey: oldValue)
            }
            
            // add to new
            if let newValue = section {
                parent?._headers[newValue] = self
            }
            
            // update status
            _updateStatus()
        }
    }
    
    // update display status
    private func _updateStatus() {
        
        // update subview
        _headers.forEach {
            $1._updateStatus()
        }
        
        // if parent is nil, can't hide
        guard let parent = parent else {
            _contentView.isHidden = false
            return
        }
        
        // if section is equal, hide 
        _contentView.isHidden = parent.section == section
    }
    
    private func _setup() {
        // setup content view
        _contentView.frame = bounds
        _contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let lb = UILabel()
        lb.frame = UIEdgeInsetsInsetRect(_contentView.bounds, .init(top: 0, left: 10, bottom: 0, right: 10))
        lb.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lb.font = UIFont.systemFont(ofSize: 15)
        lb.text = "October 10, 2009"
        _contentView.addSubview(lb)
        
        // setup subviews
        addSubview(_contentView)
    }
    
    private var _headers: [Int: BrowserAlbumHeader] = [:]
    private var _contentView: UIView = .init()
    private var _visualEffectView: UIVisualEffectView?
}
