//
//  Weak.swift
//  Ubiquity
//
//  Created by sagesse on 07/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//


internal class Weak<Wrapped> {
    
    /// Generate a weak object
    init(_ some: AnyObject) {
        _some = some
    }
    
    /// forward to this is
    var some: Wrapped? {
        return _some as? Wrapped
    }
    
    private weak var _some: AnyObject?
}
