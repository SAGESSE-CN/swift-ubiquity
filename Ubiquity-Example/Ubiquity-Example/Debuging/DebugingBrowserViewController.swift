//
//  DebugingBrowserViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 01/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import Ubiquity
import AVFoundation

class DebugingBrowserAsset: Ubiquity.UHLocalAsset {
    override init(identifier: String) {
        super.init(identifier: identifier)
        
        self.pixelWidth = 1600
        self.pixelHeight = 1200
        self.title = identifier
        self.subtitle = "1600x1200"
    }
}

class DebugingBrowserCollection: Ubiquity.UHLocalAssetCollection {
    
    init(index: Int, cmds: [String] = []) {
        _cmds = cmds
        _index = index
        super.init(identifier: "\(index)")
        title = "Collection<\(index)>"
        
        collectionSubtype = [
            .smartAlbumGeneric,
            .smartAlbumPanoramas,
            .smartAlbumVideos,
            .smartAlbumFavorites,
            .smartAlbumTimelapses,
            .smartAlbumAllHidden,
            .smartAlbumRecentlyAdded,
            .smartAlbumBursts,
            .smartAlbumSlomoVideos,
            .smartAlbumUserLibrary,
            .smartAlbumSelfPortraits,
            .smartAlbumScreenshots,
        ][index % 12]
    }
    
    override var count: Int {
        return _index % 8
    }
    
    override func count(with type: AssetType) -> Int {
        if type == .image {
            return count
        }
        return 0
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
        
        title = "CollectionList"
    }
    
    /// The number of collection in the collection list.
    override var count: Int {
        if _cmds.contains("cl-empty") {
            return 0
        }
        return 16
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
    override func request(forImage asset: UHLocalAsset, targetSize: CGSize, contentMode: RequestContentMode, options: RequestOptions, resultHandler: @escaping (UIImage?, UHLocalAssetResponse) -> ()) -> UHLocalAssetRequest? {
        let response = UHLocalAssetResponse()
        let image: UIImage
        if targetSize.width > 0 && targetSize.width < 300 {
            image = #imageLiteral(resourceName: "t1_t")
        } else {
            image = #imageLiteral(resourceName: "t1")
        }
        response.isCancelled = false
        response.isDegraded = false
        response.isDownloading = false
        response.error = nil
        resultHandler(image, response)
        return nil
    }
    
    /// Requests a representation of the video asset for playback, to be loaded asynchronously.
    override func request(forVideo asset: UHLocalAsset, options: RequestOptions, resultHandler: @escaping (AVPlayerItem?, UHLocalAssetResponse) -> ()) -> UHLocalAssetRequest? {
        return nil
    }
    
    /// Cancels an asynchronous request
    override func cancel(with request: Ubiquity.UHLocalAssetRequest) {
    }
    
    /// Requests the user’s permission, if needed, for accessing the library.
    override func requestAuthorization(_ handler: @escaping (Error?) -> Void) {
        if _cmds.contains("cl-error") {
            handler(Exception.denied)
        } else {
            handler(nil)
        }
    }
    
    private var _cmds: [String]
}

class DebugingBrowserViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: "Pop", style: .done, target: nil, action: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let title = tableView.cellForRow(at: indexPath)?.textLabel?.text else {
            return
        }
        jump(title)
    }
    
    func jump(_ str: String) {
        
        let library: Ubiquity.Library
        let source: Ubiquity.Source
        let type: Ubiquity.ControllerType
        
        switch str {
        case "Album List - Empty":
            type = .albumsList
            source = Source(collectionTypes: [.regular], title: str)
            library = DebugingBrowserLibrary(cmds: ["cl-empty"])
            
        case "Album List - Error":
            type = .albumsList
            source = Source(collectionTypes: [.regular], title: str)
            library = DebugingBrowserLibrary(cmds: ["cl-error"])

        case "Album List - Regular":
            type = .albumsList
            source = Source(collectionTypes: [.regular])
            library = DebugingBrowserLibrary()
            
        case "Album List - Moments":
            type = .albumsList
            source = Source(collectionTypes: [.moment])
            library = DebugingBrowserLibrary()
            
        case "Album List - Moments & Regular & Recently":
            type = .albumsList
            source = Source(collectionTypes: [.moment, .regular, .recentlyAdded])
            library = DebugingBrowserLibrary()
            
        case "Album List - Custom":
            type = .albumsList
            source = Source(collectionTypes: [.regular])
            library = DebugingBrowserLibrary()
            
        case "Albums - Empty":
            type = .albums
            source = Source(collectionTypes: [.regular], title: str)
            library = DebugingBrowserLibrary(cmds: ["cl-empty"])

        case "Albums - Error":
            type = .albums
            source = Source(collectionTypes: [.regular], title: str)
            library = DebugingBrowserLibrary(cmds: ["cl-error"])

        case "Albums - Regular":
            type = .albums
            source = Source(collectionTypes: [.regular], title: str)
            library = DebugingBrowserLibrary()

        case "Albums - Moments":
            type = .albums
            source = Source(collectionTypes: [.moment], title: str)
            library = DebugingBrowserLibrary()
            
        case "Albums - Moments & Regular & Recently":
            type = .albums
            source = Source(collectionTypes: [.moment, .regular, .recentlyAdded])
            library = DebugingBrowserLibrary()

        default:
            return
        }
        
        let container = Ubiquity.Browser(library: library)
        if str == "Album List - Custom" {
            container.factory(with: .albumsList).configure {
                $0.setClass(DebuggingCustomAlbumsListCell.self, for: .cell)
                $0.setClass(DebuggingCustomAlbumsListLayout.self, for: .layout)
                $0.setClass(DebuggingCustomAlbumsListController.self, for: .controller)
            }
        }
        let controller = container.instantiateViewController(with: type, source: source)
        show(controller, sender: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


