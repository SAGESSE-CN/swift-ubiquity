//
//  Caching+Library.swift
//  Ubiquity
//
//  Created by sagesse on 2018/5/18.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation

/// Provides methods for retrieving or generating preview thumbnails and full-size image or video data associated with Photos assets.
private class Cacher<T>: Caching<Library>, Library  {
    
    override init(_ ref: Library) {
        super.init(ref)
        self.logger.trace?.write()
    }
    deinit {
        self.logger.trace?.write()
    }

    // MARK: Authorization

    /// Requests the user’s permission, if needed, for accessing the library.
    func ub_requestAuthorization(_ handler: @escaping (Error?) -> Swift.Void) {
        return ref.ub_requestAuthorization(handler)
    }

    // MARK: Change

    /// Registers an object to receive messages when objects in the photo library change.
    func ub_addChangeObserver(_ observer: ChangeObserver) {
        return ref.ub_addChangeObserver(observer)
    }
    /// Unregisters an object so that it no longer receives change messages.
    func ub_removeChangeObserver(_ observer: ChangeObserver) {
        return ref.ub_removeChangeObserver(observer)
    }

    // MARK: Check

    /// Check asset exists
    func ub_exists(forItem asset: Asset) -> Bool {
        return ref.ub_exists(forItem: asset)
    }

    // MARK: Fetch

    ///
    /// Cancels an asynchronous request.
    ///
    /// When you perform an asynchronous request for image data using the [ub_request(forImage:targetSize:contentMode:options:resultHandler:)](file://) method, or for a video object using one of the methods listed in [Request](file://) object, the image manager returns a numeric identifier for the request. To cancel the request before it completes, provide this identifier when calling the [ub_cancel(with:)](file://) method.
    ///
    /// - Parameters:
    ///   - request: The asset asynchronous request.
    ///
    func ub_cancel(with request: Request) {
        //logger.trace?.write(request) // the cancel request very much
        
        // Only processing `RequestTask`
        guard let subtask = request as? RequestTask else {
            // If the request is other class, using origin
            ref.ub_cancel(with: request)
            return
        }
        
        // Quickly cancel the task, then in a suitable time to remove the task from the queue.
        subtask.cancel()
        
        // The main task of trying to delete .
        removeTask(for: subtask) { [ref] req in
            ref.ub_cancel(with: req)
        }
    }

    ///
    /// Requests an collection list for the specified type.
    ///
    /// - Parameter type: the specified collection list type.
    /// - Returns: The collection list for the specifed type.
    ///
    func ub_request(forCollectionList type: CollectionType) -> CollectionList {
        // The request is hit cache?
        if let collectionList = _collectionLists[type] {
            return collectionList
        }

        // Make a new collection list for origin.
        let collectionList = Caching.warp(ref.ub_request(forCollectionList: type))
        _collectionLists[type] = collectionList
        return collectionList
    }

