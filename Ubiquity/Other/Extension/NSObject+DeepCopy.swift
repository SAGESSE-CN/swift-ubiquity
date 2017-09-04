//
//  NSObject+DeepCopy.swift
//  Ubiquity
//
//  Created by sagesse on 05/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

public extension NSObject {
    /// copy a new object
    public func ub_deepCopy() -> Any {
        // generate a new object
        let object = type(of: self).init()
        
        // copy all member properties
        func copy<T: NSObject>(_ src: T, _ dest: T, _ cls: AnyClass) -> T {
            
            // copy all super class properties
            // NSObject annot be copy, it contains some data that does not support copy
            if let superclass = cls.superclass(), superclass != NSObject.self  {
                // priority copy super class 
                _ = copy(src, dest, superclass)
            }
            
            var count: UInt32 = 0
            
            // copy all ivar info
            guard let ptr = class_copyIvarList(cls, &count) else {
                return dest
            }
            
            // dump src to dest
            dest.setValuesForKeys(src.dictionaryWithValues(forKeys: (0 ..< Int(count)).flatMap {
                // fetch name for ptr
                guard let ivar = ptr.advanced(by: $0).move(), let name = ivar_getName(ivar) else {
                    return nil
                }
                // convert to string
                return String(cString: name, encoding: .utf8)
            }))
            
            return dest
        }
        
        return copy(self, object, type(of: self))
    }
}
