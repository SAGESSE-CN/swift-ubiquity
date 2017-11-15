//
//  Accessor.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/24/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


public class Source: NSObject {
    
    /// Custom album filter. if return false, the collection will not be displayed.
    /// Notice: that every change is filtered again 
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
        _title = nil
        _defaultTitle = collection.ub_title
    }

    /// A custom filter for source
    public var filter: CustomFilter? {
        return _filter
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
        _title = nil
        _defaultTitle = ub_defaultTitle(with: collectionLists.map({ $0.ub_collectionType }))
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
        _title = nil
        _defaultTitle = ub_defaultTitle(with: collectionTypes)
    }
    
    /// The source title.
    public var title: String? {
        set { return _title = newValue }
        get { return _title ?? _defaultTitle }
    }
    
    /// The source contains all of the collection type.
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
        _filteredCollections?.forEach {
            collectionTypes.insert($0.ub_collectionType)
        }
        
        _cachedCollectionTypes = collectionTypes
        
        return collectionTypes
    }
    
    /// The source contains all of the collection subtype.
    public var collectionSubtypes: Set<CollectionSubtype> {
        // hit cache?
        if let collectionSubtypes =  _cachedCollectionSubtypes {
            return collectionSubtypes
        }
        var collectionSubtypes = Set<CollectionSubtype>()
        
        _collections?.forEach {
            collectionSubtypes.insert($0.ub_collectionSubtype)
        }
        _filteredCollections?.forEach {
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
            
            // must preload, or seriously affect the performance of the main thread
            _ = self.numberOfAssets
            
            // teh load has been completed
            completion(nil)
        }
    }
    
    
    private func _loadData(with container: Container) {
        
        // fetch collection list with types if needed
        _collectionListTypes.map {
            _collectionLists = $0.flatMap {
                container.request(forCollectionList: $0)
            }
        }
        
        // load data for filter
        _loadCollections(with: _filter)
        
        // need to recalculate all cached info
        _cachedAssetCount = nil
        _cachedAssetsCounts = nil
        _cachedCollectionSubtypes = nil
        _cachedCollectionTypes = nil
    }
    
    /// Load filtered collections
    private func _loadCollections(with filter: CustomFilter?) {
        // get all the collection for collections & collection lists
        var collections = (_collections.map { [$0] } ?? []) + (_collectionLists ?? []).flatMap { collectionList in
            return (0 ..< collectionList.ub_count).map { index in
                return collectionList.ub_collection(at: index)
            }
        }
        
        // filter collections if needed
        // setting filters is a few cases, so check separately 
        filter.map { filter in
            // a self increasing clouser
            let fetch = { () -> (() -> Int) in
                var index = 0
                return {
                    index += 1
                    return index - 1
                }
            }()
            
            // filter all collection
            collections.enumerated().forEach {
                collections[$0] = $1.filter { filter((fetch(), $0)) }
            }
        }
        
        // fetch collcetion lists
        _filteredCollectionLists = (_collections.map { [$0] } ?? []) + (_collectionLists ?? []).flatMap { $0 }
        
        // fetch and filter success
        _filteredCollectionsOfPlane = collections
        _filteredCollections = collections.flatMap { $0 }
        
        // in title no set and only one collection, take the title of collection
        if let collection = _filteredCollections?.first, _filteredCollections?.count == 1 {
            _defaultTitle = collection.ub_title
        }
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
       return _filteredCollections?.count ?? 0
    }
    /// Returns the number of all colltion lists from the source.
    public var numberOfCollectionLists: Int {
        return _filteredCollectionsOfPlane?.count ?? 0
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
        return collection(at: index)?.ub_count ?? 0
    }
    
    /// Returns the number of all collections in collection list.
    public func numberOfCollections(inCollectionList index: Int) -> Int {
        return _filteredCollectionsOfPlane?[index].count ?? 0
    }
    
    /// Retrieves assets from the specified asset collection.
    public func asset(at index: IndexPath) -> Asset? {
        return collection(at: index.section)?.ub_asset(at: index.item)
    }
    
    /// Retrieves collection from the source.
    public func collection(at index: Int) -> Collection? {
        return _filteredCollections?[index]
    }
    /// Retrieves collection from the source.
    public func collection(at index: Int, inCollectionList section: Int) -> Collection? {
        return _filteredCollectionsOfPlane?[section][index]
    }
    
    /// Retrieves collection list from the source.
    public func collectionList(at index: Int) -> CollectionList? {
        // may be is CollectionList and Arrary<Collection>.
        return _filteredCollectionLists?[index] as? CollectionList
    }
    
    /// Generate a new source with change.
    private func _newSource(with change: Change) -> Source? {
        // generate a new source
        var hasChanges = false
        let newSource = Source(collectionTypes: _collectionListTypes ?? [])

        // copy source
        newSource._title = _title
        newSource._defaultTitle = _defaultTitle
        newSource._identifier = _identifier
        newSource._filter = _filter
        newSource._collectionListTypes = _collectionListTypes
        newSource._collectionLists = _collectionLists?.flatMap {
            // if the collection list has not change, use the original collection list
            guard let details = change.ub_changeDetails(forCollectionList: $0) else {
                return $0
            }
            hasChanges = true
            // if the collectoin list have change, use the changed collectoin list
            // if after is nil, indicates that the collection list has been deleted
            return details.after as? CollectionList
        }
        newSource._collections = _collections?.flatMap {
            // if the collection has not change, use the original collection
            guard let details = change.ub_changeDetails(forCollection: $0) else {
                return $0
            }
            hasChanges = true
            // if the collectoin have change, use the changed collectoin
            // if after is nil, indicates that the collection has been deleted
            return details.after as? Collection
        }
        
        // if no difference is compared, the event is ignored
        guard hasChanges else {
            return nil
        }
        
        /// Load filtered collections
        newSource._loadCollections(with: _filter)
        
        // generate success
        return newSource
    }
    
    
    public func changeDetails(forAssets change: Change) -> SourceChangeDetails? {
        // hit cache?
        let cachedKey = "source-assets-\(_identifier)"
        if let cachedDetails = Cacher.cache(of: change, forKey: cachedKey) as? SourceChangeDetails {
            return cachedDetails
        }
        
        // generate a new source
        guard let newSource = _newSource(with: change) else {
            return nil
        }
        
        // compare the difference between the collections changes
        let collections = ub_diff(_filteredCollections ?? [], dest: newSource._filteredCollections ?? []) {
            return ($0 === $1)
        }
        
        // if no any changes, the event is ignore
        guard !collections.isEmpty else {
            return nil 
        }
        
        // generate new change details
        let newDetails = SourceChangeDetails(before: self, after: newSource)
        
        // must be some changes
        newDetails.hasItemChanges = true
        newDetails.hasIncrementalChanges = true
        
        // handling collections change information
        collections.forEach {
            switch $0 {
            case .move(let from, let to):
                // move a section
                newDetails.moveSections?.append((from, to))
                
            case .insert(_, let to):
                // insert a new section
                newDetails.insertSections?.insert(to)
                
            case .remove(let from, _):
                // remove a section
                newDetails.deleteSections?.insert(from)
                
            case .update(let from, _):
                // update a section
                // check the change information
                guard let collection = _filteredCollections?[from] else {
                    return
                }
                
                // get the collection change details
                guard let details = change.ub_changeDetails(forCollection: collection) else {
                    return
                }
                
                // if hasItemChanges is false, the collection is changed, but asset no any change
                guard details.hasItemChanges else {
                    return // ignore the event
                }
                
                // if hasIncrementalChanges is false, the change can’t support incremental
                guard details.hasIncrementalChanges else {
                    newDetails.reloadSections?.insert(from)
                    return 
                }
                
                // convert to source change details
                details.insertedIndexes?.forEach { newDetails.insertItems?.append(.init(item: $0, section: from)) }
                details.removedIndexes?.forEach { newDetails.removeItems?.append(.init(item: $0, section: from)) }
                details.changedIndexes?.forEach { newDetails.reloadItems?.append(.init(item: $0, section: from)) }
                
                details.movedIndexes?.forEach {
                    newDetails.moveItems?.append((.init(item: $0, section: from), .init(item: $1, section: from)))
                }
            }
        }
        
        // repair data conflict
        newDetails.fix()
        
        // show debug info
        logger.debug?.write(newDetails)
        
        // save to cacher
        Cacher.cache(of: change, value: newDetails, forKey: cachedKey)
        
        // submit changes
        return newDetails
    }
    public func changeDetails(forCollections change: Change) -> SourceChangeDetails? {
        // hit cache?
        let cachedKey = "source-collections-\(_identifier)"
        if let cachedDetails = Cacher.cache(of: change, forKey: cachedKey) as? SourceChangeDetails {
            return cachedDetails
        }
        
        // generate a new source
        guard let newSource = _newSource(with: change) else {
            return nil
        }
        
        // compare the difference between the collection list changes
        let collectionLists = ub_diff(_filteredCollectionLists ?? [], dest: newSource._filteredCollectionLists ?? []) {
            return ($0 as? CollectionList)?.ub_identifier == ($1 as? CollectionList)?.ub_identifier
        }
        
        // compare the difference between the collections changes
        let collections = ub_diff(_filteredCollections ?? [], dest: newSource._filteredCollections ?? []) {
            return ($0 === $1)
        }
        
        // if no any changes, the event is ignore
        guard !collectionLists.isEmpty || !collections.isEmpty else {
            return nil
        }
        
        // generate old index paths
        let indexPaths: [IndexPath] = _filteredCollectionsOfPlane?.enumerated().flatMap { section, collections in
            return collections.enumerated().flatMap { item, collection in
                return IndexPath(item: item, section: section)
            }
        } ?? []
        
        // generate new index paths
        let newIndexPaths: [IndexPath] = newSource._filteredCollectionsOfPlane?.enumerated().flatMap { section, collections in
            return collections.enumerated().flatMap { item, collection in
                return IndexPath(item: item, section: section)
            }
        } ?? []
        
        // generate new change details
        let newDetails = SourceChangeDetails(before: self, after: newSource)
        
        // must be some changes
        newDetails.hasItemChanges = true
        newDetails.hasIncrementalChanges = true
        
        // handling collection lists change information
        collectionLists.forEach {
            switch $0 {
            case .move(let from, let to):
                // move a section
                newDetails.moveSections?.append((from, to))
                
            case .insert(_, let to):
                // insert a new section
                newDetails.insertSections?.insert(to)
                
            case .remove(let from, _):
                // remove a section
                newDetails.deleteSections?.insert(from)
                
            case .update(let from, _):
                // update a section
                newDetails.reloadSections?.insert(from)
            }
        }
        
        // handling collections change information
        collections.forEach {
            switch $0 {
            case .move(let from, let to):
                // move a collection
                newDetails.moveItems?.append((indexPaths[from], newIndexPaths[to]))
                
            case .insert(_, let to):
                // insert a new collection
                newDetails.insertItems?.append(newIndexPaths[to])
                
            case .remove(let from, _):
                // remove a collection
                newDetails.removeItems?.append(indexPaths[from])
                
            case .update(let from, _):
                // udpate a collection
                newDetails.reloadItems?.append(indexPaths[from])
            }
        }
        
        // repair data conflict
        newDetails.fix()
        
        // show debug info
        logger.debug?.write(newDetails)
        
        // save to cacher
        Cacher.cache(of: change, value: newDetails, forKey: cachedKey)
        
        // submit changes
        return newDetails
    }
    
    /// Content identifier
    private lazy var _identifier: String = UUID().uuidString
    
    private var _title: String??
    private var _defaultTitle: String?
    
    private var _filter: CustomFilter?
    
    private var _collections: Array<Collection>?
    private var _collectionLists: Array<CollectionList>?
    private var _collectionListTypes: Array<CollectionType>?
    
    private var _filteredCollections: Array<Collection>?
    private var _filteredCollectionLists: Array<Any>?
    private var _filteredCollectionsOfPlane: Array<Array<Collection>>?
    
    private var _cachedAssetCount: Int?
    private var _cachedAssetsCounts: [AssetType: Int]?
    
    private var _cachedCollectionTypes: Set<CollectionType>?
    private var _cachedCollectionSubtypes: Set<CollectionSubtype>?
}

