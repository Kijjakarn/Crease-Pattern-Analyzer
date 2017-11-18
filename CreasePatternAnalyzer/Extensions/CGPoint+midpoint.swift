//
//  CGPoint+midpoint.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 1/27/17.
//  Copyright © 2017 Kijjakarn Praditukrit. All rights reserved.
//

import Foundation

extension CGPoint {
    static func getPoint(ratio: CGFloat,
                        point1: CGPoint,
                        point2: CGPoint) -> CGPoint {
        return CGPoint(
            x: ratio*point1.x + (1 - ratio)*point2.x,
            y: ratio*point1.y + (1 - ratio)*point2.y
        )
    }
}
