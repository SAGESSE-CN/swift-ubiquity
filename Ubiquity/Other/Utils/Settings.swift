//
//  Settings.swift
//  Ubiquity
//
//  Created by sagesse on 22/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

public class Settings: NSObject {
    /// Default settings
    public static let `default`: Settings = Settings()
    
    // Minimum interval between each item allowed
    public var minimumItemSpacing: CGFloat = 2
    
    // Minimum size of each item allowed
    public var minimumItemSize: CGSize = .init(width: 78, height: 78)
 
    
    /// 
    public var contentViewColor: UIColor = #colorLiteral(red: 0.9411764706, green: 0.937254902, blue: 0.9607843137, alpha: 1)


    
    public var thumbViewEmptyImage: UIImage?
    public var thumbViewBackgroundColor: UIColor?
}
