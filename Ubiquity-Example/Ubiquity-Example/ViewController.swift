//
//  ViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
@testable import Ubiquity
//import Ubiquity

//import WebKit

class ViewController: UITableViewController, UIActionSheetDelegate, Ubiquity.PickerDelegate {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Debugger.toolsDebugColorViewBounds = true
    }
    
    @IBAction func show(_ sender: Any) {
        //browse(sender)
        pick(sender)
    }
    
    @IBAction func browse(_ sender: Any) {
        
        let browser = Ubiquity.Browser(library: Ubiquity.SystemLibrary())
        
        // configure
        browser.allowsCollectionTypes = [.regular]
        
        // display
        present(browser.initialViewController(with: .albumsList), animated: true, completion: nil)
    }
    
    @IBAction func pick(_ sender: Any) {
        
        let picker = Ubiquity.Picker(library: Ubiquity.SystemLibrary())
        
        // configure
        picker.delegate = self
        picker.allowsCollectionTypes = [.regular]
        
        // display
        present(picker.initialViewController(with: .albumsList), animated: true, completion: nil)
    }
    
    
    func picker(_ picker: Picker, shouldSelectItem asset: Asset) -> Bool {
        // the asset should selected
        return true
    }
    
    func picker(_ picker: Picker, didSelectItem asset: Asset) {
        // the asset did selected
    }
    
    func picker(_ picker: Picker, didDeselectItem asset: Asset) {
        // the asset did deselected
    }
}

