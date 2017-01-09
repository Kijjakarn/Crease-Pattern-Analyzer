//
//  PointViewController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

let numberFormat = "%.5f"

@objc
protocol PointViewControllerDelegate: class {
    func emptyInstructions()
    func updateDiagram()
}

class PointViewController: NSViewController {
    override var nibName: String? {
        return "PointViewController"
    }

    dynamic weak var delegate: PointViewControllerDelegate!

    var x: Double = 0 {
        willSet {
            xString = String(format: numberFormat, newValue)
        }
    }

    var y: Double = 0 {
        willSet {
            yString = String(format: numberFormat, newValue)
        }
    }

    let initializationQueue =
        (NSApplication.shared().delegate as! AppDelegate).initializationQueue

    // Variables for enabling/disabling the findPoint button
    dynamic var isXValid = false
    dynamic var isYValid = false

    dynamic var foundPoints = [PointReference]()

    dynamic var xString = ""
    dynamic var yString = ""

    @IBOutlet weak var xInput:          NSTextField!
    @IBOutlet weak var yInput:          NSTextField!
    @IBOutlet weak var errorMessage:    NSTextField!
    @IBOutlet weak var findPointButton: NSButton!
    @IBOutlet weak var arrayController: NSArrayController!
    @IBOutlet weak var tableView:       NSTableView!

    @IBAction
    func updateX(_ sender: NSTextField) {
        let parsedX = Parser.parsedString(from: xInput.stringValue)
        if parsedX.success {
            validate(x: parsedX.value)
            delegate.updateDiagram()
        }
        else {
            isXValid = false
            xString = ""
            errorMessage.stringValue = parsedX.string
        }
    }

    @IBAction
    func updateY(_ sender: NSTextField) {
        let parsedY = Parser.parsedString(from: yInput.stringValue)
        if parsedY.success {
            validate(y: parsedY.value)
            delegate.updateDiagram()
        }
        else {
            isYValid = false
            yString = ""
            errorMessage.stringValue = parsedY.string
        }
    }

    func validate(x: Double) {
        if main.paper.encloses(x: x) {
            self.x = x
            isXValid = true
            errorMessage.stringValue = ""
        }
        else {
            isXValid = false
            xString = ""
            errorMessage.stringValue = "The x-coordinate is out of bounds"
        }
    }

    func validate(y: Double) {
        if main.paper.encloses(y: y) {
            self.y = y
            isYValid = true
            errorMessage.stringValue = ""
        }
        else {
            isYValid = false
            yString = ""
            errorMessage.stringValue = "The y-coordinate is out of bounds"
        }
    }

    func clearX() {
        xInput.stringValue = ""
        xString = ""
    }

    func clearY() {
        yInput.stringValue = ""
        yString = ""
    }

    @IBAction
    func findPoint(_ sender: NSButton) {
        foundPoints = matchedPoints(for: PointVector(x, y))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        arrayController.addObserver(
            self,
            forKeyPath: #keyPath(NSArrayController.selectionIndex),
            context: nil
        )
    }

    override func observeValue(forKeyPath keyPath: String?,
                                        of object: Any?,
                                           change: [NSKeyValueChangeKey : Any]?,
                                          context: UnsafeMutableRawPointer?) {
        if keyPath == "selectionIndex" {
            clearInstructions()
            let index = arrayController.selectionIndex
            let solutions = arrayController.arrangedObjects as! [PointReference]
            if 0 <= index && index < solutions.count {
                _ = makeInstructions(for: solutions[index])

                // The point alrady exists on the paper
                // (it is one of the corners)
                if main.diagrams.count == 0 {
                    main.diagrams.append(Diagram())
                    main.instructions.append("")
                }
                else {
                    coalesceInstructions()
                }
                NotificationCenter.default.post(
                    name: NSNotification.Name("FindPoint"),
                    object: self
                )
            }
            else {
                delegate.emptyInstructions()
            }
        }
    }
}
