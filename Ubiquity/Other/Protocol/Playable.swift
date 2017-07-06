//
//  Playable.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// The play protocol
public protocol Playable: class {
    
    ///
    /// the player delegate
    ///
    weak var delegate: AnyObject? { set get }
    
    ///
    /// Start the player or Resume the player
    ///
    /// - parameter asset: will start play the asset
    /// - parameter container: the current the container
    ///
    func play(with asset: Asset, container: Container)
    
    ///
    /// Stop player
    ///
    /// - parameter asset: current play the asset
    /// - parameter container: the current the container
    ///
    func stop(with asset: Asset, container: Container)
    
    ///
    /// Suspend the player
    ///
    /// - parameter asset: current play the asset
    /// - parameter container: the current the container
    ///
    func suspend(with asset: Asset, container: Container)
    
    ///
    /// Resume the player
    ///
    /// - parameter asset: current play the asset
    /// - parameter container: the current the container
    ///
    func resume(with asset: Asset, container: Container)
}

/// The player delegate
public protocol PlayableDelegate: class {
    
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
