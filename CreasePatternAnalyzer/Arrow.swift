//
//  Arrow.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/22/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Darwin

struct Arrow {
    let beginPoint:   PointVector
    let endPoint:     PointVector
    let controlPoint: PointVector
    let arcRadius:    Double

    var width:  Double
    var height: Double

    // The arrow will be drawn using an arc connecting `beginPoint` and
    // `endPoint` with a radius of 60º
    init(beginPoint: PointVector, endPoint: PointVector)
    {
        let vector        = endPoint - beginPoint
        self.beginPoint   = beginPoint
        self.endPoint     = endPoint
        self.arcRadius    = vector.magnitude
        self.controlPoint = ((beginPoint + endPoint)
                          + vector.rotatedBy90()/sqrt(3))/2
        let minPaperDimension = min(main.paper.width, main.paper.height)
        if arcRadius < minPaperDimension/6.0 {
            width = arcRadius/6.0
        }
        else {
            width  = 0.045*minPaperDimension
        }
        height = 1.6*width;
    }

    func arrowheadPoints() -> [PointVector] {
        let tangent   = (controlPoint - endPoint).normalized()
        let normal    = tangent.rotatedBy90()*width/2
        let basePoint = endPoint  + tangent*height
        let point1    = basePoint + normal
        let point2    = basePoint - normal
        return [point1, point2, endPoint]
    }

    func arrowtailPoints() -> [PointVector] {
        let tangent   = (controlPoint - beginPoint).normalized()
        let normal    = tangent.rotatedBy90()*width/2
        let basePoint = beginPoint + tangent*height
        let point1    = basePoint  + normal
        let point2    = basePoint  - normal
        return [point1, point2, beginPoint]
    }
}
