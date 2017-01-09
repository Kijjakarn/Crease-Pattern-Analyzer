//
//  ConfigurationViewController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/20/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

@objc
protocol ConfigurationViewControllerDelegate: class {
    func reinitialize()
}

class TextField: NSTextField {
    override func becomeFirstResponder() -> Bool {
        let returnValue = super.becomeFirstResponder()
        (delegate as! ConfigurationViewController).isEditing = true
        stringValue = ""
        return returnValue
    }
}

class ConfigurationViewController: NSViewController,
                                   NSTextFieldDelegate {
    override var nibName: String? {
        return "ConfigurationViewController"
    }

    dynamic weak var delegate: ConfigurationViewControllerDelegate!

    dynamic var width: Double = 1 {
        didSet {
            widthInput.stringValue = String(width)
            isWidthValid  = true
        }
    }

    dynamic var height: Double = 1 {
        didSet {
            heightInput.stringValue = String(height)
            isHeightValid = true
        }
    }

    dynamic var useSquare = true {
        didSet {
            if useSquare {
                width  = 1
                height = 1
            }
        }
    }

    let initializationQueue =
        (NSApplication.shared().delegate as! AppDelegate).initializationQueue

    @IBOutlet weak var widthInput:         TextField!
    @IBOutlet weak var heightInput:        TextField!
    @IBOutlet weak var errorMessage:       NSTextField!
    @IBOutlet weak var reinitializeButton: NSButton!
    @IBOutlet weak var maxRankSelector:    NSPopUpButton!

    // Variables for enabling/disabling the findPoint button
    dynamic var isWidthValid  = true
    dynamic var isHeightValid = true

    dynamic var isEditing = false

    @IBAction
    func updateWidth(_ sender: TextField) {
        let parsedWidth = Parser.parsedString(from: widthInput.stringValue)
        isEditing = false
        if parsedWidth.success {
            if parsedWidth.value > 0 {
                width = parsedWidth.value
                errorMessage.stringValue = ""
            }
            else {
                isWidthValid = false
                errorMessage.stringValue = "Width must be a positive number"
            }
        }
        else {
            isWidthValid = false
            errorMessage.stringValue = parsedWidth.string
        }
    }

    @IBAction
    func updateHeight(_ sender: TextField) {
        let parsedHeight = Parser.parsedString(from: heightInput.stringValue)
        isEditing = false
        if parsedHeight.success {
            if parsedHeight.value > 0 {
                height = parsedHeight.value
                errorMessage.stringValue = ""
            }
            else {
                isHeightValid = false
                errorMessage.stringValue = "Height must be a positive number"
            }
        }
        else {
            isHeightValid = false
            errorMessage.stringValue = parsedHeight.string
        }
    }

    @IBAction
    func setMaxRank(_ sender: NSPopUpButton) {
        main.maxRank = maxRankSelector.indexOfSelectedItem + 1
        Swift.print(main.maxRank)
    }

    @IBAction
    func reinitialize(_ sender: NSView) {
        delegate.reinitialize()
    }

    @IBAction
    func toggleAxiom1(_ sender: NSButton) {
        toggle(axiom: 1, state: sender.state)
    }

    @IBAction
    func toggleAxiom2(_ sender: NSButton) {
        toggle(axiom: 2, state: sender.state)
    }

    @IBAction
    func toggleAxiom3(_ sender: NSButton) {
        toggle(axiom: 3, state: sender.state)
    }

    @IBAction
    func toggleAxiom4(_ sender: NSButton) {
        toggle(axiom: 4, state: sender.state)
    }

    @IBAction
    func toggleAxiom5(_ sender: NSButton) {
        toggle(axiom: 5, state: sender.state)
    }

    @IBAction
    func toggleAxiom6(_ sender: NSButton) {
        toggle(axiom: 6, state: sender.state)
    }

    @IBAction
    func toggleAxiom7(_ sender: NSButton) {
        toggle(axiom: 7, state: sender.state)
    }

    func toggle(axiom: Int, state: Int) {
        main.useAxioms[axiom - 1] = state == 0 ? false : true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        widthInput.delegate  = self
        heightInput.delegate = self
        maxRankSelector.removeAllItems()
        for i in 1...6 {
            maxRankSelector.addItem(withTitle: String(i))
        }
        maxRankSelector.selectItem(at: main.maxRank - 1)
    }
}
