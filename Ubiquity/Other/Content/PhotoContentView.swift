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

    /// The displayer delegate
    weak var delegate: AnyObject?
    
    /// Will display the asset
    func willDisplay(with asset: Asset, container: Container, orientation: UIImageOrientation) {
        logger.trace?.write()
        
        // have any change?
        guard _asset !== asset else {
            return
        }
        // save context
        _asset = asset
        _container = container
        _donwloading = false
        
        // update image
        backgroundColor = .ub_init(hex: 0xf0f0f0)
        
        let thumbSize = BrowserAlbumLayout.thumbnailItemSize
        let thumbOptions = DataSourceOptions(isSynchronous: true)
        let largeSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
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
            container.request(forImage: asset, size: thumbSize, mode: .aspectFill, options: thumbOptions) { [weak self, weak asset] contents, response in
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
            container.request(forImage: asset, size: largeSize, mode: .aspectFill, options: largeOptions) { [weak self, weak asset] contents, response in
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
    
    /// End display the asset
    func endDisplay(with asset: Asset, container: Container) {
        logger.trace?.write()
        
        // when are requesting an image, please cancel it
        _requests?.forEach { request in
            request.map { request in
                container.cancel(with: request)
            }
        }
        
        // clear context
        _asset = nil
        _requests = nil
        _container = nil
        
        // clear contents
        self.image = nil
        
        // stop animation if needed
        stopAnimating()
    }
    
    private func _updateContents(_ contents: UIImage?, response: Response, asset: Asset) {
        // the current asset has been changed?
        guard _asset === asset else {
            // change, all reqeust is expire
            logger.debug?.write("\(asset.identifier) image is expire")
            return
        }
        //logger.trace?.write("\(asset.identifier) => \(contents?.size ?? .zero)")
        
        // update contents
        self.ub_setImage(contents ?? self.image, animated: true)
    }
    
    private func _updateContentsProgress(_ progress: Double, response: Response, asset: Asset) {
        // the current asset has been changed?
        guard _asset === asset else {
            // change, all reqeust is expire
            logger.debug?.write("\(asset.identifier) progress is expire")
            return
        }
        // if the container required to download
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
        if (_donwloading && progress >= 1) || (response.error != nil) {
            _donwloading = false
            // complate download
            (delegate as? DisplayableDelegate)?.displayer(self, didEndDownload: asset, error: response.error)
        }
    }
    
    fileprivate var _asset: Asset?
    fileprivate var _container: Container?
    fileprivate var _requests: [Request?]?
    fileprivate var _donwloading: Bool = false
}
