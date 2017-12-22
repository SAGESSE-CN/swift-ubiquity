//
//  Utils.swift
//  Ubiquity
//
//  Created by sagesse on 12/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal extension Optional {
    
    @inline(__always)
    internal func ub_coalescing(_ closure: () throws -> Wrapped) rethrows -> Wrapped {
        return try self ?? closure()
    }
}

internal func ub_string(for number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.positiveFormat = "###,##0"
    return formatter.string(for: number) ?? "\(number)"
}


/// generate string for date
internal func ub_string(for date: Date) -> String {
    
    let current = Date()
    let formater = DateFormatter()
    
    repeat {
        
        // in today
        if formater.calendar.isDateInToday(date) {
            return "Today"
        }
        
        // in yesterday
        if formater.calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        
        // in tomorrow
        if formater.calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        
        let day1 = trunc((date.timeIntervalSince1970 + .init(formater.timeZone.secondsFromGMT())) /  (24 * 60 * 60))
        let day2 = trunc((current.timeIntervalSince1970 + .init(formater.timeZone.secondsFromGMT())) /  (24 * 60 * 60))
        
        // in week
        if fabs(day1 - day2) < 7 {
            formater.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEE", options: 0, locale: formater.locale)
            break
        }
        
        // in year
        if formater.calendar.isDate(date, equalTo: current, toGranularity: .year) {
            formater.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM d", options: 0, locale: formater.locale)
            break
        }
        
        // other
        formater.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyy MMMM d", options: 0, locale: formater.locale)
        
    } while false
    
    return formater.string(from: date)
}

internal func ub_string(for time: TimeInterval) -> String {
    
    let formater = DateFormatter()
    
    formater.dateStyle = .none
    formater.timeStyle = .short
    
    return formater.string(from: .init(timeIntervalSince1970: time))
}

internal func ub_defaultTitle(with collectionType: CollectionType) -> String {
    switch collectionType {
    case .moment:
        return "Moments"
        
    case .regular:
        return "Photos"
        
    case .recentlyAdded:
        return "Recently"
    }
}
internal func ub_defaultTitle(with collectionTypes: [CollectionType]) -> String {
    // if there are multiple groups, only photos is displayed 
    if let first = collectionTypes.first, collectionTypes.count == 1 {
        return ub_defaultTitle(with: first)
    }
    return ub_defaultTitle(with: .regular)
}

internal func ub_image(named: String) -> UIImage? {
    return UIImage(named: named, in: _bundle, compatibleWith: nil)
}

private weak var _bundle: Bundle? = Bundle(for: Container.self)
