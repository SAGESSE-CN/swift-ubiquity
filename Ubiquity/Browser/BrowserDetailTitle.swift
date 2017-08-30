//
//  BrowserDetailTitle.swift
//  Ubiquity
//
//  Created by sagesse on 30/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserDetailTitle: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    var asset: Asset? {
        willSet {
            guard asset !== newValue else {
                return
            }
            _title = newValue?.title
            _subtitle = newValue?.subtitle
            _mergedTitle = {
                var str = _title ?? ""
                
                if !str.isEmpty {
                    str += " "
                }
                
                return str.appending(_subtitle ?? "")
            }()
            
            // force update subview layout
            _cachedBounds = nil
            _updateLayoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // update subview layout
        _updateLayoutIfNeeded()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        // update subview layout
        _updateLayoutIfNeeded()
    }
    
    private func _setup() {
        
        autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        
        _titleLabel.font = UIFont.systemFont(ofSize: 15)
        _titleLabel.textAlignment = .center
        
        _subtitleLabel.font = UIFont.systemFont(ofSize: 11)
        _subtitleLabel.textAlignment = .center
        
        addSubview(_titleLabel)
        addSubview(_subtitleLabel)
    }
    
    private func _updateLayoutIfNeeded() {
        // if bounds is change, update title
        guard _cachedBounds?.size != superview?.bounds.size else {
            return
        }
        _cachedBounds = superview?.bounds
        
        // update layout for landscape or portrait
        guard UIScreen.main.bounds.width > UIScreen.main.bounds.height else {
            return _updateLayoutForPortrait()
        }
        return _updateLayoutForLandscap()
    }
    
    private func _updateLayoutForPortrait() {
        logger.trace?.write()
        
        // update title for portrait
        _titleLabel.text = _title
        _titleLabel.font = UIFont.systemFont(ofSize: 15)
        
        _subtitleLabel.text = _subtitle
        _subtitleLabel.alpha = 1
        
        // complute titlt & subtitle size
        let title = _titleLabel.sizeThatFits(.zero)
        let subtitle = _subtitleLabel.sizeThatFits(.zero)
        let height = max(title.height + 2 + subtitle.height, 24)
        let width = max(max(title.width, subtitle.width), 48)
        
        bounds.size = .init(width: width, height: height)
        
        // update subview layout
        _titleLabel.frame = .init(x: 0, y: 0, width: width, height: title.height)
        _subtitleLabel.frame = .init(x: 0, y: height - subtitle.height, width: width, height: subtitle.height)
    }
    
    private func _updateLayoutForLandscap() {
        logger.trace?.write()
        
        // update title for portrait
        _titleLabel.text = _mergedTitle
        _titleLabel.font = UIFont.systemFont(ofSize: 13)
        
        _subtitleLabel.text = nil
        _subtitleLabel.alpha = 0
        
        // complute titlt & subtitle size
        let title = _titleLabel.sizeThatFits(.zero)
        let height = max(title.height, 24)
        let width = max(title.width, 48)
        
        bounds.size = .init(width: width, height: height)
        
        // update subview layout
        _titleLabel.frame = .init(x: 0, y: 0, width: width, height: height)
    }
    
    private var _cachedBounds: CGRect?
    
    private var _title: String?
    private var _subtitle: String?
    private var _mergedTitle: String?
    
    private lazy var _titleLabel: UILabel = UILabel()
    private lazy var _subtitleLabel: UILabel = UILabel()
}
