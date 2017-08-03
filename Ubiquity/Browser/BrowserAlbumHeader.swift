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
    
    var source: Source? {
        didSet {
            // update content on source change
            _updateContents(source)
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
            
            // update value on section change
            _updateStatus()
            _updateContents(source ?? parent?.source)
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
    // update contetns
    private func _updateContents(_ source: Source?) {
        // source must be set
        guard let source = source else {
            return
        }
        
        // update subview
        _headers.forEach {
            $1._updateContents(source)
        }
        
        // section must be set
        guard let section = section, let collection = source.collection(at: section) else {
            _titleLabel.text = nil
            return
        }
        
        //_titleLabel.text = collection.title ?? ub_string(for: collection.startDate ?? .init())
        _titleLabel.text = ub_string(for: collection.startDate ?? .init())
    }
    
    private func _setup() {
        // setup title
        _titleLabel.font = .systemFont(ofSize: 15)
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // setup content view
        _contentView.frame = bounds
        _contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _contentView.addSubview(_titleLabel)
        _contentView.addConstraints([
            .ub_make(_contentView, .leftMargin, .equal, _titleLabel, .left),
            .ub_make(_contentView, .rightMargin, .equal, _titleLabel, .right),
            .ub_make(_contentView, .centerY, .equal, _titleLabel, .centerY),
        ])
        
        // setup subviews
        addSubview(_contentView)
    }
    
    private var _headers: [Int: BrowserAlbumHeader] = [:]
    private var _contentView: UIView = .init()
    private var _visualEffectView: UIVisualEffectView?
    
    private var _titleLabel: UILabel = .init()
}
