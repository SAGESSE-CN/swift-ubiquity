//
//  Factory.swift
//  Ubiquity
//
//  Created by sagesse on 21/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

public enum ControllerType {
    
    case albums
    case albumsList
    
    case popover
    
    case detail
}

public class Factory: NSObject {
    
    public init(controller: Controller.Type) {
        self.controller = controller
        super.init()
    }
    
    public func `class`(for key: String) -> AnyClass? {
        // Use KVC get member properties
        return value(forKey: key) as? AnyClass
    }
    
    public func `mapping`(for key: String) -> Dictionary<String, AnyClass> {
        return `class`(for: key).map { cls in
            var result = Dictionary<String, AnyClass>()
            _contents.forEach {
                result[$0] = _makeClass(cls, $1)
            }
            return result
        } ?? [:]
    }
    
    public func register(_ contentClass: AnyClass?, for identifier: String) {
        // update content class
        _contents[identifier] = contentClass
    }
    
    public func instantiateViewController(with container: Container, source: Source, parameter: Any?) -> UIViewController? {
        // ...
        return controller.init(container: container, source: source, factory: self, parameter: parameter) as? UIViewController
    }

    public var controller: Controller.Type
    
    dynamic var cell: AnyClass?
    dynamic var layout: AnyClass?
    
    private var _contents: Dictionary<String, AnyClass?> = [:]
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
