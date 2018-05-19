//
//  Caching.swift
//  Ubiquity
//
//  Created by sagesse on 2018/5/18.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import UIKit

public class Caching<T>: Logport {
    
    public let ref: T
    internal init(_ ref: T) {
        self.ref = ref
    }
    
    internal func `lazy`<C, T>(with keyPath: ReferenceWritableKeyPath<C, T?>, newValue: @autoclosure () throws -> T) rethrows -> T where C: Caching {
        guard let helper = self as? C else {
            logger.error?.write("unknow error")
            return try newValue()
        }
        
        if let value = helper[keyPath: keyPath] {
            return value
        }
        
        let value = try newValue()
        helper[keyPath: keyPath] = .some(value)
        return value
    }
    
    public lazy var extra: Dictionary<String, Any> = [:]
}

