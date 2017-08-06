//
//  UIResponder+Fullscreen.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/12/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


/// Add a full screen support
public extension UIResponder {
    
    /// the current fullscreen state
    /// default is false, must override return true
    public var ub_isFullscreen: Bool {
        return next?.ub_isFullscreen ?? false
    }

    ///
    /// Enter fullscreen mode
    ///
    /// - Parameter animated: the change need animation?
    /// - Returns: true is enter success, false is fail
    ///
    @discardableResult
    public func ub_enterFullscreen(animated: Bool) -> Bool {
        return next?.ub_enterFullscreen(animated: animated) ?? false
    }
    
    ///
    /// Exit fullscreen mode
    ///
    /// - Parameter animated: the change need animation?
    /// - Returns: true is exit success, false is fail
    ///
    @discardableResult
    public func ub_exitFullscreen(animated: Bool) -> Bool {
        return next?.ub_exitFullscreen(animated: animated) ?? false
    }
}

