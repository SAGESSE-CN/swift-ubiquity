//
//  SourceController.swift
//  Ubiquity
//
//  Created by SAGESSE on 11/21/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class SourceController: UICollectionViewController, ChangeObserver, TransitioningDataSource, ExceptionHandling {
    
    /// The current using of the data source.
    private(set) var source: Source {
        willSet {
            // only when in did not set the title will be updated
            super.title = _title ?? newValue.title
        }
    }
    /// The current using of the class factory.
    private(set) var factory: Factory
    /// The current using of the user container.
    private(set) var container: Container
    
    /// Whether the current library has been prepared.
    private(set) var prepared: Bool = false
    /// Whether the current library has been authorization.
    private(set) var authorized: Bool = false
    
    /// Whether you need to caching.
    var isCachingEnabled: Bool = true
    
    ///  Whether you need to fast loading.
    var isFastLoading: Bool = false {
        willSet {
            prepared = true
            authorized = true
        }
    }
    

    init(container: Container, source: Source, factory: Factory) {
        // setup init data
        self.source = source
        self.factory = factory
        self.container = container
        
        // if did not provide UICollectionViewLayout, create failure
        guard let collectionViewLayout = (factory.class(for: "layout") as? UICollectionViewLayout.Type)?.init() else {
            fatalError("The class factory must provide layout!!!")
        }
        
        // continue init the UI
        super.init(collectionViewLayout: collectionViewLayout)
        
        // if not configure title
        // the title will follow data source change
        super.title = source.title
        super.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: nil, action: nil)
        
        // if the navigation bar disable translucent will have an error offset
        // enabled `extendedLayoutIncludesOpaqueBars` can solve the problem
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = true
        
        // add change observer for library.
        self.container.addChangeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // remove chnage observer for library.
        self.container.removeChangeObserver(self)
        
        // clear all cache request when destroyed
        ub_cachingClear()
    }

    override var title: String? {
        willSet {
            // if take the initiative to update the title, never use the title
            _title = newValue
        }
    }
    
    override func loadView() {
        super.loadView()
        
        // setup background color.
        view.backgroundColor = .white
        collectionView?.backgroundColor = view.backgroundColor
        
        // setup registered cells for factory.
        factory.mapping(for: "cell").forEach {
            collectionView?.register($0.value, forCellWithReuseIdentifier: $0.key)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if !isFastLoading {
            ub_initialize(with: self.container, source: self.source)
        }
    }

    // MARK: Collection View Configure
    
    /// Returns the section numbers
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // without authorization, shows blank
        guard authorized else {
            return 0
        }
        return source.numberOfCollections
    }
    
    /// Return the items number in section
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // without authorization, shows blank
        guard authorized else {
            return 0
        }
        return source.numberOfAssets(inCollection: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // fetch asset for source.
        let asset = source.asset(at: indexPath)
        
        // fetch cell for asset identifier.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ub_reuseIdentifier(with: asset), for: indexPath)

        // apply data for asset.
        if let displayer = cell as? Displayable, prepared {
            asset.map {
                displayer.apply(with: $0, container: container)
            }
        }
        
        // the type must be registered
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // the cell must king of `Displayable`
        guard let displayer = cell as? Displayable, let asset = source.asset(at: indexPath), prepared else {
            return
        }
        // gets the picture direction of the current display
        let orientation = ub_container(container, orientationForAsset: asset)

        // show asset with container and orientation
        displayer.willDisplay(with: asset, container: container, orientation: orientation)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // the cell must king of `Displayable`
        guard let displayer = cell as? Displayable, prepared else {
            return
        }

        displayer.endDisplay(with: container)
    }
    
    /// The collectionView did scroll
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // the library is prepared?
        guard prepared else {
            return
        }
        
        // if isTracking is true, is a draging
        if scrollView.isTracking {
            // on draging, update target content offset
            _targetContentOffset = scrollView.contentOffset
        }
        
         ub_cachingUpdate()
    }
    
    /// The scroll view can scroll to top?
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // update target content offset
        _targetContentOffset = .init(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top)
        
        return true
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // update target content offset
        _targetContentOffset = scrollView.contentOffset
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // update target content offset
        _targetContentOffset = targetContentOffset.move()
    }
    
    // MARK: Contents Loading
    
    /// Call before request authorization
    func ub_container(_ container: Container, willAuthorization source: Source) {
        logger.trace?.write()
    }
    /// Call after completion of request authorization
    func ub_container(_ container: Container, didAuthorization source: Source, error: Error?) {
        logger.trace?.write(error ?? "")
        
        // the error message has been processed by the ExceptionHandling
        guard error == nil else {
            return
        }
        // the library authorized successed
        authorized = true
    }
    
    /// Call before request load
    func ub_container(_ container: Container, willLoad source: Source) {
        logger.trace?.write()
    }
    /// Call after completion of load
    func ub_container(_ container: Container, didLoad source: Source, error: Error?) {
        logger.trace?.write(error ?? "")

        // the error message has been processed by the ExceptionHandling
        guard error == nil else {
            return
        }
        
        // check for assets count
        guard source.numberOfAssets != 0 else {
            // count is zero, no data
            ub_execption(with: container, source: source, error: Exception.notData, animated: true)
            return
        }
        
        // Ready to complete
        self.ub_container(container, willPrepare: source)
        self.prepared = true
        self.ub_container(container, didPrepare: source)
    }
    
    func ub_container(_ container: Container, willPrepare source: Source) {
        logger.trace?.write()
        
        // refresh UI
        self.source = source
        self.collectionView?.reloadData()
    }
    func ub_container(_ container: Container, didPrepare source: Source) {
        logger.trace?.write()
        
        // The layout must be updated to create the elements.
        collectionView?.layoutIfNeeded()
        
        // after the prepared to update the cache information
        collectionView.map {
            _targetContentOffset = $0.contentOffset
            ub_cachingUpdate()
        }
    }
    
    // MARK: Contents Rotation
    
    func ub_container(_ container: Container, orientationForAsset asset: Asset) -> UIImageOrientation {
        return .up
    }
    
    // MARK: Contents Caching
    
    
    /// Clear all cached assets
    func ub_cachingClear() {
        // collectionView must be set
        guard let collectionView = collectionView, prepared, isCachingEnabled else {
            return
        }
        logger.trace?.write(collectionView.contentOffset)
        
        // stop cache all
        container.stopCachingImagesForAllAssets()
        
        // reset
        _previousPreheatRect = .zero
    }
    
    /// Update all cached assets with content offset
    func ub_cachingUpdate() {
        // collectionView must be set
        guard let collectionView = collectionView, prepared, isCachingEnabled else {
            return
        }
        
        // Calculated content offset scale.
        let scale: CGVector = ((collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection).map {
            switch $0 {
            case .horizontal:
                return .init(dx: 0.5, dy: 0.0)

            case .vertical:
                return .init(dx: 0.0, dy: 0.5)
            }
        } ?? .init(dx: 0.5, dy: 0.5)
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let targetVisibleRect = CGRect(origin: _targetContentOffset, size: collectionView.bounds.size)
        
        let preheatRect = visibleRect.insetBy(dx: -scale.dx * visibleRect.width, dy: -scale.dy * visibleRect.height)
        let targetPreheatRect = targetVisibleRect.insetBy(dx: -scale.dx * targetVisibleRect.width, dy: -scale.dy * targetVisibleRect.height)
        
        var changes = [(new: CGRect, old: CGRect)]()
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = max(abs(preheatRect.midY - _previousPreheatRect.midY) / max(view.bounds.height / 3, 1),
                        abs(preheatRect.midX - _previousPreheatRect.midX) / max(view.bounds.width / 3, 1))
        if delta >= 1 {
            // need change
            changes.append((preheatRect, _previousPreheatRect))
            // Store the preheat rect to compare against in the future.
            _previousPreheatRect = preheatRect
        }
        
        // Update only if the taget visible area is significantly different from the last preheated area.
        let targetDelta = max(abs(targetPreheatRect.midY - _previousTargetPreheatRect.midY) / max(view.bounds.height / 3, 1),
                              abs(targetPreheatRect.midX - _previousTargetPreheatRect.midX) / max(view.bounds.width / 3, 1))
        if targetDelta >= 1 {
            // need change
            changes.append((targetPreheatRect, _previousTargetPreheatRect))
            // Store the preheat rect to compare against in the future.
            _previousTargetPreheatRect = targetPreheatRect
        }
        
        // is change?
        guard !changes.isEmpty else {
            return
        }
        //logger.trace?.write("preheatRect is change: \(changes)")
        
        // Compute the assets to start caching and to stop caching.
        let details = ub_cachingChangeRect(changes.map { $0.new }, changes.map { $0.old })
        
        let added = details.added.flatMap { ub_cachingItems(in: $0) }
        let removed = details.removed.flatMap { ub_cachingItems(in: $0) }.filter { asset in
            return !added.contains {
                return $0 === asset
            }
        }
        
        // Update the assets the PHCachingImageManager is caching.
        container.startCachingImages(for: added, size: BrowserAlbumLayout.thumbnailItemSize, mode: .aspectFill, options: nil)
        container.stopCachingImages(for: removed, size: BrowserAlbumLayout.thumbnailItemSize, mode: .aspectFill, options: nil)
    }
    
    /// Get the chnage rect
    func ub_cachingChangeRect(_ new: [CGRect], _ old: [CGRect]) -> (added: [CGRect], removed: [CGRect]) {
        // step1: merge
        let newRects = _union(new)
        let oldRects = _union(old)
        
        // step2: split
        return (
            newRects.flatMap { new in
                _intersection(oldRects.flatMap { old in
                    _subtract(new, old)
                })
            },
            oldRects.flatMap { old in
                _intersection(newRects.flatMap { new in
                    _subtract(old, new)
                })
            }
        )
    }

    /// Get the items need to cache
    func ub_cachingItems(in rect: CGRect) -> [Asset] {
        return collectionViewLayout.layoutAttributesForElements(in: rect)?.flatMap {
            guard $0.representedElementCategory == .cell else {
                return nil
            }
            return source.asset(at: $0.indexPath)
        } ?? []
    }
    
    // MARK: Library Change Notification
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func ub_library(_ library: Library, didChange change: Change) {
        // if the library no authorized, ignore all change
        guard authorized else {
            return
        }
        
        // fetch the source change
        source.changeDetails(forAssets: change).map { changeDetails in
            // if new source is empty, is a unknow error.
            guard let source = changeDetails.after else {
                return
            }
            logger.trace?.write()
            
            // change notifications may be made on a background queue.
            // re-dispatch to the main queue to update the UI.
            DispatchQueue.main.async {
                // progressing
                self.ub_library(library, didChange: change, source: source, changeDetails: changeDetails)
            }
        }
    }
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func ub_library(_ library: Library, didChange change: Change, source: Source, changeDetails: SourceChangeDetails) {
        logger.trace?.write(changeDetails)

        // collectionView must be set
        guard let collectionView = collectionView else {
            return
        }
        
        // keep the new fetch result for future use.
        let osource = self.source
        self.source = source
        
        // update collection asset count change
        guard source.numberOfAssets != 0 else {
            // new data source is empty, reload all data and reset error info
            self.ub_execption(with: container, source: source, error: Exception.notData, animated: true)
            self.collectionView?.reloadData()
            return
        }

        // the library is prepared
        if !self.prepared {
            self.prepared = true
        }
        
        self.ub_execption(with: container, source: source, error: nil, animated: true)

        // the old source is empty?
        guard osource.numberOfAssets != 0 else {
            // old source is empty, reload all data
            self.collectionView?.reloadData()
            return
        }

        // the aset has any change?
        guard changeDetails.hasItemChanges else {
            return
        }

        // whether the change will support incremental updating?
        guard changeDetails.hasIncrementalChanges else {
            // does not support, forced to update all the data
            self.collectionView?.reloadData()
            return
        }

        // update collection
        collectionView.performBatchUpdates({

            // For indexes to make sense, updates must be in this order:
            // delete, insert, reload, move

            changeDetails.deleteSections.map { collectionView.deleteSections($0) }
            changeDetails.insertSections.map { collectionView.insertSections($0) }
            changeDetails.reloadSections.map { collectionView.reloadSections($0) }

            changeDetails.moveSections?.forEach { from, to in
                collectionView.moveSection(from, toSection: to)
            }

            changeDetails.removeItems.map { collectionView.deleteItems(at: $0) }
            changeDetails.insertItems.map { collectionView.insertItems(at: $0) }
            changeDetails.reloadItems.map { collectionView.reloadItems(at: $0) }

            changeDetails.moveItems?.forEach { from, to in
                collectionView.moveItem(at: from, to: to)
            }

        }, completion: nil)
    }
    
    // MARK: Animatable Transitioning
    
    /// Returns transitioning view.
    func ub_transitionView(using animator: Animator, for operation: Animator.Operation) -> TransitioningView? {
        return nil
    }
    
    /// Return a Boolean value that indicates whether users allows transition.
    func ub_transitionShouldStart(using animator: Animator, for operation: Animator.Operation) -> Bool {
        return false
    }
    
    /// Return A Boolean value that indicates whether users allows interactive animation transition.
    func ub_transitionShouldStartInteractive(using animator: Animator, for operation: Animator.Operation) -> Bool {
        return false
    }
    
    /// Transitions the context has been prepared.
    func ub_transitionDidPrepare(using animator: Animator, context: TransitioningContext) {
        logger.trace?.write()
    }
    
    /// Transitions the animation has been stated.
    func ub_transitionDidStart(using animator: Animator, context: TransitioningContext) {
        logger.trace?.write()
    }
    
    /// Transitions the animation will end.
    func ub_transitionWillEnd(using animator: Animator, context: TransitioningContext, transitionCompleted: Bool) {
        logger.trace?.write(transitionCompleted)
    }
    
    /// Transitions the animation has been end.
    func ub_transitionDidEnd(using animator: Animator, transitionCompleted: Bool) {
        logger.trace?.write(transitionCompleted)
    }
    
    // MARK: Private Method & Property

    private var _title: String?

    // cache
    private var _targetContentOffset: CGPoint = .zero
    private var _previousPreheatRect: CGRect = .zero
    private var _previousTargetPreheatRect: CGRect = .zero
}


