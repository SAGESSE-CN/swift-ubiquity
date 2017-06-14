//
//  PickerAlbumController.swift
//  Ubiquity
//
//  Created by SAGESSE on 6/9/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerAlbumController: BrowserAlbumController {
    /// collection view cell class provider
    override var collectionViewCellProvider: Templatize.Type {
        return PickerAlbumCell.self
    }
}
