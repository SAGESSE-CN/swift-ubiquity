//
//  PhotoContentView.swift
//  Ubiquity
//
//  Created by SAGESSE on 4/22/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// display photo resources
internal class PhotoContentView: AnimatedImageView, Displayable {

    ///
    /// the displayer delegate
    ///
    weak var delegate: AnyObject?
    
    ///
    /// Show an asset
    ///
    /// - parameter asset: need the display the resource
    /// - parameter library: the asset in this library
    /// - parameter orientation: need to display the image direction
    ///
    func willDisplay(with asset: Asset, in library: Library, orientation: UIImageOrientation) {
        logger.trace?.write()
        
        // have any change?
        guard _asset !== asset else {
            return
        }
        // save context
        _asset = asset
        _library = library
        _donwloading = false
        
        // update image
        backgroundColor = .ub_init(hex: 0xf0f0f0)
        
        let thumbSize = BrowserAlbumLayout.thumbnailItemSize
        let thumbOptions = DataSourceOptions(isSynchronous: true)
        let largeSize = CGSize(width: asset.ub_pixelWidth, height: asset.ub_pixelHeight)
        let largeOptions = DataSourceOptions(progressHandler: { [weak self, weak asset] progress, response in
            DispatchQueue.main.async {
                // if the asset is nil, the asset has been released
                guard let asset = asset else {
                    return
                }
                // update progress
                self?._updateContentsProgress(progress, response: response, asset: asset)
            }
        })
        
        _requests = [
            // request thumb iamge
            library.ub_requestImage(for: asset, size: thumbSize, mode: .aspectFill, options: thumbOptions) { [weak self, weak asset] contents, response in
                // if the asset is nil, the asset has been released
                guard let asset = asset else {
                    return
                }
                // the image is vaild?
                guard (self?.image?.size.width ?? 0) < (contents?.size.width ?? 0) else {
                    return
                }
                // update contents
                self?._updateContents(contents, response: response, asset: asset)
            },
            // request large image
            library.ub_requestImage(for: asset, size: largeSize, mode: .aspectFill, options: largeOptions) { [weak self, weak asset] contents, response in
                // if the asset is nil, the asset has been released
                guard let asset = asset else {
                    return
                }
                // the image is vaild?
                guard (self?.image?.size.width ?? 0) < (contents?.size.width ?? 0) else {
                    return
                }
                // update contents
                self?._updateContents(contents, response: response, asset: asset)
            }
        ]
    }
    
    ///
    /// Hide an asset
    ///
    /// - parameter asset: current display the resource
    /// - parameter library: the asset in this library
    ///
    func endDisplay(with asset: Asset, in library: Library) {
        logger.trace?.write()
        
        // when are requesting an image, please cancel it
        _requests?.forEach { request in
            request.map { request in
                // reveal cancel
                library.ub_cancelRequest(request)
            }
        }
        
        // clear context
        _asset = nil
        _requests = nil
        _library = nil
        
        // clear contents
        self.image = nil
        
        // stop animation if needed
        stopAnimating()
    }
    
    private func _updateContents(_ contents: UIImage?, response: Response, asset: Asset) {
        // the current asset has been changed?
        guard _asset === asset else {
            // change, all reqeust is expire
            logger.debug?.write("\(asset.ub_identifier) image is expire")
            return
        }
        logger.trace?.write("\(asset.ub_identifier) => \(contents?.size ?? .zero)")
        
        // update contents
        self.ub_setImage(contents ?? self.image, animated: true)
    }
    
    private func _updateContentsProgress(_ progress: Double, response: Response, asset: Asset) {
        // the current asset has been changed?
        guard _asset === asset else {
            // change, all reqeust is expire
            logger.debug?.write("\(asset.ub_identifier) progress is expire")
            return
        }
        // if the library required to download
        // if download completed start animation is an error
        if !_donwloading && progress < 1 {
            _donwloading = true
            // start downloading
            (delegate as? DisplayableDelegate)?.displayer(self, didBeginDownload: asset)
        }
        // only in the downloading  to update progress
        if (_donwloading) {
            // update donwload progress
            (delegate as? DisplayableDelegate)?.displayer(self, didReceive: asset, progress: progress)
        }
        // if the donwload completed or an error occurred, end of the download
        if (_donwloading && progress >= 1) || (response.ub_error != nil) {
            _donwloading = false
            // complate download
            (delegate as? DisplayableDelegate)?.displayer(self, didEndDownload: asset, error: response.ub_error)
        }
    }
    
    fileprivate var _asset: Asset?
    fileprivate var _library: Library?
    fileprivate var _requests: [Request?]?
    fileprivate var _donwloading: Bool = false
}
