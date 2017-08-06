//
//  SelectionScroller.swift
//  Ubiquity
//
//  Created by sagesse on 27/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

@objc
internal protocol SelectionScrollerDelegate: class {
    
    /// Update contetn offset for timeover
    @objc optional func selectionScroller(_ selectionScroller: SelectionScroller, shouldAutoScroll timestamp: CFTimeInterval, offset: CGPoint) -> Bool
    @objc optional func selectionScroller(_ selectionScroller: SelectionScroller, didAutoScroll timestamp: CFTimeInterval, offset: CGPoint)
}

@objc
internal class SelectionScroller: NSObject {

    override init() {
        super.init()
        
        // setup timer
        _timer.isPaused = true
        _timer.frameInterval = 1
        
        // add to main
        _timer.add(to: .main, forMode: .commonModes)
    }
    deinit {
        _timer.invalidate()
    }
    
    var speed: CGFloat = 0 {
        willSet {
            let paused = newValue == 0
            guard paused != _timer.isPaused else {
                return
            }
            _timer.isPaused = paused
        }
    }
    
    weak var delegate: SelectionScrollerDelegate?
    weak var scrollView: UIScrollView?
    
    // update timestamp
    private func _update(_ sender: CADisplayLink) {
        // if scroll is nil, ignore
        guard let scrollView = scrollView else {
            return
        }
        
        // compute new offset
        let edg = scrollView.contentInset
        let y = max(min(scrollView.contentOffset.y + 16 * speed, scrollView.contentSize.height - scrollView.bounds.height + edg.bottom), -edg.top)
        
        // offset has any change?
        guard scrollView.contentOffset.y != y else {
            return
        }
        
        // ask use can update content offset?
        let offset = CGPoint(x: scrollView.contentOffset.x, y: y)
        guard delegate?.selectionScroller?(self, shouldAutoScroll: sender.timestamp, offset: offset) ?? true else {
            return
        }
        
        // update content offset
        scrollView.contentOffset = offset
        delegate?.selectionScroller?(self, didAutoScroll: sender.timestamp, offset: offset)
    }
    
    private lazy var _timer: CADisplayLink = .init(block: { [weak self] in self?._update($0) })
}

