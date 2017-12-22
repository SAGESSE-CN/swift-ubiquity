//
//  R.swift
//  Ubiquity
//
//  Created by sagesse on 22/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class R: Logport {
    /// In instance destoryed before, all new resource objects are shared.
    internal static var shared: R {
        if let shared = R._shared {
            return shared
        }
        let shared = R()
        R._shared = shared
        return shared
    }
    
    init() {
        logger.trace?.write()
    }
    deinit {
        logger.trace?.write()
    }
    
    /// The current bundle.
    let bundle: Bundle? = .init(for: R.self)
    
    /// The current cache.
    let cache: NSCache<AnyObject, AnyObject> = .init()
    
    
    func image(_ named: String) -> UIImage? {
        return image(named) {
            return UIImage(named: named, in: bundle, compatibleWith: nil)
        }
    }
    func image(_ named: String, closure: () -> UIImage?) -> UIImage? {
        return cache(for: named, closure: closure)
    }

    static func image(_ named: String) -> UIImage? {
        return R.shared.image(named)
    }
    static func image(_ named: String, closure: () -> UIImage?) -> UIImage? {
        return R.shared.image(named, closure: closure)
    }

    
    /// Get the item of the cache.
    func cache<T: AnyObject>(for key: String, closure: () throws -> T?) rethrows -> T? {
        // The key hit cache?
        if let oldValue = cache.object(forKey: key as AnyObject) {
            return oldValue as? T
        }
        
        // Create a new object.
        logger.debug?.write("Create object for \"\(key)\".")
        guard let newValue = try closure() else {
            return nil
        }
        
        cache.setObject(newValue, forKey: key as AnyObject)
        return newValue
    }
    
    private static weak var _shared: R?
}


