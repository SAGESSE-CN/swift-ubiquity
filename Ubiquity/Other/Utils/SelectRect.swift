//
//  SelectRect.swift
//  Ubiquity
//
//  Created by SAGESSE on 7/30/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

@objc
internal protocol SelectRectDelegate: class {
    
    @objc optional func selectRect(_ selectRect: SelectRect, shouldBeginSelection indexPath: IndexPath) -> Bool
    @objc optional func selectRect(didEndSelection selectRect: SelectRect)
    
    @objc optional func selectRect(_ selectRect: SelectRect, didSelectItem indexPath: IndexPath)
    @objc optional func selectRect(_ selectRect: SelectRect, didDeselectItem indexPath: IndexPath)
}

@objc
internal class SelectRect: NSObject {
    
    /// The rect selector delegate
    weak var delegate: SelectRectDelegate?
    
    /// Mapping the data source
    weak var collectionView: UICollectionView? {
        willSet {
            _context = nil
            _cachedItem = nil
            _cachedLastItem = nil
        }
    }
    
    /// The rect selector is ready?
    var isSelectable: Bool {
        return _context != nil
    }
    
    /// Start select at offset
    func begin(at offset: CGPoint) -> Bool {
        // try fetch index path at offset
        guard let indexPath = _indexPath(at: offset) else {
            return false
        }
        // can activie rect selection?
        guard delegate?.selectRect?(self, shouldBeginSelection: indexPath) ?? true else {
            return false
        }
        logger.trace?.write(offset, indexPath)
        
        // starting selection requires generating context
        _context = (indexPath, nil)
        
        // prepare is successed
        return true
    }
    
    /// Update select at offset
    func update(at offset: CGPoint) {
        // if context is empty, selection no start
        guard let context = _context else {
            return
        }
        // try fetch index path at offset
        guard let indexPath = _indexPath(at: offset, check: context.end != nil), indexPath != context.end else {
            return
        }
        logger.trace?.write(indexPath)
        
        // compute origin
        let new = _makeRange(context.start, indexPath)
        let old = _makeRange(context.start, context.end)
        
        // compute diff
        let diff = _diff(old, new)
        
        // update selected items
        diff.removed.flatMap { _deselectItems(in: $0, reversed: $1) }
        diff.added.flatMap { _selectItems(in: $0, reversed: $1) }
        
        // update current context
        _context = (context.start, indexPath)
    }
    
    
    /// Stop select
    func end() {
        // if context is empty, selection no start
        guard let _ = _context else {
            return
        }
        logger.trace?.write()
        
        // clear current context
        _context = nil
        
        // notify delegate selection end
        delegate?.selectRect?(didEndSelection: self)
    }
    
    /// select items in range
    private func _selectItems(in range: Range<IndexPath>, reversed: Bool) {
        // generate items for range
        var items = _makeItems(in: range)
        
        // need reverse each?
        if reversed {
            items.reverse()
        }
        
        // notify deleaget
        items.forEach { 
            delegate?.selectRect?(self, didSelectItem: $0)
        }
    }
    
    /// deselect items in range
    private func _deselectItems(in range: Range<IndexPath>, reversed: Bool) {
        // generate items for range
        var items = _makeItems(in: range)
        
        // need reverse each?
        if reversed {
            items.reverse()
        }
        
        // notify deleaget
        items.forEach { 
            delegate?.selectRect?(self, didDeselectItem: $0)
        }
    }
    
    /// Comparing the difference between the two range
    private func _diff<T: Comparable>(_ lhs: Range<T>, _ rhs: Range<T>) -> (added: (Range<T>, Bool)?, removed: (Range<T>, Bool)?) {
        // default is empty
        var added: (Range<T>, Bool)?
        var removed: (Range<T>, Bool)?
        
        // compute added range
        if lhs.lowerBound > rhs.lowerBound {
            added = (rhs.lowerBound ..< lhs.lowerBound, true) // reversed
        }
        if rhs.upperBound > lhs.upperBound {
            added = (lhs.upperBound ..< rhs.upperBound, false)
        }
        
        // compute removed range
        if lhs.lowerBound < rhs.lowerBound {
            removed = (lhs.lowerBound ..< rhs.lowerBound, false)
        }
        if rhs.upperBound < lhs.upperBound {
            removed = (rhs.upperBound ..< lhs.upperBound, true) // reversed
        }
        
        // if lhs is empy, add all
        if lhs.isEmpty {
            removed = nil
            added?.0 = rhs
        }
        
        // if rhs is empty, remove all
        if rhs.isEmpty {
            added = nil
            removed?.0 = lhs
        }
        
        // complete
        return (added, removed)
    }
    
    /// Generate a new range, safe
    private func _makeRange(_ lhs: IndexPath, _ rhs: IndexPath?) -> Range<IndexPath> {
        
        // if rhs is empty, range is empty
        guard let rhs = rhs else {
            return lhs ..< lhs
        }
        
        guard lhs < rhs else {
            return rhs ..< .init(item: lhs.item + 1, section: lhs.section)
        }
        
        return lhs ..< .init(item: rhs.item + 1, section: rhs.section)
    }
    
    /// Generate a array in range
    private func _makeItems(in range: Range<IndexPath>) -> [IndexPath] {
        // for each all section
        return (range.lowerBound.section ... range.upperBound.section).flatMap { section -> [IndexPath] in
            // compute range begin & end
            let begin = (range.lowerBound.section == section ? range.lowerBound.item : 0)
            let end = (range.upperBound.section == section ? range.upperBound.item : collectionView?.numberOfItems(inSection: section) ?? 0)
            
            // map to array
            return (begin ..< end).map { .init(item: $0, section: section) }
        }
    }
    
    // fetch index path at offset
    fileprivate func _indexPath(at offset: CGPoint, check: Bool = true) -> IndexPath? {
        // if collection view is nil, is no prepare
        guard let collectionView = collectionView else {
            return nil
        }
        
        // hit cache?
        if let item = _cachedItem, item.rect.contains(offset) {
            return item.indexPath
        }
        
        // try fetch index path for colleciton view
        if let indexPath = collectionView.indexPathForItem(at: offset) {
            // try fetch item postion at index path, cache it
            if let rect = collectionView.layoutAttributesForItem(at: indexPath)?.frame {
                _cachedItem = (indexPath, rect)
            }
            return indexPath
        }
        
        // allows check boundary?
        guard check else {
            return nil
        }
        
        // if offset lass first item, use first item
        if offset.y < 0 {
            return IndexPath(item: 0, section: 0)
        }
        
        // generate last item
        if _cachedLastItem == nil {
            // generate last index path
            let section = collectionView.numberOfSections - 1
            let item = collectionView.numberOfItems(inSection: section) - 1
            let indexPath = IndexPath(item: item, section: section)
            
            // fetch last item frame
            guard let rect = collectionView.layoutAttributesForItem(at: indexPath)?.frame else {
                return nil
            }
            _cachedLastItem = (indexPath, rect)
        }
        
        // if last is nil, ignore
        guard let item = _cachedLastItem else {
            return nil
        }
        
        // y before the last item, ignore
        if offset.y < item.rect.minY {
            return nil
        }

        // y after the last item
        if offset.y > item.rect.maxY {
            return item.indexPath
        }
        
        // x before the last item, ignore
        if offset.x < item.rect.maxX {
            return nil
        }
        
        return item.indexPath
    }
    
    
    private var _context: (start: IndexPath, end: IndexPath?)?
    private var _cachedItem: (indexPath: IndexPath, rect: CGRect)?
    private var _cachedLastItem: (indexPath: IndexPath, rect: CGRect)?
}
