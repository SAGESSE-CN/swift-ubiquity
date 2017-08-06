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


internal func ub_identifier(with media: AssetMediaType) -> String {
    switch media {
    case .image:   return "ASSET-IMAGE"
    case .audio:   return "ASSET-AUDIO"
    case .video:   return "ASSET-VIDEO"
    case .unknown: return "ASSET-UNKNOWN"
    }
}

internal func ub_image(named: String) -> UIImage? {
    return UIImage(named: named, in: _bundle, compatibleWith: nil)
}

private weak var _bundle: Bundle? = Bundle(for: Container.self)
