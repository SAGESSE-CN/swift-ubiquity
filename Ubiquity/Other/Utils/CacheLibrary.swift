//
//  CacheLibrary.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/25/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation

internal class _Response: Response {
    
    var ub_error: Error? = nil
    
    var ub_degraded: Bool = false
    var ub_cancelled: Bool = false
    var ub_downloading: Bool = false
}


internal class CacheLibrary: NSObject, Library {
    
    // request task
    internal class Task: Request {
        
        private static var _id: Int = 0
        
        init() {
            self.id = Task._id
            Task._id += 1
        }
        
        var id: Int 
        
        var request: Request?
        var canceled: Bool = false

        func cancel() {
            canceled = true
        }
    }
    // request response cache
    internal class CacheTask {
        
        init(asset: Asset) {
            self.asset = asset
        }
        
        var asset: Asset
        
        var format: Int = 0
        var targetSize: CGSize = .zero
        var contentMode: RequestContentMode = .default
        
        var started: Bool = false
        var canceled: Bool = false
        
        var result: (UIImage?, Response)?
    }
    
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
        
        // only accept task object
        guard let task = request as? Task else {
            return
        }
        // logic cancel
        task.cancel()
        // send cancel request if needed
        guard let request = task.request else {
            return
        }
        task.request = nil
        // physics cancel
        _library.ub_cancelRequest(request)
    }
    
    /// If the asset's aspect ratio does not match that of the given targetSize, contentMode determines how the image will be resized.
    func ub_requestImage(for asset: Asset, targetSize: CGSize, contentMode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping RequestResultHandler<UIImage>) -> Request? {
        //logger.trace?.write(asset.ub_localIdentifier, targetSize) // the request very much 
        
        let task = Task()
        let format = _format(with: targetSize)
        
        // query from cache
        if let (contents, response) = _cachedContents(with: asset.ub_localIdentifier, format: format) {
            logger.debug?.write("\(asset.ub_localIdentifier), \(format) hit cache")
            // update content on main thread
            CacheLibrary.async {
                resultHandler(contents, response)
            }
            // `contents` is nil, the task need download
            // `ub_error` not is nil, the task an error
            // `ub_cancelled` is true, the task is canceled
            // `ub_degraded` is false, the task is completed
            if contents != nil && !response.ub_degraded {
                // is complete, don't send request
                logger.debug?.write("\(asset.ub_localIdentifier), \(format) hit cache, the request is completed")
                return nil
            }
        }
        
        // forward
        _requestQueue.async { [weak self, _library, _requestSemaphore] in
            // the task is cancel?
            guard !task.canceled else {
                return // yes, ignore
            }
            // get a task execute permissions
            let state = _requestSemaphore.wait(timeout: .now() + .seconds(3))
            // define clear method, notice he can only
            var _clearContext: (() -> Void)? = {
                _requestSemaphore.signal()
            }
            // wait to time over, don't use semaphore
            if state == .timedOut {
                _clearContext = nil
            }
            // the task is cancel?
            guard !task.canceled else {
                // clear the context
                _clearContext?()
                _clearContext = nil
                return
            }
            // send a request to library
            task.request = _library.ub_requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { contents, response in
                // save to cache
                self?._cacheContents(with: asset.ub_localIdentifier, format: format, contents: contents, response: response)
                // the task is cancel?
                guard !task.canceled else {
                    // clear the context
                    _clearContext?()
                    _clearContext = nil
                    return
                }
                // `contents` is nil, the task need download
                // `ub_error` not is nil, the task an error
                // `ub_cancelled` is true, the task is canceled
                // `ub_degraded` is false, the task is completed
                if contents == nil || response.ub_error != nil || response.ub_cancelled || !response.ub_degraded {
                    // clear the context
                    _clearContext?()
                    _clearContext = nil
                }
                // update content on main thread
                CacheLibrary.async {
                    // update content
                    resultHandler(contents, response)
                }
            }
        }
        
        return task
    }
    
    /// Playback only. The result handler is called on an arbitrary queue.
    func ub_requestPlayerItem(forVideo asset: Asset, options: RequestOptions?, resultHandler: @escaping RequestResultHandler<AVPlayerItem>) -> Request? {
        //logger.debug?.write(asset.ub_localIdentifier)
        
        // forward
        return _library.ub_requestPlayerItem(forVideo:asset, options:options, resultHandler:resultHandler)
    }
    
    /// Cancels all image preparation that is currently in progress.
    func ub_stopCachingImagesForAllAssets() {
        //logger.trace?.write()
        
        _stopCaching()
    }
    
    /// Prepares image representations of the specified assets for later use.
    func ub_startCachingImages(for assets: [Asset], targetSize: CGSize, contentMode: RequestContentMode, options: RequestOptions?) {
        //logger.trace?.write(assets)
        
        let format = _format(with: targetSize)
        
        // creaet cache list with format
        if _cacheMap[format] == nil {
            _cacheMap[format] = [:]
        }
        // make tasks
        let tasks = assets.reversed().flatMap { asset -> CacheTask? in
            // is cache?
            guard _cacheMap[format]?[asset.ub_localIdentifier] == nil else {
                return nil
            }
            // need create
            let task = CacheTask(asset: asset)
            
            // configure
            task.format = format
            task.targetSize = targetSize
            task.contentMode = contentMode
            
            // save the task
            _cacheMap[format]?[asset.ub_localIdentifier] = task
            
            // add task
            return task
        }
        
        // add to start queue
        _synchronized(token: _cacheQueue) {
            _cacheStartQueue.append(contentsOf: tasks)
        }
        _startCaching()
    }
    /// Cancels image preparation for the specified assets and options.
    func ub_stopCachingImages(for assets: [Asset], targetSize: CGSize, contentMode: RequestContentMode, options: RequestOptions?) {
        //logger.trace?.write(assets)
       
        let format = _format(with: targetSize)
        // make task
        let tasks = assets.flatMap { asset -> CacheTask? in
            // is cache?
            guard let task = _cacheMap[format]?.removeValue(forKey: asset.ub_localIdentifier) else {
                return nil
            }
            task.canceled = true
            // add
            return task
        }
        
        // add to stop queue
        _synchronized(token: _cacheQueue) {
            _cacheStopQueue.append(contentsOf: tasks)
        }
        _startCaching()
    }
    
    static func sync(execute work: @escaping () -> Void) {
        // if it is the main thread, and can be updated directly
        guard !Thread.current.isMainThread else {
            work()
            return
        }
        // wait to main thread
        DispatchQueue.main.sync {
            work()
        }
    }
    static func async(execute work: @escaping () -> Void) {
        // if it is the main thread, and can be updated directly
        guard !Thread.current.isMainThread else {
            work()
            return
        }
        // wait to main thread
        DispatchQueue.main.async {
            work()
        }
    }
    
    private func _startCaching() {
        
        _synchronized(token: _cacheQueue) {
            // is start?
            guard !_cacheIsRuning && !_cacheIsStarting else {
                return
            }
            _cacheIsRuning = false
            _cacheIsStarting = true
            // no start
            _cacheQueue.async {
                self._caching()
            }
        }
    }
    private func _stopCaching() {
        // stop
        _synchronized(token: _cacheQueue) {
            // clear
            let tasks = _cacheMap.flatMap {
                $1.flatMap {
                    $1
                }
            }
            _cacheStopQueue.append(contentsOf: tasks)
            _cacheStartQueue.removeAll()
            _cacheMap.removeAll()
        }
        // start
        _startCaching()
    }
    
    private func _caching() {
        logger.trace?.write("begin caching")
        
        _synchronized(token: _cacheQueue) {
            _cacheIsRuning = true
            _cacheIsStarting = false
        }
        
        while true {
            // get tasks
            let (t1, t2) = _synchronized(token: _cacheQueue) { () -> ([CacheTask]?, [CacheTask]?) in
                // is run?
                guard _cacheIsRuning else {
                    return (nil, nil)
                }
                // has any task?
                guard !_cacheStartQueue.isEmpty || !_cacheStopQueue.isEmpty else {
                    return (nil, nil)
                }
                // get task
                return (_fetchCacheStartTasks(4), _fetchCacheStopTasks(4) )
            }
            guard t1 != nil || t2 != nil else {
                break
            }
            // get start task
            if let task = t1?.first, let assets = t1?.map({ $0.asset }) {
                // send to start
                _library.ub_startCachingImages(for: assets, targetSize: task.targetSize, contentMode: task.contentMode, options: nil)
                // ==
                t1?.forEach({ task in
                    task.started = true
                })
            }
            // get stop task
            if let task = t2?.first, let assets = t2?.map({ $0.asset }) {
                // send to stop
                _library.ub_stopCachingImages(for: assets, targetSize: task.targetSize, contentMode: task.contentMode, options: nil)
                // ==
                t1?.forEach({ task in
                    task.started = false
                })
            }
            // wait?
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        _synchronized(token: _cacheQueue) {
            _cacheIsRuning = false
        }
        
        logger.trace?.write("end caching")
    }
    
    private func _fetchCacheStartTasks(_ max: Int) -> [CacheTask]? {
        
        guard let last = _cacheStartQueue.last else {
            return nil
        }
        var index = _cacheStartQueue.count - 2
        var tasks = [_cacheStartQueue.removeLast()]
        // find more
        while tasks.count < max {
            // check boundary
            guard index >= 0 else {
                break
            }
            // is match
            guard _cacheStartQueue[index].format == last.format else {
                index -= 1
                continue // no match
            }
            // remove & move curosr
            let task = _cacheStartQueue.remove(at: index)
            index -= 1
            // the task is cancel?
            guard !task.canceled && !task.started else {
                //logger.debug?.write("\(task.asset.ub_localIdentifier): is canceled")
                continue // task is invaild
            }
            tasks.append(task)
        }
        // return
        return tasks
    }
    private func _fetchCacheStopTasks(_ max: Int) -> [CacheTask]? {
        
        guard let last = _cacheStopQueue.last else {
            return nil
        }
        var index = _cacheStopQueue.count - 2
        var tasks = [_cacheStopQueue.removeLast()]
        // find more
        while tasks.count < max {
            // check boundary
            guard index >= 0 else {
                break
            }
            // is match
            guard _cacheStopQueue[index].format == last.format else {
                index -= 1
                continue // no match
            }
            // remove & move curosr
            let task = _cacheStopQueue.remove(at: index)
            index -= 1
            // the task is cancel?
            guard task.started else {
                //logger.debug?.write("\(task.asset.ub_localIdentifier): no started")
                continue // task is invaild
            }
            tasks.append(task)
        }
        // return
        return tasks
    }
    
    private func _cachedContents(with identifier: String, format: Int) -> (UIImage?, Response)? {
        return _synchronized(token: self) {
            return _cacheMap[format]?[identifier]?.result
        }
    }
    private func _cacheContents(with identifier: String, format: Int, contents: UIImage?, response: Response) {
        return _synchronized(token: self) {
            _cacheMap[format]?[identifier]?.result = (contents, response)
        }
    }
    
    private func _format(with size: CGSize) -> Int {
        return .init(log2(size.width * size.height) * 1000)
    }
    
    private let _library: Library
    
    private let _requestSemaphore: DispatchSemaphore = .init(value: 2) // must limit the number of threads
    private let _requestQueue: DispatchQueue = .init(label: "ubiquity-request-image", qos: .userInitiated)
    private let _cacheQueue: DispatchQueue = .init(label: "ubiquity-cache-image", qos: .utility)
    
    private var _cacheIsRuning: Bool = false
    private var _cacheIsStarting: Bool = false
    
    private lazy var _cacheMap: [Int:[String:CacheTask]] = [:]
    
    private lazy var _cacheStopQueue: [CacheTask] = []
    private lazy var _cacheStartQueue: [CacheTask] = []
}

internal extension Asset {
    // the size rating
    internal func ub_format(with size: CGSize, mode: RequestContentMode) -> Int {
        // scale level
        let scale: CGFloat
        
        switch mode {
        case .aspectFill: scale = max(size.width / .init(ub_pixelWidth), size.height / .init(ub_pixelHeight))
        case .aspectFit: scale = min(size.width / .init(ub_pixelWidth), size.height / .init(ub_pixelHeight))
        }
        
        return .init(scale * 1000)
    }
}

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


private func _synchronized<Result>(token: Any, invoking body: () throws -> Result) rethrows -> Result {
    objc_sync_enter(token)
    defer {
        objc_sync_exit(token)
    }
    return try body()
}

