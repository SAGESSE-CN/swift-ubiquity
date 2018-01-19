//
//  BrowserAlbumLayout.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        self.collectionView.map {
            // the size of the indent must be omitted
            var rect = UIEdgeInsetsInsetRect($0.bounds, $0.contentInset)
            
            // in iOS11, there is a security zone concept that needs to be removed from insecure areas.
            if #available(iOS 11.0, *) {
                rect = UIEdgeInsetsInsetRect(rect, $0.safeAreaInsets)
            }
            
            let (size, spacing) = BrowserAlbumLayout._itemSize(with: rect)
            
            // setup
            self.itemSize = size
            self.minimumLineSpacing = spacing
            self.minimumInteritemSpacing = spacing
        }
        
        // clear header cache
        _cachedAllHeaderLayoutAttributes = nil

        // Continue prepare layout.
        super.prepare()
    }
    
    override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        
        // clear context
        _invaildBounds = nil
        _invaildCenterIndexPath = nil
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // only when the change of access to the current center indexPath
        guard super.shouldInvalidateLayout(forBoundsChange: newBounds) else {
            return false
        }
        
        // if collectionview is not ready, ignore
        guard let collectionView = collectionView, _invaildBounds?.size != newBounds.size else {
            return true
        }
        
        // get the collection view center point
        let location = collectionView.convert(collectionView.center, from: collectionView.superview)
        
        // get the element closest to the center
        _invaildBounds = newBounds
        _invaildCenterIndexPath = collectionView.indexPathsForVisibleItems.reduce((nil, Int.max)) {
            // get the cell center
            guard let center = collectionView.layoutAttributesForItem(at: $1)?.center else {
                return $0
            }
            // compute the cell to point the disance
            let disance = Int(fabs(sqrt(pow((center.x - location.x), 2) + pow((center.y - location.y), 2))))
            // if the cell is more close to update it
            guard disance < $0.1 else {
                return $0
            }
            return ($1, disance)
        }.0
        
        
        logger.debug?.write("center at \(String(describing: _invaildCenterIndexPath))")

        // Reset all layout.
        invalidateLayout()
  
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let offset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)

        // only the process screen rotation
        guard let collectionView = collectionView, let indexPath = _invaildCenterIndexPath else {
            return offset
        }
        
        // must get the center on new layout
        guard let location = collectionView.layoutAttributesForItem(at: indexPath)?.center else {
            return offset
        }
        
        let frame = collectionView.frame
        let size = collectionViewContentSize
        let edg = collectionView.contentInset
        
        // check top boundary & bottom boundary
        return .init(x: offset.x, y: max(min(location.y - frame.midY,  size.height - frame.maxY + edg.bottom), -edg.top))
    }
    
//    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
////        return super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
//        return layoutAttributesForItem(at: itemIndexPath)
//    }
//    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        return layoutAttributesForItem(at: itemIndexPath)
////        return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
//    }
    
//    override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        return layoutAttributesForSupplementaryView(ofKind: elementKind, at: decorationIndexPath)
//    }
//    override func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        return layoutAttributesForSupplementaryView(ofKind: elementKind, at: decorationIndexPath)
//    }
    
    var allHeaderLayoutAttributes: [UICollectionViewLayoutAttributes?] {
        // hit cache
        if let allHeaderLayoutAttributes = _cachedAllHeaderLayoutAttributes {
            return allHeaderLayoutAttributes
        }
        logger.trace?.write("item is \(itemSize), spacing is \(minimumLineSpacing)")
        
        // get all header layout attributes for layout
        _cachedAllHeaderLayoutAttributes = (0 ..< (collectionView?.numberOfSections ?? 0)).map {
             layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: .init(item: 0, section: $0))
        }
        
        return _cachedAllHeaderLayoutAttributes ?? []
    }
    
    private static func _itemSize(with rect: CGRect) -> (CGSize, CGFloat) {
        
        
        let column = trunc((rect.width + Settings.default.minimumItemSpacing) / (Settings.default.minimumItemSize.width + Settings.default.minimumItemSpacing))
        let width = trunc(((rect.width + Settings.default.minimumItemSpacing) / column - Settings.default.minimumItemSpacing) * 2) / 2
        let spacing = (rect.width - width * column) / (column - 1)
        
        return (.init(width: width, height: width), spacing)
    }
    
    // Thumbnail size of the item
    static let thumbnailItemSize: CGSize = {
        
        let size = _itemSize(with: UIScreen.main.bounds).0
        let scale = UIScreen.main.scale
        
        return .init(width: size.width * scale, height: size.height * scale)
    }()
    
    private var _invaildBounds: CGRect?
    private var _invaildCenterIndexPath: IndexPath?
    
    private var _cachedAllHeaderLayoutAttributes: [UICollectionViewLayoutAttributes?]?
}

