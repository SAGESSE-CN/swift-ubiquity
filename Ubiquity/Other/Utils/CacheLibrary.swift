//
//  CacheLibrary.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/25/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation


internal class CacheLibrary: NSObject, Library {
    
    init(library: Library) {
        _library = library
        // super
        super.init()
    }
    
    /// Returns information about your app’s authorization for accessing the library.
    var ub_authorizationStatus: AuthorizationStatus {
        logger.trace?.write()
        
        // forward
        return _library.ub_authorizationStatus
    }
    
    /// Requests the user’s permission, if needed, for accessing the library.
    func ub_requestAuthorization(_ handler: @escaping (AuthorizationStatus) -> Void) {
        logger.trace?.write()
        
        // forward
        return _library.ub_requestAuthorization(handler)
    }
    
    /// Get collections with type
    func ub_collections(with type: CollectionType) -> Array<Collection> {
        logger.trace?.write(type)
        
        // forward
        return _library.ub_collections(with: type)
    }
    
    /// Cancels an asynchronous request
    func ub_cancelRequest(_ request: Request) {
        //logger.trace?.write(request) // the cancel request very much 
        
        // can only processing `RequestTask`
        guard let subtask = request as? RequestTask else {
            // send cancel request
            _library.ub_cancelRequest(request)
            return
        }
        
        // cancel the request
        subtask.cancel()
        
        // remove subtask from main task
        _dispatch.util.async {
            // if main task no any subtask, sent cancel request
            self._removeMainTask(with: subtask) { request in
                // send cancel request
                self._library.ub_cancelRequest(request)
            }
        }
    }
    
    /// If the asset's aspect ratio does not match that of the given size, mode determines how the image will be resized.
    func ub_requestImage(for asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping RequestResultHandler<UIImage>) -> Request? {
        //logger.trace?.write(asset.ub_identifier, size) // the request very much 
        
        // because the performance issue, make a temporary subtask
        let request = RequestTask(for: asset, size: size, mode: mode, result: resultHandler)
        let synchronous = (options as? DataSourceOptions)?.isSynchronous ?? false
        
        // add subtask to main task
        _dispatch.util.ub_map(synchronous) {
            self._addMainTask(with: request) { task in
                // forward send request
                self._library.ub_requestImage(for: asset, size: size, mode: mode, options: options) { contents, response in
                    // cache the result
                    task.cache(contents, response: response)
                    
                    // if the task has is canceled, processing next task
                    guard task.requesting else {
                        task.next()
                        return
                    }
                    
                    // if has any of the following case, processing next task
                    //   `ub_error` not equal nil, task an error occurred
                    //   `ub_downloading` is true, task required a download
                    //   `ub_cancelled` is true, task is canceled(system canceled)
                    //   `ub_degraded` is false, task is completed
                    if response.ub_cancelled || response.ub_error != nil || response.ub_downloading || !response.ub_degraded {
                        task.next()
                    }
                    
                    // notify update content on main thread
                    DispatchQueue.ub_asyncWithMain {
                        task.notify()
                    }
                }
            }
        }
        
        return request
    }
    
    /// Playback only. The result handler is called on an arbitrary queue.
    func ub_requestPlayerItem(forVideo asset: Asset, options: RequestOptions?, resultHandler: @escaping RequestResultHandler<AVPlayerItem>) -> Request? {
        //logger.debug?.write(asset.ub_identifier)
        
        // forward
        return _library.ub_requestPlayerItem(forVideo:asset, options:options, resultHandler:resultHandler)
    }
    
    /// Cancels all image preparation that is currently in progress.
    func ub_stopCachingImagesForAllAssets() {
        //logger.trace?.write()

        
        // clear all task
        let subtasks: [CacheTask] = _caches.values.flatMap { cache in
            return cache.allValues.flatMap {
                let subtask = ($0 as? CacheTask)
                subtask?.cancel()
                return subtask
            }
        }
        // clear all
        _caches.removeAll()
        
        // dispatch task
        _dispatch.util.async {
            // the task needs to start
            self._caching.stop(contentsOf: subtasks)
            
            // start cache thread
            self._startCachingIfNeeded()
        }
    }
    
