//
//  PickerAlbumController.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerAlbumController: BrowserAlbumController {
    
    override func loadView() {
        super.loadView()
        
        // setup block selection
        _selectionRect.delegate = self
        _selectionRect.collectionView = collectionView
        _selectionSelectScroller.delegate = self
        _selectionSelectScroller.scrollView = collectionView
        _selectionGestureRecognizer.addTarget(self, action: #selector(_selection(_:)))
        _selectionGestureRecognizer.delegate = self
        
        // add selection gesture recognizer
        collectionView?.panGestureRecognizer.require(toFail: _selectionGestureRecognizer)
        collectionView?.addGestureRecognizer(_selectionGestureRecognizer)
    }
    
    // block selection
    fileprivate lazy var _selectionRect: SelectRect = .init()
    fileprivate lazy var _selectionSelectScroller: SelectScroller = .init()
    fileprivate lazy var _selectionGestureRecognizer: UIPanGestureRecognizer = .init()
    
    fileprivate var _selectionReversed: Bool = false
    fileprivate var _selectionFastCaches: Set<IndexPath>?
    fileprivate var _selectionLastUpdateTimestamp: CFTimeInterval?
}

/// Add selection support
extension PickerAlbumController: UIGestureRecognizerDelegate, SelectScrollerDelegate, SelectRectDelegate {
    
    // rect selecting, disable scroll to top
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return super.scrollViewShouldScrollToTop(scrollView) && !_selectionRect.isSelectable
    }
    
    // start select
    func selectRect(_ selectRect: SelectRect, shouldBeginSelection indexPath: IndexPath) -> Bool {
        // if the first item is selected, it is necessary to reverse selection rect
        _selectionReversed = _statusForItem(at: indexPath)
        _selectionFastCaches = []
       
        // allows selection rect
        return true
    }
    
    // end select
    func selectRect(didEndSelection selectRect: SelectRect) {
        // reset selection flag
        _selectionReversed = false
        _selectionFastCaches = nil
    }
    
    // update select item
    func selectRect(_ selectRect: SelectRect, didSelectItem indexPath: IndexPath) {
        // get select status at index path
        let selected = _statusForItem(at: indexPath)
        if selected {
            // cache select status at index path
            _selectionFastCaches?.insert(indexPath)
        }
        
        // check whether need to reverse
        guard _selectionReversed else {
            _selectItem(at: indexPath, status: selected) // normal
            return
        }
        _deselectItem(at: indexPath, status: selected) // reversed
    }
    
    // update deselect item
    func selectRect(_ selectRect: SelectRect, didDeselectItem indexPath: IndexPath) {
        // get cached select status at index path
        let selected = _selectionFastCaches?.contains(indexPath) ?? false
        
        // check whether need to reverse
        guard _selectionReversed else {
            _deselectItem(at: indexPath, status: !selected) // normal
            return
        }
        _selectItem(at: indexPath, status: !selected) // reversed
    }
    
    // did auto scroll
    func selectScroller(_ selectScroller: SelectScroller, didAutoScroll timestamp: CFTimeInterval, offset: CGPoint) {
        // if last udpate timestamp is nil, ignore the update event
        guard let lastTimestamp = _selectionLastUpdateTimestamp else {
            _selectionLastUpdateTimestamp = timestamp
            return
        }
        
        // if updated when timestamp is greater than the threshold
        guard timestamp - lastTimestamp > 0.2 else {
            return
        }
        
        // update selected items with current content offset
        _selectionLastUpdateTimestamp = timestamp
        _selectionRect.update(at: _selectionGestureRecognizer.location(in: collectionView))
    }
    
    // check block selection gesture recognizer can begin
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // the gesture recognizer is selection gesture recognizer?
        guard _selectionGestureRecognizer === gestureRecognizer else {
            return true
        }
        
        // check gesture recognizer direction
        let velocity = _selectionGestureRecognizer.velocity(in: collectionView)
        guard fabs(velocity.y) < 80 && fabs(velocity.y / velocity.x) < 2.5 else {
            return false
        }
        
        return true
    }
    
    // selection hanlder
    fileprivate dynamic func _selection(_ sender: UIPanGestureRecognizer) {
        //logger.debug?.write(sender.location(in: collectionView))
        
        // if selection region can select, try to prepare region
        guard _selectionRect.isSelectable
            || _selectionRect.begin(at: sender.location(in: collectionView)) else {
            return
        }
        
        // update the selected items
        _selectionLastUpdateTimestamp = nil
        _selectionRect.update(at: sender.location(in: collectionView))
        
        // if the gesture recognizer is ended?
        if sender.state == .cancelled || sender.state == .failed || sender.state == .ended {
            // yes, stop auto scroll
            _selectionSelectScroller.speed = 0
            _selectionRect.end()
            return
        }
        
        // compute origin
        let origin = sender.location(in: view)
        
        // compute mininum visable rect
        let item = BrowserAlbumLayout.minimumItemSize.height / 2
        let inset = UIEdgeInsetsMake(topLayoutGuide.length + item, 0, bottomLayoutGuide.length + item, 0)
        let bounds = UIEdgeInsetsInsetRect(view.bounds, inset)
        
        // if y less than bounds, scroll up automatically
        if origin.y < bounds.minY {
            // update scroll speed(is up) & start auto scroll
            _selectionSelectScroller.speed = -((bounds.minY - origin.y) / inset.top)
            return
        }
        
        // if y greater than bounds, scroll down automatically
        if origin.y > bounds.maxY {
            // update scroll speed(is down) & start auto scroll
            _selectionSelectScroller.speed = +((origin.y - bounds.maxY) / inset.bottom)
            return
        }
        
        // stop auto scroll
        _selectionSelectScroller.speed = 0
    }
    
    
    // select item
    private func _selectItem(at indexPath: IndexPath, status: Bool) {
        // if status is true, status no change ignore
        guard !status else {
            return
        }
        
        (collectionView?.cellForItem(at: indexPath) as? PickerAlbumCell)?.setIsSelected(true, animated: false)
    }
    
    // deselect item
    private func _deselectItem(at indexPath: IndexPath, status: Bool) {
        // if status is false, status no change ignore
        guard status else {
            return
        }
        
        //(container as? Picker)?.deselect(with: asset)
        (collectionView?.cellForItem(at: indexPath) as? PickerAlbumCell)?.setIsSelected(false, animated: false)
    }
    
    // check select status
    private func _statusForItem(at indexPath: IndexPath) -> Bool {
        // if can fetch cell at index path, use the cell select status
        if let cell = collectionView?.cellForItem(at: indexPath) {
            return cell.isSelected
        }
        
        // fetch asset at index path
        guard let asset = source.asset(at: indexPath) else {
            return false
        }
        
        // fetch select status for asset
        return (container as? Picker)?.isSelected(with: asset) ?? false
    }
}

