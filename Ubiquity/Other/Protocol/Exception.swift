//
//  Exception.swift
//  Ubiquity
//
//  Created by SAGESSE on 9/2/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// Library of some common errors
public enum Exception: Error {
    
    // This application is not authorized to access photo data.
    case restricted
    
    // User has explicitly denied this application access to photos data.
    case denied
    
    // No any content
    case notData 
}

/// Exception display container
public protocol ExceptionDisplayable: class {
    
    /// Generate an exception display container
    ///
    /// - Parameters:
    ///   - container: The current use of the container
    ///   - error: The error message
    ///   - sender: Triggering errors of the sender
    init(container: Container, error: Error, sender: AnyObject)
}

