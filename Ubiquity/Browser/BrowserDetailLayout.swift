//
//  BrowserDetailLayout.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserDetailLayout: UICollectionViewFlowLayout {
    
    
    
    override init() {
        super.init()
        self.scrollDirection = .horizontal
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var itemInset: UIEdgeInsets = .init(top: 0, left: -20, bottom: 0, right: -20)
    
    override func prepare() {
        self.collectionView.map {
            // Configuration cell size.
            self.itemSize = .init(width: $0.frame.width + itemInset.left + itemInset.right,
                                  height: $0.frame.height + itemInset.top + itemInset.bottom)

            // Configuration cell interval.
            self.sectionInset.left = -itemInset.left
            self.sectionInset.right = -itemInset.right
            
            self.minimumLineSpacing = -itemInset.left + -itemInset.right
            self.minimumInteritemSpacing = -itemInset.left + -itemInset.right
        }
        super.prepare()
    }
    
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard super.shouldInvalidateLayout(forBoundsChange: newBounds) else {
            return false
        }
        invaildIndexPath = collectionView?.indexPathsForVisibleItems.first
        invalidateLayout()
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let offset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        // if cell is currently being displayed
        guard let collectionView = collectionView, let indexPath = invaildIndexPath else {
            return offset
        }
        // must, send to front
        collectionView.visibleCells.reversed().forEach {
            collectionView.bringSubview(toFront: $0)
        }
        // adjust x
        guard let attr = collectionView.layoutAttributesForItem(at: indexPath) else {
            return offset
        }
        let count = trunc(attr.center.x / collectionView.frame.width)
        let origin = CGPoint(x: count * collectionView.frame.width, y: 0)
        
        logger.debug?.write(origin)
        
        return origin
    }
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        // clear invaild index path on collection view update animation
        invaildIndexPath = nil
        super.prepare(forCollectionViewUpdates: updateItems)
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // special handling of update operations
        guard invaildIndexPath == itemIndexPath else {
            // use the original method
            return super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        }
        // ignore any animation
        return layoutAttributesForItem(at: itemIndexPath)
    }
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // special handling of update operations
        guard invaildIndexPath == itemIndexPath else {
            // use the original method
            return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        }
        // ignore any animation
        return layoutAttributesForItem(at: itemIndexPath)
    }
    
    private var invaildIndexPath: IndexPath?
}
