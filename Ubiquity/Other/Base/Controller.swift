//
//  Controller.swift
//  Ubiquity
//
//  Created by sagesse on 21/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

public protocol Controller {
    
    /// Base controller craete method
    init(container: Container, source: Source, factory: Factory, parameter: Any?)
}


/// Templated collection view controller.
open class FactoryCollectionViewController: UICollectionViewController {
    
    /// Create an instance using class factory.
    public init(factory: Factory) {
        // If did not provide `UICollectionViewLayout`, create failure
        guard let collectionViewLayout = (factory.class(for: .layout) as? UICollectionViewLayout.Type)?.init() else {
            fatalError("The class factory must provide layout!!!")
        }
        
        // Saving all context.
        self.factory = factory
        super.init(collectionViewLayout: collectionViewLayout)
    }
    /// Create an instance for the file.
    public required init?(coder aDecoder: NSCoder) {
        // The class farctory must be provided to create.
        guard let factory = aDecoder.decodeObject(forKey: "factory") as? Factory else {
            return nil
        }
        
        // If did not provide `UICollectionViewLayout`, create failure
        guard let collectionViewLayout = (factory.class(for: .layout) as? UICollectionViewLayout.Type)?.init() else {
            fatalError("The class factory must provide layout!!!")
        }
        
        // Saving all context.
        self.factory = factory
        super.init(collectionViewLayout: collectionViewLayout)
    }
    
    /// The current using of the class factory.
    open let factory: Factory
    
    /// Load the view.
    open override func loadView() {
        super.loadView()
        
        // Setup background color.
        view.backgroundColor = .white
        collectionView?.backgroundColor = view.backgroundColor
        
        // Setup registered cells for factory.
        factory.slice(for: .cell).forEach {
            collectionView?.register($1, forCellWithReuseIdentifier: $0)
        }
    }
    
    /// Asks your data source object for the reuse identifier that corresponds to the specified item in the collection view.
    open func collectionView(_ collectionView: UICollectionView, reuseIdentifierForItemAt indexPath: IndexPath) -> String {
        return "default"
    }
    
    /// Asks your data source object for the cell that corresponds to the specified item in the collection view.
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Get the reuse identifier at index path.
        let identifier = self.collectionView(collectionView, reuseIdentifierForItemAt: indexPath)
        
        // Convert the identifier to known identifier.
        let newIdentifier = _mapping[identifier].ub_coalescing {
            // Query identifier from the factory.
            let newIdentifier = factory.slice(for: .cell).matching(identifier)

            // Cache identifiers improve the access efficiency.
            _mapping[identifier] = newIdentifier
            
            logger.debug?.write("Mapping \"\(identifier)\" to \"\(newIdentifier)\"")
            
            return newIdentifier
        }
            
        return collectionView.dequeueReusableCell(withReuseIdentifier: newIdentifier, for: indexPath)
    }
    
    // MARK: ivar
    
    private lazy var _mapping: [String: String] = [:]
}

/// Templated collection view cell.
open class SourceCollectionViewCell: UICollectionViewCell {
    
    /// Create an instance with rect.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    /// Create an instance with file.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    deinit {
        // If the cell is displaying, hidden after then destroyed
        container.map {
            endDisplay($0)
        }
    }
    
    /// Specified display style of asset.
    open var asset: Asset?
    /// Specified display style of collection.
    open var collection: Collection?
    
    /// Specified the cell displayed using container.
    open var container: Container?
    /// Specified the cell displayed orientation.
    open var orientation: UIImageOrientation = .up
    
    
    /// Configure the cell.
    open func configure() {
    }
    
    /// Apply the cell with item data.
    open func apply(_ container: Container, item: Any) {
        self.asset = item as? Asset
        self.collection = item as? Collection
        self.container = container
    }
    
    /// Add the item data on screen.
    open func willDisplay(_ container: Container, orientation: UIImageOrientation) {
        self.orientation = orientation
    }
    
    /// Remove the item data on screen.
    open func endDisplay(_ container: Container) {
        self.asset = nil
        self.collection = nil
        self.container = nil
    }
    
    /// Provide content view of class
    open dynamic class var contentViewClass: AnyClass {
        return UIView.self
    }
    /// Provide container view of class
    open dynamic class var containerViewClass: AnyClass {
        return contentViewClass
    }
    
    /// Provide content view of class, iOS 8+
    private dynamic class var _contentViewClass: AnyClass {
        return containerViewClass
    }
}