    ///
    /// Requests an image representation for the specified asset.
    ///
    /// When you call this method, Photos loads or generates an image of the asset at, or near, the size you specify. Next, it calls your resultHandler block to provide the requested image. To serve your request more quickly, Photos may provide an image that is slightly larger than the target size—either because such an image is already cached or because it can be generated more efficiently. Depending on the options you specify and the current state of the asset, Photos may download asset data from the network.
    ///
    /// By default, this method executes asynchronously. If you call it from a background thread you may change the [isSynchronous](file://) property of the options parameter to true to block the calling thread until either the requested image is ready or an error occurs, at which time Photos calls your result handleo.
    ///
    /// For an asynchronous request, Photos may call your result handler block more than once. Photos first calls the block to provide a low-quality image suitable for displaying temporarily while it prepares a high-quality image. (If low-quality image data is immediately available, the first call may occur before the method returns.) When the high-quality image is ready, Photos calls your result handler again to provide it. If the image manager has already cached the requested image at full quality, Photos calls your result handler only once.
    ///
    /// - Parameters:
    ///   - asset: The asset whose image data is to be loaded.
    ///   - targetSize: The target size of image to be returned.
    ///   - contentMode: An option for how to fit the image to the aspect ratio of the requested size. For details, see [RequestContentMode](file://).
    ///   - options: Options specifying how Photos should handle the request, format the requested image, and notify your app of progress or errors. For details, see [RequestOptions](file://).
    ///   - resultHandler: A block to be called when image loading is complete, providing the requested image or information about the status of the request.
    ///
    ///     The block takes the following parameters:
    ///   - result: The requested image.
    ///   - response: A response object providing information about the status of the request. For details, see [Response](file://).
    /// - Returns:
    ///   A numeric identifier for the request. If you need to cancel the request before it completes, pass this request to the [ub_cancel(with:)](file://) method.
    ///
    func ub_request(forImage asset: Asset, targetSize: CGSize, contentMode: RequestContentMode, options: RequestOptions, resultHandler: @escaping (_ result: UIImage?, _ response: Response) -> ()) -> Request? {
        //logger.trace?.write(asset.ub_identifier, targetSize) // the request very much

        // Because the performance issue, make a temporary subtask
        let subtask = RequestTask(for: asset, size: targetSize, mode: contentMode, result: resultHandler)
        
        // Add subtask to main task.
        addTask(for: subtask, options: options) { [ref] task in
            // Forward send request
            ref.ub_request(forImage: Caching.unwarp(asset), targetSize: targetSize, contentMode: contentMode, options: options) { contents, response in
                // Cache the request result.
                task.cache(contents, response: response)
                
                // If the task has been canceled, processing next task.
                guard task.isRequesting else {
                    task.next()
                    return
                }
                
                // If has any of the following case, processing next task
                //   `ub_error` not equal nil, task an error occurred.
                //   `ub_downloading` is true, task required a download.
                //   `ub_cancelled` is true, task is canceled(system canceled).
                //   `ub_degraded` is false, task is completed.
                if response.ub_cancelled || response.ub_error != nil || response.ub_downloading || !response.ub_degraded {
                    task.next()
                }

                // Notify update contents on main thread.
                DispatchQueue.ub_asyncWithMain {
                    task.notify()
                }
            }
        }
        
        return subtask
    }

    ///
    /// Requests full-sized image data for the specified asset.
    ///
    /// When you call this method, Photos loads the largest available representation of the image asset, then calls your resultHandler block to provide the requested data. Depending on the options you specify and the current state of the asset, Photos may download asset data from the network.
    ///
    /// By default, this method executes asynchronously. If you call it from a background thread you may change the [isSynchronous](file://) property of the options parameter to true to block the calling thread until either the requested image is ready or an error occurs, at which time Photos calls your result handleo.
    ///
    /// If the version option is set to current, Photos provides rendered image data, including the results of any edits that have been made to the asset content. Otherwise, Photos provides the originally captured image data for the asset.
    ///
    /// - Parameters:
    ///   - asset: The asset for which to load image data.
    ///   - options: Options specifying how Photos should handle the request, format the requested image, and notify your app of progress or errors. For details, see [RequestOptions](file://).
    ///   - resultHandler: A block to be called when image loading is complete, providing the requested image or information about the status of the request.
    ///
    ///   The block takes the following parameters:
    ///   - imageData: The requested image.
    ///   - response: A response object providing information about the status of the request. For details, see [Response](file://).
    /// - Returns:
    ///   A numeric identifier for the request. If you need to cancel the request before it completes, pass this request to the [ub_cancel(with:)](file://) method.
    ///
    func ub_request(forData asset: Asset, options: RequestOptions, resultHandler: @escaping (_ imageData: Data?, _ response: Response) -> ()) -> Request? {
        return ref.ub_request(forData: Caching.unwarp(asset), options: options, resultHandler: resultHandler)
    }