// calculates the area after subtracting the two rect
private func _subtract(_ r1: CGRect, _ r2: CGRect) -> [CGRect] {
    // if not intersect, do not calculate
    guard r1.intersects(r2) else {
        return [r1]
    }
    var result = [CGRect]()
    
    if r2.minY > r1.minY {
        result.append(.init(x: r1.minX, y: r1.minY, width: r1.width, height: r2.minY - r1.minY))
    }
    if r1.maxY > r2.maxY {
        result.append(.init(x: r1.minX, y: r2.maxY, width: r1.width, height: r1.maxY - r2.maxY))
    }
    
    return result
}

// union all rectangles
private func _union(_ rects: [CGRect]) -> [CGRect] {
    
    var result = [CGRect]()
    // must sort, otherwise there will be break rect
    rects.sorted(by: { $0.minY < $1.minY }).forEach { rect in
        // is intersects?
        guard let last = result.last, last.intersects(rect) else {
            result.append(rect)
            return
        }
        result[result.count - 1] = last.union(rect)
    }
    
    return result
}

// intersection all rectangles
private func _intersection(_ rects: [CGRect]) -> [CGRect] {
    
    var result = [CGRect]()
    // must sort, otherwise there will be break rect
    rects.sorted(by: { $0.minY < $1.minY }).forEach { rect in
        // is intersects?
        guard let last = result.last, last.intersects(rect) else {
            result.append(rect)
            return
        }
        result[result.count - 1] = last.intersection(rect)
    }
    
    return result
}


