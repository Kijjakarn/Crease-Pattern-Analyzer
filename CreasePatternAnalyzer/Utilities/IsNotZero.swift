//
//  IsNotZero.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/24/16.
//  Copyright © 2016 Kijjakarn Praditukrit. All rights reserved.
//

import Foundation

// Return true if the passed in integer is zero
@objc(IsNotZero)
class IsNotZero: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        if value == nil {
            return false
        }
        if value as! Int != 0 {
            Swift.print("operation count: \(value as! Int)")
            return true
        }
        return false
    }
}
