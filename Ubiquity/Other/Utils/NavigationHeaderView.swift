//
//  NavigationHeaderView.swift
//  Ubiquity
//
//  Created by SAGESSE on 8/1/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class NavigationHeaderView: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    weak var parent: NavigationHeaderView?
    
    var textColor: UIColor? {
        willSet {
            _titleLabel.textColor = newValue
            _subtitleLabel.textColor = newValue
        }
    }
    
    var effect: UIVisualEffect? {
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
    
    var source: Source? {
        willSet {
            // The source is change?
            guard source !== newValue else {
                return
            }
            
            // update content 
            section.map {
                guard $0 < newValue?.numberOfCollections ?? 0 else {
                    _updateCollection(nil)
                    return
                }
                _updateCollection(newValue?.collection(at: $0))
            }
            
            // update subheader
            _headers.forEach { key, value in
                guard key < newValue?.numberOfCollections ?? 0 else {
                    value._updateCollection(nil)
                    return
                }
                value._updateCollection(newValue?.collection(at: key))
            }
        }
    }
    
    var section: Int? {
        didSet {
            // section has any change?
            guard oldValue != section else {
                return
            }
            
            // self is subheader?
            if let parent = parent {
                // remove link from parent
                if let oldValue = oldValue {
                    parent._headers.removeValue(forKey: oldValue)
                }
                
                // add link to parent
                if let newValue = section {
                    parent._headers[newValue] = self
                }
            }
            
            // update self status
            _updateStatus(section)
            
            // update self contents
            if let section = section {
                
                // if is parent header
                if parent == nil {
                    // preconfig title & subtitle
                    _titleLabel.text = _headers[section]?._titleLabel.text
                    _subtitleLabel.text = _headers[section]?._subtitleLabel.text
                }
                
                _updateCollection((source ?? parent?.source)?.collection(at: section))
            }
            
            // self is parent?
            _headers.forEach {
                $1._updateStatus($1.section)
            }
        }
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        // don't call super, size is fixed
        return frame.size
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        // update section
        if section != layoutAttributes.indexPath.section, parent != nil {
            section = layoutAttributes.indexPath.section
        }
    }
    
    
    // update display status
    private func _updateStatus(_ section: Int?) {
        
        // if parent is nil, can't hide
        guard let parent = parent else {
            _contentView.isHidden = false
            return
        }
        let isHidden = parent.section == section
        guard isHidden != _contentView.isHidden else {
            return
        }
        // if section is equal, hide
        _contentView.isHidden = isHidden
    }
    
    // update display contents
    private func _updateCollection(_ collection: Collection?) {
        // has any change?
        guard _collection !== collection else {
            return
        }
        _collection = collection
        
        // load title for the first time will be very slow
        // need to load in the background
        DispatchQueue.global(qos: .userInitiated).async { [weak _titleLabel, weak _subtitleLabel] in
            
            // if collection is change, ignore
            guard self._collection === collection else {
                return
            }
            
            // fetch title & subtitle
            let title = collection?.ub_title
            let subtitle = collection?.ub_subtitle
            
            DispatchQueue.main.async {
                
                // if collection is change, ignore
                guard self._collection === collection else {
                    return
                }
                
                // update title
                _titleLabel?.text = title
                _subtitleLabel?.text = subtitle
            }
        }
    }
    
    private func _setup() {
        
        // setup title
        _titleLabel.font = .systemFont(ofSize: 15)
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false
        _subtitleLabel.font = .systemFont(ofSize: 11)
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // center view
        let tmp = UIView(frame: bounds)
        tmp.translatesAutoresizingMaskIntoConstraints = false
        tmp.addSubview(_titleLabel)
        tmp.addSubview(_subtitleLabel)
        tmp.addConstraints([
            
            .ub_make(tmp, .top, .equal, _titleLabel, .top, -1),
            .ub_make(tmp, .left, .equal, _titleLabel, .left),
            .ub_make(tmp, .right, .equal, _titleLabel, .right),
            
            .ub_make(_titleLabel, .bottom, .equal, _subtitleLabel, .top, -1),
            
            .ub_make(tmp, .left, .equal, _subtitleLabel, .left),
            .ub_make(tmp, .right, .equal, _subtitleLabel, .right),
            .ub_make(tmp, .bottom, .equal, _subtitleLabel, .bottom),
        ])
        
        // setup content view
        _contentView.frame = bounds
        _contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _contentView.addSubview(tmp)
        _contentView.addConstraints([
            .ub_make(_contentView, .centerY, .equal, tmp, .centerY),
            .ub_make(_contentView, .leftMargin, .equal, tmp, .left),
            .ub_make(_contentView, .rightMargin, .equal, tmp, .right),
        ])
        
        // setup subviews
        addSubview(_contentView)
    }
    
    private var _collection: Collection?
    
    private var _headers: [Int: NavigationHeaderView] = [:]
    private var _contentView: UIView = .init()
    private var _visualEffectView: UIVisualEffectView?
    
    private lazy var _titleLabel: UILabel = .init()
    private lazy var _subtitleLabel: UILabel = .init()
}
