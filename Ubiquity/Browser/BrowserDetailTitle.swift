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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // superview must be set
        guard let superview = superview else {
            return
        }
        
        logger.debug?.write(superview.frame)
    }
    
    private func _setup() {
        
        // must be set, if not set will can't receive the layoutSubviews event
        autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleHeight]
    }
}
