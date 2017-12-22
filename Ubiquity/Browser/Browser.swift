//
//  Browser.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// A media browser
@objc open class Browser: Container {
    
    /// Create a media browser
    public override init(library: Library) {
        super.init(library: library)
        
        // Setup albums list.
        factory(with: .albumsList).configure {
            $0.setClass(BrowserAlbumListCell.self, for: .cell)
            $0.setClass(BrowserAlbumListLayout.self, for: .layout)
            $0.setClass(BrowserAlbumListController.self, for: .controller)
        }
        
        // Setup albums.
        factory(with: .albums).configure {
            $0.setClass(BrowserAlbumCell.self, for: .cell)
            $0.setClass(BrowserAlbumLayout.self, for: .layout)
            $0.setClass(BrowserAlbumController.self, for: .controller)
            $0.setClass(BrowserAlbumView.self, for: .view)
            
            $0.setClass(UIImageView.self, matching: "*", for: .cell)
        }
        
        factory(with: .detail).configure {
            $0.setClass(BrowserDetailCell.self, for: .cell)
            $0.setClass(BrowserDetailLayout.self, for: .layout)
            $0.setClass(BrowserDetailController.self, for: .controller)
            
            $0.setClass(PhotoContentView.self, matching: "*", for: .cell)
            $0.setClass(VideoContentView.self, matching: "video", for: .cell)
        }
        
        // Setup popover.
        factory(with: .popover).configure {
            $0.setClass(BrowserPreviewCell.self, for: .cell)
            $0.setClass(BrowserPreviewLayout.self, for: .layout)
            $0.setClass(BrowserPreviewController.self, for: .controller)
            
            $0.setClass(UIImageView.self, matching: "*", for: .cell)
        }
    }
    
    /// default is YES. Controls whether a asset can be edit
    open var allowsEditing: Bool = false
}
