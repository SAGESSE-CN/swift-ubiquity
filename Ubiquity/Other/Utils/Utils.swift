//
//  Utils.swift
//  Ubiquity
//
//  Created by sagesse on 12/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


internal func ub_string(for number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.positiveFormat = "###,##0"
    return formatter.string(for: number) ?? "\(number)"
}
