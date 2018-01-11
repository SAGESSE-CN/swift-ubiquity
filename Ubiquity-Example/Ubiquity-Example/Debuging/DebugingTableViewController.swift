//
//  DebugingTableViewController.swift
//  Ubiquity-Example
//
//  Created by SAGESSE on 11/23/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

class DebugingTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: "Pop", style: .done, target: nil, action: nil)
        
        ProcessInfo.processInfo.environment["XPCDebugger"].map {
            XPCDebugger.shared.connect(to: $0)
        }
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
