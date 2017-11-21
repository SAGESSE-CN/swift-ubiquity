//
//  BadgeView.swift
//  Ubiquity
//
//  Created by SAGESSE on 4/18/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal enum BadgeItem: Equatable {
    
    /// A badge item of image
    case image(UIImage?)
    
    /// A badge item of text
    case text(String)
    
    /// A identifier of badge item
    var identifier: String {
        switch self {
        case .image: return "Image"
        case .text: return "Text"
        }
    }
    
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    static func ==(lhs: BadgeItem, rhs: BadgeItem) -> Bool {
        switch (lhs, rhs) {
        case (.image(let lhs),
              .image(let rhs)):
            return lhs == rhs

        case (.text(let lhs),
              .text(let rhs)):
            return lhs == rhs
            
        default:
            return false
        }
    }
}

internal class BadgeView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _configure()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _configure()
    }
    
    var leftItem: BadgeItem? {
        set { return leftItems = newValue.map({ [$0] }) }
        get { return leftItems?.first }
    }
    var leftItems: Array<BadgeItem>? {
        set {
            let oldValue = _leftItems
            _leftItems = newValue ?? []
            // no need update, check it any change
            guard !_needUpdateVisableViews && !oldValue.elementsEqual(_leftItems) else {
                return
            }
            _needUpdateVisableViews = true
            setNeedsLayout()
        }
        get {
            return _leftItems
        }
    }
    
    var rightItem: BadgeItem? {
        set { return rightItems = newValue.map({ [$0] }) }
        get { return rightItems?.first }
    }
    var rightItems: Array<BadgeItem>? {
        set {
            let oldValue = _rightItems
            _rightItems = newValue ?? []
            // no need update, check it any change
            guard !_needUpdateVisableViews && !oldValue.elementsEqual(_rightItems) else {
                return
            }
            _needUpdateVisableViews = true
            setNeedsLayout()
        }
        get {
            return _rightItems
        }
    }
    
    var backgroundImage: UIImage? {
        didSet {
            guard oldValue !== backgroundImage else {
                return
            }
            _updateBackgroundImage()
        }
    }
    
    /// For each reuse identifier that the view will use, register either a class from which to instantiate a cell.
    /// If a class is registered, it will be instantiated via init(frame:)
    func register(_ cellClass: Swift.AnyClass?, forViewWithReuseIdentifier identifier: String) {
        _reusequeueClasses[identifier] = cellClass
    }
    
    /// Returns a reusable cell object located by its identifier
    func dequeueReusableView(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UIView {
        // Priority to the use of view that has been created
        if let reuseableView = _reusequeueViews[identifier]?.last {
            _reusequeueViews[identifier]?.removeLast()
            return reuseableView
        }
        // Craete view
        if let type = _reusequeueClasses[identifier] as? UIView.Type {
            let newView = type.init(frame: .zero)
            (newView as? BadgeItemView)?.identifier = identifier
            (newView as? BadgeItemView)?.prepare()
            return newView
        }
        fatalError("Unknow")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        _updateVisableViewsIfNeeded()
        _updateVisableViewLayoutIfNeeded()
    }
    
    private func _updateBackgroundImage() {
        layer.contents = backgroundImage?.cgImage
    }

    private func _updateVisableViewsIfNeeded() {
        // need update visable view?
        guard _needUpdateVisableViews else {
            return
        }
        _needUpdateVisableViews = false
        
        // Put all the view in the display to the reuse queue
        _visableViews.forEach {
            $0.forEach { view in
                guard let identifier = (view as? BadgeItemView)?.identifier else {
                    return
                }
                
                // end display
                view.isHidden = true
                
                // add to reuse queue
                _reusequeueViews[identifier]?.append(view) ?? {
                    _reusequeueViews[identifier] = [view]
                }()
            }
        }
        
        // Display all items
        _visableViews = [_leftItems, _rightItems].enumerated().map { section, elements in
            return elements.enumerated().map {
                let view = dequeueReusableView(withReuseIdentifier: $1.identifier, for: .init(item: $0, section: section))
                
                // configure data
                if let view = view as? BadgeItemView {
                    view.apply($1)
                }
                
                view.isHidden = false
                if view.superview == nil {
                    addSubview(view )
                }
                
                return view
            }
        }
        
        // Clear unnecessary items, keep only three view for identifier
        _reusequeueViews.keys.forEach {
            _reusequeueViews[$0] = _reusequeueViews[$0].map {
                // there's too much view left
                guard $0.count > 3 else {
                    return $0
                }
                $0[4 ..< $0.count].forEach {
                    $0.removeFromSuperview()
                }

                return .init($0[0 ..< 4])
            }
        }
        
        _cacheBounds = nil
    }
    private func _updateVisableViewLayoutIfNeeded() {
        // need update visable view layout?
        guard _cacheBounds?.size != self.bounds.size else {
            return
        }
        _cacheBounds = self.bounds
        
        let bounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(2, 4, 2, 4))
        let spacing = CGFloat(2)
        
        var offset = [bounds.minX, bounds.maxX]

        _visableViews.enumerated().forEach { section, elements in
            elements.forEach {
                
                let size = $0.sizeThatFits(bounds.size)
                
                let width = size.width
                let height = min(size.height, bounds.height)
                
                var rwidth = width
                var rspacing = spacing
                
                if section != 0 {
                    rwidth = -rwidth
                    rspacing = -rspacing
                }
                
                $0.frame = .init(x: (offset[section] + min(rwidth, 0)),
                                 y: (bounds.height - height) / 2,
                                 width: width,
                                 height: height)
                
                offset[section] += rwidth + rspacing
            }
        }
    }
    
    private func _configure() {
        
        register(BadgeItemTextView.self, forViewWithReuseIdentifier: "Text")
        register(BadgeItemImageView.self, forViewWithReuseIdentifier: "Image")
        
        //_updateBackgroundImage()
        _needUpdateVisableViews = true
    }
    
    // MARK: Ivar
    
    private var _cacheBounds: CGRect?
    private var _needUpdateVisableViews: Bool = true
    
    private lazy var _leftItems: [BadgeItem] = []
    private lazy var _rightItems: [BadgeItem] = []
    
    private lazy var _visableViews: [[UIView]] = []
    
    private lazy var _reusequeueViews: [String: [UIView]] = [:]
    private lazy var _reusequeueClasses: [String: AnyClass] = [:]
}

