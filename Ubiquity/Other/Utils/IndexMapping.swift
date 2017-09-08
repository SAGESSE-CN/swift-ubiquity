//
//  IndexMapping.swift
//  Ubiquity
//
//  Created by sagesse on 08/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//


/// Index filtering and mapping
public struct IndexMapping {
    
    /// Generate a mapping
    public init<Source>(_ sequence: Source, filter: ((offset: Int, element: Source.Iterator.Element)) -> Bool) where Source : Sequence {
        // create mapping table
        var filtered: Array<Int?> = []
        var unfiltered: Array<Int?> = []
        
        // each the sequence
        sequence.enumerated().forEach {
            // check that the element has been filtered?
            if filter(($0, $1)) {
                // unfiltered, index is filtered count
                unfiltered.append(filtered.count)
                filtered.append($0)
            } else {
                // filtered, index is nil
                unfiltered.append(nil)
            }
        }
        
        // update mapping table
        self.filtered = filtered
        self.unfiltered = unfiltered
    }
    
    /// Get the filtered index
    public func filtering(_ index: Int) -> Int? {
        return unfiltered[index]
    }
    
    /// Get the index before filtering
    public func reverting(_ index: Int) -> Int? {
        return filtered[index]
    }
    
    // if the element is filtered, index is nil
    public let filtered: Array<Int?>
    public let unfiltered: Array<Int?>
}
