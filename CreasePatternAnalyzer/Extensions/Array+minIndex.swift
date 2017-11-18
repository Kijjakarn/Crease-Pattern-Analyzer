//
//  Array+minIndex.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 1/27/17.
//  Copyright © 2017 Kijjakarn Praditukrit. All rights reserved.
//

import Foundation

extension Array where Element: Comparable {
    func minIndex() -> Int? {
        if self.count < 1 {
            return nil
        }
        var minIndex = 0
        var minValue = self[0]
        for i in 0..<(count - 1) {
            if self[i] < minValue {
                minIndex = i
                minValue = self[i]
            }
        }
        return minIndex
    }
}
