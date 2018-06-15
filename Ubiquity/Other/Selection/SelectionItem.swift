//
//  SelectionItem.swift
//  Ubiquity
//
//  Created by sagesse on 07/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


internal enum SelectionItemStyle {
    /// Only display image.
    case image
    
    /// Only display number.
    case number
    
    /// On 0-99 is display number, others display image.
    case auto
}

internal class SelectionItem {
    
    /// Generate a selection item
    init(asset: Asset, number: Int = 1) {
        self.asset = asset
        self.number = number
    }
    
    /// The current associated asset.
    let asset: Asset
    
    /// Display number mode.
    var mode: SelectionItemStyle = .auto
    
    // explicit
    // inexplicit
    
    /// The current selected index.
    var number: Int {
        didSet {
            // has any change?
            guard oldValue != number else {
                return
            }
            
            // notifity all observers
            notify()
        }
    }
    
    /// Notify observer.
    func notify() {
//        _observers.forEach {
//            $0.update(number, mode: mode, animated: false)
//        }
    }
    
    /// Add observer, must call remove(_:) method, not observer, are retained.
    func add(_ observer: SelectionItemView) {
        _observers.insert(observer)
    }
    
    /// Remove observer.
    func remove(_ observer: SelectionItemView) {
        _observers.remove(observer)
    }
    
    // The reason for this design is the efficiency of optimization
    private lazy var _observers: WSet<SelectionItemView> = []
}

internal class SelectionItem2: Logport {
    
    init(_ asset: Asset, index: Int = -1) {
        self.asset = asset
        self.timestamp = .init(CACurrentMediaTime())
        self.index = index
    }
    
    let asset: Asset
    let timestamp: TimeInterval
    
    var index: Int = 0
    
//    var asset: Asset?
//    weak var picker: Picker?
//
//    var selected: Bool = false
//
//
//    func select(_ animated: Bool = true) {
//        logger.trace?.write()
//    }
//
//    func deselect(_ animated: Bool = true) {
//        logger.trace?.write()
//    }
//
//
//    func update(_ selected: Bool, at index: Int) {
//
//    }
//
//    func connect(_ asset: Asset, in picker: Picker) {
//
//        self.asset = asset
//        self.picker = picker
//
////        picker.selectionController.addObserver(self)
////        let i = picker.selectionController.contains(asset)
//    }
    
}


internal class SelectionItemView: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    deinit {
        // Set to nil, clear observer
//        self.update(nil, animated: false)
    }
    
    
    var asset: Asset?
    
    // Get current status.
    var selectionItem: SelectionItem? {
//        return _item
        return nil
    }
//
    // Update the status with animation.
    internal func update(_ item: SelectionItem?, animated: Bool) {
//        // the item is change?
//        guard _item !== item else {
//            return
//        }
//
//        // update item
//        _item?.remove(self)
//        _item = item
//        _item?.add(self)
//
//        // update select status
//        isSelected = item != nil
//
//        // update the badge number.
//        update(item?.number ?? 0, mode: item?.mode ?? .auto, animated: animated)
    }
//
//    // Update the value with animation.
//    fileprivate func update(_ value: Int, mode: SelectionItemStyle, animated: Bool) {
//        // range 0 to 99 is text mode.
//        // other is image mode.
//        if mode == .number || mode == .auto && value >= 0 && value <= 2 {
//            // clear image
//            setImage(nil, for: [.selected, .normal])
//            setImage(nil, for: [.selected, .highlighted])
//
//            // set new text
//            setTitle("\(value)", for: [.selected, .normal])
//            setTitle("\(value)", for: [.selected, .highlighted])
//
//        } else {
//            // clear text
//            setTitle("", for: [.selected, .normal])
//            setTitle("", for: [.selected, .highlighted])
//
//            // set new image
//            setImage(R.image("ubiquity_checkbox_icon"), for: [.selected, .normal])
//            setImage(R.image("ubiquity_checkbox_icon"), for: [.selected, .highlighted])
//        }
//
//        // add animation if needed
//        if animated {
//            let ani = CATransition()
//            ani.type = kCATransitionFade
//            ani.duration = 0.1
//            layer.add(ani, forKey: "change")
//        }
//    }
//
    // Configure the selection view.
    fileprivate func configure() {
        self.backgroundColor = .red
//        // Setup title label.
//        titleLabel?.font = .systemFont(ofSize: 14)
//        titleLabel?.textColor = .white
//
//        // Setup background image.
//        setBackgroundImage(R.image("ubiquity_checkbox_normal"), for: [.normal])
//        setBackgroundImage(R.image("ubiquity_checkbox_normal"), for: [.highlighted])
//        setBackgroundImage(R.image("ubiquity_checkbox_selected"), for: [.selected, .normal])
//        setBackgroundImage(R.image("ubiquity_checkbox_selected"), for: [.selected, .highlighted])
//
//        // Setup default value.
//        update(nil, animated: false)
    }
//
//
//    private var _item: SelectionItem?
}


