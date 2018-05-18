//
//  CollectionList.swift
//  Ubiquity
//
//  Created by sagesse on 2018/5/18.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import Foundation


/// The abstract superclass for Photos asset collection lists.
public protocol CollectionList: class {
    
    /// The localized title of the collection list.
    var ub_title: String? { get }
    /// The localized subtitle of the collection list.
    var ub_subtitle: String? { get }
    /// A unique string that persistently identifies the object.
    var ub_identifier: String { get }
    
    /// The type of the asset collection, such as an album or a moment.
    var ub_collectionType: CollectionType { get }
    
    /// The number of collection in the collection list.
    var ub_count: Int { get }
    /// Retrieves collection from the specified collection list.
    func ub_collection(at index: Int) -> Collection
}

