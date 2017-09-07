//
//  Image.swift
//  Ubiquity
//
//  Created by sagesse on 06/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import ImageIO

public class Image: UIImage {
    
    public /*not inherited*/ init?(named name: String) {
        return nil
    }
    
    public /*not inherited*/ init?(named name: String, in bundle: Bundle?, compatibleWith traitCollection: UITraitCollection?) {
        return nil
    }

//    convenience init?(named name: String, in bundle: Bundle?, compatibleWith traitCollection: UITraitCollection?) {
//        return nil
////        // not found
////        let ext = (name as NSString).pathExtension.isEmpty ? "gif" : ""
////        guard let url = (bundle ?? .main).url(forResource: name, withExtension: ext) else {
////            return nil
////        }
////        // try to load the file
////        guard let data = try? Data(contentsOf: url) else {
////            return nil
////        }
////        // create a image data source
////        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
////            return nil
////        }
////        // create image
////        self.init(source: source)
//    }
    
    public override init?(data: Data) {
        super.init(data: data)
        _check()
    }
    
    public override init?(data: Data, scale: CGFloat) {
        fatalError("init(coder:scale:) has not been implemented")
    }
    
    public required convenience init(imageLiteralResourceName name: String) {
        fatalError("init(imageLiteralResourceName:) has not been implemented")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(itemProviderData data: Data, typeIdentifier: String) throws {
        fatalError("init(itemProviderData:typeIdentifier:) has not been implemented")
    }
    
//    public /*not inherited*/ init?(named name: String)
//
//    
//    @available(iOS 8.0, *)
//    public /*not inherited*/ init?(named name: String, in bundle: Bundle?, compatibleWith traitCollection: UITraitCollection?)
    
    public override var size: CGSize {
        return .init(width: super.cgImage?.width ?? 0, height: super.cgImage?.height ?? 0)
    }
    
    public override var cgImage: CGImage? {
        return nil//super.cgImage
    }
    
    public var placeholder: UIImage? {
        willSet {
        }
    }
    
//
//
//    public init?(contentsOfFile path: String)
//
//    public init?(data: Data)
//
//    @available(iOS 6.0, *)
//    public init?(data: Data, scale: CGFloat)
//
//    public init(cgImage: CGImage)
//
//    @available(iOS 4.0, *)
//    public init(cgImage: CGImage, scale: CGFloat, orientation: UIImageOrientation)
//
//    
//    @available(iOS 5.0, *)
//    public init(ciImage: CIImage)
//
//    @available(iOS 6.0, *)
//    public init(ciImage: CIImage, scale: CGFloat, orientation: UIImageOrientation)
    
//    internal var isSlowLoad: Bool = true
//    internal var isAnimatedImage: Bool = false
    
//        if let cgi = image.cgImage {
//            let mem = cgi.bytesPerRow * cgi.height
//            
//            logger.debug?.write("\(mem / 1024 / 1024)MiB, \(mem)B")
//        }
    
    // check image info
    private func _check() {
        // if you do not set a cgImage, ignored
        guard let image = super.cgImage else {
            return
        }
        
        // calculate the memory footprint after decoding
        let bytes = image.bytesPerRow * image.height
        
        
        logger.debug?.write("decode bytes is \(Float(bytes) / 1024 / 1024)MiB")
    }
    
    /// This is the original image
    internal var raw: CGImage? {
        return super.cgImage
    }

    /// A image renderer
    internal lazy var renderer: ImageRenderer = ImageRenderer(image: self)
}

/// A image renderer
internal class ImageRenderer: NSObject {
    
    /// Generate a image renderer for `image`
    internal init(image: Image) {
        self.image = image
    }
    
    /// The renderer associated image
    unowned let image: Image
    
    /// Create an image scaling within the specified `rect`.
    internal func scaling(to rect: CGRect) -> CGImage? {
        
        // the cgImage must be set
        guard let image = image.raw else {
            return nil
        }
        
//        guard let data = image.data else {
//            return nil
//        }
//        
//        
//        // To create image source from UIImage, use this
//        // NSData* pngData =  UIImagePNGRepresentation(image);
//        
//        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
//            return nil
//        }
//
//        // Create thumbnail options
//        let options = [
//            kCGImageSourceCreateThumbnailWithTransform as String: true,
//            kCGImageSourceCreateThumbnailFromImageAlways as String: true,
//            kCGImageSourceThumbnailMaxPixelSize as String: max(rect.width, rect.height)
//        ] as [String : Any]
//        
//        // Generate the thumbnail
//        return CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary)
        
        // calculate the scaled rect 
        let scale = min(rect.width / .init(image.width), rect.height / .init(image.height))
        let size = CGSize(width: .init(image.width) * scale, height: .init(image.height) * scale)
        
        // begin drawing image 
        autoreleasepool { 
            UIGraphicsBeginImageContext(size)
        }
        
        // automatic release at end of scope 
        defer {
            UIGraphicsEndImageContext()
        }
        
        // if the context cannot be reached, the rendering fails
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        // because of the use of context.draw and UIKit coordinates are not the same, so the need to flip drawing image
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: .init(origin: .zero, size: size), byTiling: false)
        
        // get drawing results 
        return context.makeImage()
    }
    
    /// Create an image using the data contained within the subrectangle `rect' of `image'.
    internal func cropping(to rect: CGRect) -> CGImage? {
        return image.raw?.cropping(to: rect)
    }
}
