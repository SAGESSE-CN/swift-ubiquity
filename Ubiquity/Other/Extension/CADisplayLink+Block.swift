//
//  CADisplayLink+Block.swift
//  Ubiquity
//
//  Created by sagesse on 27/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


internal extension CADisplayLink {
    // a forwarder
    private class Forwarder: NSObject {
        // make a forwarder
        init(block: @escaping (CADisplayLink) -> ()) {
            self.block = block
        }
        
        // forward
        func tick(_ sender: CADisplayLink) {
            block(sender)
        }
        
        var block: (CADisplayLink) -> ()
    }
    
    /// Returns a new display link.
    convenience init(block: @escaping (CADisplayLink) -> ()) {
        // forward to block
        self.init(target: Forwarder(block: block), selector: #selector(Forwarder.tick(_:)))
    }
}
