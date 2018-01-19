//
//  SelectionStatus.swift
//  Ubiquity
//
//  Created by sagesse on 07/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal enum SelectionMode {
    
    case all
    
    case single(Asset)
    
    case multiple([Asset])
    
    case collection(Collection)
}


internal protocol SelectionStatusObserver: class {
    
    /// Selection status did change
    func selectionStatus(_ selectionStatus: SelectionStatus, didChange number: Int)
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
