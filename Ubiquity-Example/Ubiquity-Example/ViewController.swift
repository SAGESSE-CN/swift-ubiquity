//
//  ViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
//@testable import Ubiquity
import Ubiquity

import WebKit

class ViewController: UITableViewController, UIActionSheetDelegate, Ubiquity.PickerDelegate {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func show(_ sender: Any) {
        //browse(sender)
        pick(sender)
    }
    
    @IBAction func browse(_ sender: Any) {
        
        let browser = Ubiquity.Browser(library: Ubiquity.SystemLibrary())
        
        // configure
        browser.allowsCollectionTypes = [.regular]
        
        //browser.register(UIView.self, for: .unknown, in: .albums)
        //browser.register(UIView.self, for: .unknown, in: .albumsList)
        //browser.register(UIView.self, for: .unknown, in: .detail)
        //browser.register(UIViewController.self, for: .albums)
        //browser.register(UIViewController.self, for: .albumsList)
        //browser.register(UIViewController.self, for: .detail)
        
        // display
        present(browser.initialViewController(with: .albumsList), animated: true, completion: nil)
    }
    
    @IBAction func pick(_ sender: Any) {
        
        let picker = Ubiquity.Picker(library: Ubiquity.SystemLibrary())
        
        // configure
        picker.delegate = self
        picker.allowsCollectionTypes = [.regular]
        
        //picker.register(UIView.self, for: .unknown, in: .albums)
        //picker.register(UIView.self, for: .unknown, in: .albumsList)
        //picker.register(UIView.self, for: .unknown, in: .detail)
        //picker.register(UIViewController.self, for: .albums)
        //picker.register(UIViewController.self, for: .albumsList)
        //picker.register(UIViewController.self, for: .detail)
        
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