    /// Prepares image representations of the specified assets for later use.
    func ub_startCachingImages(for assets: [Asset], size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        //logger.trace?.write(assets)
        
        // make progressing format task
        let format = Format(size: size, mode: mode)
        let cache = _caches[format] ?? {
            let cache = NSMutableDictionary()
            _caches[format] = cache
            return cache
        }()
        
        // fetch require process tasks
        let subtasks = assets.flatMap { asset -> CacheTask? in
            
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
        _dispatch.util.async {
            // the task needs to start
            self._caching.start(contentsOf: subtasks)
            
            // start cache thread
            self._startCachingIfNeeded()
        }
    }
    /// Cancels image preparation for the specified assets and options.
    func ub_stopCachingImages(for assets: [Asset], size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        //logger.trace?.write(assets)
        
        // make progressing format task
        let format = Format(size: size, mode: mode)
        let cache = _caches[format]
        
        // fetch require process tasks
        let subtasks = assets.flatMap { asset -> CacheTask? in
            
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
        _dispatch.util.async {
            // the task needs to stop
            self._caching.stop(contentsOf: subtasks)
            
            // start cache thread
            self._startCachingIfNeeded()
        }
    }
    
    
    private func _addMainTask(with subtask: RequestTask, execute work: @escaping (Task) -> Request?) {
        // the subtask is canceled?
        guard !subtask.canceled else {
            return
        }
        
        // add subtask to main task
        _task(for: subtask.asset, format: subtask.format).request(for: subtask) { [_dispatch, _token] task, prepare, complete in
            // add to start queue
            _dispatch.request.async {
                // if the task has been canceled, ignore 
                guard task.requesting else {
                    return
                }
                
                // wait for idle
                let status = _token.wait(timeout: .now() + .seconds(5))
                
                // prepare to task
                prepare([_token].filter({ _ in status != .timedOut }).first)
                
                // if the task has been canceled, ignore
                guard task.requesting else {
                    // move to next task
                    task.next()
                    return
                }
                
                // switch to main thread
                DispatchQueue.main.async {
                    // if the task has been canceled, ignore
                    guard task.requesting else {
                        // move to next task
                        task.next()
                        return
                    }
                    
                    // start request successful?
                    guard let request = work(task) else {
                        // move to next task
                        task.next()
                        return
                    }
                    
                    // start request complete
                    complete(request)
                }
            }
        }
    }
    private func _removeMainTask(with subtask: RequestTask, execute work: @escaping (Request) -> Void) {
        // cancel image request
        _taskWithoutMake(for: subtask.asset, format: subtask.format)?.cancel(with: subtask) { task, request in
            // really need to cancel?
            guard let request = request else {
                return
            }
            
            // clear memory
            _tasks[subtask.format]?.removeObject(forKey: subtask.asset.ub_identifier)
            
            // get task cached response
            if let (_, response) = task.contents {
                // the task is completed?
                if !response.ub_cancelled && !response.ub_downloading && !response.ub_degraded {
                    return // don't send cancel request
                }
            }
            
            // send cancel request in main thread
            DispatchQueue.main.async {
                work(request)
            }
        }
    }
    
    private func _startCachingIfNeeded() {
        // if is started, ignore
        guard !_started else {
            return
        }
        _started = true
        
        // switch to cache queue
        _dispatch.cache.async {
            while true {
                // sync to util queue
                let completed = self._dispatch.util.sync { () -> Bool in
                    // fetch require process tasks
                    self._caching.fetch(8) {
                        self._startCaching(with: $0, with: $1)
                    }
                    // all cache is complete?
                    return self._caching.isEmpty
                }
                
                // completed is true, all task is finished
                if completed {
                    break
                }
                
                // wait some time.
                Thread.sleep(forTimeInterval: 0.01)
            }
            // end
            self._started = false
        }
    }
    private func _startCaching(with start: [CacheTask]?, with stop: [CacheTask]?) {
        // must switch to main thread
        DispatchQueue.main.async {
            // has stop task?
            if let subtask = stop?.first, let assets = stop?.map({ $0.asset }) {
                // send to stop
                self._library.ub_stopCachingImages(for: assets, size: subtask.size, mode: subtask.mode, options: nil)
                // reset stop flag
                stop?.forEach {
                    $0.stop()
                }
            }
            // has start task?
            if let subtask = start?.first, let assets = start?.map({ $0.asset }) {
                // send to start
                self._library.ub_startCachingImages(for: assets, size: subtask.size, mode: subtask.mode, options: nil)
                // reset stop flag
                start?.forEach {
                    $0.start()
                }
            }
        }
    }
    
    private func _taskWithoutMake(for asset: Asset, format: Format) -> Task? {
        // fetch to the main task if exists
        return _tasks[format]?[asset.ub_identifier] as? Task
    }
    private func _task(for asset: Asset, format: Format) -> Task {
        
        // fetch to the main task if exists
        if let task = _taskWithoutMake(for: asset, format: format) {
            //logger.debug?.write("\(asset.ub_identifier) -> hit fast cache")
            return task
        }
        
        // if needed create a task list
        if _tasks[format] == nil {
            _tasks[format] = [:]
        }
        
        // make a main task
        let task = Task(asset: asset, format: format)
        _tasks[format]?[asset.ub_identifier] = task
        //logger.debug?.write("\(asset.ub_identifier) -> create a task, count: \(_tasks[format]?.count ?? 0)")
        return task
    }
    
    private let _library: Library
    
    // must limit the number of threads
    private let _token: DispatchSemaphore = .init(value: 4)
    private let _dispatch: (util: DispatchQueue, cache: DispatchQueue, request: DispatchQueue) = (
        .init(label: "ubiquity-dispatch-util", qos: .userInteractive),
        .init(label: "ubiquity-dispatch-cache", qos: .background),
        .init(label: "ubiquity-dispatch-request", qos: .userInitiated)
    )
    
    private var _started: Bool = false
    
    private lazy var _tasks: Dictionary<Format, NSMutableDictionary> = [:]
    private lazy var _caches: Dictionary<Format, NSMutableDictionary> = [:]
    
    private lazy var _caching: Queue = .init()
}

// cache util
internal extension Library {
    /// generate support cache the library
    internal var ub_cache: Library {
        // if already support, to return
        if let library  = self as? CacheLibrary {
            return library
        }
        // add a cache layer
        return CacheLibrary(library: self)
    }
}

// util
internal extension CacheLibrary {
    
    // request task
    internal class Task: Request, Logport {
        
        /// init
        init(asset: Asset, format: Format) {
            self.asset = asset
            self.format = format
        }
        
        // the task with asset & request format
        let asset: Asset
        let format: Format
        
        // the task sent request
        private(set) var request: Request?
        private(set) var semaphore: DispatchSemaphore?
        
        // the task status
        private(set) var version: Int = 1
        private(set) var requesting: Bool = false
        
        // the task cached response contents
        private(set) var contents: (UIImage?, Response)?
        
        // the task subtask
        private(set) var requestTasks: Array<RequestTask> = []
        
        // generate a request options
        func options(with options: RequestOptions?) -> RequestOptions? {
            return options
        }
        
        func request(for subtask: RequestTask, transform: (Task, (@escaping (DispatchSemaphore?) -> Void), (@escaping (Request?) -> Void )) -> Void) {
            // if there is a cache, use it
            if let (contents, response) = contents {
                // update content on main thread
                DispatchQueue.ub_asyncWithMain {
                    // get contents
                    guard let (contents, response) = self.contents else {
                        return
                    }
                    subtask.notify(contents, response: response, version: self.version)
                }
                
                // if the task has been completed, do not create a new subtask
                if !response.ub_cancelled && !response.ub_downloading && !response.ub_degraded {
                    logger.debug?.write("\(asset.ub_identifier) - response[completed] hit cache")
                    return
                }
                logger.debug?.write("\(asset.ub_identifier) - response hit cache")
            }
            
            // add to task queue
            requestTasks.append(subtask)
            
            // if the task is not start, start the task
            guard !requesting else {
                // no need start
                return
            }
            // set flag
            requesting = true
            
            // start request
            transform(self, { self.semaphore = $0 }, { self.request = $0 })
        }
        
        // cancel this request task
        func cancel(with subtask: RequestTask, handler: (Task, Request?) -> Void) {
            // if the index is not found, the subtask has been cancelled
            guard let index = requestTasks.index(where: { $0 === subtask }) else {
                return
            }
            // context
            requestTasks.remove(at: index)
            
            // when the last request, cancel the task
            guard requestTasks.isEmpty else {
                return
            }
            
            // sent the request
            let sent = request
            
            // clear context
            request = nil
            requesting = false
            
            // exec cancel
            handler(self, sent)
            
            // move to next if needed
            next()
        }
        
        // cache contents & response
        func cache(_ contents: UIImage?, response: Response) {
            // update cached content
            self.version += 1
            self.contents = (contents, response)
//            
//            // receives notice has been cancelled or complete notification
//            if response.ub_cancelled || response.ub_error != nil || !response.ub_degraded {
//                request = nil
//            }
        }
        
        // move to next task
        func next() {
            // move to next
            semaphore?.signal()
            semaphore = nil
        }
        
        // notify all subtask
        func notify() {
            // copy to local
            let requestTasks = self.requestTasks
            let result = self.contents
            
            // if content is empty, no need notify
            guard let (contents, response) = result else {
                return
            }
            // notify
            requestTasks.forEach { subtask in
                subtask.notify(contents, response: response, version: version)
            }
        }
    }
    internal class RequestTask: Request {
        
        init(for asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions? = nil, result: RequestResultHandler<UIImage>?) {
            self.asset = asset
            self.format = .init(size: size, mode: mode)
            
            self._result = result
        }
        
        let asset: Asset
        let format: Format
        
        var canceled: Bool = false
        
        func cancel() {
            canceled = true
        }
        
        // update content
        func notify(_ contents: UIImage?, response: Response, version: Int) {
            // if the subtask has been cancelled, don't need to notify
            guard !canceled else {
                return
            }
            
            // the version is change
            guard _version != version else {
                return
            }
            
            // notify
            _version = version
            _result?(contents, response)
        }
        
        //private var _progress: RequestProgressHandler?
        private var _result: RequestResultHandler<UIImage>?
        private var _version: Int = 0
    }
    internal class CacheTask: Request {
        
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
    
    internal class Format: Hashable {
        
        static func ==(lhs: CacheLibrary.Format, rhs: CacheLibrary.Format) -> Bool {
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
        
        init(size: CGSize, mode: RequestContentMode) {
            _mode = mode.rawValue
            _width = Int(sqrt(size.width))
            _height = Int(sqrt(size.height))
            
            let size = (MemoryLayout.size(ofValue: _width) << 2) - 1
            let mask = ~(.max << size)
            
            let part1 = (_height & mask) << (2 + size)
            let part2 = (_width & mask) << (2)
            
            _hashValue = part1 | part2 | _mode
        }
        
        var hashValue: Int {
            return _hashValue
        }
        
        private var _mode: Int
        private var _width: Int
        private var _height: Int
        
        private var _hashValue: Int
    }
    internal class Queue {
        
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
    
    
}

internal extension DispatchQueue {
    
    internal func ub_map(_ synchronous: Bool, invoking body: @escaping () -> Void) {
        if synchronous {
            // this is a synchronous request
            sync(execute: body)
            
        } else {
            // this is a asynchronous request
            async(execute: body)
        }
    }
    
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
