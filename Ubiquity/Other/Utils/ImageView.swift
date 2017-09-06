//
//  ImageView.swift
//  Ubiquity
//
//  Created by sagesse on 06/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class ImageLayer: CATiledLayer, CALayerDelegate {
    
    internal override init() {
        super.init()
        _setup()
    }
    internal override init(layer: Any) {
        super.init(layer: layer)
        _setup()
    }
    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    /// Animation duration for after tile loading finishes
    override class func fadeDuration() -> CFTimeInterval {
        return 0.00
    }
    
    /// limit the maximum tile zoom level
    var tileMaximumZoomLevel: Int = 4
    
    internal var image: Image? {
        willSet {
            setNeedsDisplay()
        }
    }
    
    /// Render each tile
    internal func draw(_ layer: CALayer, in ctx: CGContext) {
        
        // get the current need display rect
        let rect = ctx.boundingBoxOfClipPath
        
        // limit the maximum tile size, because if the tile beyond this size you can't see it
        guard (1 / ctx.ctm.a / contentsScale) <= CGFloat(tileMaximumZoomLevel + 1) else {
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
        
        //#if DEBUG
        //    ctx.setFillColor(UIColor.black.withAlphaComponent(0.2).cgColor)
        //    ctx.fill(.init(origin: .zero, size: rect.size))
        //#endif
    }
    
    /// Setup layer configure
    private func _setup() {
        
        delegate = self
        
        tileSize = .init(width: 512, height: 512)
        tileMaximumZoomLevel = 5 // 2560x2560
        
        levelsOfDetail = 1
        levelsOfDetailBias = 2
    }
}

public class ImageView: UIImageView {
    
    
    public override var image: UIImage? {
        willSet {
            
            guard let image = newValue as? Image else {
                return
            }
            
            DispatchQueue.global().async {
                
                guard let nr = image.renderer.scaling(to: .init(x: 0, y: 0, width: 2560, height: 2560)) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.layer.contents = nr
                }
            }
            
            
            let tiled = ImageLayer()
////            let renderer = ImageRenderer()
//            
            tiled.image = newValue as? Image
//
////            tiled.levelsOfDetail = 1
////            tiled.levelsOfDetailBias = 3
////            tiled.frame = bounds
////            tiled.delegate = renderer
////            
////            _tiledRender = renderer
//            
//            
//            
            layer.addSublayer(tiled)
//
            _tiledLayer = tiled
        }
    }
//    public override var contentScaleFactor: CGFloat {
//        willSet {
//            guard let renderer = _tiledRender else {
//                return
//            }
//            _tiledLayer?.tileSize = renderer.tileSize.applying(.init(scaleX: contentScaleFactor, y: contentScaleFactor))
//        }
//    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // the layout is change?
        if _tiledLayer?.frame != bounds {
            _tiledLayer?.frame = bounds
        }
    }
    
    private var _tiledLayer: ImageLayer?
    private var _tiledRender: ImageRenderer?
}



//class TestLargeLayer: CATiledLayer {
//    
//    
//}
//
//class TestLargeImageView: UIView {
//    
//    override class var layerClass: AnyClass {
//        return TestLargeLayer.self
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        _setup()
//    }
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        _setup()
//    }
//    
//    var image: UIImage?
//    
//    
//    
////        let scale = context.ctm.a / tiledLayer.contentsScale
////        let column = Int(rect.minX * scale / tileSize.width + 0.5)
////        let row = Int(rect.minY * scale / tileSize.height + 0.5)
////        
////        let str = "\(rect)\n\(ceil(scale * 200) / 200)\n[\(row), \(column)]" as NSString
////        logger.debug?.write(rect.size)
//    
//    private func _setup() {
//        
//        // configure tile
//        tiledLayer.tileSize = tileSize.applying(.init(scaleX: contentScaleFactor, y: contentScaleFactor))
//        tiledLayer.levelsOfDetail = 1
//        tiledLayer.levelsOfDetailBias = 3
//        
//        
//        backgroundColor = .clear
//    }
//}

