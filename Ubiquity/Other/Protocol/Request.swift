//
//  Request.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// Uniquely identify a cancellable async request
public protocol Request {
}

/// A set of options affecting the delivery of still image representations of Photos assets you request from an image manager.
public protocol RequestOptions {
    
    /// if necessary will download the image from reomte
    var isNetworkAccessAllowed: Bool { get }
    
    /// provide caller a way to be told how much progress has been made prior to delivering the data when it comes from remote server.
    var progressHandler: ((Double, Response) -> ())? { get }
}

/// Options for fitting an image's aspect ratio to a requested size
public enum RequestContentMode: Int {
    
    /// Scales the image so that its larger dimension fits the target size.
    ///
    /// Use this option when you want the entire image to be visible, such as when presenting it in a view with the scaleAspectFit content mode.
    case aspectFit = 0

    /// Scales the image so that it completely fills the target size.
    ///
    /// Use this option when you want the image to completely fill an area, such as when presenting it in a view with the scaleAspectFill content mode.
    case aspectFill = 1
 
    /// Fits the image to the requested size using the default option, aspectFit.
    ///
    /// Use this content mode when requesting a full-sized image using the PHImageManagerMaximumSize value for the target size. In this case, the image manager does not scale or crop the image.
    static var `default`: RequestContentMode = .aspectFill
}