    ///
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    ///
    /// When you call this method, Photos downloads the video data (if necessary) and creates a player item.
    /// It then calls your resultHandler block to provide the requested video.
    ///
    /// - Parameters:
    ///   - asset: The video asset to be played back.
    ///   - options: Options specifying how Photos should handle the request and notify your app of progress or errors. For details, see [RequestOptions](file://).
    ///   - resultHandler: A block Photos calls after loading the asset’s data and preparing the player item.
    ///
    ///     The block takes the following parameters:
    ///   - playerItem: An [AVPlayerItem](file://) object that you can use for playing back the video asset.
    ///   - response: A response object providing information about the status of the request. For details, see [Response](file://).
    /// - Returns:
    ///   A numeric identifier for the request. If you need to cancel the request before it completes, pass this request to the [ub_cancel(with:)](file://) method.
    ///
    func ub_request(forVideo asset: Asset, options: RequestOptions, resultHandler: @escaping (_ playerItem: AVPlayerItem?, _ response: Response) -> ()) -> Request? {
        return ref.ub_request(forVideo: Caching.unwarp(asset), options: options, resultHandler: resultHandler)
    }

    // MARK: Cacher

    ///A Boolean value that determines whether the image manager prepares high-quality images.
    var ub_allowsCachingHighQualityImages: Bool {
        set { return ref.ub_allowsCachingHighQualityImages = newValue }
        get { return ref.ub_allowsCachingHighQualityImages }
    }

    /// Prepares image representations of the specified assets for later use.
    func ub_startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // If no data is provided, ignore
        guard !assets.isEmpty else {
            return
        }
        //logger.trace?.write(assets)
        
        // make progressing format task
        let format = Format(size: size, mode: mode)
        let cache = caches[format] ?? {
            let cache = NSMutableDictionary()
            caches[format] = cache
            return cache
        }()
        
        // fetch require process tasks
        let subtasks = assets.compactMap { asset -> CacheTask? in
            
            //  in caching, ignore
            if let _ = cache[asset.ub_identifier] as? CacheTask {
                return nil
            }
            // create a cache task
            let subtask = CacheTask(for: asset, size: size, mode: mode)
            
            // prepare cache
            cache[asset.ub_identifier] = subtask
            subtask.prepare()
            
            // the task need start
            return subtask
        }
        
