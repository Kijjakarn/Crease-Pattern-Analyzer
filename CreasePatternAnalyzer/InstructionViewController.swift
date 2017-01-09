//
//  InstructionViewController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/23/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

@objc
protocol InstructionViewControllerDelegate: class {
}

class InstructionViewController: NSViewController {
    override var nibName: String? {
        return "InstructionViewController"
    }

    dynamic weak var delegate: InstructionViewControllerDelegate!

    dynamic var enableNextButton = false
    dynamic var enablePreviousButton = false

    var viewNumber: Int = 0 {
        didSet {
            if (viewNumber == 0) {
                enablePreviousButton = false
            }
            else if (viewNumber == main.diagrams.count - 1) {
                enableNextButton = false
            }
            else {
                enablePreviousButton = true
                enableNextButton = true
            }
            CATransaction.commit()
            if main.diagrams.isEmpty {
                return
            }
            diagramView.diagram = main.diagrams[viewNumber]
            instruction.stringValue = main.instructions[viewNumber]
            diagramView.needsDisplay = true
        }
    }

    @IBOutlet weak var diagramView:    DiagramView!
    @IBOutlet weak var instruction:    NSTextField!
    @IBOutlet weak var nextButton:     NSButton!
    @IBOutlet weak var previousButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update instruction views when the find point button is clicked
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(InstructionViewController.updateViews(_:)),
            name: NSNotification.Name("FindPoint"),
            object: nil
        )
        diagramView.delegate = parent as! DiagramViewDelegate
    }

    @IBAction
    func showPrevious(_ sender: NSButton) {
        viewNumber -= 1
    }

    @IBAction
    func showNext(_ sender: NSButton) {
        viewNumber += 1
    }

    @objc func updateViews(_ note: NSNotification) {
        enableNextButton = true
        viewNumber = 0
    }
}
