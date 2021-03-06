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

class PointViewController: NSViewController, NSTableViewDelegate {
    @objc dynamic weak var delegate: PointViewControllerDelegate!

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

    // Variables for enabling/disabling the findPoint button
    @objc dynamic var isXValid = false
    @objc dynamic var isYValid = false

    @objc dynamic var foundPoints = [PointReference]()

    @objc dynamic var xString = ""
    @objc dynamic var yString = ""

    var xInput:          NSTextField!
    var yInput:          NSTextField!
    var errorMessage:    NSTextField!
    var arrayController: NSArrayController!

    override func loadView() {
        view = NSView()
    }

    @objc func updateX(_ sender: NSTextField) {
        let parsedX = Parser.parsedString(from: sender.stringValue)
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

    @objc func updateY(_ sender: NSTextField) {
        let parsedY = Parser.parsedString(from: sender.stringValue)
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

    @objc func findPoint() {
        foundPoints = matchedPoints(for: PointVector(x, y))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }

    func setUpView() {
        let xText = NSTextField()
        let xColon = NSTextField()
        xInput = NSTextField()
        let xEquals = NSTextField()
        let xOutput = NSTextField()
        setUp(textField: xText)
        setUp(textField: xColon)
        setUp(textField: xEquals)
        xText.stringValue = "x"
        xColon.stringValue = ":"
        xInput.placeholderString = "x-coordinate"
        xInput.action = #selector(PointViewController.updateX)
        xInput.target = self
        xOutput.alignment = .right
        xOutput.bind(
            NSBindingName(rawValue: "value"),
            to: self,
            withKeyPath: "xString",
            options: nil
        )
        let xStack = NSStackView(
            views: [xText, xColon, xInput, xEquals, xOutput]
        )
        xStack.orientation = .horizontal
        xStack.translatesAutoresizingMaskIntoConstraints = false
        xInput.translatesAutoresizingMaskIntoConstraints = false
        xInput.widthAnchor.constraint(equalToConstant: 100).isActive = true

        let yText = NSTextField()
        let yColon = NSTextField()
        yInput = NSTextField()
        let yEquals = NSTextField()
        let yOutput = NSTextField()
        setUp(textField: yText)
        setUp(textField: yColon)
        setUp(textField: yEquals)
        yText.stringValue = "y"
        yColon.stringValue = ":"
        yInput.placeholderString = "y-coordinate"
        yInput.action = #selector(PointViewController.updateY)
        yInput.target = self
        yOutput.alignment = .right
        yOutput.bind(
            NSBindingName(rawValue: "value"),
            to: self,
            withKeyPath: "yString",
            options: nil
        )
        let yStack = NSStackView(
            views: [yText, yColon, yInput, yEquals, yOutput]
        )
        yStack.orientation = .horizontal
        yStack.translatesAutoresizingMaskIntoConstraints = false
        yInput.translatesAutoresizingMaskIntoConstraints = false
        yInput.widthAnchor.constraint(equalToConstant: 100).isActive = true

        errorMessage = NSTextField()
        setUp(textField: errorMessage)

        let findPointButton = NSButton(
            title: "Find Point",
            target: self,
            action: #selector(PointViewController.findPoint)
        )
        findPointButton.bind(
            NSBindingName(rawValue: "enabled"),
            to: self,
            withKeyPath: "isXValid",
            options: nil
        )
        findPointButton.bind(
            NSBindingName(rawValue: "enabled2"),
            to: self,
            withKeyPath: "isYValid",
            options: nil
        )
        findPointButton.bind(
            NSBindingName(rawValue: "enabled3"),
            to: self,
            withKeyPath: "delegate.hasFinishedInitialization",
            options: nil
        )

        let foundPointsText = NSTextField()
        foundPointsText.stringValue = "Found Points"
        setUp(textField: foundPointsText)

        let foundPointsScrollView = NSScrollView()
        let foundPointsTableView  = NSTableView()
        foundPointsTableView.delegate = self
        arrayController = NSArrayController()
        let pointsColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier(rawValue: "Point")
        )
        let ranksColumn  = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier(rawValue: "Rank")
        )
        let errorsColumn = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier(rawValue: "Error")
        )
        pointsColumn.title = "Point"
        ranksColumn.title  = "Rank"
        errorsColumn.title = "Error"
        ranksColumn.width = 50
        pointsColumn.headerCell.alignment = .center
        ranksColumn.headerCell.alignment  = .center
        errorsColumn.headerCell.alignment = .center
        pointsColumn.bind(
            NSBindingName(rawValue: "value"),
            to: arrayController,
            withKeyPath: "arrangedObjects.pointString",
            options: nil
        )
        ranksColumn.sortDescriptorPrototype = NSSortDescriptor(
            key: "rank",
            ascending: true,
            selector: #selector(NSNumber.compare(_:))
        )
        errorsColumn.sortDescriptorPrototype = NSSortDescriptor(
            key: "distanceError",
            ascending: false,
            selector: #selector(NSNumber.compare(_:))
        )
        ranksColumn.bind(
            NSBindingName(rawValue: "value"),
            to: arrayController,
            withKeyPath: "arrangedObjects.rank",
            options: nil
        )
        errorsColumn.bind(
            NSBindingName(rawValue: "value"),
            to: arrayController,
            withKeyPath: "arrangedObjects.distanceError",
            options: nil
        )
        foundPointsTableView.addTableColumn(pointsColumn)
        foundPointsTableView.addTableColumn(ranksColumn)
        foundPointsTableView.addTableColumn(errorsColumn)
        foundPointsTableView.bind(
            NSBindingName(rawValue: "content"),
            to: arrayController,
            withKeyPath: "arrangedObjects",
            options: nil
        )
        foundPointsTableView.bind(
            NSBindingName(rawValue: "selectionIndexes"),
            to: arrayController,
            withKeyPath: "selectionIndexes",
            options: nil
        )
        foundPointsTableView.bind(
            NSBindingName(rawValue: "sortDescriptors"),
            to: arrayController,
            withKeyPath: "sortDescriptors",
            options: nil
        )
        arrayController.bind(
            NSBindingName(rawValue: "contentArray"),
            to: self,
            withKeyPath: "foundPoints",
            options: nil
        )
        arrayController.bind(
            NSBindingName(rawValue: "sortDescriptors"),
            to: NSUserDefaultsController.shared,
            withKeyPath: "values.sortDescriptors",
            options: [
                .valueTransformerName:
                    NSValueTransformerName.unarchiveFromDataTransformerName
            ]
        )
        arrayController.addObserver(
            self,
            forKeyPath: #keyPath(NSArrayController.selectionIndex),
            context: nil
        )
        foundPointsScrollView.documentView = foundPointsTableView

        let stackView = NSStackView(
            views: [
                xStack,
                yStack,
                errorMessage,
                findPointButton,
                foundPointsText,
                foundPointsScrollView,
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

        findPointButton.translatesAutoresizingMaskIntoConstraints = false
        findPointButton.rightAnchor
                       .constraint(equalTo: stackView.rightAnchor)
                       .isActive = true
        findPointButton.setContentHuggingPriority(
            NSLayoutConstraint.Priority(rawValue: 261),
            for: .horizontal
        )

        foundPointsScrollView.translatesAutoresizingMaskIntoConstraints = false
        foundPointsScrollView.heightAnchor
                             .constraint(equalToConstant: 200)
                             .isActive = true
    }

    func setUp(textField: NSTextField) {
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.isSelectable = false
        textField.drawsBackground = false
        textField.isBordered = false
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

    // MARK: NSTableViewDelegate

    func tableView(_ tableView: NSTableView,
          willDisplayCell cell: Any,
               for tableColumn: NSTableColumn?,
                           row: Int) {
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier("Rank") {
            if let cell = cell as? NSCell {
                cell.alignment = .center
            }
        }
    }
}
