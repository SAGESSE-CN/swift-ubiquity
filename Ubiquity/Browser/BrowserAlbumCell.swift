//
//  BrowserAlbumCell.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumCell: UICollectionViewCell, Displayable {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    deinit {
        // if the cell is displaying, hidden after then destroyed
        guard let container = _container else {
            return
        }
        
        // call end display
        endDisplay(with: container)
    }
    
    /// the displayer delegate
    weak var delegate: AnyObject? 
    
    /// Will display the asset
    func willDisplay(with asset: Asset, container: Container, orientation: UIImageOrientation) {
        
        // save context
        _asset = asset
        _container = container
        _orientation = orientation
       
        _badgeView?.isHidden = true
        
        // make options
        let options = SourceOptions()
        
        // setup content
        _allowsInvaildContents = true
        _request = container.request(forImage: asset, size: BrowserAlbumLayout.thumbnailItemSize, mode: .aspectFill, options: options) { [weak self, weak asset] contents, response in
            // if the asset is nil, the asset has been released
            guard let asset = asset else {
                return
            }
            // update contents
            self?._updateContents(contents, response: response, asset: asset)
        }
    }
    
    /// End display the asset
    func endDisplay(with container: Container) {
        
        // when are requesting an image, please cancel it
        _request.map { request in
            // cancel
            container.cancel(with: request)
        }
        
        // clear context
        _asset = nil
        _request = nil
        _container = nil
        
        // NOTE: can't clear images, otherwise  fast scroll when will lead to generate a snapshot of the blank
        //_imageView?.image = nil
    }
    
    // update contents
    private func _updateContents(_ contents: UIImage?, response: Response, asset: Asset) {
        // the current asset has been changed?
        guard _asset === asset else {
            // changed, all reqeust is expire
            guard _allowsInvaildContents else {
                logger.debug?.write("\(asset.identifier) image is expire")
                return
            }
            // update invaild contents
            _imageView?.image = contents
            return
        }
        
        // update contents
        _imageView?.image = contents?.ub_withOrientation(_orientation)
        _allowsInvaildContents = false
        
        // update badge icon
        _updateBadge(with: contents == nil)
    }
    
    private func _updateBadge(with downloading: Bool) {
        
        let mediaType = _asset?.mediaType ?? .unknown
        let mediaSubtypes = _asset?.mediaSubtypes ?? []
        
        // setup badge item
        switch mediaType {
        case .video:
            
            // less than 1, the display of 1
            let duration = ceil(_asset?.duration ?? 0)
            
            _badgeView?.backgroundImage = BadgeView.ub_backgroundImage
            _badgeView?.rightItem = .text(.init(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60))
            _badgeView?.leftItem = {
                // high-frame-rate video.
                if mediaSubtypes.contains(.videoHighFrameRate) {
                    return .slomo
                }
                // time-lapse video.
                if mediaSubtypes.contains(.videoTimelapse) {
                    return .timelapse
                }
                // normal video.
                return .video
            }()
            
        case .image,
             .audio,
             .unknown:
            
            // large-format panorama photo.
            if mediaSubtypes.contains(.photoPanorama) {
                // show icon
                _badgeView?.leftItem = .panorama
                _badgeView?.rightItem = nil
                _badgeView?.backgroundImage = BadgeView.ub_backgroundImage
                
            } else {
                // hidden all
                _badgeView?.leftItem = nil
                _badgeView?.rightItem = nil
                _badgeView?.backgroundImage = nil
            }
        }
        
        // the currently download?
        if downloading {
            // the icon is downloading
            _badgeView?.rightItem = .downloading
        }
        
        // show badge
        _badgeView?.isHidden = false
    }
    
    private func _setup() {
        
        // setup badge view
        let badgeView = BadgeView()
        badgeView.frame = .init(x: 0, y: contentView.bounds.height - 20, width: contentView.bounds.width, height: 20)
        badgeView.tintColor = .white
        badgeView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        badgeView.isUserInteractionEnabled = false
        
        // set default background color
        contentView.backgroundColor = .ub_init(hex: 0xf0f0f0)
        //contentView.clearsContextBeforeDrawing = false
        contentView.clipsToBounds = true
        contentView.contentMode = .scaleAspectFill
        contentView.addSubview(badgeView)
        
        isOpaque = true
        clipsToBounds = true
        backgroundColor = contentView.backgroundColor
        
        // mapping
        _imageView = contentView as? UIImageView
        _badgeView = badgeView
    }
    
    fileprivate var _asset: Asset?
    fileprivate var _container: Container?
    
    fileprivate var _request: Request?
    fileprivate var _orientation: UIImageOrientation = .up
    fileprivate var _allowsInvaildContents: Bool = false
    
    fileprivate var _imageView: UIImageView?
    fileprivate var _badgeView: BadgeView?
}

/// Add dynamic class support
extension BrowserAlbumCell {
    
    // provide content view of class
    dynamic class var contentViewClass: AnyClass {
        return UIImageView.self
    }
    // provide content view of class, iOS 8+
    fileprivate dynamic class var _contentViewClass: AnyClass {
        return contentViewClass
    }
}

/// Add custom transition support
extension BrowserAlbumCell: TransitioningView {
    
    var ub_frame: CGRect {
        return convert(bounds, to: window)
    }
    var ub_bounds: CGRect {
        // if the asset was not set
        guard let asset = _asset else {
            // can’t alignment
            return contentView.bounds
        }
        return contentView.bounds.ub_aligned(with: .init(width: asset.pixelWidth, height: asset.pixelHeight))
    }
    var ub_transform: CGAffineTransform {
        return contentView.transform.rotated(by: _orientation.ub_angle)
    }
    
    func ub_snapshotView(with context: TransitioningContext) -> UIView? {
        return contentView.snapshotView(afterScreenUpdates: context.ub_operation.appear)
    }
}