        // dispatch task
        dispatch.util.async {
            // the task needs to start
            self.caching.start(contentsOf: subtasks)
            
            // start cache thread
            self.startCachingIfNeeded()
        }
    }
    /// Cancels image preparation for the specified assets and options.
    func ub_stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        // If no data is provided, ignore
        guard !assets.isEmpty else {
            return
        }
        
        //logger.trace?.write(assets)
        
        // make progressing format task
        let format = Format(size: size, mode: mode)
        let cache = caches[format]
        
        // fetch require process tasks
        let subtasks = assets.compactMap { asset -> CacheTask? in
            
            //  no in caching, ignore
            guard let subtask = cache?[asset.ub_identifier] as? CacheTask else {
                return nil
            }
            
            // cancel cache
            cache?.removeObject(forKey: asset.ub_identifier)
            subtask.cancel()
            
            // the task need stop
            return subtask
        }
        
        // dispatch task
        dispatch.util.async {
            // the task needs to stop
            self.caching.stop(contentsOf: subtasks)
            
            // start cache thread
            self.startCachingIfNeeded()
        }
    }

    /// Cancels all image preparation that is currently in progress.
    func ub_stopCachingImagesForAllAssets() {
        //logger.trace?.write()
        
        // clear all task
        let subtasks: [CacheTask] = caches.values.flatMap { cache in
            return cache.allValues.flatMap {
                let subtask = ($0 as? CacheTask)
                subtask?.cancel()
                return subtask
            }
        }
        // clear all
        caches.removeAll()
        
        // dispatch task
        dispatch.util.async {
            // the task needs to start
            self.caching.stop(contentsOf: subtasks)
            
            // start cache thread
            self.startCachingIfNeeded()
        }
    }

    // MARK: Configure

    /// Predefined size of the original request
    var ub_requestMaximumSize: CGSize {
        return ref.ub_requestMaximumSize
    }
    
    //    /// Tells your observer that a set of changes has occurred in the Photos library.
    //    open func ub_library(_ library: Library, didChange change: Change) {
    //        // update all collection
    //        _ = Cacher.bridging(of: change)
    //        _collectionLists.forEach { type, collectionList in
    //            // the collection list has any change?
    //            guard let details = change.ub_changeDetails(forCollectionList: collectionList) else {
    //                return
    //            }
    //
    //            // update value
    //            _collectionLists[type] = details.after as? CollectionList
    //        }
    //    }
    
    // MARK: -
    
    func addTask(for subtask: RequestTask, options: RequestOptions? = nil, forwarder: @escaping (Task) -> Request?) {
        self.dispatch.util.async {
            // If the subtask has been cancelled, ignore it.
            guard !subtask.isCanceled else {
                return
            }
            
            // Find the main task and try to start it.
            self.ntask(for: subtask.asset, format: subtask.format).start(subtask) { task, prepare, complete in
                // The first step for the task processing authorization.
                self.dispatch.request.async {
                    // If the task has been canceled, ignore it.
                    guard task.isRequesting else {
                        return
                    }
                    
                    // Wait for queue idle.
                    if self.token.wait(timeout: .now() + .seconds(5)) != .timedOut {
                        prepare(self.token)
                    }
                    
                    // If the task has been canceled, processing next task.
                    guard task.isRequesting else {
                        task.next()
                        return
                    }

                    // Switch to main thread start request.
                    DispatchQueue.main.async {
                        // If the task has been canceled, processing next task.
                        guard task.isRequesting else {
                            task.next()
                            return
                        }

                        // If forward request is fail, processing next task.
                        guard let request = forwarder(task) else {
                            task.next()
                            return
                        }
                        
                        // Start main task successful.
                        complete(request)
                    }
                }
            }
        }
    }
    func removeTask(for subtask: RequestTask, forwarder: @escaping (Request) -> ()) {
        self.dispatch.util.async {
            // Forced cancel of subtask.
            subtask.cancel { task, request in
                // Clear memory for main task.
                self.rtask(for: subtask.asset, format: subtask.format, task: task)

                // The request is forwarded?
                guard let request = request else {
                    return // No
                }

                // Get task cached response
                if let (_, response) = task.contents {
                    // The task is completed?
                    if !response.ub_cancelled && !response.ub_downloading && !response.ub_degraded {
                        return // Don't send cancel request
                    }
                }

                // Forward cancel request in main thread.
                DispatchQueue.main.async {
                    forwarder(request)
                }
            }
        }
    }
    
    func rtask(for asset: Asset, format: Format, task: Task) {
        // If not has task list, ignore it.
        guard let tasks = tasks[format] else {
            return
        }
        
        // If not task or task is change, ignore it.
        guard let ctask = tasks[asset.ub_identifier] as? Task, ctask === task else {
            return
        }
        
        // Remove main task.
        tasks.removeObject(forKey: asset.ub_identifier)
    }
    
    func ntask(for asset: Asset, format: Format) -> Task {
        // Fetch to the main task if exists.
        if let task = tasks[format]?[asset.ub_identifier] as? Task, task.asset.ub_version == asset.ub_version {
            //logger.debug?.write("\(asset.ub_identifier) -> hit fast cache")
            return task
        }
        
        // If needed create a task list
        if tasks[format] == nil {
            tasks[format] = [:]
        }
        
        // Make a new main task.
        let task = Task(asset: asset, format: format)
        tasks[format]?[asset.ub_identifier] = task
        //logger.debug?.write("\(asset.ub_identifier) -> create a task, count: \(tasks[format]?.count ?? 0)")
        return task

    }
    
    func startCachingIfNeeded() {
        // if is started, ignore
        guard !_started else {
            return
        }
        _started = true
        
        // switch to cache queue
        dispatch.cache.async {
            while true {
                // sync to util queue
                let completed = self.dispatch.util.sync { () -> Bool in
                    // fetch require process tasks
                    self.caching.fetch(16) {
                        self.startCaching(with: $0, with: $1)
                    }
                    // all cache is complete?
                    return self.caching.isEmpty
                }
                
                // completed is true, all task is finished
                if completed {
                    break
                }
                
                // wait some time.
                Thread.sleep(forTimeInterval: 0.05)
            }
            // end
            self._started = false
        }
    }
    func startCaching(with start: [CacheTask]?, with stop: [CacheTask]?) {
        // must switch to main thread
        DispatchQueue.main.async { [ref] in
            // has stop task?
            if let subtask = stop?.first, let assets = stop?.map({ Caching.unwarp($0.asset) }) {
                // send to stop
                ref.ub_stopCachingImages(for: assets, size: subtask.size, mode: subtask.mode, options: nil)
                // reset stop flag
                stop?.forEach {
                    $0.stop()
                }
            }
            // has start task?
            if let subtask = start?.first, let assets = start?.map({ Caching.unwarp($0.asset) }) {
                // send to start
                ref.ub_startCachingImages(for: assets, size: subtask.size, mode: subtask.mode, options: nil)
                // reset stop flag
                start?.forEach {
                    $0.start()
                }
            }
        }
    }

    
    /// Must limit the number of threads.
    let token: DispatchSemaphore = .init(value: 2)
    let dispatch: (util: DispatchQueue, cache: DispatchQueue, request: DispatchQueue) = (
        .init(label: "ubiquity-dispatch-util", qos: .userInteractive),
        .init(label: "ubiquity-dispatch-cache", qos: .background),
        .init(label: "ubiquity-dispatch-request", qos: .userInitiated)
    )
    
    var resource: R = R.shared

    var tasks: [Format: NSMutableDictionary] = [:]
    var caches: [Format: NSMutableDictionary] = [:]
    
    var caching: TaskQueue = .init()

    // MARK: -
    
    fileprivate var _started: Bool = false
    
    fileprivate var _collectionLists: Dictionary<CollectionType, CollectionList> = [:]
}

