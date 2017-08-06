//
//  SelectionRectangle.swift
//  Ubiquity
//
//  Created by SAGESSE on 7/30/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

@objc
internal protocol SelectionRectangleDelegate: class {
    
    /// Start rectangle select
    @objc optional func selectionRectangle(_ selectionRectangle: SelectionRectangle, shouldBeginSelection indexPath: IndexPath) -> Bool
    
    /// End rectangle select
    @objc optional func selectionRectangle(didEndSelection selectionRectangle: SelectionRectangle)
    
    /// Update selected item
    @objc optional func selectionRectangle(_ selectionRectangle: SelectionRectangle, didSelectItem indexPath: IndexPath)
    
    /// Update deselected item
    @objc optional func selectionRectangle(_ selectionRectangle: SelectionRectangle, didDeselectItem indexPath: IndexPath)
}

@objc
internal class SelectionRectangle: NSObject {
    
    /// The rectangle selector delegate
    weak var delegate: SelectionRectangleDelegate?
    
    /// Mapping the data source
    weak var collectionView: UICollectionView? {
        willSet {
            _selectedItem = nil
            _selectedIndexPaths = nil
        }
    }
    
    /// The rectangle selector is ready?
    var isSelectable: Bool {
        return _selectedIndexPaths != nil
    }
    
    /// Start select at offset
    func begin(at offset: CGPoint) -> Bool {
        // update section cache on begin
        if _sections == nil {
            _updateSectionCaches()
        }
        
        // try fetch index path at offset
        guard let indexPath = _indexPath(at: offset, checkBoundary: true) else {
            return false
        }
        // can activie rectangle selection?
        guard delegate?.selectionRectangle?(self, shouldBeginSelection: indexPath) ?? true else {
            return false
        }
        logger.trace?.write(offset, indexPath)
        
        // starting selection requires generating context
        _selectedIndexPaths = (indexPath, nil)
        
        // prepare is successed
        return true
    }
    
    /// Update select at offset
    func update(at offset: CGPoint) {
        // if context is empty, selection no start
        guard let indexPaths = _selectedIndexPaths else {
            return
        }
        // try fetch index path at offset
        guard let indexPath = _indexPath(at: offset, checkBoundary: indexPaths.end != nil), indexPath != indexPaths.end else {
            return
        }
        logger.trace?.write(indexPath)
        
        // compute origin
        let new = _makeRange(indexPaths.start, indexPath)
        let old = _makeRange(indexPaths.start, indexPaths.end)
        
        // compute diff
        let diff = _diff(old, new)
        
        // update selected items
        diff.removed.flatMap { _deselectItems(in: $0, reversed: $1) }
        diff.added.flatMap { _selectItems(in: $0, reversed: $1) }
        
        // update current context
        _selectedIndexPaths = (indexPaths.start, indexPath)
    }
    
    /// Stop select
    func end() {
        // if context is empty, selection no start
        guard let _ = _selectedIndexPaths else {
            return
        }
        logger.trace?.write()
        
        // clear current context
        _selectedIndexPaths = nil
        
        // notify delegate selection end
        delegate?.selectionRectangle?(didEndSelection: self)
    }
    
