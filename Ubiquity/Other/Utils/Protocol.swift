//
//  Protocol.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// the templatize class
internal protocol Templatize: class {
    // with `conetntClass` generates a new class
    static func `class`(with conetntClass: AnyClass) -> AnyClass
}

/// the display protocol
internal protocol Displayable: class {
    
    ///
    /// the displayer delegate
    ///
    weak var delegate: AnyObject? { set get }
    
    ///
    /// Show an asset
    ///
    /// - parameter asset: need the display the resource
    /// - parameter library: the asset in this library
    /// - parameter orientation: need to display the image direction
    ///
    func willDisplay(with asset: Asset, in library: Library, orientation: UIImageOrientation)
    
    ///
    /// Hide an asset
    ///
    /// - parameter asset: current display the resource
    /// - parameter library: the asset in this library
    ///
    func endDisplay(with asset: Asset, in library: Library)
    
}
/// the displayer delegate
internal protocol DisplayableDelegate: class {
    
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

/// the play protocol
internal protocol Playable: class {
    
    ///
    /// the player delegate
    ///
    weak var delegate: AnyObject? { set get }
    
    ///
    /// Start the player or Resume the player
    ///
    /// - parameter asset: will start play the asset
    /// - parameter library: the asset in this library
    ///
    func play(with asset: Asset, in library: Library)
    
    ///
    /// Stop player
    ///
    /// - parameter asset: current play the asset
    /// - parameter library: the asset in this library
    ///
    func stop(with asset: Asset, in library: Library)
    
    ///
    /// Suspend the player
    ///
    /// - parameter asset: current play the asset
    /// - parameter library: the asset in this library
    ///
    func suspend(with asset: Asset, in library: Library)
    
    ///
    /// Resume the player
    ///
    /// - parameter asset: current play the asset
    /// - parameter library: the asset in this library
    ///
    func resume(with asset: Asset, in library: Library)
}
/// the player delegate
internal protocol PlayableDelegate: class {
    
    ///
    /// Tell the delegate that the player is prepared
    ///
    /// - parameter player: current player
    /// - parameter asset: current play the asset
    ///
    func player(_ player: Playable, didPrepared asset: Asset)
    
    ///
    /// Tell the delegate that player start play
    ///
    /// - parameter player: current player
    /// - parameter asset: current play the asset
    ///
    func player(_ player: Playable, didStartPlay asset: Asset)
    
    ///
    /// Tell the delegate that player stop
    ///
    /// - parameter player: current player
    /// - parameter asset: current play the asset
    ///
    func player(_ player: Playable, didStop asset: Asset)
    
    ///
    /// Tell the delegate that player interruption due to lack of enough data
    ///
    /// - parameter player: current player
    /// - parameter asset: current play the asset
    ///
    func player(_ player: Playable, didStalled asset: Asset)
    
    ///
    /// Tell the delegate that player interrupte play, automatic: background/foreground mode switch
    ///
    /// - parameter player: current player
    /// - parameter asset: current play the asset
    ///
    func player(_ player: Playable, didSuspend asset: Asset)
    
    ///
    /// Tell the delegate that player restore play , automatic: background/foreground mode switch
    ///
    /// - parameter player: current player
    /// - parameter asset: current play the asset
    ///
    func player(_ player: Playable, didResume asset: Asset)
    
    ///
    /// Tell the delegate that player play finish
    ///
    /// - parameter player: current player
    /// - parameter asset: current play the asset
    ///
    func player(_ player: Playable, didFinish asset: Asset)
    
    ///
    /// Tell the delegate that player play occur error
    ///
    /// - parameter player: current player
    /// - parameter asset: current play the asset
    /// - parameter error: error info
    ///
    func player(_ player: Playable, didOccur asset: Asset, error: Error?)
}

