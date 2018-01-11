//
//  BrowserCollectionController.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// the asset list in album
internal class BrowserAlbumController: SourceCollectionViewController, TransitioningDataSource, DetailControllerItemUpdateDelegate, UICollectionViewDelegateFlowLayout {
    
    required init(container: Container, source: Source, factory: Factory, parameter: Any?) {
        super.init(container: container, source: source, factory: factory, parameter: parameter)
        
        // if the navigation bar disable translucent will have an error offset, enabled `extendedLayoutIncludesOpaqueBars` can solve the problem
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = true
        
        // The enable precache.
        self.cachingItemEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Specify the caching item size.
    override var cachingItemSize: CGSize {
        return BrowserAlbumLayout.thumbnailItemSize
    }

    /// Specifies whether the view controller prefers the header view to be hidden or shown.
    var prefersHeaderViewHidden: Bool {
        return !source.collectionTypes.contains(.moment)
    }

    /// Specifies whether the view controller prefers the footer view to be hidden or shown.
    var prefersFooterViewHidden: Bool {
        return false
    }
    
    override func loadView() {
        super.loadView()

        // the collectionView must king of `BrowserAlbumView`
        object_setClass(collectionView, BrowserAlbumView.self)

        collectionView?.alwaysBounceVertical = true
        collectionView?.register(NavigationHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HEADER")

        // the header view is enabled?
        if !prefersHeaderViewHidden {

            // generate header view
            let headerView = NavigationHeaderView(frame: .init(x: 0, y: 0, width: view.frame.width, height: 48))

            // config
            headerView.layer.zPosition = -0.5
            headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(_hanleHeader(_:))))

            // header style follow navgationbar style
            if let style = navigationController?.navigationBar.barStyle, style != .default {
                // drak theme
                headerView.effect = UIBlurEffect(style: .dark)
                headerView.textColor = navigationController?.navigationBar.titleTextAttributes?[NSForegroundColorAttributeName] as? UIColor ?? .white

            } else {
                // light theme
                headerView.effect = UIBlurEffect(style: .extraLight)
                headerView.textColor = navigationController?.navigationBar.titleTextAttributes?[NSForegroundColorAttributeName] as? UIColor ?? .black
            }

            // link to screen
            _headerView = headerView
        }

        // the footer view is enabled?
        if !prefersFooterViewHidden {

            // generate footer view
            let footerView = NavigationFooterView()

            // config
            footerView.frame = .init(x: 0, y: 0, width: collectionView?.frame.width ?? 0, height: 48)
            footerView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            footerView.alpha = 0

            // add to view
            collectionView?.addSubview(footerView)

            // link to screen
            _footerView = footerView
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // check
        let size = collectionViewLayout.collectionViewContentSize
        guard size != _cachedSize, prepared else {
            return
        }

        // update view
        _updateFooterView()
        _updateHeaderView()

        // update cache
        _cachedSize = size
    }

    // MARK: Collection View Configure

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // generate the cell for indexPath
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)

        // the zPosition of cell must be below header view
        cell.layer.zPosition = -1

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // generate the view for kind
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HEADER", for: indexPath)

        // the zPosition of header view must be below scroll indicator
        view.layer.zPosition = -0.75

        return view
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        // the view must king of `NavigationHeaderView`
        guard let view = view as? NavigationHeaderView else {
            return
        }