/// Cacher request manager task format.
private class Format: Hashable, CustomStringConvertible {
    
    init(size: CGSize, mode: RequestContentMode) {
        _mode = mode.rawValue
        _width = Int(sqrt(max(size.width, 0)))
        _height = Int(sqrt(max(size.height, 0)))
        
        let size = (MemoryLayout.size(ofValue: _width) << 2) - 1
        let mask = ~(.max << size)
        
        let part1 = (_height & mask) << (2 + size)
        let part2 = (_width & mask) << (2)
        
        _hashValue = part1 | part2 | _mode
    }
    
    var hashValue: Int {
        return _hashValue
    }
    
    var description: String {
        return .init(format: "%zx(%zd, %zd)", _hashValue, _width * _width, _height * _height)
    }
    
    static func ==(lhs: Format, rhs: Format) -> Bool {
        // if the memory is the same, the results will be the same
        guard lhs !== rhs else {
            return true
        }
        // if the hash value is different, the results will be different
        guard lhs._hashValue == rhs._hashValue else {
            return false
        }
        // complute result
        return lhs._mode == rhs._mode
            && lhs._width == rhs._width
            && lhs._height == rhs._height
    }
    
    private var _mode: Int
    private var _width: Int
    private var _height: Int
    
    private var _hashValue: Int
}

/// Cacher request manager task.
private class Task: Request, Logport {

    let asset: Asset
    let format: Format

    /// Create a main task.
    init(asset: Asset, format: Format) {
        self.asset = asset
        self.format = format
    }
    
