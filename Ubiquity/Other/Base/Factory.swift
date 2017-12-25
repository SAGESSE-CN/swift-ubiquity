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
    
    public enum Key: String {
        case cell
        case view
        case layout
        case controller
    }
    
    public class Slice: Logport {
        
        /// Create a class factory slice instance.
        public init(factory: Factory, key: Key) {
            self.factory = factory
            self.key = key
        }
        
        /// The slice for key.
        public let key: Key
        /// The slice of factory.
        public unowned let factory: Factory
        
        /// Registered a new class for predicat in slice.
        public func register(_ newClass: AnyClass?, for format: String) {
            _registedClasss[format] = newClass
            _resistedPredicates[format] = newClass.map { _ in
                (format, _weight(format), _predicate(format))
            }
        }
        
        /// Iterate through all the registered predicate.
        public func forEach(_ closure: ((identifier: String, `class`: AnyClass)) -> ()) {
            // The superclass must has be exists.
            guard let superclass = factory.class(for: key) else {
                return
            }
            
            // Register a base class.
            closure((_identifier(), superclass))
            
            // Register a cluster class.
            _registedClasss.forEach {
                closure((_identifier($0), _synthetize(superclass, $1)))
            }
        }
        
        /// Match a format with identifier.
        public func matching(_ identifier: String) -> String {
            // Start matching from the highest weight.
            let values = _resistedPredicates.values.sorted {
                return $0.1 > $1.1
            }
            
            // Using predicates to match.
            guard let matching = values.first(where: { $2.evaluate(with: identifier) }) else {
                return _identifier() // use base identifier
            }
            
            return _identifier(matching.0)
        }
        
        // Generate the  identifier with predicate.
        private func _identifier(_ format: String? = nil) -> String {
            let base = "factory.\(key)"
            
            guard let format = format else {
                return base
            }
            
            return "\(base).\(format)"
        }
        
        /// Create a predicate.
        private func _predicate(_ format: String) -> NSPredicate {
            return NSPredicate(format: "SELF LIKE [C] '\(format)'")
        }
        
        /// Calculate weight of the predicate.
        private func _weight(_ format: String) -> Double {
            
            // The weight of preferences:
            //   extra > other > sigle > any
            let any = 0.0 // matching any character
            let other = 1.0 // matching the specified characters
            let single = 0.8 // matching one any character
            let extra = 4.0 // matching continuous characters, extra weight
            
            let weight = format.reduce((0.0, 0.0)){
                switch $1 {
                case "*":
                    return ($0.0 + any + max($0.1 - extra, 0), 0)
                    
                case "?":
                    return ($0.0 + single + max($0.1 - extra, 0), 0)
                    
                default:
                    return ($0.0 + other, $0.1 + extra)
                }
            }
            
            return weight.0 + max(weight.1 - extra, 0)
        }
        
        /// With `conetntClass` generates a new class
        private func _synthetize(_ superclass: AnyClass, _ specifiedClass: AnyClass) -> AnyClass {
            // If the class has been registered, ignore
            let newClassName = "\(NSStringFromClass(superclass))<\(NSStringFromClass(specifiedClass))>"
            if let newClass = objc_getClass(newClassName) as? AnyClass {
                return newClass
            }
            
            // If you have not registered this, dynamically generate it
            guard let newClass = objc_allocateClassPair(superclass, newClassName, 0) else {
                return superclass // Generate a new class failure.
            }
            logger.debug?.write("Make class \"\(NSStringFromClass(newClass))\" king of \"\(NSStringFromClass(superclass))\"")

            // Registered the class with the system.
            objc_registerClassPair(newClass)
            
            // Because it is a class method, it can not used class, need to use meta class
            guard let metaClass = objc_getMetaClass(newClassName) as? AnyClass else {
                return newClass
            }

            let selector = Selector(String("contentViewClass"))
            let getter: @convention(block) () -> AnyClass = {
                 return specifiedClass
            }
            
            
            // Rewrite the class method.
            class_getClassMethod(superclass, selector).ub_map {
               class_addMethod(metaClass, selector, imp_implementationWithBlock(unsafeBitCast(getter, to: AnyObject.self)), method_getTypeEncoding($0))
            }

            return newClass
        }

        
        private var _registedClasss: [String: AnyClass] = [:]
        private var _resistedPredicates: [String: (String, Double, NSPredicate)] = [:]
    }

    /// Configure the class factory with closure.
    public func configure(_ closure: (Factory) -> ()) {
        closure(self)
    }
    
    /// Set a class for key.
    public func setClass(_ newClass: AnyClass?, for key: Key) {
        return _registedClasss[key] = newClass
    }
    /// Set a class in cluster class with matching for key.
    public func setClass(_ newClass: AnyClass?, matching predicate: String, for key: Key) {
        // Lazy loading the slize for key.
        let slice = self.slice(for: key)
        
        // Registered a new class for predicat in slice.
        slice.register(newClass, for: predicate)
    }
    
    public func `class`(for key: Key) -> AnyClass? {
        return _registedClasss[key]
    }
    public func `slice`(for key: Key) -> Slice {
        return _registedFactorySlices[key].ub_coalescing {
            // Create a new slice.
            let slice = Slice(factory: self, key: key)
            
            _registedFactorySlices[key] = slice
            
            return slice
        }
    }
    
    public func instantiateViewController(with container: Container, source: Source, parameter: Any?) -> UIViewController? {
        // Read the currently registered controller class.
        guard let controllerType = `class`(for: .controller) as? Controller.Type else {
            return nil
        }
        
        // Try to create a controller instance with controllerType.
        guard let controller = controllerType.init(container: container, source: source, factory: self, parameter: parameter) as? UIViewController else {
            return nil
        }
        
        return controller
    }

    private lazy var _registedClasss: [Key: AnyClass] = [:]
    private lazy var _registedFactorySlices: [Key: Slice] = [:]
}




