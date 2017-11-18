//
//  CGPath+hitTarget.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 9/7/17.
//  Copyright © 2017 Kijjakarn Praditukrit. All rights reserved.
//

import Foundation

extension CGPath {
    static var hitTargetWidth: CGFloat = 3

    var hitTarget: CGPath {
        return copy(strokingWithWidth: CGPath.hitTargetWidth,
                              lineCap: .butt,
                             lineJoin: .miter,
                           miterLimit: 0)
    }
}