    func start(_ subtask: RequestTask, handler: (Task, (@escaping (DispatchSemaphore?) -> Void), (@escaping (Request?) -> Void )) -> Void) {
        // If there is a cache, use it
        if let (_, response) = contents {
            // Response contents on main thread.
            DispatchQueue.ub_asyncWithMain {
                // Get contents from cache.
                guard let (contents, response) = self.contents else {
                    return
                }
                subtask.notify(contents, response: response, version: self.version)
            }
            //logger.debug?.write("hit cache: \(asset.ub_identifier) - \(subtask.format)")
            
            // If the task has been completed, do not create a new subtask
            if !response.ub_cancelled && !response.ub_downloading && !response.ub_degraded {
                return
            }
        }
        
        // add to task queue
        subtasks.append(subtask)
        subtask.task = self
        
        // If the task is not start, start the task
        guard !isRequesting else {
            // No need start
            return
        }
        isRequesting = true

        // Start a main task.
        handler(self, { self.semaphore = $0 }, { self.request = $0 })
    }
    
    // the task sent request
    private(set) var request: Request?
    private(set) var semaphore: DispatchSemaphore?

    // the task status
    private(set) var version: Int = 1
    private(set) var isRequesting: Bool = false

    // the task cached response contents
    private(set) var contents: (UIImage?, Response)?

    // the task subtask
    private(set) var subtasks: Array<RequestTask> = []

    // generate a request options
    func options(with options: RequestOptions?) -> RequestOptions? {
        return options
    }

    // cancel this request task
    func cancel(with subtask: RequestTask, handler: (Task, Request?) -> Void) {
        // filter all cancelled items
        subtasks = subtasks.filter { !$0.isCanceled }

        // When the last request, cancel the task.
        guard subtasks.isEmpty else {
            return
        }

        // sent the request
        let sent = request

        // clear context
        request = nil
        isRequesting = false

        // exec cancel
        handler(self, sent)

        // move to next if needed
        next()
    }

    // Vache contents & response
    func cache(_ contents: UIImage?, response: Response) {
        // Update cached content
        self.version += 1
        self.contents = (contents, response)
        
        // If request is complete do some..
    }

    // Move to next task
    func next() {
        // move to next
        self.semaphore?.signal()
        self.semaphore = nil
    }

    // notify all subtask
    func notify() {
        // copy to local
        let subtasks = self.subtasks
        let result = self.contents

        // if content is empty, no need notify
        guard let (contents, response) = result else {
            return
        }
        // notify
        subtasks.forEach {
            $0.notify(contents, response: response, version: version)
        }
    }
}

/// Caching respond task.
private class RequestTask: Request, Logport {
    
    let asset: Asset
    let format: Format
    
    /// Create a request task.
    init(for asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions? = nil, result: ((UIImage?, Response) -> ())?) {
        self.asset = asset
        self.format = .init(size: size, mode: mode)
        
        self.version = 0
        self.result = result
    }

    weak var task: Task?
    var isCanceled: Bool = false
    
    var version: Int = 0
    var result: ((UIImage?, Response) -> ())?

    
    /// Quickly cancel the task.
    func cancel() {
        isCanceled = true
    }
    
    /// Slow cancel the task.
    func cancel(_ handler: (Task, Request?) -> Void) {
        // Send cancel request to main task.
        task?.cancel(with: self, handler: handler)
        task = nil
    }
    
    // Update contents
    func notify(_ contents: UIImage?, response: Response, version: Int) {
        // if the subtask has been cancelled, don't need to notify
        guard !isCanceled else {
            return
        }
        
        // the version is change
        guard version != self.version else {
            return
        }
        
        // notify
        self.version = version
        self.result?(contents, response)
    }
}

/// Caching cache task
private class CacheTask: Request, Logport {
    
    init(for asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions? = nil) {
        self.asset = asset
        self.size = size
        self.mode = mode
        self.format = .init(size: size, mode: mode)
    }

    let size: CGSize
    let mode: RequestContentMode

    let asset: Asset
    let format: Format

    private(set) var started: Bool = false
    private(set) var starting: Bool = false
    private(set) var stoping: Bool = false

