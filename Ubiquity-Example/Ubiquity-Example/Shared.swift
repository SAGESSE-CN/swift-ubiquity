//
//  Shared.swift
//  Ubiquity-Example
//
//  Created by SAGESSE on 11/23/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class Shared {
    
    /// An default shared data.
    internal static let `default` = Shared(name: "SA.Ubiquity-Example")
    
    /// Create a shared data with name.
    internal init(name: String) {
        _name = name
        /// Starting in iOS 10, the Find pasteboard (identified with the UIPasteboardNameFind constant) is unavailable.
        _pasteboard = UIPasteboard.general
    }
    
    /// Get/Set shared data.
    internal subscript(key: String) -> Any? {
        set {
            return _pasteboard.map {
                return $0.setData(_encode(newValue), forPasteboardType: key)
            } ?? ()
        }
        get {
            return _pasteboard.flatMap {
                return _decode($0.data(forPasteboardType: key))
            }
        }
    }
    
    
    private func _encode(_ value: Any?) -> Data {
        return value.map {
            return NSKeyedArchiver.archivedData(withRootObject: $0)
        } ?? Data()
    }
    private func _decode(_ data: Data?) -> Any? {
        return data.flatMap {
            return NSKeyedUnarchiver.unarchiveObject(with: $0)
        }
    }
    
    private let _name: String
    private let _pasteboard: UIPasteboard?
}
