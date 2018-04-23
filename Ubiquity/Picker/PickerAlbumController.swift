//
//  PickerAlbumController.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerAlbumController: BrowserAlbumController, SelectionScrollerDelegate, SelectionRectangleDelegate, UIGestureRecognizerDelegate, SelectionStatusUpdateDelegate, ContainerOptionsDelegate {
    
    override func loadView() {
        super.loadView()
        
        // if it is not picker, ignore
        guard let picker = container as? Picker else {
            return
        }
        
        // setup block selection
        _selectionScroller.delegate = self
        _selectionScroller.scrollView = collectionView
        _selectionRectangle.delegate = self
        _selectionRectangle.collectionView = collectionView
        _selectionGestureRecognizer.delegate = self
        _selectionGestureRecognizer.addTarget(self, action: #selector(_selectionHandler(_:)))

        // add selection gesture recognizer
        collectionView?.panGestureRecognizer.require(toFail: _selectionGestureRecognizer)
        collectionView?.addGestureRecognizer(_selectionGestureRecognizer)
        
        // configure selection for picker
        _selectionGestureRecognizer.isEnabled = picker.allowsSelection && picker.allowsSelectionGestureRecognizer
    }
    
    /// Apply the change details to UI.
    override func container(_ container: Container, change: Change, source: Source, apply changeDetails: SourceChangeDetails) {
        super.container(container, change: change, source: source, apply: changeDetails)
        
        // clear selector cache
        _selectionRectangle.clear()
    }
    
    /// The scroll view can scroll to top?
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // if rectangle selector is actived, disable scroll to top
        return super.scrollViewShouldScrollToTop(scrollView) && !_selectionRectangle.isSelectable
    }
    
    /// Check rectangle selection recognizer can begin
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
    
    
    // MARK: Options change
    
    func ub_container(_ container: Container, options: String, didChange value: Any?) {
        // update all cell that is being displayed
        collectionView?.visibleCells.forEach {
            guard let reciver = ($0 as? ContainerOptionsDelegate) else {
                return
            }
            reciver.ub_container(container, options: options, didChange: value)
        }
        
        // if it is not picker, ignore
        guard let picker = container as? Picker, options == "allowsSelection" else {
            return
        }
        _selectionGestureRecognizer.isEnabled = picker.allowsSelection && picker.allowsSelectionGestureRecognizer
    }
    
    // MARK: Rectangle Selection
    
    /// Start rectangle select
    func selectionRectangle(_ selectionRectangle: SelectionRectangle, shouldBeginSelection indexPath: IndexPath) -> Bool {
        // if the first item is selected, it is necessary to reverse selection rect
        _selectionReversed = _statusOfItem(at: indexPath)
        _selectionFastCaches = []
       
        // begin ignore change events
        container.beginIgnoringChangeEvents()
        
        // allows selection rect
        return true
    }
    
    /// End rectangle select
    func selectionRectangle(didEndSelection selectionRectangle: SelectionRectangle) {
        // reset selection flag
        _selectionReversed = false
        _selectionFastCaches = nil
        
        // end ignore change events
        container.endIgnoringChangeEvents()
    }
    
    /// Update selected item
    func selectionRectangle(_ selectionRectangle: SelectionRectangle, didSelectItem indexPath: IndexPath) {
        // get select status at index path
        let selected = _statusOfItem(at: indexPath)
        if selected {
            // cache select status at index path
            _selectionFastCaches?.insert(indexPath)
        }
        
        // check whether need to reverse
        guard _selectionReversed else {
            _selectItem(at: indexPath, oldStatus: selected) // normal
            return
        }
        _deselectItem(at: indexPath, oldStatus: selected) // reversed
    }
    
    /// Update deselected item
    func selectionRectangle(_ selectionRectangle: SelectionRectangle, didDeselectItem indexPath: IndexPath) {
        // get cached select status at index path
        let selected = _selectionFastCaches?.contains(indexPath) ?? false
        
        // check whether need to reverse
        guard _selectionReversed else {
            _deselectItem(at: indexPath, oldStatus: !selected) // normal
            return
        }
        _selectItem(at: indexPath, oldStatus: !selected) // reversed
    }
    
    // MARK: Automatic Scroll
    
    /// Update contetn offset for timeover
    func selectionScroller(_ selectionScroller: SelectionScroller, didAutoScroll timestamp: CFTimeInterval, offset: CGPoint) {
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
        _selectionRectangle.update(at: _selectionGestureRecognizer.location(in: collectionView))
    }
    
    // MARK: Selection change
    
    func selectionStatus(_ selectionStatus: SelectionStatus, didSelectItem asset: Asset, sender: AnyObject) {
        // ignore the events that itself sent
        guard sender !== self else {
            return
        }
        logger.debug?.write()
        
        // udpate all visable cell
        collectionView?.visibleCells.forEach {
            // the asset in displaying
            guard let cell = ($0 as? PickerAlbumCell), cell.asset?.ub_identifier == asset.ub_identifier else {
                return
            }
            // update selection
            cell.status = selectionStatus
        }
    }
    
    func selectionStatus(_ selectionStatus: SelectionStatus, didDeselectItem asset: Asset, sender: AnyObject) {
        // ignore the events that itself sent
        guard sender !== self else {
            return
        }
        logger.debug?.write()
        
        // udpate all visable cell
        collectionView?.visibleCells.forEach {
            // the asset in displaying
            guard let cell = ($0 as? PickerAlbumCell), cell.asset?.ub_identifier == asset.ub_identifier else {
                return
            }
            // clear selection
            cell.status = nil
        }
    }
    
    // MARK: Selection Event
    
    /// Returns the item selected status at index path
    private func _statusOfItem(at indexPath: IndexPath) -> Bool {
        // if can fetch cell at index path, use the cell select status
        if let cell = collectionView?.cellForItem(at: indexPath) as? PickerAlbumCell {
            return cell.status != nil
        }
        
        // fetch asset at index path
        guard let asset = source.asset(at: indexPath) else {
            return false
        }
        
        // fetch select status for asset
        return (container as? Picker)?.statusOfItem(with: asset) != nil
    }
    
    /// Select the item at index path
    private func _selectItem(at indexPath: IndexPath, oldStatus: Bool) {
        // if status is true, status no change ignore
        guard let collectionView = collectionView, !oldStatus else {
            return
        }
        
        // fetch asset at index path
        guard let asset = source.asset(at: indexPath) else {
            return
        }
        
        // select item for picker
        let status = (container as? Picker)?.selectItem(with: asset, sender: self)
        
        // update cell selection status
        (collectionView.cellForItem(at: indexPath) as? PickerAlbumCell)?.status = status
    }
    
    /// Deselect the item at index path
    private func _deselectItem(at indexPath: IndexPath, oldStatus: Bool) {
        // if status is false, status no change ignore
        guard let collectionView = collectionView, oldStatus else {
            return
        }
        
        // fetch asset at index path
        guard let asset = source.asset(at: indexPath) else {
            return
        }
        
        // deselect item for picker
        let status = (container as? Picker)?.deselectItem(with: asset, sender: self)
        
        // update cell selection status
        (collectionView.cellForItem(at: indexPath) as? PickerAlbumCell)?.status = status
    }
    
    /// Selection hanlder
    @objc private dynamic func _selectionHandler(_ sender: UIPanGestureRecognizer) {
        //logger.trace?.write()
        
        // if selection region can select, try to prepare region
        guard _selectionRectangle.isSelectable
            || _selectionRectangle.begin(at: sender.location(in: collectionView)) else {
            return
        }

        // update the selected items
        _selectionLastUpdateTimestamp = nil
        _selectionRectangle.update(at: sender.location(in: collectionView))

        // if the gesture recognizer is ended?
        if sender.state == .cancelled || sender.state == .failed || sender.state == .ended {
            // yes, stop auto scroll
            _selectionScroller.speed = 0
            _selectionRectangle.end()
            return
        }

        // compute origin
        let origin = sender.location(in: view)

        // compute mininum visable rect
        let item = Settings.default.minimumItemSize.height
        let inset = UIEdgeInsetsMake(topLayoutGuide.length + item, 0, bottomLayoutGuide.length + item, 0)
        let bounds = UIEdgeInsetsInsetRect(view.bounds, inset)
        
        // if y less than bounds, scroll up automatically
        if origin.y < bounds.minY {
            // update scroll speed(is up) & start auto scroll
            _selectionScroller.speed = -((bounds.minY - origin.y) / inset.top)
            return
        }

        // if y greater than bounds, scroll down automatically
        if origin.y > bounds.maxY {
            // update scroll speed(is down) & start auto scroll
            _selectionScroller.speed = +((origin.y - bounds.maxY) / inset.bottom)
            return
        }

        // stop auto scroll
        _selectionScroller.speed = 0
    }
    
    // MARK: Ivar
    
    // selector status
    private var _selectionReversed: Bool = false
    private var _selectionFastCaches: Set<IndexPath>?
    private var _selectionLastUpdateTimestamp: CFTimeInterval?
    
    // rectangle selector
    private lazy var _selectionScroller: SelectionScroller = .init()
    private lazy var _selectionRectangle: SelectionRectangle = .init()
    private lazy var _selectionGestureRecognizer: UIPanGestureRecognizer = .init()
 
    var isSelectMode: Bool = true {
        willSet{
            self.isSelectMode = newValue
            _selectionGestureRecognizer.isEnabled = newValue
            (self.collectionView?.visibleCells as? [PickerAlbumCell])?.forEach{
                $0.isSelectedMode = newValue
            }
        }
    }

}

extension PickerAlbumController {
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        if let pickerCell = cell as? PickerAlbumCell {
            if pickerCell.isSelectedMode != isSelectMode {
                pickerCell.isSelectedMode = isSelectMode
            }
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let pickerCell = cell as? PickerAlbumCell {
            if pickerCell.isSelectedMode != isSelectMode {
                pickerCell.isSelectedMode = isSelectMode
            }
        }
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)

    }
}