/// Templated collection view controller.
open class SourceCollectionViewController: FactoryCollectionViewController, Controller, ChangeObserver, ExceptionHandling {
    
    /// Create an instance using class factory.
    public required init(container: Container, source: Source, factory: Factory, parameter: Any?) {
        // setup init data
        self.source = source
        self.container = container
        
        super.init(factory: factory)
        
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
        
        logger.trace?.write()
    }
    /// Create an instance for the file.
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// When an instance is destroyed, the listener must be removed.
    deinit {
        logger.trace?.write()
        
        // Remove chnage observer for library.
        self.container.removeChangeObserver(self)
        
        // Clear all cache request when destroyed
        self.cachingClear()
    }
    
    /// The current using of the user container.
    open let container: Container
    /// The current using of the data source.
    open var source: Source {
        willSet {
            // Only when in did not set the title will be updated
            super.title = _title ?? newValue.title
        }
    }
    
    /// The current displayed title,
    /// Default title only when in did not set the title will be updated.
    open override var title: String? {
        willSet {
            // If take the initiative to update the title, never use the title
            _title = newValue
        }
    }
    
    /// Whether the current library has been prepared.
    open var prepared: Bool = false
    /// Whether the current library has been authorization.
    open var authorized: Bool = false
    
    /// Whether allowe item precache.
    open var cachingItemEnabled: Bool = false
    /// Specify the caching item size.
    open var cachingItemSize: CGSize {
        return .init(width: 80, height: 80)
    }
    
