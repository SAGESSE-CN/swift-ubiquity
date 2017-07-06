//
//  Container.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// The container
public protocol Container: Library {
    
    /// the current the library
    var library: Library { get }
}
