//
//  Factory.swift
//  Ubiquity
//
//  Created by sagesse on 21/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

public enum ControllerType {
    
    case albums
    case albumsList
    
    case detail
}


internal protocol Controller {
    
    /// Base controller craete method
    //init(container: Container, factory: Factory, source: Source, sender: Any)
    init(container: Container, source: UHSource, sender: Any?)
}

public class UHSource: NSObject {
    
    /// Custom album filter. if return false, the collection will not be displayed.
    public typealias CustomFilter = ((offset: Int, collectoin: Collection)) -> Bool
    
    /// A data source with collection.
    public init(collection: Collection) {
        super.init()
        
        // configure the source data
        _filter = nil
        _collections = [collection]
        _collectionLists = nil
        _collectionListTypes = nil
        
        // configure other
        title = collection.ub_title
    }
    
    /// A data source with collection list.
    public convenience init(collectionList: CollectionList, filter: CustomFilter? = nil) {
        self.init(collectionLists: [collectionList], filter: filter)
    }
    /// A data source with collection list type.
    public convenience init(collectionType: CollectionType, filter: CustomFilter? = nil) {
        self.init(collectionTypes: [collectionType], filter: filter)
    }
    
    /// A data source with multiple collection lists.
    public init(collectionLists: [CollectionList], filter: CustomFilter? = nil) {
        super.init()
        
        // configure the source data
        _filter = filter
        _collections = nil
        _collectionLists = collectionLists
        _collectionListTypes = nil
        
        // configure title
        title = _title(with: collectionLists.first?.ub_collectionType ?? .regular)
    }
    /// A data source with multiple collection list types.
    public init(collectionTypes: [CollectionType], filter: CustomFilter? = nil) {
        super.init()
        
        // configure the source data
        _filter = filter
        _collections = nil
        _collectionLists = nil
        _collectionListTypes = collectionTypes
        
        // configure title
        title = _title(with: collectionTypes.first ?? .regular)
    }
    
    ///
    public var title: String?
    
    private func _title(with collectionType: CollectionType) -> String {
        switch collectionType {
        case .moment:
            return "Moments"
            
        case .regular:
            return "Photos"
            
        case .recentlyAdded:
            return "Recently"
        }
    }
    
    public var collectionTypes: Set<CollectionType> {
        // hit cache?
        if let collectionTypes =  _cachedCollectionTypes {
            return collectionTypes
        }
        var collectionTypes = Set<CollectionType>()
        
        _collectionListTypes?.forEach {
            collectionTypes.insert($0)
        }
        
        _collectionLists?.forEach {
            collectionTypes.insert($0.ub_collectionType)
        }
        
        _collections?.forEach {
            collectionTypes.insert($0.ub_collectionType)
        }
        
        _cachedCollectionTypes = collectionTypes
        
        return collectionTypes
    }
    public var collectionSubtypes: Set<CollectionSubtype> {
        // hit cache?
        if let collectionSubtypes =  _cachedCollectionSubtypes {
            return collectionSubtypes
        }
        var collectionSubtypes = Set<CollectionSubtype>()
        
        _collections?.forEach {
            collectionSubtypes.insert($0.ub_collectionSubtype)
        }
        
        _cachedCollectionSubtypes = collectionSubtypes
        
        return collectionSubtypes
    }
    
    
    /// Load data with container.
    internal func loadData(with container: Container, completion: @escaping (Error?) -> Void) {
        logger.trace?.write()
        
        DispatchQueue.global().async {
            
            self._loadData(with: container)
            

            
            completion(nil)
        }
    }
    
    private func _loadData(with container: Container) {
        
        // fetch collection list with types if needed
        _collectionListTypes.map {
            _collectionLists = $0.flatMap {
                container.library.ub_request(forCollectionList: $0)
            }
        }
        
        // fetch collection with collection list if needed
        _collectionLists.map {
            _collections = $0.flatMap { collectionList in
                (0 ..< collectionList.ub_count).map {
                    collectionList.ub_collection(at: $0)
                }
            }
        }
        
        // setup filter if needed
        _mapping = _filter.map { filter in
            _collections.map { collectoins in
                .init(collectoins,
                      filter: filter)
            }
        } ?? nil
    }
    
    /// Returns the number of all assets from the source.
    public var numberOfAssets: Int {
        // count hit cache.
        if let count = _cachedAssetCount {
            return count
        }
        // fetch assets count for all collections
        let count = (0 ..< numberOfCollections).reduce(0) { $0 + (collection(at: $1)?.ub_count ?? 0) }
        _cachedAssetCount = count
        return count
    }
    /// Returns the number of all colltions from the source.
    public var numberOfCollections: Int {
        // if there is no filtering, show all collections
        return _mapping?.filtered.count ?? _collections?.count ?? 0
    }
    /// Returns the number of all colltion lists from the source.
    public var numberOfCollectionLists: Int {
        return _collectionLists?.count ?? 0
    }
    
