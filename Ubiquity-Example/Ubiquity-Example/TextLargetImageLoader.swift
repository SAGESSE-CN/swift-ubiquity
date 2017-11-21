//
//  TextLargetImageLoader.swift
//  Ubiquity-Example
//
//  Created by SAGESSE on 9/3/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

import CoreGraphics
import CoreGraphics.CGImage

import Ubiquity

//@testable import Ubiquity
//
//class TestLargeLayer: CATiledLayer {
//    
//    override class func fadeDuration() -> CFTimeInterval {
//        return 0.02
//    }
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
//        _configure()
//    }
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        _configure()
//    }
//    
//    // MARK: Properties
//    
//    var tiledLayer: CATiledLayer {
//        return layer as! CATiledLayer
//    }
//    
//    var tileSize: CGSize = .init(width: 256, height: 256) {
//        willSet {
//            tiledLayer.tileSize = newValue.applying(.init(scaleX: contentScaleFactor, y: contentScaleFactor))
//        }
//    }
//    
//    var image: UIImage?
//    
//    /// limit the maximum tile zoom level
//    var maximumTileZoomLevel: Int = 16
//    
//    override func draw(_ rect: CGRect) {
//        // limit the maximum tile size, because if the tile beyond this size you can't see it
//        guard let context = UIGraphicsGetCurrentContext(), ceil(rect.width / tileSize.width) <= CGFloat(maximumTileZoomLevel + 1) else {
//            return
//        }
//        
//        // cropping the image that need to be display from source image
//        guard let cropped = image?.cgImage?.cropping(to: rect) else {
//            return
//        }
//        
//        // must set the starting point for the drawing, otherwise the flip drawing will wrong
//        context.translateBy(x: rect.minX, y: rect.minY)
//        
//        // because of the use of context.draw and UIKit coordinates are not the same, so the need to flip drawing image
//        context.translateBy(x: 0, y: rect.height)
//        context.scaleBy(x: 1, y: -1)
//        
//        // drawing cropped image
//        context.draw(cropped, in: .init(origin: .zero, size: rect.size))
//    }
//    
////        let scale = context.ctm.a / tiledLayer.contentsScale
////        let column = Int(rect.minX * scale / tileSize.width + 0.5)
////        let row = Int(rect.minY * scale / tileSize.height + 0.5)
////        
////        let str = "\(rect)\n\(ceil(scale * 200) / 200)\n[\(row), \(column)]" as NSString
////        logger.debug?.write(rect.size)
//    
//    private func _configure() {
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
//

class TextLargetImageLoader: UIViewController, UIScrollViewDelegate {
    
    
//- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize
//{
//    UIImage *sourceImage = self;
//    UIImage *newImage = nil;
//    
//    if (!sourceImage)
//    {
//        return nil;
//    }
//    
//    CGSize imageSize = sourceImage.size;
//    CGFloat width = imageSize.width;
//    CGFloat height = imageSize.height;
//    
//    CGFloat targetWidth = targetSize.width;
//    CGFloat targetHeight = targetSize.height;
//    
//    CGFloat scaleFactor = 0.0;
//    CGFloat scaledWidth = targetWidth;
//    CGFloat scaledHeight = targetHeight;
//    
//    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
//    
//    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
//        
//        CGFloat widthFactor = targetWidth / width;
//        CGFloat heightFactor = targetHeight / height;
//        
//        if (widthFactor < heightFactor)
//            scaleFactor = widthFactor;
//        else
//            scaleFactor = heightFactor;
//        
//        scaledWidth  = width * scaleFactor;
//        scaledHeight = height * scaleFactor;
//        
//        // center the image
//        
//        if (widthFactor < heightFactor) {
//            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
//        } else if (widthFactor > heightFactor) {
//            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
//        }
//    }
//    
//    
//    // this is actually the interesting part:
//    
//    UIGraphicsBeginImageContext(targetSize);
//    
//    CGRect thumbnailRect = CGRectZero;
//    thumbnailRect.origin = thumbnailPoint;
//    thumbnailRect.size.width  = scaledWidth;
//    thumbnailRect.size.height = scaledHeight;
//    
//    [sourceImage drawInRect:thumbnailRect];
//    
//    newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    if(newImage == nil) NSLog(@"could not scale image");
//    
//    
//    return newImage ;
//}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let path = Bundle.main.url(forResource: "《塞尔达传说：荒野之息》导航地图", withExtension: "jpg") else {
            return
        }
        guard let data = try? Data(contentsOf: path, options: .mappedIfSafe) else {
            return
        }
        
        let image = Ubiquity.Image(data: data)
        let size = image?.size ?? .zero
        let scale = view.bounds.width / max(size.width, 1)
        
        let imageView = Ubiquity.ImageView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
//        let scrollView = UIScrollView(frame: view.bounds)
        
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.image = image
        imageView.placeholderImage = #imageLiteral(resourceName: "ser")
        
//        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        scrollView.contentSize = size
//        scrollView.delegate = self
//        scrollView.addSubview(imageView)
//
//        view.addSubview(scrollView)
//
//        _contentView = imageView
//
//        scrollView.minimumZoomScale = 1 / scale
//        scrollView.maximumZoomScale = 1
//        scrollView.zoomScale = scrollView.minimumZoomScale
        
        imageView.frame = .init(x: 0, y: 88, width: size.width * scale, height: size.height * scale)
        
        view.addSubview(imageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return _contentView
    }
    
    private var _contentView: UIView?
}
