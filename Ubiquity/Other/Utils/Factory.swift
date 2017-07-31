//
//  Factory.swift
//  Ubiquity
//
//  Created by sagesse on 21/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

enum Page {
    
    case albums
    case albumsList
    
    case detail
}

internal protocol Controller {
    
    /// Base controller craete method
    init(container: Container, factory: Factory, source: Source, sender: Any)
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
    
    
    func register(_ contentClass: AnyClass?, for media: AssetMediaType) {
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
