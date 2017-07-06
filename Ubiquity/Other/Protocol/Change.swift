//
//  Change.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// A change info
public protocol Change {
}

/// A protocol you can implement to be notified of changes that occur in the Photos library.
public protocol ChangeObserver {
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Any)
}
