//
//  BrowserAlbumCell.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumCell: UICollectionViewCell, Displayable, TransitioningView {
    
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
        guard let container = container else {
            return
        }
        
        // call end display
        endDisplay(with: container)
    }
    
    // MARK: Asset Display
    
    /// the displayer delegate
    weak var delegate: AnyObject?
    
    /// Will display the asset
    func willDisplay(with asset: Asset, container: Container, orientation: UIImageOrientation) {
        
        // save context
        self.asset = asset
        self.container = container
        self.orientation = orientation
       
        _badgeView?.isHidden = true
        _allowsInvaildContents = true
        
        // make options
        let options = SourceOptions()
        
        // setup content
        self.request = container.request(forImage: asset, size: BrowserAlbumLayout.thumbnailItemSize, mode: .aspectFill, options: options) { [weak self, weak asset] contents, response in
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
        request.map { request in
            container.cancel(with: request)
        }
        
        // clear context
        self.asset = nil
        self.request = nil
        self.container = nil
        
        // NOTE: can't clear images, otherwise  fast scroll when will lead to generate a snapshot of the blank
        //_imageView?.image = nil
    }
    
    // MARK: Dynamic Class
    
    /// Provide content view of class
    dynamic class var contentViewClass: AnyClass {
        return UIImageView.self
    }
    
    /// Provide content view of class, iOS 8+
    private dynamic class var _contentViewClass: AnyClass {
        return contentViewClass
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
        return contentView.bounds.ub_aligned(with: .init(width: asset.pixelWidth, height: asset.pixelHeight))
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
                logger.debug?.write("\(asset.identifier) image is expire")
                return
            }
            // update invaild contents
            _imageView?.image = contents
            return
        }
        
        // update contents
        _imageView?.image = contents?.ub_withOrientation(self.orientation)
        _allowsInvaildContents = false
        
        // update badge icon
        _updateBadge(with: contents == nil)
    }
    
    // MARK: Asset Contents
    
    /// Update badge
    private func _updateBadge(with downloading: Bool) {
        
        let mediaType = asset?.mediaType ?? .unknown
        let mediaSubtypes = asset?.mediaSubtypes ?? []
        
        // setup badge item
        switch mediaType {
        case .video:
            
            // less than 1, the display of 1
            let duration = ceil(asset?.duration ?? 0)
            
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
    
    /// Init UI
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
    
    // MARK: Property
    
    // contents
    private(set) var asset: Asset?
    private(set) var container: Container?
    
    // status
    private(set) var request: Request?
    private(set) var orientation: UIImageOrientation = .up
    
    // MARK: Ivar
    
    private var _allowsInvaildContents: Bool = false
    
    private var _imageView: UIImageView?
    private var _badgeView: BadgeView?
}
