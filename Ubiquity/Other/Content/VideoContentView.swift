//
//  VideoContentView.swift
//  Ubiquity
//
//  Created by SAGESSE on 4/22/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation

/// display video resources
internal class VideoContentView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    weak var delegate: AnyObject? {
        willSet {
            _thumbView.delegate = newValue
        }
    }
    
    private func _setup() {
        
        // setup thumb view
        _thumbView.frame = bounds
        _thumbView.clipsToBounds = true
        _thumbView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(_thumbView)
        
        
        // setup player view
        _playerView.frame = bounds
        _playerView.delegate = self
        _playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    fileprivate var _asset: Asset?
    fileprivate var _container: Container?
    
    fileprivate var _request: Request?
    fileprivate var _prepareing: Bool = false
    fileprivate var _prepared: Bool = false
    
    fileprivate lazy var _thumbView: PhotoContentView = .init()
    fileprivate lazy var _playerView: PlayerView = .init()
}

extension VideoContentView: Displayable {
    
    /// Will display the asset
    func willDisplay(with asset: Asset, container: Container, orientation: UIImageOrientation) {
        logger.debug?.write()
        
        // save context
        _asset = asset
        _container = container
        
        // update large content
        _thumbView.willDisplay(with: asset, container: container, orientation: orientation)
    }
    
    /// End display the asset
    func endDisplay(with container: Container) {
        logger.trace?.write()
        
        // when are requesting an player item, please cancel it
        _request.map { request in
            // reveal cancel
            container.cancel(with: request)
        }
        
        // stop player if needed
        _playerView.stop()
        
        // clear context
        _asset = nil
        _request = nil
        _container = nil
        // reset status
        _prepared = false
        _prepareing = false
        
        // clear content
        _thumbView.endDisplay(with: container)
    }
}
extension VideoContentView: Playable {
    
    /// Start the player or Resume the player
    func play(with asset: Asset, container: Container) {
        
        // if is prepared, start playing
        if _prepared {
            _playerView.play()
            return
        }
        // if is prepareing, start prepare
        if !_prepareing {
            _prepare()
            return
        }
    }
    
    /// Stop player
    func stop(with asset: Asset, container: Container) {
        _playerView.stop()
    }
    
    /// Suspend the player
    func suspend(with asset: Asset, container: Container) {
        _playerView.suspend()
    }
    
    /// Resume the player
    func resume(with asset: Asset, container: Container) {
        _playerView.resume()
    }
    
    /// Prepare the player
    private func _prepare() {
        // there must be the item
        guard let asset = _asset, let container = _container else {
            return
        }
        
        // prepare data
        let options = SourceOptions()
        
        // request player item
        _prepareing = true
        _prepared = false
        _request = container.request(forItem: asset, options: options) { [weak self, weak asset] item, response in
            // if the asset is nil, the asset has been released
            guard let asset = asset, let item = item as? AVPlayerItem else {
                return
            }
            self?._prepareing = false
            self?._prepared = true
            self?._updateItem(item, response: response, asset: asset)
        }
    }
    // update palyer item
    private func _updateItem(_ item: AVPlayerItem?, response: Response, asset: Asset) {
        // the current asset has been changed?
        guard _asset === asset else {
            // reset status
            _prepareing = false
            _prepared = false
            // change, all reqeust is expire
            logger.debug?.write("\(asset.identifier) item is expire")
            return
        }
        logger.trace?.write("\(asset.identifier)")
        
        // if item is nil, the player preare error 
        guard let item = item else {
            // notice to delegate
            (delegate as? PlayableDelegate)?.player(self, didOccur: asset, error: response.error)
            return
        }
        _playerView.prepare(with: item)
    }
    
}

/// provide player event forward support
extension VideoContentView: PlayerViewDelegate {
    
    /// if the data is prepared to do the call this method
    func player(didPrepare player: PlayerView, item: AVPlayerItem) {
        // if asset is nil, the view no display
        guard let asset = _asset else {
            return
        }
        (delegate as? PlayableDelegate)?.player(self, didPrepared: asset)
        // prepare in a hidden the view
        _playerView.frame = bounds
        addSubview(_playerView)
        _thumbView.removeFromSuperview()
    }
    
    /// if you start playing the call this method
    func player(didStartPlay player: PlayerView, item: AVPlayerItem) {
        // if asset is nil, the view no display
        guard let asset = _asset else {
            return
        }
        (delegate as? PlayableDelegate)?.player(self, didStartPlay: asset)
    }
    /// if take the initiative to stop the play call this method
    func player(didStop player: PlayerView, item: AVPlayerItem) {
        // if asset is nil, the view no display
        guard let asset = _asset else {
            return
        }
        (delegate as? PlayableDelegate)?.player(self, didStop: asset)
        // stop to clear
        _thumbView.frame = bounds
        addSubview(_thumbView)
        _playerView.removeFromSuperview()
    }
    
    /// if the interruption due to lack of enough data to invoke this method
    func player(didStalled player: PlayerView, item: AVPlayerItem) {
        // if asset is nil, the view no display
        guard let asset = _asset else {
            return
        }
        (delegate as? PlayableDelegate)?.player(self, didStalled: asset)
    }
    /// if play is interrupted call the method, example: pause, in background mode, in the call
    func player(didSuspend player: PlayerView, item: AVPlayerItem) {
        // if asset is nil, the view no display
        guard let asset = _asset else {
            return
        }
        (delegate as? PlayableDelegate)?.player(self, didSuspend: asset)
    }
    /// if interrupt restored to call this method
    /// automatically restore: in background mode to foreground mode, in call is end
    func player(didResume player: PlayerView, item: AVPlayerItem) {
        // if asset is nil, the view no display
        guard let asset = _asset else {
            return
        }
        (delegate as? PlayableDelegate)?.player(self, didResume: asset)
    }
    
    /// if play completed call this method
    func player(didFinish player: PlayerView, item: AVPlayerItem) {
        // if asset is nil, the view no display
        guard let asset = _asset else {
            return
        }
        (delegate as? PlayableDelegate)?.player(self, didFinish: asset)
    }
    /// if the occur error call the method
    func player(didOccur player: PlayerView, item: AVPlayerItem, error: Error?) {
        // if asset is nil, the view no display
        guard let asset = _asset else {
            return
        }
        (delegate as? PlayableDelegate)?.player(self, didOccur: asset, error: error)
        // stop to clear
        addSubview(_thumbView)
        _playerView.removeFromSuperview()
    }
}
