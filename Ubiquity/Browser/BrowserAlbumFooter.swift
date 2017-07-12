//
//  BrowserAlbumFooter.swift
//  Ubiquity
//
//  Created by sagesse on 12/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumFooter: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    var source: DataSource? {
        willSet {
            guard let source = newValue else {
                return
            }
            DispatchQueue.global().async {
                
                let counts = (source.count(with: .image),
                              source.count(with: .video),
                              source.count(with: .audio),
                              source.count(with: .unknown))
                
                DispatchQueue.main.async {
                    self._update(with: counts.0, video: counts.1, audio: counts.2, unknow: counts.3)
                }
            }
            
        }
    }
    
    private func _update(with image: Int, video: Int, audio: Int, unknow: Int) {
        
        var tmp: [String] = []
        
        if image != 0 {
            tmp.append(String(format: "%@ Photos", ub_string(for: image)))
        }
        if video != 0 {
            tmp.append(String(format: "%@ Videos", ub_string(for: video)))
        }
        if audio != 0 {
            tmp.append(String(format: "%@ Audios", ub_string(for: audio)))
        }
        
        _titleLabel.text = tmp.reduce(nil) {
            guard let title = $0 else {
                return $1
            }
            return title + ", " + $1
        }
    }
    
    private func _setup() {
        
        _titleLabel.font = UIFont.systemFont(ofSize: 17)
        _titleLabel.textColor = .black
        _titleLabel.textAlignment = .center
        _titleLabel.numberOfLines = 0
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false
        _titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        _titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        
        // setup content view
        addSubview(_titleLabel)
        addConstraints([
            .ub_make(_titleLabel, .top, .equal, self, .top),
            .ub_make(_titleLabel, .width, .lessThanOrEqual, self, .width),
            .ub_make(_titleLabel, .centerX, .equal, self, .centerX),
            .ub_make(_titleLabel, .bottom, .equal, self, .bottom),
        ])
    }
    
    private lazy var _titleLabel = UILabel()
}
