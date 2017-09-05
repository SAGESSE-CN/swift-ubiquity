//
//  Cacher.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation


internal class Cacher: NSObject {
    
    init(library: Library) {
        _library = library
        // super
        super.init()
    }
    
    /// Returns collections with collectoin type
    open func request(forCollectionList type: CollectionType) -> CollectionList {
        // the request is hit cache?
        if let collectionList = _collectionLists[type] {
            return collectionList // eys
        }
        
        // create collection list and cache
        let collectionList = _library.ub_request(forCollectionList: type)
        _collectionLists[type] = Cacher.bridging(of: collectionList)
        return collectionList
    }
    
    /// Requests an image representation for the specified asset.
    func request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
        //logger.trace?.write(asset.ub_identifier, size) // the request very much 
        
        // because the performance issue, make a temporary subtask
        let request = RequestTask(for: asset, size: size, mode: mode, result: resultHandler)
        let synchronous = options?.isSynchronous ?? false
        
        // add subtask to main task
        _dispatch.util.ub_map(synchronous) {
            self._addMainTask(with: request) { task in
                // forward send request
                self._library.ub_request(forImage: asset, size: size, mode: mode, options: options) { contents, response in
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
    
    /// Cancels an asynchronous request
    func cancel(with request: Request) {
        //logger.trace?.write(request) // the cancel request very much
        
        // can only processing `RequestTask`
        guard let subtask = request as? RequestTask else {
            // send cancel request
            _library.ub_cancel(with: request)
            return
        }
        
        // cancel the request
        subtask.cancel()
        
        // remove subtask from main task
        _dispatch.util.async {
            // if main task no any subtask, sent cancel request
            self._removeMainTask(with: subtask) { request in
                // send cancel request
                self._library.ub_cancel(with: request)
            }
        }
    }
    
    /// Prepares image representations of the specified assets for later use.
    func startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
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
    func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
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
    
    /// Cancels all image preparation that is currently in progress.
    func stopCachingImagesForAllAssets() {
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
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    open func library(_ library: Library, didChange change: Change) {
        // update all collection
        _ = Cacher.bridging(of: change)
        _collectionLists.forEach { type, collectionList in
            // the collection list has any change?
            guard let details = change.ub_changeDetails(forCollectionList: collectionList) else {
                return
            }
            
            // update value
            _collectionLists[type] = details.after as? CollectionList
        }
    }
    
    // MARK: Bridging
    
    @nonobjc static func bridging(of object: Asset) -> Asset {
        bridging(of: object, protocol: Asset.self, cacher: __CacherOfAsset.self)
        return object
    }
    
    @nonobjc static func bridging(of object: Collection) -> Collection {
        bridging(of: object, protocol: Collection.self, cacher: __CacherOfCollection.self)
        return object
    }
    
    @nonobjc static func bridging(of object: CollectionList) -> CollectionList {
        bridging(of: object, protocol: CollectionList.self, cacher: __CacherOfCollectionList.self)
        return object
    }
    
    @nonobjc static func bridging(of object: Change) -> Change {
        bridging(of: object, protocol: Change.self, cacher: __CacherOfChange.self)
        return object
    }
    
    /// The establishment and bridging between buffer
    @nonobjc static func bridging(of object: AnyObject, protocol: Protocol, cacher: AnyClass) {
        // generate bridge info
        let cls: AnyClass = type(of: object)
        let selector: Selector = Selector(String("__ub_cacher"))
        
        // the object is bridged?
        guard !object.responds(to: selector) else {
            return
        }
        
        // need to repeat filtering method
        var count: UInt32 = 0
        var methods: [Selector: objc_method_description] = [:]
        
        // gets the protocol require all the methods.
        if let descriptions = protocol_copyMethodDescriptionList(`protocol`, true, true, &count) {
            for index in 0 ..< Int(count) {
                let method = descriptions.advanced(by: index).move()
                methods[method.name] = method
            }
        }
        
        // gets the protocol optional all the methods.
        if let descriptions = protocol_copyMethodDescriptionList(`protocol`, false, true, &count) {
            for index in 0 ..< Int(count) {
                let method = descriptions.advanced(by: index).move()
                methods[method.name] = method
            }
        }
        
        // exchange all protocol method
        methods.forEach {
            // generate method info
            let caching = Selector("__" + NSStringFromSelector($0.key))
            let origin = $0.key
            
            // if cache is not supported, ignore
            guard let tmp = class_getInstanceMethod(cacher, caching) else {
                return
            }
            
            // copy caching method to object
            guard class_addMethod(cls, caching, method_getImplementation(tmp), $0.value.types) else {
                return
            }
            
            // get the caching method and the origin method
            let m1 = class_getInstanceMethod(cls, caching)
            let m2 = class_getInstanceMethod(cls, origin)
            
            // exchange method
            method_exchangeImplementations(m1, m2)
        }
        
        // copy ub_cacher to object
        guard let method = class_getInstanceMethod(cacher, selector) else {
            return
        }
        class_addMethod(cls, selector, method_getImplementation(method), method_getTypeEncoding(method))
    }
    
    
    /// internal using the library
    fileprivate let _library: Library
    
    /// must limit the number of threads
    fileprivate let _token: DispatchSemaphore = .init(value: 4)
    fileprivate let _dispatch: (util: DispatchQueue, cache: DispatchQueue, request: DispatchQueue) = (
        .init(label: "ubiquity-dispatch-util", qos: .userInteractive),
        .init(label: "ubiquity-dispatch-cache", qos: .background),
        .init(label: "ubiquity-dispatch-request", qos: .userInitiated)
    )
    
    fileprivate var _started: Bool = false
    
    fileprivate lazy var _tasks: Dictionary<Format, NSMutableDictionary> = [:]
    fileprivate lazy var _caches: Dictionary<Format, NSMutableDictionary> = [:]
    
    fileprivate lazy var _caching: Queue = .init()
    
    
    /// collection list cache
    fileprivate lazy var _collectionLists: Dictionary<CollectionType, CollectionList> = [:]
}

internal extension Cacher {
    
    fileprivate func _addMainTask(with subtask: RequestTask, execute work: @escaping (Task) -> Request?) {
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
    fileprivate func _removeMainTask(with subtask: RequestTask, execute work: @escaping (Request) -> Void) {
        // cancel image request
        subtask.cancel { task, request in
            // clear memory
            if let tasks = _tasks[subtask.format], (tasks[subtask.asset.ub_identifier] as? Task) === task {
                tasks.removeObject(forKey: subtask.asset.ub_identifier)
            }
            
            // need sent to cancel request?
            guard let request = request else {
                return
            }
            
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
    
    fileprivate func _startCachingIfNeeded() {
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
    fileprivate func _startCaching(with start: [CacheTask]?, with stop: [CacheTask]?) {
        // must switch to main thread
        DispatchQueue.main.async { [_library] in
            // has stop task?
            if let subtask = stop?.first, let assets = stop?.map({ $0.asset }) {
                // send to stop
                _library.ub_stopCachingImages(for: assets, size: subtask.size, mode: subtask.mode, options: nil)
                // reset stop flag
                stop?.forEach {
                    $0.stop()
                }
            }
            // has start task?
            if let subtask = start?.first, let assets = start?.map({ $0.asset }) {
                // send to start
                _library.ub_startCachingImages(for: assets, size: subtask.size, mode: subtask.mode, options: nil)
                // reset stop flag
                start?.forEach {
                    $0.start()
                }
            }
        }
    }
    
    fileprivate func _task(for asset: Asset, format: Format) -> Task {
        
        // fetch to the main task if exists
        if let task = _taskWithoutMake(for: asset, format: format), task.asset.ub_version == asset.ub_version {
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
    
    fileprivate func _taskWithoutMake(for asset: Asset, format: Format) -> Task? {
        // fetch to the main task if exists
        return _tasks[format]?[asset.ub_identifier] as? Task
    }
}

extension Cacher {
    
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
            if let (_, response) = contents {
                // update content on main thread
                DispatchQueue.ub_asyncWithMain {
                    // get contents
                    guard let (contents, response) = self.contents else {
                        return
                    }
                    subtask.notify(contents, response: response, version: self.version)
                }
                logger.debug?.write("hit cache: \(asset.ub_identifier) - \(subtask.format)")
                
                // if the task has been completed, do not create a new subtask
                if !response.ub_cancelled && !response.ub_downloading && !response.ub_degraded {
                    return
                }
            }
            
            // add to task queue
            requestTasks.append(subtask)
            subtask.task = self
            
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
            
            // filter all cancelled items
            requestTasks = requestTasks.filter { !$0.canceled }
            
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
        
        init(for asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions? = nil, result: ((UIImage?, Response) -> ())?) {
            self.asset = asset
            self.format = .init(size: size, mode: mode)
            
            self._result = result
        }
        
        let asset: Asset
        let format: Format
        
        weak var task: Task?
        
        var canceled: Bool = false
        
        func cancel() {
            canceled = true
        }
        
        func cancel(_ handler: (Task, Request?) -> Void) {
            // send cancel request
            task?.cancel(with: self, handler: handler)
            task = nil
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
        
        private var _result: ((UIImage?, Response) -> ())?
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
    
    internal class Format: Hashable, CustomStringConvertible {
        
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

extension DispatchQueue {
    
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

///  Adding cache support for asset
private class __CacherOfAsset: NSObject {
    
    /// A cacher used to provide fast cache
    dynamic var __ub_cacher: __CacherOfAsset {
        return __ub_property(self, selector: #selector(getter: self.__ub_cacher), newValue: __CacherOfAsset())
    }
    
    /// The localized title of the asset.
    dynamic var __ub_title: String? {
        return __ub_property(&__ub_cacher.__title, newValue: self.__ub_title)
    }
    
    /// The localized subtitle of the asset.
    dynamic var __ub_subtitle: String? {
        return __ub_property(&__ub_cacher.__subtitle, newValue: self.__ub_subtitle)
    }
    
    /// A unique string that persistently identifies the object.
    dynamic var __ub_identifier: String {
        return __ub_property(&__ub_cacher.__identifier, newValue: self.__ub_identifier)
    }
    
    /// The type of the asset, such as video or audio.
    dynamic var __ub_type: AssetType {
        return __ub_property(&__ub_cacher.__type, newValue: self.__ub_type)
    }
    
    /// The subtypes of the asset, an option of type `AssetSubtype`
    dynamic var __ub_subtype: UInt {
        return __ub_property(&__ub_cacher.__subtype, newValue: self.__ub_subtype)
    }
    
    private var __title: String??
    private var __subtitle: String??
    private var __identifier: String?
    
    private var __type: AssetType?
    private var __subtype: UInt?
}

///  Adding cache support for collection
private class __CacherOfCollection: NSObject {
    
    /// A cacher used to provide fast cache
    dynamic var __ub_cacher: __CacherOfCollection {
        return __ub_property(self, selector: #selector(getter: self.__ub_cacher), newValue: __CacherOfCollection())
    }
    
    /// The localized title of the collection.
    dynamic var __ub_title: String? {
        return __ub_property(&__ub_cacher.__title, newValue: self.__ub_title)
    }
    
    /// The localized subtitle of the collection.
    dynamic var __ub_subtitle: String? {
        return __ub_property(&__ub_cacher.__subtitle, newValue: self.__ub_subtitle)
    }
    
    /// A unique string that persistently identifies the object.
    dynamic var __ub_identifier: String {
        return __ub_property(&__ub_cacher.__identifier, newValue: self.__ub_identifier)
    }
    
    /// The number of assets in the asset collection.
    dynamic var __ub_count: Int {
        return __ub_property(&__ub_cacher.__count, newValue: self.__ub_count)
    }
    
    /// The number of assets in the asset collection.
    dynamic func __ub_count(with type: AssetType) -> Int {
        // count is cached?
        let cacher = __ub_cacher
        if let count = cacher.__counts[type] {
            return count
        }
        
        // get count for origin
        let count = __ub_count(with: type)
        cacher.__counts[type] = count
        return count
    }
    
    /// Retrieves assets from the specified asset collection.
    dynamic func __ub_asset(at index: Int) -> Asset {
        // collection is cached?
        let cacher = __ub_cacher
        if let asset = cacher.__assets?[index] {
            return asset
        }
        
        // if there is no cache at once, initialize
        if cacher.__assets == nil {
            cacher.__assets = Array(repeating: nil, count: self.__ub_count)
        }
        
        // fetch asset and bridging and cache
        let asset = __ub_asset(at: index)
        cacher.__assets?[index] = Cacher.bridging(of: asset)
        return asset
    }

    private var __title: String??
    private var __subtitle: String??
    private var __identifier: String?
    
    private var __count: Int?
    private var __counts: [AssetType: Int] = [:]
    
    private var __assets: [Asset?]?
}

///  Adding cache support for collection list
private class __CacherOfCollectionList: NSObject {
    
    /// A cacher used to provide fast cache
    dynamic var __ub_cacher: __CacherOfCollectionList {
        return __ub_property(self, selector: #selector(getter: self.__ub_cacher), newValue: __CacherOfCollectionList())
    }
    
    /// The number of collection in the collection list.
    dynamic var __ub_count: Int {
        return self.__ub_count
    }
    
    /// Retrieves collection from the specified collection list.
    dynamic func __ub_collection(at index: Int) -> Collection {
        // collection is cached?
        let cacher = __ub_cacher
        if let collection = cacher.__colltions?[index] {
            return collection
        }
        
        // if there is no cache at once, initialize
        if cacher.__colltions == nil {
            cacher.__colltions = Array(repeating: nil, count: self.__ub_count)
        }
        
        // fetch collection and bridging and cache
        let collection = __ub_collection(at: index)
        cacher.__colltions?[index] = Cacher.bridging(of: collection)
        return collection
    }
    
    private var __colltions: [Collection?]?
}

///  Adding cache support for asset
private class __CacherOfChange: NSObject {
    
    /// A cacher used to provide fast cache
    dynamic var __ub_cacher: __CacherOfChange {
        return __ub_property(self, selector: #selector(getter: self.__ub_cacher), newValue: __CacherOfChange())
    }
    
    /// Returns detailed change information for the specified collection.
    dynamic func __ub_changeDetails(forCollection collection: Collection) -> ChangeDetails? {
        // hit collection cache?
        let cacher = __ub_cacher
        if let details = cacher.__collectionCaches[collection.ub_identifier] {
            return details
        }
        
        // make change details and cache
        let details = __ub_changeDetails(forCollection: collection)
        cacher.__collectionCaches[collection.ub_identifier] = details
        return details
    }
    
    /// Returns detailed change information for the specified colleciotn list.
    dynamic func __ub_changeDetails(forCollectionList collectionList: CollectionList) -> ChangeDetails? {
        // hit collection cache?
        let cacher = __ub_cacher
        if let details = cacher.__collectionListCaches[collectionList.ub_collectionType] {
            return details
        }
        
        // make change details and cache
        let details = __ub_changeDetails(forCollectionList: collectionList)
        cacher.__collectionListCaches[collectionList.ub_collectionType] = details
        return details
    }
    
    /// Cached change details
    private var __collectionCaches: Dictionary<String, ChangeDetails?> = [:]
    private var __collectionListCaches: Dictionary<CollectionType, ChangeDetails?> = [:]
}

/// Access variables, if not exists automatic create
private func __ub_property<T>(_ ivar: inout T?, newValue: @autoclosure () throws -> T) rethrows -> T {
    // the object is hit cache?
    if let object = ivar {
        return object
    }
    // generate an new object
    let object = try newValue()
    ivar = object
    return object
}

/// Access variables for ivar, if not exists automatic create 
private func __ub_property<T>(_ self: Any!, selector: Selector, newValue: @autoclosure () throws -> T) rethrows -> T {
    // the object is hit cache?
    if let object = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: selector.hashValue)) as? T {
        return object
    }
    // generate an new object
    let object = try newValue()
    objc_setAssociatedObject(self, UnsafeRawPointer(bitPattern: selector.hashValue), object, .OBJC_ASSOCIATION_RETAIN)
    return object
}