public class SourceFolding: NSObject, Collection {
    
    /// Create a collection list folding object
    public init(collectionList: CollectionList) {
        self.collectionList = collectionList
        super.init()
    }
    
    /// Collection list in folding
    public let collectionList: CollectionList
    
    /// Returns the number of all colltions from the source.
    public var numberOfCollections: Int {
        return collectionList.ub_count
    }
    /// Returns the number of folded colltions from the source.
    public var numberOfFoldedCollections: Int {
        return min(collectionList.ub_count, 1)
    }
    
    /// Retrieves collection from the collection list.
    public func collection(at index: Int) -> Collection? {
        return self
    }
    
    // MARK: Collection
    
    /// The localized title of the collection.
    public var ub_title: String? {
        if _cachedTitle == nil {
            _cachedTitle = ub_defaultTitle(with: collectionList.ub_collectionType)
        }
        return _cachedTitle
    }
    /// The localized subtitle of the collection.
    public var ub_subtitle: String? {
        return nil
    }
    /// A unique string that persistently identifies the object.
    public var ub_identifier: String {
        return collectionList.ub_identifier
    }
    
    /// The type of the asset collection, such as an album or a moment.
    public var ub_collectionType: CollectionType {
        return collectionList.ub_collectionType
    }
    /// The subtype of the asset collection.
    public var ub_collectionSubtype: CollectionSubtype {
        return .smartAlbumGeneric
    }
    
