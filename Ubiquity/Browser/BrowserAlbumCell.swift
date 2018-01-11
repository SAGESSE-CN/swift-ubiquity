//
//  BrowserAlbumCell.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumCell: SourceCollectionViewCell, TransitioningView {
    
    
    /// The current displayed content size.
    var contentSize: CGSize = .zero

    /// The current display content inset.
    var contentInset: UIEdgeInsets = .zero

    
    override func configure() {
        super.configure()
        
        // setup badge view
        let badgeView = BadgeView(frame: .zero)
        
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
        
        // setup default value
        contentSize = .init(width: frame.width * UIScreen.main.scale, height: frame.height * UIScreen.main.scale)
        contentInset = .init(top: 4.5, left: 4.5, bottom: 4.5, right: 4.5)
        
        // mapping
        _imageView = contentView as? UIImageView
        _badgeView = badgeView
    }
    
    override func willDisplay(_ container: Container, orientation: UIImageOrientation) {
        super.willDisplay(container, orientation: orientation)
        
        // Only processing asset data.
        guard let asset = asset else {
            return
        }
        
        _badgeView?.isHidden = true
        _allowsInvaildContents = true
        
        // setup content
        self.request = container.request(forImage: asset, size: contentSize, mode: .aspectFill, options: .init()) { [weak self, weak asset] contents, response in
            // if the asset is nil, the asset has been released
            guard let asset = asset else {
                return
            }
            // update contents
            self?._updateContents(contents, response: response, asset: asset)
        }
    }
    
    override func endDisplay(_ container: Container) {
        super.endDisplay(container)
        
        // when are requesting an image, please cancel it
        request.map {
            container.cancel(with: $0)
        }
        
        // clear context
        self.request = nil
        
        // NOTE: can't clear images, otherwise  fast scroll when will lead to generate a snapshot of the blank
        //_imageView?.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // update content size.
        contentSize = .init(width: frame.width * UIScreen.main.scale,
                            height: frame.height * UIScreen.main.scale)
    }
    
    // MARK: Custom Transition
    
    var ub_frame: CGRect {
        return convert(bounds, to: window)
    }
    
    var ub_bounds: CGRect {
        // if the asset was not set
        guard let asset = asset else {
            // can’t alignment
            return contentView.bounds
        }
        return contentView.bounds.ub_aligned(with: .init(width: asset.ub_pixelWidth, height: asset.ub_pixelHeight))
    }
    
    var ub_transform: CGAffineTransform {
        return contentView.transform.rotated(by: orientation.ub_angle)
    }
    
    func ub_snapshotView(with context: TransitioningContext) -> UIView? {
        return contentView.snapshotView(afterScreenUpdates: context.ub_operation.appear)
    }
    
    // MARK: Asset Contents
    
    /// Update contents
    private func _updateContents(_ contents: UIImage?, response: Response, asset: Asset) {
        // the current asset has been changed?
        guard self.asset === asset else {
            // changed, all reqeust is expire
            guard _allowsInvaildContents else {
                logger.debug?.write("\(asset.ub_identifier) image is expire")
                return
            }
            // update invaild contents
            _imageView?.image = contents
            return
        }
        
        // update contents
        _imageView?.image = contents//?.ub_withOrientation(self.orientation)
        _allowsInvaildContents = false
        
        // update badge icon
        _updateBadge(with: contents == nil)
    }
    
    // MARK: Asset Contents
    
    /// Update badge
    private func _updateBadge(with downloading: Bool) {
        
        let mediaType = asset?.ub_type ?? .unknown
        let mediaSubtypes = AssetSubtype(rawValue: asset?.ub_subtype ?? 0)
        
        // setup badge item
        switch mediaType {
        case .video:
            
            // less than 1, the display of 1
            let duration = ceil(asset?.ub_duration ?? 0)
            
            _badgeView?.backgroundImage = BadgeView.defaultBackgroundImage
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
                _badgeView?.backgroundImage = BadgeView.defaultBackgroundImage
                
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
    
    
    // MARK: Property
    
    // status
    private(set) var request: Request?
    
    // MARK: Ivar
    
    private var _allowsInvaildContents: Bool = false
    
    private var _imageView: UIImageView?
    private var _badgeView: BadgeView?
}