internal protocol BadgeItemView: class  {
    
    /// View reuse identifier
    var identifier: String? { set get }
    
    /// Prepare display
    func prepare()
    
    /// Display with badge item.
    func apply(_ item: BadgeItem)
    
}

internal class BadgeItemTextView: UILabel, BadgeItemView {
    
    /// View reuse identifier
    var identifier: String?
    
    /// Prepare display
    func prepare() {
        
        font = .systemFont(ofSize: 12)
        textColor = tintColor
        //adjustsFontSizeToFitWidth = true
    }

    /// Display with badge item.
    func apply(_ item: BadgeItem) {
        switch item {
        case .image:
            text = nil

        case .text(let contents):
            text = contents
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.textColor = tintColor
    }
}
internal class BadgeItemImageView: UIImageView, BadgeItemView {
    
    /// View reuse identifier
    var identifier: String?

    /// Prepare display
    func prepare() {
        
        contentMode = .center
    }
    
    /// Display with badge item.
    func apply(_ item: BadgeItem) {
        switch item {
        case .image(let contents):
            image = contents
        
        case .text:
            image = nil
        }
    }
}

extension BadgeView {
    static var ub_backgroundImage: UIImage? {
        if let image = __backgroundImage {
            return image
        }
        logger.debug?.write("load `ubiquity_background_gradient`")
        let image = ub_image(named: "ubiquity_background_gradient")
        __backgroundImage = image
        return image
    }
}

private weak var __backgroundImage: UIImage?

