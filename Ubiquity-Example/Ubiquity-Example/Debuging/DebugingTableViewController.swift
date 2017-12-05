//
//  DebugingTableViewController.swift
//  Ubiquity-Example
//
//  Created by SAGESSE on 11/23/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

@objc protocol DebugingRemoteDelegate {
    // ..
    func debugger(_ server: Shared, remote: Shared, didRecive data: Any?)
}

extension UIViewController: DebugingRemoteDelegate {
    func debugger(_ server: Shared, remote: Shared, didRecive data: Any?) {
        childViewControllers.forEach {
            $0.debugger(server, remote: remote, didRecive: data)
        }
    }
}

class DebugingTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        view.accessibilityLabel = "Server"
        view.accessibilityValue = _shared.address.base64EncodedString()
        
        _shared.recive { [weak self] c, d in
            self.map {
                $0.navigationController?.debugger($0._shared, remote: c, didRecive: d)
            }
        }
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    private lazy var _shared: Shared = .listen("127.0.0.1")
}
