//
//  BrowserDetailController.swift
//  Ubiquity
//
//  Created by sagesse on 21/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserDetailController: SourceCollectionViewController, TransitioningDataSource, DetailControllerItemUpdateDelegate, DetailControllerItemRotationDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {

    required init(container: Container, source: Source, factory: Factory, parameter: Any?) {
        super.init(container: container, source: source, factory: factory, parameter: parameter)

        // Set the display position
        self.displayedIndexPath = parameter as? IndexPath ?? .init(item: 0, section: 0)

        // the page must hide the bottom bar
        //self.hidesBottomBarWhenPushed = true

        // setup toolbar items
        let toolbarItems = [
            indicatorItem,
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
        ]
        setToolbarItems(toolbarItems, animated: false)

        // if the navigation bar disable translucent will have an error offset, enabled `extendedLayoutIncludesOpaqueBars` can solve the problem
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false

        // Don't need a cache for details
        self.cachingItemEnabled = false
        self.authorized = true
        self.prepared = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var prefersTabBarHidden: Bool {
        return true
    }
    
    override var prefersToolbarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // full screen mode shows white status bar
        guard _isFullscreen else {
            // default case
            return super.preferredStatusBarStyle
        }
        return .lightContent
    }
    
    override func loadView() {
        super.loadView()

        view.clipsToBounds = true
        view.backgroundColor = .white

        // setup gesture recognizer
        interactiveDismissGestureRecognizer.delegate = self
        interactiveDismissGestureRecognizer.maximumNumberOfTouches = 1
        interactiveDismissGestureRecognizer.addTarget(self, action: #selector(_dismissHandler(_:)))

        view.addGestureRecognizer(interactiveDismissGestureRecognizer)

        // Setup colleciton view
        collectionView?.frame = UIEdgeInsetsInsetRect(view.bounds, (collectionViewLayout as? BrowserDetailLayout)?.itemInset ?? .zero)
        collectionView?.scrollsToTop = false
        collectionView?.isPagingEnabled = true
        collectionView?.alwaysBounceVertical = false
        collectionView?.alwaysBounceHorizontal = true
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.allowsMultipleSelection = false
        collectionView?.allowsSelection = false
        collectionView?.backgroundColor = view.backgroundColor

        // in the iOS11 if there is no disable adjustment, `scrollToItem(at:, at:, animated:)` will location to a wrong position
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .never
        }

        //        // setup indicator
        //        indicatorItem.indicatorView.delegate = self
        //        indicatorItem.indicatorView.dataSource = self
        //        indicatorItem.indicatorView.register(IndicatorViewCell.dynamic(with: UIImageView.self), forCellWithReuseIdentifier: "ASSET-IMAGE")
        //        //indicatorItem.indicatorView.register(IndicatorViewCell.dynamic(with: UIScrollView.self), forCellWithReuseIdentifier: "ASSET-IMAGE")

        // setup title view
        navigationItem.titleView = _titleView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // setup title color for navgation bar
        _titleView.barStyle = navigationController?.navigationBar.barStyle ?? .default
        _titleView.titleTextAttributes = navigationController?.navigationBar.titleTextAttributes

        UIView.performWithoutAnimation {
            // update current item
            _updateCurrentItem(at: displayedIndexPath)

            collectionView?.scrollToItem(at: displayedIndexPath, at: .centeredHorizontally, animated: false)
            //            indicatorItem.indicatorView.scrollToItem(at: _itemIndexPath, animated: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        super.viewWillAppear(animated)

        //        UIView.animate(withDuration: 0.25) {
        ////            self.tabBarController?.tabBar.alpha = 0
        //            self.navigationController?.setToolbarHidden(false, animated: animated)
        //        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        //        UIView.animate(withDuration: 0.25) {
        //            self.navigationController?.setToolbarHidden(true, animated: animated)
        ////            self.tabBarController?.tabBar.alpha = 1
        //        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // size change
        guard _cachedBounds?.size != view.bounds.size else {
            return
        }

        // update title layout
        navigationItem.titleView?.setNeedsLayout()
        navigationItem.titleView?.layoutIfNeeded()

        // view.bounds is change, need update content inset
        _cachedBounds = view.bounds
        _updateSystemContentInsetIfNeeded()
    }


    // MARK: Dismiss Gesture Recognizer

    /// The dismiss gesture recognizer should begin
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // only processing interactive dismiss gesture recognizer
        guard interactiveDismissGestureRecognizer == gestureRecognizer else {
            return true // ignore
        }

        // detect the direction of gestures => up or down
        let velocity = interactiveDismissGestureRecognizer.velocity(in: collectionView)
        guard fabs(velocity.x / velocity.y) < 1.5 else {
            return false
        }
        guard let cell = collectionView?.visibleCells.last as? BrowserDetailCell else {
            return false
        }

        // check this gesture event can not trigger bounces
        let point = interactiveDismissGestureRecognizer.location(in: cell.ub_contentView?.superview)
        guard (point.y - view.frame.height) <= 0 else {
            return false
        }
        return true
    }

    /// The dismiss gesture recognizer show simultaneously
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // only processing interactive dismiss gesture recognizer
        guard interactiveDismissGestureRecognizer == gestureRecognizer else {
            return false // ignore
        }

        // if it has started to interact, it is the exclusive mode
        guard !_transitionIsInteractiving else {
            return false
        }
        guard let panGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        // only allow canvas view gestures can operate
        guard let view = panGestureRecognizer.view, view.superview is CanvasView else {
            return false
        }
        return true
    }

    // MARK: Collection View Configure

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)

        // Only process the `BrowserDetailCell`
        (cell as? BrowserDetailCell).map {
            $0.delegate = self
            $0.updateContentInset(_systemContentInset, forceUpdate: false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // if section is empty, there is no need to fill in the blanks
        guard let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout, collectionView.numberOfItems(inSection: section) != 0 else {
            return .zero
        }
        return collectionViewLayout.sectionInset
    }

    /// The scrollView did scroll
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // only process in collection view
        // check whether to allow the change of content offset
        guard collectionView === scrollView, !ignoreContentOffsetChange else {
            return
        }
        //logger.trace?.write(scrollView.contentOffset)

        // update current item & index pathd
        _updateCurrentItem(with: scrollView.contentOffset)
        _updateCurrentItemForIndicator(with: scrollView.contentOffset)
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // only process in collection view
        guard collectionView === scrollView else {
            return
        }

        //        // notify indicator interactive start
        //        indicatorItem.indicatorView.beginInteractiveMovement()
    }

    override  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // only process in collection view
        // if you do not need to decelerate, notify indicator interactive finish
        guard collectionView === scrollView, !decelerate else {
            return
        }
        //
        //        indicatorItem.indicatorView.endInteractiveMovement()
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // only process in collection view
        guard collectionView === scrollView else {
            return
        }

        //        // notify indicator interactive finish
        //        indicatorItem.indicatorView.endInteractiveMovement()
    }


    // MARK: Full-Screen Display

    override var ub_isFullscreen: Bool {
        return _isFullscreen
    }

    @discardableResult
    override func ub_enterFullscreen(animated: Bool) -> Bool {
        logger.debug?.write(animated)

        _isFullscreen = true
        _animate(with: 0.25, options: .curveEaseInOut, animations: {
            // need to add animation?
            guard animated else {
                return
            }

            self.setNeedsStatusBarAppearanceUpdate()

            self.view.backgroundColor = .black
            self.collectionView?.backgroundColor = .black

            if !self.prefersToolbarHidden {
                self.navigationController?.toolbar?.alpha = 0
            }
            if !self.prefersNavigationBarHidden {
                self.navigationController?.navigationBar.alpha = 0
            }

            self._updateSystemContentInsetIfNeeded(forceUpdate: true)

        }, completion: { finished in

            self.setNeedsStatusBarAppearanceUpdate()

            self.view.backgroundColor = .black
            self.collectionView?.backgroundColor = .black

            if !self.prefersToolbarHidden {
                self.navigationController?.toolbar?.alpha = 1
                self.navigationController?.toolbar.isHidden =  true
            }
            if !self.prefersNavigationBarHidden {
                self.navigationController?.navigationBar.alpha = 1
                self.navigationController?.navigationBar.isHidden =  true
            }

            self._updateSystemContentInsetIfNeeded()
        })

        return true
    }

    @discardableResult
    override func ub_exitFullscreen(animated: Bool) -> Bool {
        logger.debug?.write(animated)

        _isFullscreen = false
        _animate(with: 0.25, options: .curveEaseInOut, animations: {
            // need to add animation?
            guard animated else {
                return
            }
            UIView.performWithoutAnimation {

                if !self.prefersToolbarHidden {
                    self.navigationController?.toolbar?.alpha = 0
                    self.navigationController?.toolbar.isHidden = false
                }
                if !self.prefersNavigationBarHidden {
                    self.navigationController?.navigationBar.alpha = 0
                    self.navigationController?.navigationBar.isHidden = false
                }
            }

            self.setNeedsStatusBarAppearanceUpdate()

            self.view.backgroundColor = .white
            self.collectionView?.backgroundColor = .white

            if !self.prefersToolbarHidden {
                self.navigationController?.toolbar?.alpha = 1
            }
            if !self.prefersNavigationBarHidden {
                self.navigationController?.navigationBar.alpha = 1
            }

            self._updateSystemContentInsetIfNeeded(forceUpdate: true)

        }, completion: { finished in

            self.view.backgroundColor = .white
            self.collectionView?.backgroundColor = .white

            self._updateSystemContentInsetIfNeeded()
        })

        return true
    }

    // MARK: Animatable Transitioning

    /// Returns transitioning view.
    func ub_transitionView(using animator: Animator, for operation: Animator.Operation) -> TransitioningView? {
        logger.trace?.write()

        guard let indexPath = animator.indexPath else {
            return nil
        }
        // get at current index path the cell
        return collectionView?.cellForItem(at: indexPath) as? BrowserDetailCell
    }

    /// Return a Boolean value that indicates whether users allows transition.
    func ub_transitionShouldStart(using animator: Animator, for operation: Animator.Operation) -> Bool {
        logger.trace?.write()

        animator.indexPath = displayedIndexPath

        // check the boundary
        guard displayedIndexPath.section < source.numberOfCollections && displayedIndexPath.item < source.numberOfAssets(inCollection: displayedIndexPath.section) else {
            return false
        }

        return true
    }

    /// Return A Boolean value that indicates whether users allows interactive animation transition.
    func ub_transitionShouldStartInteractive(using animator: Animator, for operation: Animator.Operation) -> Bool {
        logger.trace?.write()

        let state = interactiveDismissGestureRecognizer.state
        guard state == .changed || state == .began else {
            return false
        }
        // transitions in full-screen mode, require additional add exit full-screen of the animation
        guard ub_isFullscreen else {
            return true
        }
        UIView.performWithoutAnimation {

            self.setNeedsStatusBarAppearanceUpdate()

            if !self.prefersToolbarHidden {
                self.navigationController?.toolbar?.alpha = 0
                self.navigationController?.toolbar?.isHidden = false
            }
            if !self.prefersNavigationBarHidden {
                self.navigationController?.navigationBar.alpha = 0
                self.navigationController?.navigationBar.isHidden = false
            }
        }
        UIView.animate(withDuration: 0.25) {

            if !self.prefersToolbarHidden {
                self.navigationController?.toolbar?.alpha = 1
            }
            if !self.prefersNavigationBarHidden {
                self.navigationController?.navigationBar.alpha = 1
            }

            self.setNeedsStatusBarAppearanceUpdate()
        }
        return true
    }

    /// Transitions the context has been prepared.
    func ub_transitionDidPrepare(using animator: Animator, context: TransitioningContext) {
        // must be attached to the collection view
        guard let collectionView = collectionView, let indexPath = animator.indexPath else {
            return
        }
        // check the index path is displaying
        if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
            // no, scroll to the cell at index path
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            // must call the layoutIfNeeded method, otherwise cell may not create
            UIView.performWithoutAnimation {
                collectionView.setNeedsLayout()
                collectionView.layoutIfNeeded()
                //                indicatorItem.indicatorView.setNeedsLayout()
                //                indicatorItem.indicatorView.layoutIfNeeded()
            }
        }
    }

    /// Transitions the animation has been start.
    func ub_transitionDidStart(using animator: Animator, context: TransitioningContext) {
        _transitionContext = context
    }

    /// Transitions the animation has been end.
    func ub_transitionDidEnd(using animator: Animator, transitionCompleted: Bool) {
        _transitionContext = nil

        // transitions in failure, if needed restore full-screen mode
        guard !transitionCompleted && ub_isFullscreen else {
            return
        }
        UIView.performWithoutAnimation {

            self.navigationController?.toolbar?.alpha = 1
            self.navigationController?.toolbar?.isHidden = true
            self.navigationController?.navigationBar.alpha = 1
            self.navigationController?.navigationBar.isHidden = true

            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func controller(_ container: Container, didPrepare source: Source) {

        // setup title color for navgation bar
        _titleView.barStyle = navigationController?.navigationBar.barStyle ?? .default
        _titleView.titleTextAttributes = navigationController?.navigationBar.titleTextAttributes

        UIView.performWithoutAnimation {
            // update current item
            _updateCurrentItem(at: displayedIndexPath)

            collectionView?.scrollToItem(at: displayedIndexPath, at: .centeredHorizontally, animated: false)
            //            indicatorItem.indicatorView.scrollToItem(at: _itemIndexPath, animated: false)
        }
        
        super.controller(container, didPrepare: source)
    }

    override func orientation(_ source: Source, at indexPath: IndexPath) -> UIImageOrientation {
        //
        guard let asset = source.asset(at: indexPath), !_orientationes.isEmpty else {
            return .up
        }
        
        return _orientationes[asset.ub_identifier] ?? .up
    }

    // MARK: Library Change Notification
    
    override func library(_ library: Library, change: Change, source: Source, apply changeDetails: SourceChangeDetails) {
        // must be clear the layout attributes cache
        _clearItemCache()

        // check collection asset count change
        guard source.numberOfAssets != 0 else {
            // new source is empty, back to albums
            self.collectionView?.reloadData()
            self.navigationController?.popViewController(animated: true)
            return
        }

        super.library(library, change: change, source: source, apply: changeDetails)

        // Update current item.
        self.collectionView.map {
            _updateCurrentItem(with: $0.contentOffset)
            _updateCurrentItemForIndicator(with: $0.contentOffset)
        }
    }
    
    // MARK: Item Change

    // Display item will change
    func detailController(_ detailController: Any, willShowItem indexPath: IndexPath) {
        logger.debug?.write(indexPath)

        // forward
        updateDelegate?.detailController(self, willShowItem: indexPath)
    }

    // Display item did change
    func detailController(_ detailController: Any, didShowItem indexPath: IndexPath) {
        logger.debug?.write(indexPath)

        // forward
        updateDelegate?.detailController(self, didShowItem: indexPath)

        // update title in item change
        _titleView.asset = source.asset(at: indexPath)
    }

    // MARK: Item Rotation

    /// Display item will rotationing
    func detailController(_ detailController: Any, shouldBeginRotationing asset: Asset) -> Bool {
        logger.debug?.write(asset.ub_identifier)

        // allow
        return true
    }

    /// Display item did rotationing
    func detailController(_ detailController: Any, didEndRotationing asset: Asset, at orientation: UIImageOrientation) {
        logger.debug?.write(asset.ub_identifier, "is landscape: \(orientation.ub_isLandscape)")

        // save
        _orientationes[asset.ub_identifier] = orientation
    }

    // MARK: Event

    /// Dismiss handler
    private dynamic func _dismissHandler(_ sender: UIPanGestureRecognizer) {

        if !_transitionIsInteractiving { // start
            // check the direction of gestures => vertical & up
            let velocity = sender.velocity(in: view)
            guard velocity.y > 0 && fabs(velocity.x / velocity.y) < 1.5 else {
                return
            }
            // get cell & detail view & container view
            guard let cell = collectionView?.visibleCells.last as? BrowserDetailCell, let contentView = cell.ub_contentView else {
                return
            }
            // check whether this has triggered bounces
            let mh = sender.location(in: view).y
            let point = sender.location(in: cell.ub_contentView?.superview)
            guard point.y - mh < 0 || contentView.frame.height <= view.frame.height else {
                return
            }
            // enable interactiving
            _transitionAtLocation = sender.location(in: nil)
            _transitionIsInteractiving = true
            // dismiss
            DispatchQueue.main.async {
                // if is navigation controller poped
                if let navigationController = self.navigationController {
                    navigationController.popViewController(animated: true)
                    return
                }

                // is presented
                self.dismiss(animated: true, completion: nil)
            }
            logger.debug?.write("start")

        } else if sender.state == .changed { // update

            let origin = _transitionAtLocation
            let current = sender.location(in: nil)

            let offset = CGPoint(x: current.x - origin.x, y: current.y - origin.y)
            let percent = offset.y / (UIScreen.main.bounds.height * 3 / 5)

            _transitionContext?.ub_update(percent: min(max(percent, 0), 1), at: offset)

        } else { // stop

            logger.debug?.write("stop")
            // read of state
            let context = _transitionContext
            let complete = sender.state == .ended && sender.velocity(in: nil).y >= 0
            // have to delay treatment, otherwise will not found draggingContentOffset
            DispatchQueue.main.async {
                // forced to reset the content of offset
                // prevent jitter caused by the rolling animation
                self.collectionView?.visibleCells.forEach {
                    // fetch cell & containerView
                    guard let cell = ($0 as? BrowserDetailCell), let containerView = cell.ub_containerView else {
                        return
                    }
                    guard let offset = cell.ub_draggingContentOffset, containerView.isDecelerating else {
                        return
                    }
                    // stop all scroll animation
                    containerView.setContentOffset(offset, animated: false)
                }
                // commit animation
                context?.ub_complete(complete)
            }
            // disable interactiving
            _transitionContext = nil
            _transitionIsInteractiving = false
        }
    }

    fileprivate func _clearItemCache() {

        // the item layout
        _cachedItemLayoutAttributes = nil
    }

    fileprivate func _updateCurrentItem(at indexPath: IndexPath) {
        logger.debug?.write(indexPath)

        // notify user item did change
        detailController(self, willShowItem: indexPath)

        // update current item index path
        displayedItem = source.asset(at: indexPath)
        displayedIndexPath = indexPath

        // update current item context
        _cachedItemLayoutAttributes = collectionView?.layoutAttributesForItem(at: indexPath)

        detailController(self, didShowItem: indexPath)
    }
    fileprivate func _updateCurrentItem(with contentOffset: CGPoint) {

        // must has a collection view
        guard let collectionView = collectionView else {
            return
        }
        let x = contentOffset.x + collectionView.bounds.width / 2

        // check for any changes
        if let item = _cachedItemLayoutAttributes, item.frame.minX <= x && x < item.frame.maxX {
            return // hit cache
        }

        // find item at content offset
        guard let indexPath = collectionView.indexPathForItem(at: .init(x: x, y: 0)) else {
            return // not found, ignore
        }
        _updateCurrentItem(at: indexPath)
    }

    fileprivate func _updateCurrentItemForIndicator(with contentOffset: CGPoint) {
//        // must has a collection view
//        guard let collectionView = collectionView else {
//            return
//        }
//        let value = contentOffset.x / collectionView.bounds.width
//        let to = Int(ceil(value))
//        let from = Int(floor(value))
//        let percent = modf(value + 1).1
//        // if from index is changed
//        if _interactivingFromIndex != from {
//            // get index path from collection view
//            let indexPath = collectionView.indexPathForItem(at: CGPoint(x: (CGFloat(from) + 0.5) * collectionView.bounds.width , y: 0))
//
//            _interactivingFromIndex = from
//            _interactivingFromIndexPath = indexPath
//        }
//        // if to index is changed
//        if _interactivingToIndex != to {
//            // get index path from collection view
//            let indexPath = collectionView.indexPathForItem(at: CGPoint(x: (CGFloat(to) + 0.5) * collectionView.bounds.width , y: 0))
//
//            _interactivingToIndex = to
//            _interactivingToIndexPath = indexPath
//        }
//        // use percentage update index
//        indicatorItem.indicatorView.updateIndexPath(from: _interactivingFromIndexPath, to: _interactivingToIndexPath, percent: percent)
    }
    fileprivate func _updateSystemContentInsetIfNeeded(forceUpdate: Bool = false) {

        var contentInset  = UIEdgeInsets.zero

        if !ub_isFullscreen {
            // have navigation bar?
            contentInset.top = topLayoutGuide.length
            // have toolbar?
            contentInset.bottom = bottomLayoutGuide.length //+ indicatorItem.height
        }
        // is change?
        guard _systemContentInset != contentInset else {
            return
        }
        logger.trace?.write(contentInset)

        // notice all displayed cell
        collectionView?.visibleCells.forEach {
            ($0 as? BrowserDetailCell)?.updateContentInset(contentInset, forceUpdate: forceUpdate)
        }
        // update cache
        _systemContentInset = contentInset
    }

    fileprivate func _performWithoutContentOffsetChange<T>(_ actionsWithoutAnimation: () -> T) -> T {
        objc_sync_enter(self)
        _ignoreContentOffsetChange = true
        let result = actionsWithoutAnimation()
        _ignoreContentOffsetChange = false
        objc_sync_exit(self)
        return result
    }

    // MARK: internal var

    var animator: Animator? {
        willSet {
            ub_transitioningDelegate = newValue
        }
    }

    let indicatorItem = IndicatorItem()
    let interactiveDismissGestureRecognizer = UIPanGestureRecognizer()
    let tapGestureRecognizer = UITapGestureRecognizer()

    var vaildContentOffset = CGPoint.zero

    var ignoreContentOffsetChange: Bool {
        objc_sync_enter(self)
        let result = _ignoreContentOffsetChange
        objc_sync_enter(self)
        return result
    }

    /// the any item update delegate
    weak var updateDelegate: DetailControllerItemUpdateDelegate?

    fileprivate func _animate(with duration: TimeInterval, options: UIViewAnimationOptions, animations: @escaping () -> Swift.Void, completion: ((Bool) -> Void)? = nil) {
        //UIView.animate(withDuration: duration * 5, delay: 0, options: options, animations: animations, completion: completion)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: options, animations: animations, completion: completion)
    }

    // MARK: Property

    private(set) var displayedItem: Asset?
    private(set) var displayedIndexPath: IndexPath = []

    // MARK: Ivar

    // title view
    fileprivate var _titleView: NavigationTitleView = .init(frame: .init(x: 0, y: 0, width: 48, height: 24))

    // transition
    fileprivate var _transitionIsInteractiving: Bool = false
    fileprivate var _transitionAtLocation: CGPoint = .zero
    fileprivate var _transitionContext: TransitioningContext?

    // full-screen mode
    fileprivate var _isFullscreen: Bool = false

    // cache
    fileprivate var _cachedBounds: CGRect?
    fileprivate var _cachedItemLayoutAttributes: UICollectionViewLayoutAttributes?

    // 插入/删除的时候必须清除
    fileprivate var _interactivingFromIndex: Int?
    fileprivate var _interactivingFromIndexPath: IndexPath?
    fileprivate var _interactivingToIndex: Int?
    fileprivate var _interactivingToIndexPath: IndexPath?


    fileprivate var _orientationes: [String: UIImageOrientation] = [:]

    fileprivate var _ignoreContentOffsetChange: Bool = false
    fileprivate var _systemContentInset: UIEdgeInsets = .zero
}

