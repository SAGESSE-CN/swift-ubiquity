//
//  Factory.swift
//  Ubiquity
//
//  Created by sagesse on 21/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

enum Page {
    case edit
    case album
    case detail
}

internal class Factory {
    
    init(controller: Controller.Type, cell: UIView.Type, contents: Dictionary<AssetMediaType, AnyClass> = [:]) {
        self.controller = controller
        self.contents = [:]
        self.cell = cell
        
        // register default
        [AssetMediaType.audio, .image, .video, .unknown].forEach {
            register(nil, for: $0)
        }
        // register init
        contents.forEach {
            register($1, for: $0)
        }
    }
    
    private(set) var cell: UIView.Type
    private(set) var contents: Dictionary<String, AnyClass>
    private(set) var controller: Controller.Type
    
    func register(_ contentClass: AnyClass?, for media: AssetMediaType) {
        // update content class
        contents[ub_identifier(with: media)] = _makeClass(cell, contentClass)
    }
}

internal protocol Controller {
    
    /// Base controller craete method
    init(container: Container, factory: Factory, source: DataSource, sender: Any)
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