    func prepare() {
        // will start
        starting = true
        stoping = false
    }
    func cancel() {
        // will stop
        stoping = true
        starting = false
    }

    func start() {
        // reset status
        starting = false
        stoping = false

        // task is started
        started = true
    }
    func stop() {
        // reset status
        starting = false
        stoping = false

        // task is started
        started = false
    }
}


private class TaskQueue {

    func start(contentsOf newElements: Array<CacheTask>) {
        _startContainer = (newElements.reversed() + _startContainer).filter {
            $0.starting && !$0.started
        }
    }
    func stop(contentsOf newElements: Array<CacheTask>) {
        _stopContainer = (newElements.reversed() + _stopContainer).filter {
            $0.stoping && $0.started
        }
    }

    func fetch(_ count: Int, _ body: ((start: Array<CacheTask>?, stop: Array<CacheTask>?)) -> Void) {

        let start = _fetchForStart(count, isVaild: {
            $0.starting && !$0.started
        })
        let stop = _fetchForStop(count, isVaild: {
            $0.stoping && $0.started
        })

        // is empty
        guard start?.count != 0 || stop?.count != 0 else {
            return
        }

        body((start, stop))
    }

    var isEmpty: Bool {
        return _startContainer.isEmpty && _stopContainer.isEmpty
    }

    private func _fetchForStart(_ count: Int, isVaild: (CacheTask) -> Bool) -> [CacheTask]? {
        // for the last value
        guard let last = _startContainer.last else {
            return nil
        }

        // init
        var index = _startContainer.count - 2
        var results = [_startContainer.removeLast()]

        // find more
        while results.count < count {

            // check boundary
            guard index >= 0 else {
                break
            }

            // is match
            guard _startContainer[index].format == last.format else {
                // no match, ignore
                index -= 1
                continue
            }

            // match, remove & move cursor
            let item = _startContainer.remove(at: index)
            index -= 1

            // the task is vaild?
            guard isVaild(item) else {
                //logger.debug?.write("\(task.asset.ub_identifier): no started")
                continue // task is invaild
            }
            results.append(item)
        }

        return results
    }
    private func _fetchForStop(_ count: Int, isVaild: (CacheTask) -> Bool) -> [CacheTask]? {
        // for the last value
        guard let last = _stopContainer.last else {
            return nil
        }

        // init
        var index = _stopContainer.count - 2
        var results = [_stopContainer.removeLast()]

        // find more
        while results.count < count {

            // check boundary
            guard index >= 0 else {
                break
            }

            // is match
            guard _stopContainer[index].format == last.format else {
                // no match, ignore
                index -= 1
                continue
            }

            // match, remove & move cursor
            let item = _stopContainer.remove(at: index)
            index -= 1

            // the task is vaild?
            guard isVaild(item) else {
                //logger.debug?.write("\(task.asset.ub_identifier): no started")
                continue // task is invaild
            }
            results.append(item)
        }

        return results
    }

    private lazy var _startContainer: Array<CacheTask> = []
    private lazy var _stopContainer: Array<CacheTask> = []
}

extension DispatchQueue {
    
    internal static func ub_syncWithMain(invoking body: @escaping () -> Void) {
        // if it is the main thread, and can be updated directly
        guard !Thread.current.isMainThread else {
            body()
            return
        }
        // wait to main thread
        DispatchQueue.main.sync {
            body()
        }
    }
    internal static func ub_asyncWithMain(invoking body: @escaping () -> Void) {
        // if it is the main thread, and can be updated directly
        guard !Thread.current.isMainThread else {
            body()
            return
        }
        // wait to main thread
        DispatchQueue.main.async {
            body()
        }
    }
}


extension Caching where T == Library {
    
    static func unwarp(_ value: Library) -> Library {
        if let value = value as? Cacher<Library> {
            return value.ref
        }
        return value
    }

    static func warp(_ value: Library) -> Library {
        if let value = value as? Cacher<Library> {
            return value
        }
        return Cacher<Library>(value)
    }
}

