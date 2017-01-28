//
//  NSBezierPath+CGPath.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 1/20/17.
//  Copyright © 2017 Kijjakarn Praditukrit. All rights reserved.

//  This extension is a direct translation from https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Paths/Paths.html#//apple_ref/doc/uid/TP40003290-CH206-SW2

import Cocoa

extension NSBezierPath {
    var cgPath: CGPath? {
        var path: CGMutablePath? = nil
        let numElements = elementCount
        if numElements > 0 {
            path = CGMutablePath.init()
            let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
            var didClosePath = true
            for i in 0..<numElements {
                switch element(at: i, associatedPoints: points) {
                case .moveToBezierPathElement:
                    path?.move(to: CGPoint(x: points[0].x, y: points[0].y))
                case .lineToBezierPathElement:
                    path?.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
                    didClosePath = false
                case .curveToBezierPathElement:
                    path?.addCurve(to: CGPoint(x: points[0].x, y: points[0].y),
                             control1: CGPoint(x: points[1].x, y: points[1].y),
                             control2: CGPoint(x: points[2].x, y: points[2].y))
                    didClosePath = false
                case .closePathBezierPathElement:
                    path?.closeSubpath()
                    didClosePath = true
                }
            }
            if !didClosePath {
                path?.closeSubpath()
            }
        }
        return path
    }
}