    /// Clear cacle
    func clear() {
        _sections = nil
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
            delegate?.selectionRectangle?(self, didSelectItem: $0)
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
            delegate?.selectionRectangle?(self, didDeselectItem: $0)
        }
    }
    
    /// Comparing the difference between the two range
    private func _diff<T: Comparable>(_ lhs: Range<T>, _ rhs: Range<T>) -> (added: (Range<T>, Bool)?, removed: (Range<T>, Bool)?) {
        // default is empty
        var added: (Range<T>, Bool)?
        var removed: (Range<T>, Bool)?
        
        // compute added range
        if rhs.upperBound > lhs.upperBound {
            added = (lhs.upperBound ..< rhs.upperBound, false)
        }
        if lhs.lowerBound > rhs.lowerBound {
            added = (rhs.lowerBound ..< lhs.lowerBound, true) // reversed
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
    
    // fetch index path at offset for boundary
    private func _indexPath(at offset: CGPoint, checkBoundary: Bool) -> IndexPath? {
        // collection view & sections must be set
        guard let collectionView = collectionView, let sections = _sections, !sections.isEmpty else {
            return nil
        }
        
        // the last time the selected hit?
        if let selectedItem = _selectedItem, selectedItem.rect.contains(offset) {
            return selectedItem.indexPath
        }
        
        // backward: fetch first -n or 0
        var start = min(_section, sections.count - 1)
        while start >= 0 {
            // the section has header view?
            guard let range = sections[start] else {
                start -= 1
                continue
            }
            // is -n or 0?
            guard (range.begin.minY - offset.y) < 0 else {
                start -= 1
                continue
            }
            break
        }
        
        // is over boundary of up
        guard start >= 0 else {
            // allows overstep boundary?
            guard checkBoundary else {
                return nil
            }
            
            // generate index path for top overstep the boundary
            return .init(item: 0, section: 0)
        }
        
        // forward: fetch first +n or inf
        var end = start
        while end < sections.count {
            // the section has header view?
            guard let range = sections[end] else {
                end += 1
                continue
            }
            // is +n
            guard (range.begin.minY - offset.y) > 0 else {
                start = end
                end += 1
                continue
            }
            break
        }
        
        // cache for optimize search speed
        _section = start
        
        // in the section?
        guard let range = sections[start] else {
            return nil // error
        }
        
        // bottom over boundary?
        if offset.y > range.end.maxY {
            // allows overstep boundary?
            guard checkBoundary else {
                return nil
            }
            
            // if selected is nil, there is ambiguity, ignore
            guard let section = _selectedIndexPaths?.start.section else {
                return nil
            }
            
            // fetch the most close to the item from the start
            guard start >= section else {
                // generate index path for bottom overstep the boundary
                return .init(item: 0, section: start + 1)
            }
            
            // generate index path for bottom overstep the boundary
            return .init(item: collectionView.numberOfItems(inSection: start) - 1, section: start )
        }
        
        // left over boundary?
        if offset.y <= range.begin.maxY && offset.x < range.begin.minX {
            // allows overstep boundary?
            guard checkBoundary else {
                return nil
            }
            
            // generate index path for right overstep the boundary
            return .init(item: 0, section: start - 1)
        }
        
        // right over boundary?
        if offset.y >= range.end.minY && offset.x > range.end.maxX {
            // allows overstep boundary?
            guard checkBoundary else {
                return nil
            }
            
            // generate index path for right overstep the boundary
            return .init(item: collectionView.numberOfItems(inSection: start) - 1, section: start )
        }
        
        // fetch index path for colleciton view
        if let indexPath = collectionView.indexPathForItem(at: offset) {
            // fetch item postion at index path, if find cache it
            if let rect = collectionView.layoutAttributesForItem(at: indexPath)?.frame {
                _selectedItem = (indexPath, rect)
            }
            return indexPath
        }
        
        // not found
        return nil
    }
    
    // update section caches
    private func _updateSectionCaches() {
        // collection view must be set
        guard let collectionView = collectionView else {
            return
        }
        
        // compute items
        _sections = (0 ..< collectionView.numberOfSections).map { section in
            // check the section range
            let count = collectionView.numberOfItems(inSection: section)
            guard count != 0 else {
                return nil
            }
            
            // fetch the section begin item & end item
            guard let begin = collectionView.layoutAttributesForItem(at: .init(item: 0, section: section)) else {
                return nil
            }
            guard let end = collectionView.layoutAttributesForItem(at: .init(item: count - 1, section: section)) else {
                return nil
            }
            
            // generate range
            return (begin.frame, end.frame)
        }
    }
    
    private var _section: Int = 0
    private var _sections: [(begin: CGRect, end: CGRect)?]?
    
    private var _selectedItem: (indexPath: IndexPath, rect: CGRect)?
    private var _selectedIndexPaths: (start: IndexPath, end: IndexPath?)?
}
