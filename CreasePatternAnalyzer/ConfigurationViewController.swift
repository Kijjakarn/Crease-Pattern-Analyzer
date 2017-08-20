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
                                   NSControlTextEditingDelegate,
                                   NSTextFieldDelegate {
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
                isEditing = false
            }
        }
    }

    let initializationQueue =
        (NSApplication.shared().delegate as! AppDelegate).initializationQueue

    var widthInput:   TextField!
    var heightInput:  TextField!
    var errorMessage: NSTextField!

    // Variables for enabling/disabling the reinitialize button
    dynamic var isWidthValid  = true
    dynamic var isHeightValid = true
    dynamic var isEditing     = false

    override func loadView() {
        view = NSView()
    }

    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText)
      -> Bool {
        print("Should end editing called")
        if (control === widthInput) {
            print("Going to update width")
            updateWidth()
        }
        if (control === heightInput) {
            print("Going to update height")
            updateHeight()
        }
        return true
    }

    func updateWidth() {
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

    func updateHeight() {
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

    func setMaxRank(_ sender: NSPopUpButton) {
        main.maxRank = sender.indexOfSelectedItem + 1
    }

    func reinitialize() {
        delegate.reinitialize()
    }

    func toggleAxiom(_ sender: NSButton) {
        main.useAxioms[sender.tag - 1] = sender.state == 0 ? false : true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }

    func setUpView() {
        let paperDimensionsText = NSTextField()
        paperDimensionsText.stringValue = "Paper Dimensions"
        setUp(textField: paperDimensionsText)
        paperDimensionsText.font = NSFont.boldSystemFont(ofSize: 13)
        paperDimensionsText.alignment = .center

        let useSquareButton = NSButton(
            checkboxWithTitle: "Square",
            target: nil,
            action: nil
        )
        useSquareButton.bind(
            "value",
            to: self,
            withKeyPath: "useSquare",
            options: nil
        )

        let aspectRatioText = NSTextField()
        let aspectRatioColon = NSTextField()
        aspectRatioText.stringValue = "Aspect Ratio"
        aspectRatioColon.stringValue = ":"
        setUp(textField: aspectRatioText)
        setUp(textField: aspectRatioColon)
        widthInput  = TextField()
        heightInput = TextField()
        widthInput.delegate  = self
        heightInput.delegate = self
        widthInput.target  = self
        heightInput.target = self
        widthInput.action = #selector(ConfigurationViewController.updateWidth)
        heightInput.action = #selector(ConfigurationViewController.updateHeight)
        widthInput.bind(
            "enabled",
            to: self,
            withKeyPath: "useSquare",
            options: [
                NSValueTransformerNameBindingOption:
                    NSValueTransformerName.negateBooleanTransformerName
            ]
        )
        heightInput.bind(
            "enabled",
            to: self,
            withKeyPath: "useSquare",
            options: [
                NSValueTransformerNameBindingOption:
                    NSValueTransformerName.negateBooleanTransformerName
            ]
        )
        useSquare = true
        let aspectRatioStack = NSStackView(
            views: [aspectRatioText, widthInput, aspectRatioColon, heightInput]
        )
        widthInput.translatesAutoresizingMaskIntoConstraints  = false
        heightInput.translatesAutoresizingMaskIntoConstraints = false
        widthInput.widthAnchor.constraint(equalToConstant: 100).isActive  = true
        heightInput.widthAnchor.constraint(equalToConstant: 100).isActive = true
        aspectRatioStack.orientation = .horizontal

        let axiomsText = NSTextField()
        axiomsText.stringValue = "Axioms"
        setUp(textField: axiomsText)
        let axiomsStack = NSStackView()
        axiomsStack.orientation = .horizontal
        axiomsStack.addArrangedSubview(axiomsText)
        for i in 1...7 {
            let axiomButton = NSButton(
                checkboxWithTitle: String(i),
                target: self,
                action: #selector(ConfigurationViewController.toggleAxiom(_:))
            )
            axiomButton.state = 1
            axiomButton.tag = i
            axiomsStack.addArrangedSubview(axiomButton)
            if i == 7 {
                axiomButton.translatesAutoresizingMaskIntoConstraints = false
                axiomButton.rightAnchor
                           .constraint(equalTo: axiomsStack.rightAnchor)
                           .isActive = true
            }
        }

        let maxRankText = NSTextField()
        maxRankText.stringValue = "Maximum Rank"
        setUp(textField: maxRankText)
        let maxRankSelector = NSPopUpButton(
            title: "",
            target: self,
            action: #selector(ConfigurationViewController.setMaxRank(_:))
        )
        for i in 1...6 {
            maxRankSelector.addItem(withTitle: String(i))
        }
        maxRankSelector.selectItem(at: main.maxRank - 1)
        let maxRankStack = NSStackView(
            views: [maxRankText, maxRankSelector]
        )
        maxRankSelector.setContentHuggingPriority(249, for: .horizontal)
        maxRankStack.orientation = .horizontal

        errorMessage = NSTextField()
        setUp(textField: errorMessage)

        let reinitializeButton = NSButton(
            title: "Reinitialize",
            target: self,
            action: #selector(ConfigurationViewController.reinitialize)
        )
        reinitializeButton.bind(
            "enabled",
            to: self,
            withKeyPath: "isWidthValid",
            options: nil
        )
        reinitializeButton.bind(
            "enabled2",
            to: self,
            withKeyPath: "isHeightValid",
            options: nil
        )
        reinitializeButton.bind(
            "enabled3",
            to: self,
            withKeyPath: "delegate.hasFinishedInitialization",
            options: nil
        )
        reinitializeButton.bind(
            "enabled4",
            to: self,
            withKeyPath: "isEditing",
            options: [
                NSValueTransformerNameBindingOption:
                    NSValueTransformerName.negateBooleanTransformerName
            ]
        )
        reinitializeButton.setContentHuggingPriority(261, for: .horizontal)

        let stackView = NSStackView(
            views: [
                paperDimensionsText,
                useSquareButton,
                aspectRatioStack,
                axiomsStack,
                maxRankStack,
                errorMessage,
                reinitializeButton,
            ]
        )
        stackView.orientation = .vertical
        stackView.alignment = .left

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leftAnchor
                     .constraint(equalTo: view.leftAnchor, constant: 20),
            stackView.rightAnchor
                     .constraint(equalTo: view.rightAnchor, constant: -20),
            stackView.topAnchor
                     .constraint(equalTo: view.topAnchor, constant: 20),
        ])

        paperDimensionsText.translatesAutoresizingMaskIntoConstraints = false
        paperDimensionsText.centerXAnchor
                           .constraint(equalTo: stackView.centerXAnchor)
                           .isActive = true

        aspectRatioStack.translatesAutoresizingMaskIntoConstraints = false
        aspectRatioStack.rightAnchor
                        .constraint(equalTo: stackView.rightAnchor)
                        .isActive = true

        axiomsStack.translatesAutoresizingMaskIntoConstraints = false
        axiomsStack.rightAnchor
                   .constraint(equalTo: stackView.rightAnchor)
                   .isActive = true

        maxRankStack.translatesAutoresizingMaskIntoConstraints = false
        maxRankStack.rightAnchor
                    .constraint(equalTo: stackView.rightAnchor)
                    .isActive = true

        reinitializeButton.translatesAutoresizingMaskIntoConstraints = false
        reinitializeButton.rightAnchor
                          .constraint(equalTo: stackView.rightAnchor)
                          .isActive = true
    }

    func setUp(textField: NSTextField) {
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.isSelectable = false
        textField.drawsBackground = false
        textField.isBordered = false
    }
}
