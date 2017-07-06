//
//  DataSource.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/24/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class DataSource {
    
    init(collection: Collection) {
        self.collections = [collection]
//        _collections = (0 ..< 30).map { _ in
//            collection
//        }
    }
    init(collections: Array<Collection>) {
        self.collections = collections
    }
    
    var title: String? {
        return collections.first?.title
    }
    
    var count: Int {
        return collections.reduce(0) {
            $0 + $1.assetCount
        }
    }
    func count(with type: AssetMediaType) -> Int {
        return collections.reduce(0) {
            $0 + $1.assetCount(with: type)
        }
    }
    
    
    var numberOfSections: Int {
        return collections.count
    }
    func numberOfItems(inSection section: Int) -> Int {
        return collections.ub_get(at: section)?.assetCount ?? 0
    }
    
    func asset(at indexPath: IndexPath) -> Asset? {
        return collections.ub_get(at: indexPath.section)?.asset(at: indexPath.item)
    }
    
    var collections: Array<Collection>
}

internal class DataSourceOptions: RequestOptions {
    
    init(isSynchronous: Bool = false, progressHandler: ((Double, Response) -> ())? = nil) {
        self.isSynchronous = isSynchronous
        self.progressHandler = progressHandler
    }
    
    /// if necessary will download the image from reomte
    var isNetworkAccessAllowed: Bool = true
    
    // return only a single result, blocking until available (or failure). Defaults to NO
    var isSynchronous: Bool = false
    
    /// provide caller a way to be told how much progress has been made prior to delivering the data when it comes from remote.
    var progressHandler: ((Double, Response) -> ())?
}