    /// The view is loaded successfully, Check access authorization.
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        /// If there is no access authorization, will request access authorize.
        if !authorized {
            ub_initialize(with: self.container, source: self.source)
        }
    }
    
    // MARK: Data Access
    
    /// Get the cell orientation at index path.
    open func orientation(_ source: Source, at indexPath: IndexPath) -> UIImageOrientation {
        return .up
    }
    
    /// Get the cell data at index path.
    open func data(_ source: Source, at indexPath: IndexPath) -> Any? {
        return source.asset(at: indexPath)
    }
    
    // MARK: Collection View Configure
    
    /// Asks your data source object for the number of sections in the collection view.
    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // Without access authorization, shows blank
        guard prepared else {
            return 0
        }
        
        return source.numberOfCollections
    }
    
    /// Asks your data source object for the number of items in the specified section.
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Without access authorization, shows blank
        guard prepared else {
            return 0
        }
        
        return source.numberOfAssets(inCollection: section)
    }
    
    /// Asks your data source object for the reuse identifier that corresponds to the specified item in the collection view.
    open override func collectionView(_ collectionView: UICollectionView, reuseIdentifierForItemAt indexPath: IndexPath) -> String {
        // Get the type of the asset at index path.
        return ((data(source, at: indexPath) as? Asset)?.ub_type.description).ub_coalescing {
            // If the asset is not found, the use of identifier provided by the superclass.
            return super.collectionView(collectionView, reuseIdentifierForItemAt: indexPath)
        }
    }
    
    /// Asks your data source object for the cell that corresponds to the specified item in the collection view.
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // The super class solved access reuse identifier and register cell class issue.
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        
        // The item must be exists.
        guard let item = data(source, at: indexPath) else {
            return cell
        }
        
        // Configure the cell on cell is king of `Source.CollectionViewCell`.
        (cell as? SourceCollectionViewCell).map {
            $0.apply(container, item: item)
        }
        
        return cell
    }
    
    /// Tells the delegate that the specified cell is about to be displayed in the collection view.
    open override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Configure the cell on cell is king of `Source.CollectionViewCell`.
        (cell as? SourceCollectionViewCell).map {
            $0.willDisplay(container, orientation: orientation(source, at: indexPath))
        }
    }
    
    /// Tells the delegate that the specified cell was removed from the collection view.
    open override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Configure the cell on cell is king of `Source.CollectionViewCell`.
        (cell as? SourceCollectionViewCell).map {
            $0.endDisplay(container)
        }
    }
    
    /// Tells the delegate when the user scrolls the content view within the receiver.
    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // The library is prepared?
        guard prepared else {
            return
        }
        
        // If isTracking is true, is a draging, sync target offset to offset
        if scrollView.isTracking {
            targetContentOffset = scrollView.contentOffset
        }
        
        // Update caching items.
        cachingUpdate()
    }
    
    /// Asks the delegate if the scroll view should scroll to the top of the content.
    open override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // Update target content offset
        targetContentOffset = .init(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top)
        
        return true
    }
    
    /// Collecting scrolling information.
    open override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Update target content offset
        targetContentOffset = scrollView.contentOffset
    }
    
    /// Collecting scrolling information.
    open override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset newTargetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Update target content offset
        targetContentOffset = newTargetContentOffset.move()
    }
    
    // MARK: Controller Loading
    
    /// The controller will request access authorization.
    open func controller(_ container: Container, willAuthorization source: Source) {
        logger.trace?.write()
    }
    /// The controller access authorization has been completed.
    open func controller(_ container: Container, didAuthorization source: Source, error: Error?) {
        logger.trace?.write(error ?? "")
        
        // The error message has been processed by the ExceptionHandling
        guard error == nil else {
            return
        }
        
        // The library authorized successed
        authorized = true
    }
    
    /// The controller will request source data.
    open func controller(_ container: Container, willLoad source: Source) {
        logger.trace?.write()
    }
    /// The controller source data has been completed.
    open func controller(_ container: Container, didLoad source: Source, error: Error?) {
        logger.trace?.write(error ?? "")
        
        // The error message has been processed by the ExceptionHandling
        guard error == nil else {
            return
        }
        
        // Ready to complete
        self.controller(container, willPrepare: source)
        self.prepared = true
        self.source = source
        self.collectionView?.reloadData()
        self.controller(container, didPrepare: source)
    }
    
    /// The controller will prepare UI element.
    open func controller(_ container: Container, willPrepare source: Source) {
        logger.trace?.write()
    }
    /// The controller prepare UI has been completed.
    open func controller(_ container: Container, didPrepare source: Source) {
        logger.trace?.write()
        
        guard let collectionView = collectionView, prepared, cachingItemEnabled else {
            return
        }
        
        // The layout must be updated to create the elements.
        collectionView.layoutIfNeeded()
        
        // after the prepared to update the cache information
        targetContentOffset = collectionView.contentOffset
        
        // Update caching items.
        cachingUpdate()
    }
    
    // MARK: Item Caching
    
    /// Clear all cached assets.
    open func cachingClear() {
        // The collectionView must be set
        guard let collectionView = collectionView, prepared, cachingItemEnabled else {
            return
        }
        logger.trace?.write(collectionView.contentOffset)
        
        // Stop cache all
        container.stopCachingImagesForAllAssets()
        
        // Reset all cache preheat rect.
        previousPreheatRect = .zero
        previousTargetPreheatRect = .zero
    }
    
    /// Update all cached assets with content offset
    open func cachingUpdate() {
        // The collectionView must be set
        guard let collectionView = collectionView, prepared, cachingItemEnabled else {
            return
        }
        //logger.trace?.write(collectionView.contentOffset)
        
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
        let targetVisibleRect = CGRect(origin: self.targetContentOffset, size: collectionView.bounds.size)
        
        let preheatRect = visibleRect.insetBy(dx: -scale.dx * visibleRect.width, dy: -scale.dy * visibleRect.height)
        let targetPreheatRect = targetVisibleRect.insetBy(dx: -scale.dx * targetVisibleRect.width, dy: -scale.dy * targetVisibleRect.height)
        
        var changes = [(new: CGRect, old: CGRect)]()
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = max(abs(preheatRect.midY - self.previousPreheatRect.midY) / max(view.bounds.height / 3, 1),
                        abs(preheatRect.midX - self.previousPreheatRect.midX) / max(view.bounds.width / 3, 1))
        if delta >= 1 {
            // need change
            changes.append((preheatRect, self.previousPreheatRect))
            // Store the preheat rect to compare against in the future.
            self.previousPreheatRect = preheatRect
        }
        
        // Update only if the taget visible area is significantly different from the last preheated area.
        let targetDelta = max(abs(targetPreheatRect.midY - self.previousTargetPreheatRect.midY) / max(view.bounds.height / 3, 1),
                              abs(targetPreheatRect.midX - self.previousTargetPreheatRect.midX) / max(view.bounds.width / 3, 1))
        if targetDelta >= 1 {
            // need change
            changes.append((targetPreheatRect, self.previousTargetPreheatRect))
            // Store the preheat rect to compare against in the future.
            self.previousTargetPreheatRect = targetPreheatRect
        }
        
        // is change?
        guard !changes.isEmpty else {
            return
        }
        //logger.trace?.write("preheatRect is change: \(changes)")
        
        // Compute the assets to start caching and to stop caching.
        let details = _diff(changes.map { $0.new }, changes.map { $0.old })
        
        let added = details.added.flatMap { cachingIndexPaths(in: $0) }
        let removed = details.removed.flatMap { cachingIndexPaths(in: $0) }.filter { added.contains($0) }
        
        // Update the assets the PHCachingImageManager is caching.
        container.startCachingImages(for: cachingItems(at: added),
                                     size: cachingItemSize,
                                     mode: .aspectFill,
                                     options: nil)
        
        container.stopCachingImages(for: cachingItems(at: removed),
                                    size: cachingItemSize,
                                    mode: .aspectFill,
                                    options: nil)
    }
    
    /// Get the index path that needs to be cached in the specified rect.
    open func cachingIndexPaths(in rect: CGRect) -> [IndexPath] {
        //logger.trace?.write(rect)
        return collectionViewLayout.layoutAttributesForElements(in: rect)?.flatMap {
            guard $0.representedElementCategory == .cell else {
                return nil
            }
            return $0.indexPath
        } ?? []
    }
    
    /// Get the asset that needs to be cached in the specified index paths.
    open func cachingItems(at indexPaths: [IndexPath]) -> [Asset] {
        //logger.trace?.write(indexPaths)
        return indexPaths.flatMap {
            return data(source, at: $0) as? Asset
        }
    }

    // MARK: Library Change Notification
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    open func library(_ library: Library, didChange change: Change) {
        // if the library no authorized, ignore all change
        guard authorized else {
            return
        }
        logger.debug?.write()
        
        // Fetch the source change.
        guard let newChangeDetails = self.library(library, change: change, fetch: source) else {
            return
        }
        
        // If new source is empty, is a unknow error.
        guard let newSource = newChangeDetails.after else {
            return
        }
        
        // Change notifications may be made on a background queue.
        // Re-dispatch to the main queue to update the UI.
        DispatchQueue.main.async {
            // progressing
            self.library(library, change: change, source: newSource, apply: newChangeDetails)
        }
    }
    
    /// Get the details of the change.
    open func library(_ library: Library, change: Change, fetch source: Source) -> SourceChangeDetails? {
        return source.changeDetails(forAssets: change)
    }
    /// Apply the change details to UI.
    open func library(_ library: Library, change: Change, source: Source, apply changeDetails: SourceChangeDetails) {
        logger.trace?.write(changeDetails)
        
        // The collectionView must be set
        guard let collectionView = collectionView else {
            return
        }
        
        // Keep the new fetch result for future use.
        let oldSouce = self.source
        self.source = source
        
        //  The new data source has no any items.
        guard source.numberOfAssets != 0 else {
            // Emptying all the data & display empty data pages.
            collectionView.reloadData()
            ub_execption(with: container, source: source, error: Exception.notData, animated: true)
            return
        }
        
        // The library is prepared
        if !prepared {
            prepared = true
        }
        
        ub_execption(with: container, source: source, error: nil, animated: true)
        
        // If the old data has no any items, forced update all data.
        guard oldSouce.numberOfAssets != 0 else {
            collectionView.reloadData()
            return
        }
        
        // If items does no any change, ignore.
        guard changeDetails.hasItemChanges else {
            return
        }
        
        // If the source does not support incremental changes, must be forced updated all the data.
        guard changeDetails.hasIncrementalChanges else {
            collectionView.reloadData()
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
    
    // MARK: Private Method & Property
    
    // cache configure
    internal private(set) var targetContentOffset: CGPoint = .zero
    internal private(set) var previousPreheatRect: CGRect = .zero
    internal private(set) var previousTargetPreheatRect: CGRect = .zero
    
    // default configure
    private var _title: String?
}

/// Get the chnage rect
private func _diff(_ new: [CGRect], _ old: [CGRect]) -> (added: [CGRect], removed: [CGRect]) {
    // step1: merge
    let newRects = merging(new)
    let oldRects = merging(old)
    
    // step2: split
    return (
        newRects.flatMap { new in
            intersection(oldRects.flatMap { old in
                remaining(new, old)
            })
        },
        oldRects.flatMap { old in
            intersection(newRects.flatMap { new in
                remaining(old, new)
            })
        }
    )
}

/// Calculates the remaining rectangles.
internal func remaining(_ lhs: CGRect, _ rhs: CGRect) -> Array<CGRect> {
    // If the rectangle is not intersected, remaining all
    guard lhs.intersects(rhs), rhs.size != .zero else {
        return [lhs]
    }
    
    // +-+-----------+-+
    // | +-----------+ |
    // | |           | |
    // | +-----------+ |
    // +-+-----------+-+
    var results: [CGRect] = []
    
    // Left side(full)
    if lhs.minX < rhs.minX {
        let x1 = lhs.minX
        let x2 = rhs.minX
        let y1 = lhs.minY
        let y2 = lhs.maxY
        
        results.append(.init(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
    }
    
    // Right side(full)
    if rhs.maxX < lhs.maxX {
        let x1 = rhs.maxX
        let x2 = lhs.maxX
        let y1 = lhs.minY
        let y2 = lhs.maxY
        
        results.append(.init(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
    }
    
    // Top side(remaining)
    if lhs.minY < rhs.minY {
        let x1 = max(rhs.minX, lhs.minX)
        let x2 = min(rhs.maxX, lhs.maxX)
        let y1 = lhs.minY
        let y2 = rhs.minY
        
        results.append(.init(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
    }
    
    // Bottom side(remaining)
    if rhs.maxY < lhs.maxY {
        let x1 = max(rhs.minX, lhs.minX)
        let x2 = min(rhs.maxX, lhs.maxX)
        let y1 = rhs.maxY
        let y2 = lhs.maxY
        
        results.append(.init(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
    }
    
    return results
}

/// Calculates the merged rectangles
internal func merging(_ rects: [CGRect]) -> [CGRect] {

    var result = [CGRect]()
    // Must sort, otherwise there will be break rect
    rects.sorted(by: { $0.minY < $1.minY && $0.minX < $1.minX }).forEach { rect in
        // Is intersects?
        guard let last = result.last, last.intersects(rect) else {
            result.append(rect)
            return
        }
        result[result.count - 1] = last.union(rect)
    }

    return result
}

/// Calculates the intersection all rectangles
internal func intersection(_ rects: [CGRect]) -> [CGRect] {

    var result = [CGRect]()
    // must sort, otherwise there will be break rect
    rects.sorted(by: { $0.minY < $1.minY && $0.minX < $1.minX }).forEach { rect in
        // is intersects?
        guard let last = result.last, last.intersects(rect) else {
            result.append(rect)
            return
        }
        result[result.count - 1] = last.intersection(rect)
    }

    return result
}

