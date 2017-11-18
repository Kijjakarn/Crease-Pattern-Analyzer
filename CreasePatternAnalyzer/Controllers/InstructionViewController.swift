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
    @objc dynamic weak var delegate: InstructionViewControllerDelegate!

    @objc dynamic var enableNextButton = false
    @objc dynamic var enablePreviousButton = false

    var viewNumber: Int = 0 {
        didSet {
            if viewNumber == 0 {
                enablePreviousButton = false
            }
            else if viewNumber == main.diagrams.count - 1 {
                enableNextButton = false
            }
            else {
                enablePreviousButton = true
                enableNextButton = true
            }
            if main.diagrams.isEmpty {
                CATransaction.commit()
                return
            }
            diagramView.diagram = main.diagrams[viewNumber]
            if main.diagrams.count == 1 {
                enableNextButton = false
            }
            CATransaction.commit()
            instruction.string = main.instructions[viewNumber]
            diagramView.drawAll()
        }
    }

    var diagramView: DiagramView!
    var instruction: NSTextView!

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update instruction views when the find point button is clicked
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(InstructionViewController.updateViews(_:)),
            name: NSNotification.Name("FindPoint"),
            object: nil
        )

        setUpView()
    }

    func setUpView() {
        instruction = NSTextView()
        instruction.font = NSFont.systemFont(ofSize: 13)
        instruction.isEditable = false
        let scrollView = NSScrollView()
        scrollView.documentView = instruction

        let previousButton = NSButton(
            title: "Previous",
            target: self,
            action: #selector(InstructionViewController.showPrevious)
        )
        previousButton.bind(
            NSBindingName(rawValue: "enabled"),
            to: self,
            withKeyPath: "enablePreviousButton",
            options: nil
        )
        previousButton.bind(
            NSBindingName(rawValue: "enabled2"),
            to: self,
            withKeyPath: "delegate.hasFinishedInitialization",
            options: nil
        )

        let nextButton = NSButton(
            title: "Next",
            target: self,
            action: #selector(InstructionViewController.showNext)
        )
        nextButton.bind(
            NSBindingName(rawValue: "enabled"),
            to: self,
            withKeyPath: "enableNextButton",
            options: nil
        )
        nextButton.bind(
            NSBindingName(rawValue: "enabled2"),
            to: self,
            withKeyPath: "delegate.hasFinishedInitialization",
            options: nil
        )

        let buttonsContainer = NSStackView(
            views: [previousButton, nextButton]
        )
        let stackView = NSStackView(
            views: [diagramView, buttonsContainer, scrollView]
        )
        view.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints        = false
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        previousButton.translatesAutoresizingMaskIntoConstraints   = false
        nextButton.translatesAutoresizingMaskIntoConstraints       = false
        scrollView.translatesAutoresizingMaskIntoConstraints       = false
        instruction.autoresizingMask = .width

        stackView.orientation = .vertical
        stackView.alignment = .left

        NSLayoutConstraint.activate([
            stackView.leftAnchor
                     .constraint(equalTo: view.leftAnchor, constant: 20),
            stackView.rightAnchor
                     .constraint(equalTo: view.rightAnchor, constant: -20),
            stackView.topAnchor
                     .constraint(equalTo: view.topAnchor, constant: 20),
            stackView.bottomAnchor
                     .constraint(equalTo: view.bottomAnchor, constant: -20),
        ])

        scrollView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        scrollView.borderType = .noBorder
    }

    @objc func showPrevious() {
        viewNumber -= 1
    }

    @objc func showNext() {
        viewNumber += 1
    }

    @objc func updateViews(_ note: NSNotification) {
        enableNextButton = true
        viewNumber = 0
    }
}
