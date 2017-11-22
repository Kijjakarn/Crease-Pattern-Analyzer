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
    func stopInitialization()
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
    @objc dynamic weak var delegate: ConfigurationViewControllerDelegate!

    @objc dynamic var width: Double = 1 {
        didSet {
            widthInput.stringValue = String(width)
            isWidthValid  = true
        }
    }

    @objc dynamic var height: Double = 1 {
        didSet {
            heightInput.stringValue = String(height)
            isHeightValid = true
        }
    }

    @objc dynamic var useSquare = true {
        didSet {
            if useSquare {
                width  = 1
                height = 1
                isEditing = false
            }
        }
    }

    var widthInput:   TextField!
    var heightInput:  TextField!
    var errorMessage: NSTextField!

    // Variables for enabling/disabling the reinitialize button
    @objc dynamic var isWidthValid  = true
    @objc dynamic var isHeightValid = true
    @objc dynamic var isEditing     = false

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

    @objc func updateWidth() {
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

    @objc func updateHeight() {
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

    @objc func setMaxRank(_ sender: NSPopUpButton) {
        main.maxRank = sender.indexOfSelectedItem + 1
    }

    @objc func toggleAxiom(_ sender: NSButton) {
        main.useAxioms[sender.tag - 1] = sender.state.rawValue == 0 ? false : true
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
            NSBindingName(rawValue: "value"),
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
            NSBindingName(rawValue: "enabled"),
            to: self,
            withKeyPath: "useSquare",
            options: [
                .valueTransformerName:
                    NSValueTransformerName.negateBooleanTransformerName
            ]
        )
        heightInput.bind(
            NSBindingName(rawValue: "enabled"),
            to: self,
            withKeyPath: "useSquare",
            options: [
                .valueTransformerName:
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
            axiomButton.state = NSControl.StateValue(rawValue: 1)
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
        maxRankSelector.setContentHuggingPriority(
            NSLayoutConstraint.Priority(rawValue: 249),
            for: .horizontal
        )
        maxRankStack.orientation = .horizontal

        errorMessage = NSTextField()
        setUp(textField: errorMessage)

        let reinitializeButton = NSButton(
            title: "Reinitialize",
            target: delegate,
            action: #selector(ConfigurationViewControllerDelegate.reinitialize)
        )
        reinitializeButton.bind(
            NSBindingName(rawValue: "enabled"),
            to: self,
            withKeyPath: "isWidthValid",
            options: nil
        )
        reinitializeButton.bind(
            NSBindingName(rawValue: "enabled2"),
            to: self,
            withKeyPath: "isHeightValid",
            options: nil
        )
        reinitializeButton.bind(
            NSBindingName(rawValue: "enabled3"),
            to: self,
            withKeyPath: "isEditing",
            options: [
                .valueTransformerName:
                    NSValueTransformerName.negateBooleanTransformerName
            ]
        )
        reinitializeButton.setContentHuggingPriority(
            NSLayoutConstraint.Priority(rawValue: 261),
            for: .horizontal
        )

        let stopInitializationButton = NSButton(
            title: "Stop Initialization",
            target: delegate,
            action: #selector(
                ConfigurationViewControllerDelegate.stopInitialization
            )
        )
        stopInitializationButton.bind(
            NSBindingName(rawValue: "enabled"),
            to: self,
            withKeyPath: "delegate.hasFinishedInitialization",
            options: [
                .valueTransformerName:
                    NSValueTransformerName.negateBooleanTransformerName
            ]
        )
        stopInitializationButton.setContentHuggingPriority(
            NSLayoutConstraint.Priority(rawValue: 261),
            for: .horizontal
        )

        let stackView = NSStackView(
            views: [
                paperDimensionsText,
                useSquareButton,
                aspectRatioStack,
                axiomsStack,
                maxRankStack,
                errorMessage,
                reinitializeButton,
                stopInitializationButton,
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

        stopInitializationButton
            .translatesAutoresizingMaskIntoConstraints = false
        stopInitializationButton
            .rightAnchor
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
