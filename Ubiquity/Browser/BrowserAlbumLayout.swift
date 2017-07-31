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
        super.prepare()
        
        // must be attached to the collection view
        guard let collectionView = collectionView else {
            return
        }
        
        // recompute
        let rect = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset)
        let (size, spacing) = BrowserAlbumLayout._itemSize(with: rect)
        
        // setup
        itemSize = size
        sectionInset = .init(top: 4, left: 0, bottom: 4, right: 0)
        minimumLineSpacing = spacing
        minimumInteritemSpacing = spacing
    }
    
    override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        
        // clear context
        _invaildBounds = nil
        _invaildCenterIndexPath = nil
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard super.shouldInvalidateLayout(forBoundsChange: newBounds) else {
            return false
        }
        
        // the bounds is change?
        if let collectionView = collectionView, _invaildBounds?.size != newBounds.size {
            let location = collectionView.convert(collectionView.center, from: collectionView.superview)
            
            // save center index path
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
            
            // update layout 
            invalidateLayout()
        }
        
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let offset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        
        // only the process screen rotation
        if let collectionView = collectionView, let indexPath = _invaildCenterIndexPath {
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
        
        return offset
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
    
    
    private static func _itemSize(with rect: CGRect) -> (CGSize, CGFloat) {
        
        let column = trunc((rect.width + minimumItemSpacing) / (minimumItemSize.width + minimumItemSpacing))
        let width = trunc(((rect.width + minimumItemSpacing) / column - minimumItemSpacing) * 2) / 2
        let spacing = (rect.width - width * column) / (column - 1)
        
        return (.init(width: width, height: width), spacing)
    }
    
    static let minimumItemSpacing: CGFloat = 2
    static let minimumItemSize: CGSize = .init(width: 78, height: 78)
    
    static let thumbnailItemSize: CGSize = {
        
        let size = _itemSize(with: UIScreen.main.bounds).0
        let scale = UIScreen.main.scale
        
        return .init(width: size.width * scale, height: size.height * scale)
    }()
    
    private var _invaildBounds: CGRect?
    private var _invaildCenterIndexPath: IndexPath?
}

