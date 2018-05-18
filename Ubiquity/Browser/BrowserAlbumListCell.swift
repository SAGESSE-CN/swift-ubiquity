//
//  BrowserAlbumListCell.swift
//  Ubiquity
//
//  Created by sagesse on 21/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumListCell: SourceCollectionViewCell {
    
    override func configure() {
        super.configure()
        
        // Setup thumb
        _thumbView.frame = .init(x: 0, y: 0, width: 70, height: 70)
        _thumbView.backgroundColor = .white
        _thumbView.translatesAutoresizingMaskIntoConstraints = false
        _thumbView.addSubview(_badgeView)

        // Setup badge
        _badgeView.frame = UIEdgeInsetsInsetRect(_thumbView.bounds, UIEdgeInsetsMake(_thumbView.bounds.height - 24, 0.5, 0.5, 0.5))
        _badgeView.tintColor = .white
        _badgeView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        // Setup title
        _titleLabel.font = .preferredFont(forTextStyle: .body)
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup subtitle label
        _subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup indicator image view.
        _indicatorImageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        _indicatorImageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        _indicatorImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(_thumbView)
        contentView.addSubview(_titleLabel)
        contentView.addSubview(_subtitleLabel)
        contentView.addSubview(_indicatorImageView)

        // Add constraints
        contentView.addConstraints([
            
            .ub_make(_thumbView, .leading, .equal, contentView, .leadingMargin, 8),
            .ub_make(_thumbView, .centerY, .equal, contentView, .centerY),
            
            .ub_make(_thumbView, .width, .equal, nil, .notAnAttribute, 70),
            .ub_make(_thumbView, .height, .equal, nil, .notAnAttribute, 70),
            
            .ub_make(_titleLabel, .bottom, .equal, contentView, .centerY, -2),
            .ub_make(_titleLabel, .leading, .equal, _thumbView, .trailing, 8),
            .ub_make(_titleLabel, .trailing, .equal, _indicatorImageView, .leading, -8),
            
            .ub_make(_subtitleLabel, .top, .equal, contentView, .centerY, 2),
            .ub_make(_subtitleLabel, .leading, .equal, _thumbView, .trailing, 8),
            .ub_make(_subtitleLabel, .trailing, .equal, _indicatorImageView, .leading, -8),
            
            .ub_make(_indicatorImageView, .trailing, .equal, contentView, .trailingMargin, -8),
            .ub_make(_indicatorImageView, .centerY, .equal, contentView, .centerY),
        ])
        
        isAccessibilityElement = false
    }
    
    /// Will display the collection
    override func willDisplay(_ container: Container, orientation: UIImageOrientation) {
        super.willDisplay(container, orientation: orientation)
        
        // Only processing collection data.
        guard let collection = collection else {
            return
        }
        
        // save context
        _collection = collection
        
        let count = collection.ub_count
        let assets = (max(count - 3, 0) ..< count).flatMap { collection.ub_asset(at: $0) }
        
        // setup content
        _titleLabel.text = collection.ub_title
        _subtitleLabel.text = ub_string(for: count)
        
        // setup badge icon & background
        if let icon = BadgeItem(subtype: collection.ub_collectionSubtype) {
            // show icon
            _badgeView.leftItem = icon
            _badgeView.backgroundImage = BadgeView.defaultBackgroundImage
            
        } else {
            // hide icon
            _badgeView.leftItem = nil
            _badgeView.backgroundImage = nil
        }
        
        // make options
        let size = _thumbView.bounds.size.ub_fitWithScreen
        let options = RequestOptions()
        
        // setup thumbnail image
        _thumbView.setImages(assets.map { _ in nil },
                             animated: false)
        _requests = assets.reversed().enumerated().flatMap { offset, asset in
            // request thumbnail image
            container.library.ub_request(forImage: asset, targetSize: size, contentMode: .aspectFill, options: options) { [weak self, weak collection] contents, response in
                // if the asset is nil, the asset has been released
                guard let collection = collection else {
                    return
                }
                // update thumbnail image
                self?._updateContents(contents, collection: collection, at: offset)
            }
        }
    }
    /// End display the collection
    override func endDisplay(_ container: Container) {
        super.endDisplay(container)
        
        //logger.trace?.write(collection.ub_identifier)
        
        // when are requesting an image, please cancel it
        _requests?.forEach { request in
            // cancel
            container.library.ub_cancel(with: request)
        }
        
        // clear context
        _requests = nil
        _collection = nil
    }
    
    // update thumbnail image
    private func _updateContents(_ contents: UIImage?, collection: Collection, at index: Int) {
        // the current collection has been changed?
        guard _collection === collection else {
            // change, all reqeust is expire
            logger.debug?.write("\(collection.ub_identifier) image is expire")
            return
        }
        // no change, update content
        _thumbView.setImage(contents, at: index, animated: true)
    }

    override var isSelected: Bool {
        willSet {
            _switch(isHighlighted || newValue)
        }
    }
    override var isHighlighted: Bool {
        willSet {
            _switch(isSelected || newValue)
        }
    }
    
    override var accessibilityIdentifier: String? {
        set { return super.accessibilityIdentifier = newValue }
        get { return super.accessibilityIdentifier ?? _titleLabel.accessibilityLabel }
    }
    
    private func _switch(_ enabeld: Bool) {
        if enabeld {
            backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1977739726)
        } else {
            backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
    
    private var _collection: Collection?
    
    private var _requests: Array<Request>?
    
    private lazy var _titleLabel: UILabel = .init()
    private lazy var _subtitleLabel: UILabel = .init()
    
    private lazy var _thumbView: ThumbView = ThumbView(frame: .zero)
    private lazy var _badgeView: BadgeView = BadgeView(frame: .zero)
    
    private lazy var _indicatorImageView: UIImageView = UIImageView(image: R.image("ubiquity_button_indicator"))
}