    /// The number of assets in the asset collection.
    public var ub_count: Int {
        // count hit cache.
        if let count = _cachedAssetCount {
            return count
        }
        // fetch assets count for all collections
        let count = (0 ..< numberOfCollections).reduce(0) { $0 + (collectionList.ub_collection(at: $1).ub_count) }
        _cachedAssetCount = count
        return count
    }
    /// The number of assets in the asset collection.
    public func ub_count(with type: AssetType) -> Int {
        // count hit cache.
        if let count = _cachedAssetsCounts?[type] {
            return count
        }
        // is first cache.
        if _cachedAssetsCounts == nil {
            _cachedAssetsCounts = [:]
        }
        // fetch assets count for all collections
        let count = (0 ..< numberOfCollections).reduce(0) { $0 + (collectionList.ub_collection(at: $1).ub_count(with: type)) }
        _cachedAssetsCounts?[type] = count
        return count
    }
    /// Retrieves assets from the specified asset collection.
    public func ub_asset(at index: Int) -> Asset {
        // asset hit cache.
        if let asset = _cachedAsset?[index] {
            return asset
        }
        // is first cache.
        if _cachedAsset == nil {
            _cachedAsset = [:]
        }
        
        // find section 
        var item = index
        for section in 0 ..< numberOfCollections {
            let collection = collectionList.ub_collection(at: section)
            
            guard item < collection.ub_count else {
                item -= collection.ub_count
                continue
            }
            
            let asset = collection.ub_asset(at: item)
            _cachedAsset?[index] = asset
            return asset
        }
        
        // find fail
        fatalError()
    }
    
