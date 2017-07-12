//
//  Displayable.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// The display protocol
public protocol Displayable: class {
    
    ///
    /// the displayer delegate
    ///
    weak var delegate: AnyObject? { set get }
    
    ///
    /// Show an asset
    ///
    /// - parameter asset: need the display the resource
    /// - parameter container: the current the container
    /// - parameter orientation: need to display the image direction
    ///
    func willDisplay(with asset: Asset, container: Container, orientation: UIImageOrientation)
    
    ///
    /// Hide an asset
    ///
    /// - parameter container: the current the container
    ///
    func endDisplay(with container: Container)
}

/// The displayer delegate
public protocol DisplayableDelegate: class {
    
    ///
    /// Tell the delegate that begin download from the remote server
    ///
    /// - parameter displayer: current the displayer
    /// - parameter asset: current displaying the resouce
    ///
    func displayer(_ displayer: Displayable, didBeginDownload asset: Asset)
    
    ///
    /// Tell the delegate that to receive new data from the remote server
    ///
    /// - parameter displayer: current the displayer
    /// - parameter asset: current displaying the resouce
    /// - parameter progress: current donwlading the progress, value is 0~1
    ///
    func displayer(_ displayer: Displayable, didReceive asset: Asset, progress: Double)
    
    ///
    /// Tell the delegate that end download from the remote server
    ///
    /// - parameter displayer: current the displayer
    /// - parameter asset: current displaying the resouce
    /// - parameter error: if error is nil, download finish, if error is not nil, download fail
    ///
    func displayer(_ displayer: Displayable, didEndDownload asset: Asset, error: Error?)
}
