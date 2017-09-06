//
//  Image.swift
//  Ubiquity
//
//  Created by sagesse on 06/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

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
    
    internal var sucgImage: CGImage? {
        return super.cgImage
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
        
        let scale = min(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        if let sub = image.sucgImage {
            context?.translateBy(x: 0, y: size.height)
            context?.scaleBy(x: 1, y: -1)
            context?.draw(sub, in: .init(origin: .zero, size: size), byTiling: false)
        }
        
        let ni = context?.makeImage()
        UIGraphicsEndImageContext()
        return ni
    }
    
    /// Create an image using the data contained within the subrectangle `rect' of `image'.
    internal func cropping(to rect: CGRect) -> CGImage? {
        return image.sucgImage?.cropping(to: rect)
    }
}
