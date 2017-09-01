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
    
    var barStyle: UIBarStyle = .default {
        willSet {
            guard barStyle != newValue else {
                return
            }
            
            // update text color with bar style
            switch newValue {
            case .black,
                 .blackTranslucent:
                _titleLabel.textColor = .white
                _subtitleLabel.textColor = .white
                
                
            case .default:
                _titleLabel.textColor = .black
                _subtitleLabel.textColor = .black
            }
        }
    }
    var titleTextAttributes: [String: Any]? {
        willSet {
            guard let newValue = newValue, !newValue.isEmpty else {
                return
            }
            
            // the navgationBar specifies the font
            if let font = newValue[NSFontAttributeName] as? UIFont {
                _titleLabel.font = UIFont(descriptor: font.fontDescriptor, size: 15)
                _subtitleLabel.font = UIFont(descriptor: font.fontDescriptor, size: 11)
            }
            
            // the navgationBar specifies the color
            if let color = newValue[NSForegroundColorAttributeName] as? UIColor {
                _titleLabel.textColor = color
                _subtitleLabel.textColor = color
            }
            
            // the navgationBar specifies the shadow
            if let color = newValue[NSShadowAttributeName] as? NSShadow {
                _titleLabel.shadowColor = color.shadowColor as? UIColor
                _titleLabel.shadowOffset = color.shadowOffset
                _subtitleLabel.shadowColor = color.shadowColor as? UIColor
                _subtitleLabel.shadowOffset = color.shadowOffset
            }
        }
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
        _titleLabel.font = UIFont(descriptor: (_titleLabel.font ?? .systemFont(ofSize: 15)).fontDescriptor, size: 15)
        
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
        _titleLabel.font = UIFont(descriptor: (_titleLabel.font ?? .systemFont(ofSize: 13)).fontDescriptor, size: 13)
        
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
