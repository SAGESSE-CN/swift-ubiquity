//
//  SelectionTests.swift
//  Ubiquity-Example
//
//  Created by sagesse on 2018/5/17.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import XCTest
@testable import Ubiquity

class AssetT: Ubiquity.UHLocalAsset {
}
class CollectionT: Ubiquity.UHLocalAssetCollection {
    
    var assets: [AssetT] = []
    
    override func contains(_ asset: UHLocalAsset) -> Bool {
        return assets.contains(where: {
            $0.identifier == asset.identifier
        })
    }
}


class SelectionTests: XCTestCase {
    
    var collections: [CollectionT]!
    var assets: [[AssetT]]!
    
    override func setUp() {
        super.setUp()
        
        collections = (0 ..< 5).map {
            CollectionT(identifier: "collection-[\($0)]")
        }
        assets = collections.map { collection in
            collection.assets = (0 ..< 100).map {
                let asset = AssetT(identifier: "asset-\($0) in \(collection.identifier)")
//                asset.ub_collection = collection
                return asset
            }
            return collection.assets
        }
    }
    
    func emptyController() -> SelectionController? {
        return Ubiquity.SelectionController()
    }
    func fullController() -> SelectionController? {
        let controller = Ubiquity.SelectionController()
        controller.select(.all)
        return controller
    }
    
    func testEmpty() {
        if let controller = emptyController() {
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
        }
    }
    
