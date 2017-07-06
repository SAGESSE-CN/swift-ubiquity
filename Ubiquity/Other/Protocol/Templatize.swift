//
//  Templatize.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// the templatize class
public protocol Templatize: class {
    // with `conetntClass` generates a new class
    static func `class`(with conetntClass: AnyClass) -> AnyClass
}

