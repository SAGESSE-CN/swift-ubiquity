//
//  BrowserAlbumCell.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    deinit {
        // on destory if not the end display, need to manually call it
        guard let asset = _asset, let library = _library else {
            return
        }
        // call end display
        endDisplay(with: asset, in: library)
    }
    
    // display asset
    func willDisplay(with asset: Asset, in library: Library, orientation: UIImageOrientation) {
        
        // save context
        _asset = asset
        _library = library
        _orientation = orientation
       
        _badgeView?.isHidden = true
        
        // make options
        let options = DataSourceOptions()
        
        // setup content
        _allowsInvaildContents = true
        _request = library.ub_requestImage(for: asset, targetSize: BrowserAlbumLayout.thumbnailItemSize, contentMode: .aspectFill, options: options) { [weak self, weak asset] contents, response in
            // if the asset is nil, the asset has been released
            guard let asset = asset else {
                return
            }
            // update contents
            self?._updateContents(contents, response: response, asset: asset)
        }
    }
    // end display asset
    func endDisplay(with asset: Asset, in library: Library) {
        
        // when are requesting an image, please cancel it
        _request.map { request in
            // cancel
            library.ub_cancelRequest(request)
        }
        
        // clear context
        _asset = nil
        _request = nil
        _library = nil
        
        // can't clear images, otherwise  fast scroll when will lead to generate a snapshot of the blank
        //_imageView?.image = nil
    }
    
    // update contents
    private func _updateContents(_ contents: UIImage?, response: Response, asset: Asset) {
        // the current asset has been changed?
        guard _asset === asset else {
            // changed, all reqeust is expire
            guard _allowsInvaildContents else {
                logger.debug?.write("\(asset.ub_localIdentifier) image is expire")
                return
            }
            // update invaild contents
            _imageView?.image = contents
            return
        }
        logger.trace?.write("\(asset.ub_localIdentifier) => \(contents?.size ?? .zero)")
        
        // if the request status is completed or cancelled, clear the request
        // `contents` is nil, the task need download
        // `ub_error` not is nil, the task an error
        // `ub_cancelled` is true, the task is canceled
        // `ub_degraded` is false, the task is completed
        if response.ub_error != nil || response.ub_cancelled || (contents != nil && !response.ub_degraded) {
            _request = nil
        }
        
        // update contents
        _imageView?.image = contents?.ub_withOrientation(_orientation)
        _allowsInvaildContents = false
        
        // update badge icon
        _updateBadge(with: contents == nil)
    }
    private func _updateBadge(with downloading: Bool) {
        
        let mediaType = _asset?.ub_mediaType ?? .unknown
        let mediaSubtypes = _asset?.ub_mediaSubtypes ?? []
        
        // setup badge item
        switch mediaType {
        case .video:
            
            // less than 1, the display of 1
            let duration = ceil(_asset?.ub_duration ?? 0)
            
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
    fileprivate var _library: Library?
    
    fileprivate var _request: Request?
    fileprivate var _orientation: UIImageOrientation = .up
    fileprivate var _allowsInvaildContents: Bool = false
    
    fileprivate var _imageView: UIImageView?
    
    fileprivate var _badgeView: BadgeView?
}

/// custom transition support
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
        return contentView.bounds.ub_aligned(with: .init(width: asset.ub_pixelWidth, height: asset.ub_pixelHeight))
    }
    var ub_transform: CGAffineTransform {
        return contentView.transform.rotated(by: _orientation.ub_angle)
    }
    
    func ub_snapshotView(with context: TransitioningContext) -> UIView? {
        return contentView.snapshotView(afterScreenUpdates: context.ub_operation.appear)
    }
}

/// dynamic class support
internal extension BrowserAlbumCell {
    // dynamically generated class
    dynamic class func `dynamic`(with viewClass: AnyClass) -> AnyClass {
        let name = "\(NSStringFromClass(self))<\(NSStringFromClass(viewClass))>"
        // if the class has been registered, ignore
        if let newClass = objc_getClass(name) as? AnyClass {
            return newClass
        }
        // if you have not registered this, dynamically generate it
        let newClass: AnyClass = objc_allocateClassPair(self, name, 0)
        let method: Method = class_getClassMethod(self, #selector(getter: contentViewClass))
        objc_registerClassPair(newClass)
        // because it is a class method, it can not used class, need to use meta class
        guard let metaClass = objc_getMetaClass(name) as? AnyClass else {
            return newClass
        }
        let getter: @convention(block) () -> AnyClass = {
            return viewClass
        }
        // add class method
        class_addMethod(metaClass, #selector(getter: contentViewClass), imp_implementationWithBlock(unsafeBitCast(getter, to: AnyObject.self)), method_getTypeEncoding(method))
        return newClass
    }
    // provide content view of class
    dynamic class var contentViewClass: AnyClass {
        return CanvasView.self
    }
    // provide content view of class, iOS 8+
    fileprivate dynamic class var _contentViewClass: AnyClass {
        return contentViewClass
    }
}