    func testFull() {
        if let controller = fullController() {
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[1][1]))
        }
    }
    
    func testSelect() {
        if let controller = emptyController() {
            controller.select(.single(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
        }

        if let controller = emptyController() {
            controller.select(.multiple([assets[0][0], assets[0][1]]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[0][2]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
        }
        
        if let controller = emptyController() {
            controller.select(.collection(collections[0]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
        }

        if let controller = emptyController() {
            controller.select(.all)
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[2][0]))
        }
        if let controller = emptyController() {
            controller.select(.single(assets[0][0]))
            controller.select(.multiple([assets[0][0], assets[1][0], assets[1][1], assets[2][0]]))
            controller.select(.collection(collections[2]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[1][1]))
            XCTAssertTrue(!controller.contains(assets[1][2]))
            XCTAssertTrue(controller.contains(assets[2][0]))
            XCTAssertTrue(controller.contains(assets[2][1]))
            XCTAssertTrue(controller.contains(assets[2][2]))
            XCTAssertTrue(!controller.contains(assets[3][0]))
            XCTAssertTrue(!controller.contains(assets[3][1]))
        }
        if let controller = emptyController() {
            controller.select(.all)
            controller.select(.single(assets[3][0]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[2][0]))
        }
        if let controller = emptyController() {
            controller.select(.all)
            controller.select(.collection(collections[2]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[2][0]))
        }
        if let controller = emptyController() {
            controller.select(.collection(collections[1]))
            controller.select(.single(assets[1][0]))
            controller.select(.collection(collections[1]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[1][1]))
            XCTAssertTrue(!controller.contains(assets[2][0]))
        }
        if let controller = emptyController() {
            controller.select(.single(assets[1][0]))
            controller.select(.collection(collections[1]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[1][1]))
            XCTAssertTrue(!controller.contains(assets[2][0]))
        }
    }
    
    func testDeselect() {
        if let controller = fullController() {
            controller.deselect(.single(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
        }
        
        if let controller = fullController() {
            controller.deselect(.multiple([assets[0][0], assets[0][1]]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[0][2]))
            XCTAssertTrue(controller.contains(assets[1][0]))
        }
        
        if let controller = fullController() {
            controller.deselect(.collection(collections[0]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
        }
        
        if let controller = fullController() {
            controller.deselect(.all)
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[2][0]))
        }
        if let controller = fullController() {
            controller.deselect(.single(assets[0][0]))
            controller.deselect(.multiple([assets[0][0], assets[1][0], assets[1][1], assets[2][0]]))
            controller.deselect(.collection(collections[2]))
            XCTAssertFalse(controller.contains(assets[0][0]))
            XCTAssertFalse(!controller.contains(assets[0][1]))
            XCTAssertFalse(controller.contains(assets[1][0]))
            XCTAssertFalse(controller.contains(assets[1][1]))
            XCTAssertFalse(!controller.contains(assets[1][2]))
            XCTAssertFalse(controller.contains(assets[2][0]))
            XCTAssertFalse(controller.contains(assets[2][1]))
            XCTAssertFalse(controller.contains(assets[2][2]))
            XCTAssertFalse(!controller.contains(assets[3][0]))
            XCTAssertFalse(!controller.contains(assets[3][1]))
        }
        if let controller = fullController() {
            controller.deselect(.all)
            controller.deselect(.single(assets[3][0]))
            XCTAssertFalse(controller.contains(assets[0][0]))
            XCTAssertFalse(controller.contains(assets[0][1]))
            XCTAssertFalse(controller.contains(assets[1][0]))
            XCTAssertFalse(controller.contains(assets[2][0]))
        }
        if let controller = fullController() {
            controller.deselect(.all)
            controller.deselect(.collection(collections[2]))
            XCTAssertFalse(controller.contains(assets[0][0]))
            XCTAssertFalse(controller.contains(assets[0][1]))
            XCTAssertFalse(controller.contains(assets[1][0]))
            XCTAssertFalse(controller.contains(assets[2][0]))
        }
        if let controller = fullController() {
            controller.deselect(.collection(collections[1]))
            controller.deselect(.single(assets[1][0]))
            controller.deselect(.collection(collections[1]))
            XCTAssertFalse(!controller.contains(assets[0][0]))
            XCTAssertFalse(!controller.contains(assets[0][1]))
            XCTAssertFalse(controller.contains(assets[1][0]))
            XCTAssertFalse(controller.contains(assets[1][1]))
            XCTAssertFalse(!controller.contains(assets[2][0]))
        }
        if let controller = fullController() {
            controller.deselect(.single(assets[1][0]))
            controller.deselect(.collection(collections[1]))
            XCTAssertFalse(!controller.contains(assets[0][0]))
            XCTAssertFalse(!controller.contains(assets[0][1]))
            XCTAssertFalse(controller.contains(assets[1][0]))
            XCTAssertFalse(controller.contains(assets[1][1]))
            XCTAssertFalse(!controller.contains(assets[2][0]))
        }
    }
    
    func testMix() {
        if let controller = emptyController() {
            controller.select(.single(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.deselect(.single(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.select(.multiple([assets[0][0], assets[0][1]]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.deselect(.multiple([assets[0][0]]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.deselect(.collection(collections[0]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.select(.collection(collections[0]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.deselect(.collection(collections[0]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.select(.all)
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[1][1]))
            controller.deselect(.collection(collections[1]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.deselect(.all)
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.deselect(.collection(collections[0]))
            XCTAssertTrue(!controller.contains(assets[0][0]))
            XCTAssertTrue(!controller.contains(assets[0][1]))
            XCTAssertTrue(!controller.contains(assets[1][0]))
            XCTAssertTrue(!controller.contains(assets[1][1]))
            controller.select(.all)
            controller.deselect(.single(assets[1][0]))
            controller.select(.collection(collections[1]))
            XCTAssertTrue(controller.contains(assets[0][0]))
            XCTAssertTrue(controller.contains(assets[0][1]))
            XCTAssertTrue(controller.contains(assets[1][0]))
            XCTAssertTrue(controller.contains(assets[1][1]))
        }
    }
    
    func testIncalculable() {
        if let controller = emptyController() {
            controller.select(.single(assets[0][0]))
            XCTAssertTrue(!controller.incalculable)
            controller.select(.multiple([assets[0][0], assets[0][1]]))
            XCTAssertTrue(!controller.incalculable)
            controller.select(.collection(collections[0]))
            XCTAssertTrue(controller.incalculable)
        }
        if let controller = emptyController() {
            controller.select(.collection(collections[0]))
            XCTAssertTrue(controller.incalculable)
            controller.deselect(.collection(collections[0]))
            XCTAssertTrue(!controller.incalculable)
        }
        if let controller = emptyController() {
            controller.select(.all)
            XCTAssertTrue(controller.incalculable)
            controller.deselect(.all)
            XCTAssertTrue(!controller.incalculable)
        }

    }
}
