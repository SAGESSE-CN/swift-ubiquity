//
//  ImageView.swift
//  Ubiquity
//
//  Created by sagesse on 06/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class ImageTiledLayer: CATiledLayer, CALayerDelegate {
    
    /// Animation duration for after tile loading finishes
    override class func fadeDuration() -> CFTimeInterval {
        return 0.02
    }
}

internal class ImageTiledView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _configure()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _configure()
    }
    
    var image: Image? {
        willSet {
            setNeedsDisplay()
        }
    }
    
    /// limit the maximum tile zoom level
    var maximumZoomLevel: CGFloat {
        return _maximumZoomLevel
    }
    
    /// The display tiled size
    var tileSize: CGSize {
        set { return _update(forTile: newValue) }
        get { return _tileSize }
    }
    
    override func draw(_ rect: CGRect) {
        // only ImageTiledLayer events are handled
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // limit the maximum tile size, because if the tile beyond this size you can't see it
        guard (1 / ctx.ctm.a) <= CGFloat(maximumZoomLevel + 0.5) else {
            return
        }
        
        // cropping the image that need to be display from source image
        guard let cropped = image?.renderer.cropping(to: rect) else {
            return
        }
        
        // must set the starting point for the drawing, otherwise the flip drawing will wrong
        ctx.translateBy(x: rect.minX, y: rect.minY)
        
        // because of the use of context.draw and UIKit coordinates are not the same, so the need to flip drawing image
        ctx.translateBy(x: 0, y: rect.height)
        ctx.scaleBy(x: 1, y: -1)
        
        // drawing cropped image
        ctx.draw(cropped, in: .init(origin: .zero, size: rect.size))
        
//        #if DEBUG
//            ctx.setFillColor(UIColor.black.withAlphaComponent(0.2).cgColor)
//            ctx.fill(.init(origin: .zero, size: rect.size))
//        #endif
    }
    
//    var affineTransform: CGAffineTransform {
//        guard let size = image?.size else {
//            return .identity
//        }
//        if let affineTransform = _affineTransform {
//            return affineTransform
//        }
//        let affineTransform = CGAffineTransform(scaleX: size.width / bounds.width, y: size.height / bounds.height)
//        _affineTransform = affineTransform
//        return affineTransform
//    }
//
//    private var _affineTransform: CGAffineTransform?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // the cost of rendering is very large, so do not call setNeedsDisplay if it is not necessary
        if _cachedBounds?.size != bounds.size {
            _cachedBounds = bounds
            
            // it must be redraw
            setNeedsDisplay()
        }
    }
    
    override class var layerClass: AnyClass {
        return ImageTiledLayer.self
    }
    
    /// Update the tile configuration information
    private func _update(forTile size: CGSize) {
        // convert to absolute size
        let newSize = tileSize.applying(.init(scaleX: contentScaleFactor, y: contentScaleFactor))
        let newLevel = Image.largeImageMinimumSize.width / tileSize.width / contentScaleFactor
        
        logger.debug?.write("\(size) => \(newSize)/\(newLevel)")
        
        // update ivar
        _tileSize = size
        _maximumZoomLevel = newLevel
        
        // update layer
        _cachedLayer?.tileSize = newSize
    }
    
    private func _configure() {
        
        // update cache info
        _cachedLayer = layer as? ImageTiledLayer
        _cachedBounds = bounds
        
        // configure tile layer
        _update(forTile: _tileSize)
        
        _cachedLayer?.levelsOfDetail = 1
        _cachedLayer?.levelsOfDetailBias = 2
        
        // configure self
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    private var _cachedLayer: ImageTiledLayer?
    private var _cachedBounds: CGRect?
    
    private lazy var _tileSize: CGSize = .init(width: 256, height: 256)
    private lazy var _maximumZoomLevel: CGFloat = 2
}

public class ImageView: UIImageView {
    
    public override var image: UIImage? {
        set { return _update(forNormal: newValue, animated: false) }
        get { return _image }
    }
    
    public var placeholderImage: UIImage? {
        set { return _update(forPlaceholder: newValue, animated: false) }
        get { return _placeholderImage }
    }
    
    private func _update(forNormal newValue: UIImage?, animated: Bool) {
        // the image is changed?
        guard _image !== newValue else {
            return
        }
        logger.trace?.write()
        
        // update ivar
        _image = newValue
        
        // custom views are displayed only when needed
        guard let image = newValue as? Image, image.type != nil else {
            // need to call it to hide the custom view
            _update(forCustomizeView: nil, animated: animated)
            
            // update image using the super method
            // if image is empty, display placeholderImage
            return super.image = newValue ?? placeholderImage
        }
        
        // destory old custom view and create new custom view
        _update(forCustomizeView: image, animated: animated)
    }
    
    private func _update(forPlaceholder newValue: UIImage?, animated: Bool) {
        // the image is changed?
        let oldValue = _placeholderImage
        guard oldValue !== newValue else {
            return
        }
        logger.trace?.write()
        
        // update ivar
        _placeholderImage = newValue
        
        // only when you are using placeholderImage will you update it
        guard super.image === oldValue else {
            return
        }
        super.image = newValue
    }
    
    private func _update(forCustomizeView newValue: Image?, animated: Bool) {
        logger.trace?.write()

        // hiden tiled view for large image
        if let tiledView = _tiledView {
            
            tiledView.image = nil
            tiledView.removeFromSuperview()
            
            // disconnect, but there is no hidden, because it may need to hide animation
            _tiledView = nil
        }
        // hide animated view for animated image
        if let animatedView = _animatedView {
            
            animatedView.image = nil
            animatedView.removeFromSuperview()
            
            // disconnect, but there is no hidden, because it may need to hide animation
            _animatedView = nil
        }
        
        // is there a new image
        guard let newValue = newValue else {
            return
        }
        
        // since the custom is asynchronous, must first display placeholderImage
        if !newValue.largeImageIsLoaded {
            super.image = placeholderImage
        }

        // load large image
        newValue.generateLargeImage { largeImage in
            // this may not be in the main thread
            DispatchQueue.main.async {
                // if the image version has been changed, ignore the event
                guard newValue === self.image else {
                    return
                }
                
                // continue update custom view
                self._update(forCustomizeView: newValue, largeImage: largeImage, animated: animated)
            }
        }
    }
    private func _update(forCustomizeView newValue: Image, largeImage: UIImage?, animated: Bool) {
        logger.trace?.write()
        
        // if the larger image load fails, continue to display the placeholderImage
        super.image = largeImage ?? placeholderImage
        
        // 隐藏旧的附加视图
        let view = ImageTiledView(frame: self.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.image = newValue
        view.contentMode = contentMode
        view.transform = .init(scaleX: self.bounds.width / newValue.size.width, y: self.bounds.height / newValue.size.height )
        view.frame = self.bounds
        self.addSubview(view)
        _tiledView = view
        
        logger.debug?.write(self.bounds, newValue.size)
    }

    public override var frame: CGRect {
        didSet {
            logger.debug?.write(bounds)
            
            guard let image = _tiledView?.image else {
                return
            }
            _tiledView?.transform = .init(scaleX: bounds.width / image.size.width, y: bounds.height / image.size.height )
            _tiledView?.frame = bounds
        }
    }

    private var _image: UIImage?
    private var _placeholderImage: UIImage?
    
    private var _tiledView: ImageTiledView?
    private var _animatedView: ImageTiledView?
}

