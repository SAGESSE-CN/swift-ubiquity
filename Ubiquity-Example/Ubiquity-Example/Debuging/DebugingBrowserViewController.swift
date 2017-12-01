//
//  DebugingBrowserViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 01/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

import Ubiquity

class DebugingBrowserAsset: Ubiquity.UHLocalAsset {
}

class DebugingBrowserCollection: Ubiquity.UHLocalAssetCollection {
    
    init(index: Int, cmds: [String] = []) {
        _cmds = cmds
        _index = index
        super.init(identifier: "\(index)")
        title = "Collection<\(index)>"
    }
    
    override var count: Int {
        return _index
    }
    
    /// Retrieves assets from the specified asset collection.
    override func asset(at index: Int) -> Ubiquity.UHLocalAsset {
        return DebugingBrowserAsset(identifier: "Asset<\(index)>")
    }
    
    private var _index: Int
    private var _cmds: [String]
}
class DebugingBrowserCollectionList: Ubiquity.UHLocalAssetCollectionList {
    
    init(collectionType: Ubiquity.CollectionType, cmds: [String] = []) {
        _cmds = cmds
        super.init(collectionType: collectionType)
    }
    
    /// The number of collection in the collection list.
    override var count: Int {
        if _cmds.contains("cl-empty") {
            return 0
        }
        return 8
    }
    /// Retrieves collection from the specified collection list.
    override func collection(at index: Int) -> Ubiquity.UHLocalAssetCollection {
        return DebugingBrowserCollection(index: index, cmds: _cmds)
    }
    
    private var _cmds: [String]
}

class DebugingBrowserLibrary: Ubiquity.UHLocalAssetLibrary {
    
    init(cmds: [String] = []) {
        _cmds = cmds
        super.init()
    }
    
    /// Check asset exists
    override func exists(forItem asset: Ubiquity.UHLocalAsset) -> Bool {
        return false
    }
    
    /// Get collections with type
    override func request(forCollection type: Ubiquity.CollectionType) -> Ubiquity.UHLocalAssetCollectionList {
        return DebugingBrowserCollectionList(collectionType: type, cmds: _cmds)
    }
    
    /// Requests an image representation for the specified asset.
    override func request(forImage asset: Ubiquity.UHLocalAsset, size: CGSize, mode: Ubiquity.RequestContentMode, options: Ubiquity.RequestOptions?, resultHandler: @escaping (UIImage?, UHLocalAssetResponse) -> ()) -> UHLocalAssetRequest? {
        let response = UHLocalAssetResponse()
        let image = #imageLiteral(resourceName: "t1_t")
        response.isCancelled = false
        response.isDegraded = false
        response.isDownloading = false
        response.error = nil
        resultHandler(image, response)
        return nil
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    override func request(forItem asset: Ubiquity.UHLocalAsset, options: Ubiquity.RequestOptions?, resultHandler: @escaping (AnyObject?, Ubiquity.UHLocalAssetResponse) -> ()) -> Ubiquity.UHLocalAssetRequest? {
        return nil
    }
    
    /// Cancels an asynchronous request
    override func cancel(with request: Ubiquity.UHLocalAssetRequest) {
    }
    
    /// Requests the user’s permission, if needed, for accessing the library.
    override func ub_requestAuthorization(_ handler: @escaping (Error?) -> Void) {
        if _cmds.contains("cl-error") {
            handler(Exception.denied)
        } else {
            handler(nil)
        }
    }
    
    private var _cmds: [String]
}

class DebugingBrowserViewController: UITableViewController {
    
    override func debugger(_ server: Shared, remote: Shared, didRecive data: Any?) {
        guard let cmd = data as? String else {
            return
        }
        logger.debug?.write(cmd)
        
        
//        if cmd.hasPrefix("jump:") {
//            jump(cmd.substring(from: cmd.startIndex + 5))
//            return
//        }
       
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let title = tableView.cellForRow(at: indexPath)?.textLabel?.text else {
            return
        }
        jump(title)
    }
    
    func jump(_ str: String) {
        
        switch str {
        case "Album List(Empty)":
            let library = DebugingBrowserLibrary(cmds: ["cl-empty"])
            let container = Ubiquity.Browser(library: library)
            let controller = container.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.regular]))
            show(controller, sender: nil)
            
        case "Album List(Error)":
            let library = DebugingBrowserLibrary(cmds: ["cl-error"])
            let container = Ubiquity.Browser(library: library)
            let controller = container.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.regular]))
            show(controller, sender: nil)

        case "Album List":
            let library = DebugingBrowserLibrary()
            let container = Ubiquity.Browser(library: library)
            let controller = container.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.regular]))
            show(controller, sender: nil)
            
        case "Album Lists":
            let library = DebugingBrowserLibrary()
            let container = Ubiquity.Browser(library: library)
            let controller = container.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.moment, .regular, .recentlyAdded]))
            show(controller, sender: nil)


        default:
            print(str)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
