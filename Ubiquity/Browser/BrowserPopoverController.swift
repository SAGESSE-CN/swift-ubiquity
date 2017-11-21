//
//  BrowserPopoverController.swift
//  Ubiquity
//
//  Created by sagesse on 21/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserPopoverController: UICollectionViewController, Controller {

    required init(container: Container, source: Source, sender: Any?) {
        // setup init data
        self.source = source
        self.container = container
        
        // continue init the UI
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        super.title = source.title
//
//        // listen albums any change
//        self.container.addChangeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
//        // clear all cache request when destroyed
//        _clearCachingAssets()
//
//        // cancel listen change
//        container.removeChangeObserver(self)
    }
    
    override func loadView() {
        super.loadView()
        
        // setup controller
        view.backgroundColor = .white
        
        // setup colleciton view
        collectionView?.backgroundColor = view.backgroundColor
        collectionView?.alwaysBounceHorizontal = true
        
        // fetch all register cell for albums.
        container.factory(with: .popover).contents.forEach {
            // forward to collection view
            collectionView?.register($1, forCellWithReuseIdentifier: $0)
        }
    }

    // library status
    private(set) var prepared: Bool = false
    private(set) var authorized: Bool = false
    
    private(set) var container: Container
    private(set) var source: Source {
        willSet {
        }
    }
}
