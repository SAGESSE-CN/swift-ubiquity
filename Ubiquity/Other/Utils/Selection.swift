//
//  Selection.swift
//  Ubiquity
//
//  Created by SAGESSE on 1/23/18.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import UIKit

//internal enum SelectionMode {
//    
//    case all
//    
//    case single(Asset)
//    
//    case multiple([Asset])
//    
//    case collection(Collection)
//}
//


/// Picker selection item.
public enum Selection {
    /// Selects all objects on the assets.
    case all
    
    /// Select the specified assets.
    case asset(Asset)
    case assets(Array<Asset>)
    
    /// Selected to specify the source of the assets.
    case collection(Source)
}


internal enum SelectionStatusStyle {
    case number
    case normal
}

internal class SelectionStatus {
    
    /// Generate a selection status
    init(asset: Asset, number: Int = 1) {
        self.asset = asset
        self.number = number
    }
    
    /// The selected asset
    let asset: Asset
    
    /// The selected number
    var number: Int  {
        didSet {
            // has change?
            guard oldValue != number else {
                return
            }
            
            // notifity all observers
            _observers.forEach {
                $0.selectionStatus(self, didChange: number)
            }
        }
    }
    
    /// Add observer, must call removeObserver(_:) method, not observer, are retained.
    func addObserver(_ observer: SelectionStatusObserver) {
        _observers.insert(observer)
    }
    
    /// Remove observer
    func removeObserver(_ observer: SelectionStatusObserver) {
        _observers.remove(observer)
    }
    
    // The reason for this design is the efficiency of optimization
    private lazy var _observers: WSet<SelectionStatusObserver> = []
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
//            setTitle("\(status.number)", for: .selected)
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
        
        setBackgroundImage(R.image("ubiquity_checkbox_normal"), for: [.normal])
        setBackgroundImage(R.image("ubiquity_checkbox_normal"), for: [.highlighted])
        setBackgroundImage(R.image("ubiquity_checkbox_selected"), for: [.selected, .normal])
        setBackgroundImage(R.image("ubiquity_checkbox_selected"), for: [.selected, .highlighted])
        
        // default value
//        setTitle("1", for: .selected)
        setImage(R.image("ubiquity_checkbox_icon"), for: .selected)
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

internal protocol SelectionStatusObserver: class {
    
    /// Selection status did change
    func selectionStatus(_ selectionStatus: SelectionStatus, didChange number: Int)
}

