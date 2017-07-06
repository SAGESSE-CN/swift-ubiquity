//
//  Browser.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// A media browser
open class Browser: NSObject, Container {
    
    /// Create a media browser
    public init(library: Library) {
        self.cache = .init(library: library)
        self.library = library
        super.init()
    }
    
    /// the current the library
    open var library: Library
    
    
    // MARK: Authorization
    
    
    /// Returns information about your app’s authorization for accessing the library.
    open func authorizationStatus() -> AuthorizationStatus {
        logger.trace?.write()
        
        return library.authorizationStatus()
    }
    
    /// Requests the user’s permission, if needed, for accessing the library.
    open func requestAuthorization(_ handler: @escaping (AuthorizationStatus) -> Swift.Void) {
        logger.trace?.write()
        
        return library.requestAuthorization(handler)
    }
    
    
    // MARK: Change
    
    
    /// Registers an object to receive messages when objects in the photo library change.
    open func register(_ observer: ChangeObserver) {
        logger.trace?.write(observer)
        
        return library.register(observer)
    }
    
    /// Unregisters an object so that it no longer receives change messages.
    open func unregisterObserver(_ observer: ChangeObserver) {
        logger.trace?.write(observer)
        
        return library.unregisterObserver(observer)
    }
    
    
    // MARK: Fetch
    
    
    ///A Boolean value that determines whether the image manager prepares high-quality images.
    open var allowsCachingHighQualityImages: Bool {
        set { return library.allowsCachingHighQualityImages = newValue }
        get { return library.allowsCachingHighQualityImages }
    }
    
    /// Get collections with type
    open func request(forCollection type: CollectionType) -> Array<Collection> {
        return library.request(forCollection: type)
    }
    
    /// Requests an image representation for the specified asset.
    open func request(forImage asset: Asset, size: CGSize, mode: RequestContentMode, options: RequestOptions?, resultHandler: @escaping (UIImage?, Response) -> ()) -> Request? {
        return cache.request(forImage: asset, size: size, mode: mode, options: options, resultHandler: resultHandler)
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    open func request(forItem asset: Asset, options: RequestOptions?, resultHandler: @escaping (AnyObject?, Response) -> ()) -> Request? {
        return library.request(forItem: asset, options: options, resultHandler: resultHandler)
    }
    
    /// Cancels an asynchronous request
    open func cancel(with request: Request) {
        return cache.cancel(with: request)
    }
    
    
    // MARK: Cache
    
    
    /// Prepares image representations of the specified assets for later use.
    open func startCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        return library.startCachingImages(for: assets, size: size, mode: mode, options: options)
    }
    
    /// Cancels image preparation for the specified assets and options.
    open func stopCachingImages(for assets: Array<Asset>, size: CGSize, mode: RequestContentMode, options: RequestOptions?) {
        return library.stopCachingImages(for: assets, size: size, mode: mode, options: options)
    }
    
    /// Cancels all image preparation that is currently in progress.
    open func stopCachingImagesForAllAssets() {
        return library.stopCachingImagesForAllAssets()
    }
    
    
    /// the current cache
    internal var cache: Cache 
}

//internal class BrowserItem {
//    
//    init(_ index: Int) {
//        
//        //let url = URL(string: "http://192.168.2.3/a.mp4")!
//        //let url = URL(string: "http://192.168.2.3/b.mp4")!
//        //let url = URL(string: "http://192.168.2.3/c.m4v")!
//        
//        //let url = URL(string: "http://192.168.0.101/a.mp4")!
//        //let url = URL(string: "http://192.168.0.101/b.mp4")!
//        
//        //let url = URL(string: "http://v4.music.126.net/20170515034222/b4396eb8d9d89d77190fe23b7b45ef2c/web/cloudmusic/Nzg5MzEyMTY=/b6f37d9ea0b4483212dece4f6ff4620d/a359f74e73667f6ff32fab9340277671.mp4")!
//        //let url = URL(string: "http://v4.music.126.net/20170515021110/337ebc2471c25ccb1192a770facac8f7/web/cloudmusic/JiYxMSEgIyAiJiAwMiQwMA==/mv/5373013/b8517d36ac9170989eb899b6a6da36e5.mp4")!
//        //let url = URL(string: "http://v4.music.126.net/20170515033630/c55e887cd510599c700624516e39caba/web/cloudmusic/ODE1MDgxMDg=/027190c853c462390e40008fa242362d/60a8d1ad5c0e03ff2d398d8df56782a1.mp4")!
//        
//        //let base = "http://192.168.2.3"
//        let base = "http://192.168.0.107"
//        
//        if (index == 0) {
//            size = .init(width: 1600, height: 1200)
//            image = __image1
//            return
//        }
//        if (index == 1) {
//            size = .init(width: 848, height: 480)
//            url = URL(string: base + "/a.mp4")!
////            type = .video
//            return
//        }
//        if (index == 2) {
//            size = .init(width: 1920, height: 1080)
//            url = URL(string: base + "/b.mp4")!
//            image = __image2
////            type = .video
//            return
//        }
//        if (index == 3) {
//            size = .init(width: 600, height: 338)
//            url = URL(string: base + "/c.m4v")!
//            image = __image3
////            type = .video
//            return
//        }
//        if (index == 4) {
//            size = .init(width: 400, height: 300)
//            image = AnimatedImage(named: "a.gif")
//            return
//        }
//        if (index == 5) {
//            size = .init(width: 600, height: 338)
//            image = AnimatedImage(named: "rock.gif")
//            return
//        }
//        
//        
//        size = .init(width: 640, height: 1136)
////        image = UIImage(named: "cl_\((__index % 12) + 1)")
////        __index += 1
//    }
//    
//    var size: CGSize
//    
//    var image: UIImage?
//    //var type: ItemType = .image
//    
//    var url: URL!
//}
fileprivate var __index = 0
internal var __image1 = UIImage(named: "t1")
internal var __image2 = UIImage(named: "t1_t")
internal var __image3 = UIImage(named: "t1_g")


//public class Ubiquity: BrowseDataSource, BrowseDelegate {
//    
//    public func numberOfSections(in browser: Any) -> Int {
//        return 1
//    }
//    public func browser(_ browser: Any, numberOfItemsInSection section: Int) -> Int {
//        return _assets.count
//    }
//    public func browser(_ browser: Any, assetForItemAt indexPath: IndexPath) -> Browseable {
//        return _assets[indexPath.item]
//    }
//    
//    lazy var _assets:[Browseable] = {
//        return (0 ..< 2800).map{ _ in
//            return LocalImageAsset()
//        }
//    }()
//    
//    static let displayQueue = DispatchQueue(label: "Ubiquity.Display.Queue")
//}
//
//public protocol BrowseDelegate: class {
//}
//
//public protocol BrowseDataSource: class {
//    
//    func numberOfSections(in browser: Any) -> Int 
//    
//    func browser(_ browser: Any, numberOfItemsInSection section: Int) -> Int
//    
//    func browser(_ browser: Any, assetForItemAt indexPath: IndexPath) -> Browseable 
//}

//let browser = Browser()
//
//browser.register(UIView.self, UIView.self)
//browser.dataSource = nil
//browser.delegate = nil
//
//browser.reloadData()
//browser.insertItems(at: [])
//browser.reloadItems(at: [])
//browser.deleteItems(at: [])
//
//browser.transitioningDelegate = nil
//UIViewController().show(browser, sender: indexPath)
