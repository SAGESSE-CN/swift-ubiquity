//
//  ViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
#if DEBUG
    @testable import Ubiquity
#else
    import Ubiquity
#endif

//import WebKit

class ViewController: UIViewController, Ubiquity.PickerDelegate, UIPopoverPresentationControllerDelegate {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .init("test"), object: nil, queue: nil) { [logger] in
            logger.debug?.write($0.object ?? "")
        }

        #if DEBUG
            UIApplication.shared.delegate?.window??.showsFPS = true
        #endif
    }
    
    @IBOutlet weak var type: UISegmentedControl!
    @IBOutlet weak var style: UISegmentedControl!
    @IBOutlet weak var page: UISegmentedControl!
    
    @IBOutlet weak var allowsEditing: UISwitch!
    @IBOutlet weak var allowsSelection: UISwitch!
    @IBOutlet weak var allowsMultipleSelection: UISwitch!
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirm(_ sender: Any) {
        
        let library: Library
        let container: Container
        let controller: UIViewController
        
        library = Ubiquity.UHAssetLibrary()
        
        // create an image browser
        switch type.selectedSegmentIndex {
        case 1:
            let picker = Ubiquity.Picker(library: library)
            picker.delegate = self
            picker.allowsSelection = allowsSelection.isOn
            picker.allowsMultipleSelection = allowsMultipleSelection.isOn
            container = picker

        default:
            let browser = Ubiquity.Browser(library: library)
            container = browser
        }
        
        // create an view controller for albums
        switch page.selectedSegmentIndex {
        case 0: // albums
            //controller = container.instantiateViewController(with: .albumsList, source: .init(collectionType: .regular))
            //controller = container.instantiateViewController(with: .albumsList, source: .init(collectionType: .moment))
            controller = container.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.moment, .regular]))
            //controller = container.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.moment, .regular, .recentlyAdded]))
            //controller = container.instantiateViewController(with: .albumsList, source: .init(collectionType: .regular))
            //controller = container.instantiateViewController(with: .albumsList, source: .init(collectionType: .regular, filter: { $0.offset == 0 }))
            //controller = container.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.regular, .moment], filter: { $0.offset == 0 }))
            //controller = container.instantiateViewController(with: .albumsList, source: .init(collection: browser.request(forCollectionList: .regular).ub_collection(at: 0)))
            
        case 1: // moment
            //controller = container.instantiateViewController(with: .albums, source: .init(collectionType: .regular))
            controller = container.instantiateViewController(with: .albums, source: .init(collectionType: .moment))
            //controller = container.instantiateViewController(with: .albums, source: .init(collectionTypes: [.moment, .regular, .recentlyAdded]))
            //controller = container.instantiateViewController(with: .albums, source: .init(collectionType: .regular, filter: { $0.offset == 0 }))
            
        case 2: // recently
            //controller = container.instantiateViewController(with: .popover, source: .init(collectionType: .recentlyAdded))
            //controller = container.instantiateViewController(with: .popover, source: .init(collectionType: .regular, filter: { $0.offset == 0 }))
            controller = container.instantiateViewController(with: .popover, source: .init(collectionType: .moment))

            
        default:
            controller = container.instantiateViewController(with: .albums, source: .init(collectionType: .regular, filter: { (offset, collection) in
                return collection.ub_collectionSubtype == .smartAlbumFavorites
            }))
        }
        
        // display controller
        switch style.selectedSegmentIndex {
        case 0:
            controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(cancel(_:)))
            present(controller, animated: true, completion: nil)

        case 1:
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: nil, action: nil)
            show(controller, sender: nil)

        default:
            controller.preferredContentSize = .init(width: view.frame.width, height: 160)
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            controller.popoverPresentationController?.delegate = self

            present(controller, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
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

