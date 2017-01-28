//
//  Diagram.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/22/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

struct Diagram {
    var rank    = 0
    var fold:     LineReference!
    var creases = [LineReference]()
    var points  = [PointReference]()
    var lines   = [LineReference]()
    var arrows  = [Arrow]()
    var bounds  = NSRect()
}
