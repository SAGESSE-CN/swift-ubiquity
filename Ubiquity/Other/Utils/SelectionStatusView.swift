//
//  SelectionStatusView.swift
//  Ubiquity
//
//  Created by sagesse on 01/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal enum SelectionStatusStyle {
    case number
    case normal
}

internal class SelectionStatusView: UIButton, SelectionStatusObserver {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        _configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // must clear status
        _update(nil, animated: false)
    }
    
    /// Selection status did change
    func selectionStatus(_ selectionStatus: SelectionStatus, didChange index: Int) {
        // in selection status change, update number
        setTitle("\(selectionStatus.number)", for: .selected)
    }
    
    private func _update(_ status: SelectionStatus?, animated: Bool) {
        // status is change?
        guard _status !== status else {
            return
        }
        
        _status?.removeObserver(self)
        _status = status
        _status?.addObserver(self)
        
        // update state
        isSelected = status != nil

        if let status = status  {
            setTitle("\(status.number)", for: .selected)
        }
        
        // update ui
        isSelected = isSelected
        
        // need add animation
        guard animated else {
            return
        }
        let ani = CATransition()
        ani.type = kCATransitionFade
        ani.duration = 0.1
        layer.add(ani, forKey: "change")
    }
    
    private func _configure() {
        
        // title
        titleLabel?.font = UIFont.systemFont(ofSize: 14)
        
        setBackgroundImage(ub_image(named: "ubiquity_checkbox_normal"), for: [.normal])
        setBackgroundImage(ub_image(named: "ubiquity_checkbox_normal"), for: [.highlighted])
        setBackgroundImage(ub_image(named: "ubiquity_checkbox_selected"), for: [.selected, .normal])
        setBackgroundImage(ub_image(named: "ubiquity_checkbox_selected"), for: [.selected, .highlighted])
        
        // default value
        setTitle("1", for: .selected)
    }

    // update status without animation
    var status: SelectionStatus? {
        set { return _update(newValue, animated: false) }
        get { return _status }
    }
    
    func setStatus(_ status: SelectionStatus?, animated: Bool) {
        return _update(status, animated: animated)
    }

    private var _status: SelectionStatus?
}