    /// Returns the number of all assets for `type` from the source.
    public func numberOfAssets(with type: AssetType) -> Int {
        // count hit cache.
        if let count = _cachedAssetsCounts?[type] {
            return count
        }
        // is first cache.
        if _cachedAssetsCounts == nil {
            _cachedAssetsCounts = [:]
        }
        // fetch assets count for all collections
        let count = (0 ..< numberOfCollections).reduce(0) { $0 + (collection(at: $1)?.ub_count(with: type) ?? 0) }
        _cachedAssetsCounts?[type] = count
        return count
    }
    /// Returns the number of all assets in collection.
    public func numberOfAssets(inCollection index: Int) -> Int {
        // get the filtered collection at index
        return collection(at: index)?.ub_count ?? 0
    }
    
    /// Returns the number of all collections in collection list.
    public func numberOfCollections(inCollectionList index: Int) -> Int {
        return _collectionLists?[index].ub_count ?? 0
    }
    
    /// Retrieves assets from the specified asset collection.
    public func asset(at index: IndexPath) -> Asset? {
        // get the filtered collection at index
        return collection(at: index.section)?.ub_asset(at: index.item)
    }
    
    /// Retrieves collection from the source.
    public func collection(at index: Int) -> Collection? {
        // convert index to unfiltered before
        return _collections?[_mapping?.reverting(index) ?? index]
    }
    
    /// Retrieves collection list from the source.
    public func collectionList(at index: Int) -> CollectionList? {
        return _collectionLists?[index]
    }
    
    
    private var _filter: CustomFilter?
    private var _mapping: IndexMapping?
    
    private var _collections: Array<Collection>?
    private var _collectionLists: Array<CollectionList>?
    private var _collectionListTypes: Array<CollectionType>?
    
    private var _cachedAssetCount: Int?
    private var _cachedAssetsCounts: [AssetType: Int]?
    
    private var _cachedCollectionTypes: Set<CollectionType>?
    private var _cachedCollectionSubtypes: Set<CollectionSubtype>?
}

internal class Factory {
    
    init(controller: Controller.Type, cell: UIView.Type) {
        self.controller = controller
        self.cell = cell
    }
    
    var cell: UIView.Type
    
    var contents: Dictionary<String, AnyClass> {
        var result = Dictionary<String, AnyClass>()
        _contents.forEach {
            result[$0] = _makeClass(cell, $1)
        }
        return result
    }
    
    var controller: Controller.Type
    
    
    func register(_ contentClass: AnyClass?, for media: AssetType) {
        // update content class
        _contents[ub_identifier(with: media)] = contentClass
    }

    private var _contents: Dictionary<String, AnyClass?> = [:]
}

internal class FactoryAlbums: Factory {
    
    override init(controller: Controller.Type = BrowserAlbumController.self, cell: UIView.Type = BrowserAlbumCell.self) {
        super.init(controller: controller, cell: cell)
        
        // setup default
        register(UIImageView.self, for: .audio)
        register(UIImageView.self, for: .image)
        register(UIImageView.self, for: .video)
        register(UIImageView.self, for: .unknown)
    }
}

internal class FactoryAlbumsList: Factory {
    
    override init(controller: Controller.Type = BrowserAlbumListController.self, cell: UIView.Type = BrowserAlbumListCell.self) {
        super.init(controller: controller, cell: cell)
    }
}

internal class FactoryDetail: Factory {
    
    override init(controller: Controller.Type = BrowserDetailController.self, cell: UIView.Type = BrowserDetailCell.self) {
        super.init(controller: controller, cell: cell)
        
        // setup default
        register(PhotoContentView.self, for: .audio)
        register(PhotoContentView.self, for: .image)
        register(VideoContentView.self, for: .video)
        register(PhotoContentView.self, for: .unknown)
    }
}


// with `conetntClass` generates a new class
private func _makeClass(_ cellClass: AnyClass, _ contentClass: AnyClass?) -> AnyClass {
    // if content class is empty, use base cell class
    guard let contentClass = contentClass else {
        return cellClass
    }
    
    // if the class has been registered, ignore
    let name = "\(NSStringFromClass(cellClass))<\(NSStringFromClass(contentClass))>"
    if let newClass = objc_getClass(name) as? AnyClass {
        return newClass
    }
    
    // if you have not registered this, dynamically generate it
    let newSelector: Selector = .init(String("contentViewClass"))
    let newClass: AnyClass = objc_allocateClassPair(cellClass, name, 0)
    let method: Method = class_getClassMethod(cellClass, newSelector)
    objc_registerClassPair(newClass)
    // because it is a class method, it can not used class, need to use meta class
    guard let metaClass = objc_getMetaClass(name) as? AnyClass else {
        return newClass
    }
    
    let getter: @convention(block) () -> AnyClass = {
        return contentClass
    }
    // add class method
    class_addMethod(metaClass, newSelector, imp_implementationWithBlock(unsafeBitCast(getter, to: AnyObject.self)), method_getTypeEncoding(method))
    
    return newClass
}
