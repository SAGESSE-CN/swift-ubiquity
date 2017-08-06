//
//  BrowserDetailController.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserDetailController: UICollectionViewController, Controller, ChangeObserver, TransitioningDataSource, DetailControllerItemRotationDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {
    
    required init(container: Container, factory: Factory, source: Source, sender: Any) {
        self.source = source
        self.factory = factory
        self.container = container
        self.itemIndexPath = sender as? IndexPath ?? .init(item: 0, section: 0)
        
        let collectionViewLayout = BrowserDetailLayout()
        
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumLineSpacing = -extraContentInset.left * 2
        collectionViewLayout.minimumInteritemSpacing = -extraContentInset.right * 2
        collectionViewLayout.headerReferenceSize = CGSize(width: -extraContentInset.left, height: 0)
        collectionViewLayout.footerReferenceSize = CGSize(width: -extraContentInset.right, height: 0)

        // continue init the UI
        super.init(collectionViewLayout: collectionViewLayout)
        
//        // the page must hide the bottom bar
//        self.hidesBottomBarWhenPushed = true
        
        // setup toolbar items
        let toolbarItems = [
            indicatorItem,
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
        ]
        setToolbarItems(toolbarItems, animated: false)
        
        // listen albums any change
        container.addChangeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // cancel listen change
        container.removeChangeObserver(self)
    }
    
    override var prefersTabBarHidden: Bool {
        return true
    }
    
    override var prefersToolbarHidden: Bool {
        return true
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
        // setup controller
        title = "Detail"
        automaticallyAdjustsScrollViewInsets = false
        
        // setup view
        view.clipsToBounds = true
        view.backgroundColor = .white
        
        // setup gesture recognizer
        interactiveDismissGestureRecognizer.delegate = self
        interactiveDismissGestureRecognizer.maximumNumberOfTouches = 1
        interactiveDismissGestureRecognizer.addTarget(self, action: #selector(_dismissHandler(_:)))
        
        view.addGestureRecognizer(interactiveDismissGestureRecognizer)
        
        // setup colleciton view
        collectionView?.frame = UIEdgeInsetsInsetRect(view.bounds, extraContentInset)
        collectionView?.scrollsToTop = false
        collectionView?.isPagingEnabled = true
        collectionView?.alwaysBounceVertical = false
        collectionView?.alwaysBounceHorizontal = true
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.allowsMultipleSelection = false
        collectionView?.allowsSelection = false
        collectionView?.backgroundColor = .white
        
        // register colleciton cell
        factory.contents.forEach {
            collectionView?.register($1, forCellWithReuseIdentifier: $0)
        }
        
//        // setup indicator 
//        indicatorItem.indicatorView.delegate = self
//        indicatorItem.indicatorView.dataSource = self
//        indicatorItem.indicatorView.register(IndicatorViewCell.dynamic(with: UIImageView.self), forCellWithReuseIdentifier: "ASSET-IMAGE")
//        //indicatorItem.indicatorView.register(IndicatorViewCell.dynamic(with: UIScrollView.self), forCellWithReuseIdentifier: "ASSET-IMAGE")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIView.performWithoutAnimation {
            collectionView?.scrollToItem(at: itemIndexPath, at: .centeredHorizontally, animated: false)
//            indicatorItem.indicatorView.scrollToItem(at: _itemIndexPath, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        super.viewWillAppear(animated)
        self.t_viewWillAppear(animated)
        
        
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
        guard _cacheBounds?.size != view.bounds.size else {
            return
        }
        // view.bounds is change, need update content inset
        _cacheBounds = view.bounds
        _updateSystemContentInsetIfNeeded()
    }
    
    // MARK: Collection View Scroll
    
    /// The scrollView did scroll
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // only process in collection view
        // check whether to allow the change of content offset
        guard collectionView === scrollView, !ignoreContentOffsetChange else {
            return
        }
        
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
    
    // MARK: Collection View Configure
    
    /// Returns the section numbers
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return source.numberOfSections
    }
    
    /// Return the items number in section
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return source.numberOfItems(inSection: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // generate the reuse identifier
        let type = source.asset(at: indexPath)?.mediaType ?? .unknown
        
        // generate cell for media type
        return collectionView.dequeueReusableCell(withReuseIdentifier: ub_identifier(with: type), for: indexPath)
    }
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // cell must king of `Displayable`
        guard let displayer = cell as? Displayable, let asset = source.asset(at: indexPath) else {
            return
        }
        
        // update content inset
        (cell as? BrowserDetailCell)?.updateContentInset(_systemContentInset, forceUpdate: false)
        
        // update disaply content
        displayer.delegate = self
        displayer.willDisplay(with: asset, container: container, orientation: _orientationes[asset.identifier] ?? .up)
    }
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // cell must king of `Displayable`
        guard let displayer = cell as? BrowserDetailCell else {
            return
        }
        
        displayer.endDisplay(with: container)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.frame.size
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
        animator.indexPath = itemIndexPath
        
        // check the boundary
        guard itemIndexPath.section < source.numberOfSections && itemIndexPath.item < source.numberOfItems(inSection: itemIndexPath.section) else {
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
        logger.trace?.write()
        
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
    
    // MARK: Library Change Notification
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change) {
        // fetch source change details
        guard let details = source.changeDetails(for: change) else {
            return // no change
        }
        logger.trace?.write()
        
        // change notifications may be made on a background queue.
        // re-dispatch to the main queue to update the UI.
        DispatchQueue.main.async {
            // progressing
            self.library(library, didChange: change, details: details)
        }
    }
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change, details: SourceChangeDetails) {
        
        // get collection view and new data source
        guard let collectionView = collectionView, let source = details.after else {
            return
        }
        // keep the new fetch result for future use.
        self.source = source
        
        // update collection asset count change
        guard source.count != 0 else {
            // count is zero, no data
            collectionView.reloadData()
            navigationController?.popViewController(animated: true)
            return
        }

        // the aset has any change?
        guard details.hasAssetChanges else {
            return
        }
        
        // update collection
        collectionView.performBatchUpdates({
            
            // For indexes to make sense, updates must be in this order:
            // delete, insert, reload, move
            
            details.deleteSections.map { collectionView.deleteSections($0) }
            details.insertSections.map { collectionView.insertSections($0) }
            details.reloadSections.map { collectionView.reloadSections($0) }
            
            details.removeItems.map { collectionView.deleteItems(at: $0) }
            details.insertItems.map { collectionView.insertItems(at: $0) }
            details.reloadItems.map { collectionView.reloadItems(at: $0) }
            
            // move
            details.enumerateMoves { from, to in
                collectionView.moveItem(at: from, to: to)
            }
            
        }, completion: { _ in
            // cell animation perform finished, update index path
            self.scrollViewDidScroll(collectionView)
        })
    }
    
    // MARK: Detail Rotation
    
    /// Display item will change
    func detailController(_ detailController: Any, shouldBeginRotationing asset: Asset) -> Bool {
        logger.debug?.write(asset.identifier)
        // allow
        return true
    }
    
    /// Display item did rotationing
    func detailController(_ detailController: Any, didEndRotationing asset: Asset, at orientation: UIImageOrientation) {
        logger.debug?.write(asset.identifier, "is landscape: \(orientation.ub_isLandscape)")
        // save
        _orientationes[asset.identifier] = orientation
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
    
    
    fileprivate func _updateCurrentItem(at indexPath: IndexPath) {
        logger.debug?.write(indexPath)
        
        // notify user item will change
        updateDelegate?.detailController(self, willShowItem: indexPath)
        
        // update current item index path
        itemIndexPath = indexPath
        
        title = source.asset(at: indexPath)?.title
        
        
        // update current item context
        _itemLayoutAttributes = collectionView?.layoutAttributesForItem(at: indexPath)
        
        // notify user item did change
        updateDelegate?.detailController(self, didShowItem: indexPath)
    }
    fileprivate func _updateCurrentItem(with contentOffset: CGPoint) {
        
        // must has a collection view
        guard let collectionView = collectionView else {
            return
        }
        let x = contentOffset.x + collectionView.bounds.width / 2
        
        // check for any changes
        if let item = _itemLayoutAttributes, item.frame.minX <= x && x < item.frame.maxX {
            return // hit cache
        }
        
        // find item at content offset
        guard let indexPath = collectionView.indexPathForItem(at: CGPoint(x: x, y: 0)) else {
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
    
    let extraContentInset = UIEdgeInsetsMake(0, -20, 0, -20)
    
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
    
    private(set) var itemIndexPath: IndexPath
    private(set) var container: Container
    private(set) var factory: Factory
    private(set) var source: Source
    
    // MARK: Ivar
    
    // transition
    fileprivate var _transitionIsInteractiving: Bool = false
    fileprivate var _transitionAtLocation: CGPoint = .zero
    fileprivate var _transitionContext: TransitioningContext?
    
    // full-screen mode
    fileprivate var _isFullscreen: Bool = false
    
    // cache
    fileprivate var _cacheBounds: CGRect?
    
    // 插入/删除的时候必须清除
    fileprivate var _interactivingFromIndex: Int?
    fileprivate var _interactivingFromIndexPath: IndexPath?
    fileprivate var _interactivingToIndex: Int?
    fileprivate var _interactivingToIndexPath: IndexPath?
    
    // the current item context
    fileprivate var _itemLayoutAttributes: UICollectionViewLayoutAttributes?
    
    fileprivate var _orientationes: [String: UIImageOrientation] = [:]
    
    fileprivate var _ignoreContentOffsetChange: Bool = false
    fileprivate var _systemContentInset: UIEdgeInsets = .zero
}

//
//// add indicator view display support
//extension BrowserDetailController: IndicatorViewDataSource, IndicatorViewDelegate {
//    
//    func numberOfSections(in indicator: IndicatorView) -> Int {
//        return _source.numberOfSections
//    }
//    
//    func indicator(_ indicator: IndicatorView, numberOfItemsInSection section: Int) -> Int {
//        return _source.numberOfItems(inSection: section)
//    }
//    
//    func indicator(_ indicator: IndicatorView, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let asset = _source.asset(at: indexPath)
//        return .init(width: asset?.ub_pixelWidth ?? 0, height: asset?.ub_pixelHeight ?? 0)
//    }
//    
//    func indicator(_ indicator: IndicatorView, cellForItemAt indexPath: IndexPath) -> IndicatorViewCell {
//        logger.trace?.write(indexPath)
//        return indicator.dequeueReusableCell(withReuseIdentifier: "ASSET-IMAGE", for: indexPath)
//    }
//    
//    
//    func indicator(_ indicator: IndicatorView, willDisplay cell: IndicatorViewCell, forItemAt indexPath: IndexPath) {
//        logger.trace?.write(indexPath)
//        
//        guard let asset = _source.asset(at: indexPath) else {
//            return
//        }
//        
//        let size = CGSize(width: 20, height: 38).ub_fitWithScreen
//        let options = SourceOptions()
//        
//        if let imageView = cell.contentView as? UIImageView {
//            imageView.contentMode = .scaleAspectFill
//            //imageView.image = container.item(at: indexPath).image
//            
//            //imageView.ub_setImage(nil, animated: false)
//            imageView.image = nil
//            _container.ub_requestImage(for: asset, size: size, mode: .aspectFill, options: options) { image, info in
//                imageView.image = image
//                //imageView.ub_setImage(image, animated: true)
//            }
//        }
//        
//        // set default background color
//        cell.contentView.backgroundColor = .ub_init(hex: 0xf0f0f0)
//    }
//    
//    func indicatorWillBeginDragging(_ indicator: IndicatorView) {
//        logger.trace?.write()
//        
//        collectionView?.isScrollEnabled = false
//        interactiveDismissGestureRecognizer.isEnabled = false
//    }
//    func indicatorDidEndDragging(_ indicator: IndicatorView) {
//        logger.trace?.write()
//        
//        collectionView?.isScrollEnabled = true
//        interactiveDismissGestureRecognizer.isEnabled = true
//    }
//
//    func indicator(_ indicator: IndicatorView, didSelectItemAt indexPath: IndexPath) {
//        logger.trace?.write(indexPath)
//        
////        guard !isInteractiving else {
////            return // 正在交互
////        }
//        
//        // index path is changed
//        guard indexPath != _itemIndexPath else {
//            return
//        }
//        
//        _updateCurrentItem(at: indexPath)
//        
//        _performWithoutContentOffsetChange {
//            // prevent possible animations
//            UIView.performWithoutAnimation {
//                collectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
//            }
//        }
//    }
//}