        // update data
        view.parent = _headerView
        view.section = indexPath.section
    }
    override func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        // the view must king of `NavigationHeaderView`
        guard let view = view as? NavigationHeaderView else {
            return
        }

        // clear data
        view.parent = nil
        view.section = nil
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // collectionViewLayout must king of `UICollectionViewFlowLayout`
        guard let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return .zero
        }
        var edg = UIEdgeInsets(top: collectionViewLayout.minimumLineSpacing, left: 0, bottom: 0, right: 0)

        if #available(iOS 11.0, *) {
            edg.left = collectionView.safeAreaInsets.left
            edg.right = collectionView.safeAreaInsets.right
        }

        // in header, top is 4
        if !prefersHeaderViewHidden {
            edg.top = 4
        }

        // if the section is empty, don't inset
        if collectionView.numberOfItems(inSection: section) == 0 {
            edg.top = 0
            edg.bottom = 0
        }

        // in first section, top is 4
        if section == 0 {
            edg.top = 4
        }

        // in last section, bottom is 4
        if section == collectionView.numberOfSections - 1 {
            edg.bottom = 4
        }

        return edg
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // if the section is empty, ignore
        // if the source can't allows show header, ignore
        guard !prefersHeaderViewHidden && collectionView.numberOfItems(inSection: section) != 0 else {
            return .zero
        }

        return .init(width: 0, height: 48)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.debug?.write("show detail with: \(indexPath)")

        // Try generate detail controller for factory
        let controller = container.instantiateViewController(with: .detail, source: source, parameter: indexPath)

        // can't use animator?
        if let controller = controller as? BrowserDetailController {

            controller.animator = Animator(source: self, destination: controller)
            controller.updateDelegate = self
        }

        // show next page
        show(controller, sender: indexPath)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)

        // The library is prepared?
        guard prepared else {
            return
        }
        
        _updateHeaderView()
    }

    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // Must call the parent class for caching
        let enabled = super.scrollViewShouldScrollToTop(scrollView)

        // If transitions animation is started, can't scroll
        return !_transitioning && enabled
    }

    // MARK: Detail Display Notification

    /// Display item will change
    func detailController(_ detailController: Any, willShowItem indexPath: IndexPath) {
        // if is, this suggests that are displaying
        if collectionView?.indexPathsForVisibleItems.contains(indexPath) ?? false {
            return
        }
        logger.debug?.write("over screen, scroll to \(indexPath)")

        // the indexPath is valid?
        guard indexPath.section < source.numberOfCollections && indexPath.item < source.numberOfAssets(inCollection: indexPath.section) else {
            return
        }

        // no displaying, scroll to item
        collectionView?.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        collectionView?.layoutIfNeeded()
    }

    /// Display item did change
    func detailController(_ detailController: Any, didShowItem indexPath: IndexPath) {
    }

    // MARK: Animatable Transitioning

    /// Returns transitioning view.
    func ub_transitionView(using animator: Animator, for operation: Animator.Operation) -> TransitioningView? {
        // the indexPath must be set
        guard let indexPath = animator.indexPath else {
            return nil
        }
        logger.trace?.write()

        // fetch cell at index path
        return collectionView?.cellForItem(at: indexPath) as? TransitioningView
    }

    /// Return a Boolean value that indicates whether users allows transition.
    func ub_transitionShouldStart(using animator: Animator, for operation: Animator.Operation) -> Bool {
        return true
    }

    /// Return A Boolean value that indicates whether users allows interactive animation transition.
    func ub_transitionShouldStartInteractive(using animator: Animator, for operation: Animator.Operation) -> Bool {
        return false
    }

    /// Transitions the context has been prepared.
    func ub_transitionDidPrepare(using animator: Animator, context: TransitioningContext) {
        
        // the indexPath & collectionView must be set
        guard let collectionView = collectionView, let indexPath = animator.indexPath  else {
            return
        }
        logger.trace?.write()

        // check the index path is displaying
        if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
            // no, scroll to the cell at index path
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)

            // must call the layoutIfNeeded method, otherwise cell may not create
            collectionView.layoutIfNeeded()
        }

        // the cell must exist, otherwise it is not show
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }

        // if it is to, reset cell boundary
        if context.ub_operation == .pop || context.ub_operation == .dismiss {
            let frame = cell.convert(cell.bounds, to: view)
            let height = view.frame.height - topLayoutGuide.length - bottomLayoutGuide.length

            let y1 = -topLayoutGuide.length + frame.minY - (_headerView?.frame.height ?? 0)
            let y2 = -topLayoutGuide.length + frame.maxY

            // reset content offset if needed
            if y2 > height {
                // bottom over boundary, reset to y2(bottom)
                collectionView.contentOffset.y += y2 - height
            } else if y1 < 0 {
                // top over boundary, rest to y1(top)
                collectionView.contentOffset.y += y1
            }
        }
        cell.isHidden = true

        // current transitions animation is started
        _transitioning = true
    }

    /// Transitions the animation will end.
    func ub_transitionWillEnd(using animator: Animator, context: TransitioningContext, transitionCompleted: Bool) {
        // the indexPath must be set & only process for disappear
        guard let indexPath = animator.indexPath, context.ub_operation.disappear else {
            return
        }
        logger.trace?.write(transitionCompleted)

        // the cell must exist, otherwise it is not show
        guard let cell = collectionView?.cellForItem(at: indexPath), let snapshotView = context.ub_snapshotView else {
            return
        }

        // generate a new snapshot view for transtion animation end
        let newSnapshotView = snapshotView.snapshotView(afterScreenUpdates: false)

        // config the new snapshot view
        newSnapshotView?.transform = snapshotView.transform
        newSnapshotView?.bounds = .init(origin: .zero, size: snapshotView.bounds.size)
        newSnapshotView?.center = .init(x: snapshotView.bounds.midX, y: snapshotView.bounds.midY)
        newSnapshotView.map {
            cell.addSubview($0)
        }

        // add animation for new snapshot view hidden
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            newSnapshotView?.alpha = 0
        }, completion: { _ in
            newSnapshotView?.removeFromSuperview()
        })
    }

    /// Transitions the animation has been end.
    func ub_transitionDidEnd(using animator: Animator, transitionCompleted: Bool) {
        // the cell must exist, otherwise it is not show
        guard let indexPath = animator.indexPath, let cell = collectionView?.cellForItem(at: indexPath) else {
            return
        }
        logger.trace?.write(transitionCompleted)

        // restore
        cell.isHidden = false

        // current transitions animation is end
        _transitioning = false
    }


    // MARK: Container Observer

    override func container(_ container: Container, change: Change, source: Source, apply changeDetails: SourceChangeDetails) {
        // Must update header & footer before update the data source.
        _headerView?.source = source
        _footerView?.source = source
        
        super.container(container, change: change, source: source, apply: changeDetails)
        
        // Update header & footer layout
        _updateHeaderView()
        _updateFooterView()
    }

    // MARK: Contents Loading

    override func controller(_ container: Container, didPrepare source: Source) {
        //
        collectionView.map {
            // update header view & footer view
            _headerView?.source = source
            _footerView?.source = source

            // scroll after update footer
            _updateFooterView()

            // scroll to init position if needed
            if source.collectionSubtypes.contains(.smartAlbumUserLibrary) || source.collectionTypes.contains(.moment) {
                // if the contentOffset over boundary
                let size = collectionViewLayout.collectionViewContentSize
                let height = view.frame.height - bottomLayoutGuide.length

                // reset vaild contentOffset in collectionView internal
                $0.contentOffset.y = size.height - height
            }
        }
        
        super.controller(container, didPrepare: source)
    }
    
    override func controller(_ container: Container, didLoad source: Source, error: Error?) {
        guard source.numberOfAssets != 0 else {
            self.ub_execption(with: container, source: source, error: Exception.notData, animated: true)
            return
        }
        super.controller(container, didLoad: source, error: error)
    }

    // MARK: Private Method & Property

    /// Returns header at offset
    private func _header(at offset: CGFloat) -> (Int, CGFloat)? {
        // header layouts must be set
        guard let headers = (collectionViewLayout as? BrowserAlbumLayout)?.allHeaderLayoutAttributes, !headers.isEmpty else {
            return nil
        }

        // the distance from the next setion
        var distance = CGFloat.greatestFiniteMagnitude

        // backward: fetch first -n or 0
        var start = min(_header, headers.count - 1)
        while start >= 0 {
            // the section has header view?
            guard let attributes = headers[start] else {
                // If the first header is empty, break
                guard start != 0 else {
                    break
                }
                start -= 1
                continue
            }
            // is -n or 0?
            guard (attributes.frame.minY - offset) < 0 else {
                start -= 1
                continue
            }
            break
        }

        // is over hide
        guard start >= 0 else {
            return nil
        }

        // forward: fetch first +n or inf
        var end = start
        while end < headers.count {
            // the section has header view?
            guard let attributes = headers[end] else {
                end += 1
                continue
            }
            // is +n
            guard (attributes.frame.minY - offset) > 0 else {
                start = end
                end += 1
                continue
            }
            distance = (attributes.frame.minY - offset)
            break
        }

        // cache for optimize search speed
        _header = start

        // success
        return (start, distance)
    }

    /// Update header view & layout
    private func _updateHeaderView() {
        // collection view must be set
        guard let collectionView = collectionView, let headerView = _headerView else {
            return
        }

        // fetch current section
        var offset = collectionView.contentOffset.y + collectionView.contentInset.top

        // in iOS11, if activated `safeAreaInsets`, need to subtraction the area
        if #available(iOS 11.0, *) {
            offset += collectionView.safeAreaInsets.top
        }

        guard let (section, distance) = _header(at: offset) else {
            headerView.section = nil
            headerView.removeFromSuperview()
            return
        }

        // if header layout is nil, no header view
        guard let attributes = (collectionViewLayout as? BrowserAlbumLayout)?.allHeaderLayoutAttributes[section] else {
            headerView.section = nil
            headerView.removeFromSuperview()
            return
        }

        // update position
        var header = attributes.frame
        header.origin.y = offset + min(distance - header.height, 0)

        // header view position is chnage?
        if headerView.frame != header {
            headerView.frame = header
        }

        // the header view section is change?
        if headerView.section != section {
            headerView.section = section
        }

        // the header view need show?
        if headerView.superview == nil {
            collectionView.insertSubview(headerView, at: 0)
        }
    }

    /// Update footer view & layout
    private func _updateFooterView() {
        // collection view must be set
        guard let collectionView = collectionView, let footerView = _footerView else {
            return
        }

        // the content size is change?
        let contentSize = collectionViewLayout.collectionViewContentSize

        var nframe = footerView.frame
        nframe.origin.y = contentSize.height + 0
        nframe.size.width = view.bounds.width

        // footer view position is change?
        if footerView.frame != nframe {
            footerView.frame = nframe
        }

        // calculates the height of the current minimum display
        let top = collectionView.contentInset.top - _footerViewInset.top
        let bottom = collectionView.contentInset.bottom - _footerViewInset.bottom
        let visableHeight = view.frame.height - top - bottom
        guard visableHeight < contentSize.height else {
            // too small to hide footer view
            _footerView?.alpha = 0
            _footerViewInset.bottom = 0
            return
        }

        // if status has change
        if footerView.alpha != 1 {
            // too large to show footer view & update content insets
            _footerView?.alpha = 1
            _footerViewInset.bottom = footerView.frame.height
        }
    }

    /// Tap header view
    fileprivate dynamic func _hanleHeader(_ sender: Any) {
        // the section must be set
        guard let section = _headerView?.section, let frame = (collectionViewLayout as? BrowserAlbumLayout)?.allHeaderLayoutAttributes[section]?.frame else {
            return
        }
        logger.debug?.write(frame, section)

        // scroll to header start position
        collectionView?.scrollRectToVisible(frame, animated: true)
    }

    // footer
    private var _footerView: NavigationFooterView?
    private var _footerViewInset: UIEdgeInsets = .zero {
        willSet {
            // collectionView must be set
            guard let collectionView = collectionView, newValue != _footerViewInset else {
                return
            }
            var edg = collectionView.contentInset

            edg.top += newValue.top - _footerViewInset.top
            edg.left += newValue.left - _footerViewInset.left
            edg.right += newValue.right - _footerViewInset.right
            edg.bottom += newValue.bottom - _footerViewInset.bottom

            collectionView.contentInset = edg
        }
    }

    // header
    private var _header: Int = 0
    private var _headerView: NavigationHeaderView?

    private var _cachedSize: CGSize?
    private var _transitioning: Bool = false
}

