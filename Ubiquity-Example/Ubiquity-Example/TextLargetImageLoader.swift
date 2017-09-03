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

@testable import Ubiquity

class TestLargeLayer: CATiledLayer {
    
    override class func fadeDuration() -> CFTimeInterval {
        return 0.02
    }
    
}
class TestLargeImageView: UIView {
    
    override class var layerClass: AnyClass {
        return TestLargeLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    // MARK: Properties
    
    var tiledLayer: CATiledLayer {
        return layer as! CATiledLayer
    }
    
    var tileSize: CGSize = .init(width: 256, height: 256) {
        willSet {
            tiledLayer.tileSize = newValue.applying(.init(scaleX: contentScaleFactor, y: contentScaleFactor))
        }
    }
    
    var image: UIImage?
    
//
    override func draw(_ rect: CGRect) {
//        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let scale = context.ctm.a / tiledLayer.contentsScale
        let column = Int(rect.minX * scale / tileSize.width + 0.5)
        let row = Int(rect.minY * scale / tileSize.height + 0.5)
        
//        let str = "\(rect)\n\(ceil(scale * 200) / 200)\n[\(row), \(column)]" as NSString
//        
//        if (Int(row % 2) + column) % 2 == 0 {
//            UIColor(white: 0, alpha: 0.5).setFill()
//            UIGraphicsGetCurrentContext()?.fill(rect)
//            str.draw(at: rect.origin, withAttributes: [NSForegroundColorAttributeName: UIColor.white,
//                                                       NSFontAttributeName: UIFont.systemFont(ofSize: 16 * 1 / scale),
//                                                       ])
//        } else {
//            UIColor(white: 0, alpha: 0.0).setFill()
//            UIGraphicsGetCurrentContext()?.fill(rect)
//            str.draw(at: rect.origin, withAttributes: [NSForegroundColorAttributeName: UIColor.red,
//                                                       NSFontAttributeName: UIFont.systemFont(ofSize: 16 * 1 / scale),
//                                                       ])
//        }
        
//        //裁剪展示视图
//        CGImageRef cgRef = _orImage.CGImage;
//        CGImageRef imageRef = CGImageCreateWithImageInRect(cgRef, CGRectMake(self.scrollView.contentOffset.x *multipleF   ,self.scrollView.contentOffset.y *multipleF, width, height));
//        UIImage *thumbScale = [UIImage imageWithCGImage:imageRef];
//        CGImageRelease(imageRef);
//        self.bigCupImageView.image = thumbScale;
        
        if let cropped = image?.cgImage?.cropping(to: rect) {
            
            context.translateBy(x: rect.minX, y: rect.minY + rect.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(cropped, in: .init(origin: .zero, size: rect.size))
        }
        
        
        //if (Int(row % 2) + column) % 2 == 0 {
//            UIColor(white: 0, alpha: 0.5).setFill()
//            UIGraphicsGetCurrentContext()?.fill(.init(origin: .zero, size: rect.size))
        //}
    }
    
    private func _setup() {
        
        // configure tile
        tiledLayer.tileSize = tileSize.applying(.init(scaleX: contentScaleFactor, y: contentScaleFactor))
        tiledLayer.levelsOfDetail = 1
        tiledLayer.levelsOfDetailBias = 3
        
        
        backgroundColor = .clear
    }
}

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
        
        let image = UIImage(contentsOfFile: Bundle.main.path(forResource: "《塞尔达传说：荒野之息》导航地图", ofType: "jpg")!)!
        let scrollView = UIScrollView(frame: view.bounds)
        
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.contentSize = image.size
        scrollView.delegate = self
        scrollView.minimumZoomScale = view.bounds.width / image.size.width
        scrollView.maximumZoomScale = 1
        
        let bounds = UIScreen.main.bounds
        
        let scale = min(bounds.width / scrollView.contentSize.width, bounds.height / scrollView.contentSize.height) * 2
        let size = CGSize(width: scrollView.contentSize.width * scale, height: scrollView.contentSize.height * scale)
        
        let _ = UIGraphicsBeginImageContext(size)
        
        image.draw(in: .init(origin: .zero, size: size))
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
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let contentView = UIImageView(frame: .init(origin: .zero, size: image.size))
        
        contentView.backgroundColor = .random
        contentView.image = newImage
        
        let imageView = TestLargeImageView(frame: contentView.bounds)
        imageView.image = image
        contentView.addSubview(imageView)
        //let v = image.cgImage
        
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        
        _contentView = contentView
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return _contentView
    }
    
    private var _contentView: UIView?
}
