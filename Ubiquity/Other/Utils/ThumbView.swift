//
//  ThumbView.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/5/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class ThumbView: UIView {

    
    init(frame: CGRect, depth: Int = 3) {
        super.init(frame: frame)
        self.configure(depth)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure(3)
    }
    
    
    /// All the displayed image view, the page appears stutters when using CALayer.
    private(set) lazy var displayedImageViews: Array<UIImageView> = []
    private(set) lazy var displayedImages: [UIImage?] = []
    
    func setImages(_ images: [UIImage?]?, animated: Bool) {
        // If the images is empty, show empty photo album
        guard let images = images, !images.isEmpty else {
            // Blank structure needs to be displayed
            displayedImageViews.enumerated().forEach {
                $1.image = _emptyImage
                $1.isHidden = false
                
                displayedImages[$0] = nil
            }
            return
        }

        // Update the content of each sublayer.
        displayedImageViews.enumerated().forEach {
            guard $0 < images.count else {
                $1.image = nil
                $1.isHidden = true
                
                displayedImages[$0] = nil
                return
            }
            
            setImage(images[$0], at: $0, animated: animated)
        }
    }
    func setImage(_ image: UIImage?, at index: Int, animated: Bool) {
        // Whether or not the image changes.
        guard index < displayedImageViews.count, image != displayedImageViews[index].image else {
            return
        }
        
        displayedImageViews[index].isHidden = false
        displayedImageViews[index].image = image

        displayedImages[index] = image
    }

    func configure(_ depth: Int) {
        
        // Create a layer with the specified depth
        displayedImageViews = (0 ..< depth).map { index in
            let view = UIImageView()
            
            view.layer.borderWidth = 0.5
            view.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            view.clipsToBounds = true
            view.contentMode = .scaleAspectFill
            
            view.isHidden = false
            view.backgroundColor = #colorLiteral(red: 0.9411764706, green: 0.937254902, blue: 0.9607843137, alpha: 1)

            view.isAccessibilityElement = true
            view.accessibilityLabel = "ThumbImageView-\(index)"
            
            return view
        }
        
        // Add to layer.
        displayedImageViews.reversed().forEach {
            addSubview($0)
        }

        // Setup default image.
        displayedImages = .init(repeating: nil, count: displayedImageViews.count)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Refresh all sublayers
        displayedImageViews.enumerated().forEach {
            $1.frame = UIEdgeInsetsInsetRect(bounds, _inset(at: $0))
        }
    }
    
    private var _inset: UIEdgeInsets = .init(top: 2, left: 2, bottom: 2, right: 2)
    private func _inset(at offset: Int) -> UIEdgeInsets {
        return .init(top: _inset.top * .init(offset) * -1,
                     left: _inset.left * .init(offset),
                     bottom: _inset.bottom * .init(offset) + (_inset.top * .init(offset)) * 2,
                     right: _inset.right * .init(offset))
    }
    
    private var __emptyImage: UIImage?
    private var _emptyImage: UIImage? {
        // image has been cache?
        if let image = __emptyImage ?? __sharedEmptyImage {
            // update cache
            __emptyImage = image
            __sharedEmptyImage = image
            
            return image
        }
        logger.debug?.write("load `ubiquity_icon_empty_album`")
        
        let rect = CGRect(x: 0, y: 0, width: 70, height: 70)
        let tintColor = UIColor.ub_init(hex: 0xb4b3b9)
        let backgroundColor = UIColor.ub_init(hex: 0xF0EFF5)
        // begin draw
        UIGraphicsBeginImageContextWithOptions(rect.size, true, UIScreen.main.scale)
        // check the current context
        if let context = UIGraphicsGetCurrentContext() {
            // set the background color
            backgroundColor.setFill()
            context.fill(rect)
            // draw icon
            if let image = ub_image(named: "ubiquity_icon_empty_album") {
                // generate tint image with tint color
                UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
                let context = UIGraphicsGetCurrentContext()
                
                tintColor.setFill()
                context?.fill(.init(origin: .zero, size: image.size))
                image.draw(at: .zero, blendMode: .destinationIn, alpha: 1)
                
                let image2 = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // draw to main context
                image2?.draw(at: .init(x: rect.midX - image.size.width / 2, y: rect.midY - image.size.height / 2))
            }
            
            __emptyImage = UIGraphicsGetImageFromCurrentImageContext()
            __sharedEmptyImage = __emptyImage
        }
        // end draw
        UIGraphicsEndImageContext()
        
        return __emptyImage
    }
}

private weak var __sharedEmptyImage: UIImage?