    private var _cachedTitle: String?
    
    private var _cachedAsset: [Int: Asset]?
    private var _cachedAssetCount: Int?
    private var _cachedAssetsCounts: [AssetType: Int]?
}

public class SourceChangeDetails: NSObject {
    
    /// Create an change detail
    init(before: Source, after: Source?) {
        self.before = before
        self.after = after
    }
    
    /// the object in the state before this change
    let before: Source
    /// the object in the state after this change
    let after: Source?
    
    /// A Boolean value that indicates whether objects have been any change in the source.
    var hasItemChanges: Bool = false
    /// A Boolean value that indicates whether changes to the source can be described incrementally.
    var hasIncrementalChanges: Bool = false
    
    /// The indexes from which objects have been removed from the source.
    var removeItems: [IndexPath]? = []
    /// The indexes of objects in the source whose content or metadata have been updated.
    var reloadItems: [IndexPath]? = []
    /// The indexes where new objects have been inserted in the source.
    var insertItems: [IndexPath]? = []
    /// The indexs where new object have move
    var moveItems: [(IndexPath, IndexPath)]? = []
    
    /// The indexes from which groups have been rmoved from the source.
    var deleteSections: IndexSet? = []
    /// The indexes of groups in the source whose content or metadata have been updated.
    var reloadSections: IndexSet? = []
    /// The indexes from which groups have been inserted from the source.
    var insertSections: IndexSet? = []
    /// The indexs where new object have move
    var moveSections: [(Int, Int)]? = []
    
