//
//  Response.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// the request response
public protocol Response {
    
    /// An error that occurred when Photos attempted to load the image.
    var error: Error? { get }
    
    /// The result image is a low-quality substitute for the requested image.
    var degraded: Bool { get }
    
    /// The image request was canceled.
    var cancelled: Bool { get }
    
    /// The photo asset data is stored on the local device or must be downloaded from remote server
    var downloading: Bool { get }
}