    // fixed invalid data
    func fix() {
        
         // if the section has been deleted, clear all data about that section
        deleteSections?.forEach { section in
            moveItems = moveItems?.filter { $0.section != section && $1.section != section }
            removeItems = removeItems?.filter { $0.section != section }
            insertItems = insertItems?.filter { $0.section != section }
            reloadItems = reloadItems?.filter { $0.section != section }
        }
        
        // if the section has been reloaded, clear all data about that section
        reloadSections?.forEach { section in
            moveItems = moveItems?.filter { $0.section != section && $1.section != section }
            removeItems = removeItems?.filter { $0.section != section }
            insertItems = insertItems?.filter { $0.section != section }
            reloadItems = reloadItems?.filter { $0.section != section }
        }
        
        // if the section has been move, clear all data about that section
        moveSections?.forEach { section, _ in
            moveItems = moveItems?.filter { $0.section != section && $1.section != section }
            removeItems = removeItems?.filter { $0.section != section }
            insertItems = insertItems?.filter { $0.section != section }
            reloadItems = reloadItems?.filter { $0.section != section }
        }
        
        // clear invaild data
        __clear(&removeItems)
        __clear(&reloadItems)
        __clear(&insertItems)
        __clear(&moveItems)
        __clear(&deleteSections)
        __clear(&reloadSections)
        __clear(&insertSections)
        __clear(&moveSections)
    }
    
    /// Display debug info
    public override var description: String {
        // generate debug information
        let tmp = [
            insertSections?.map { "S-AN/\($0)" },
            reloadSections?.map { "S-R\($0)/\($0)" },
            deleteSections?.map { "S-D\($0)/N" },
            moveSections?.map { "S-M\($0)/\($1)" },
            
            insertItems?.map { "AN/\($0.section):\($0.item)" },
            reloadItems?.map { "R\($0.section):\($0.item)/\($0.section):\($0.item)" },
            removeItems?.map { "D\($0.section):\($0.item)/N" },
            moveItems?.map { "M\($0.section):\($0.item)/\($1.section):\($1.item)" },
        ]
        
        // convert to string
        let str = tmp.flatMap { $0 }.flatMap { $0 }.reduce("") {
            guard !$0.isEmpty else {
                return $1
            }
            return $0 + ", " + $1
        }
        
        return "\(super.description), title: \"\(self.before.title ?? "<Empty>")\", diffs: [\(str)]"
    }
}

// clear empty collection
private func __clear<T: Swift.Collection>(_ seq: inout T?) {
    // if the collection is emtpy, clear to nil
    guard seq?.isEmpty ?? false else {
        return
    }
    seq = nil
}
