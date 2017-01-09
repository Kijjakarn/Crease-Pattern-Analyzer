//
//  Parser.swift
//  CreasePatternAnalyzer
//
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Darwin

// String passed into this function must start with "." or a digit
func parseDouble(_ str: inout String) -> Double? {
    var double = 0.0
    var char = str.remove(at: str.startIndex)
    if char == "." {
        if str.isEmpty {
            str.insert(char, at: str.startIndex)
            return nil
        }
        let char2 = str[str.startIndex]

        // Naked "."
        if !isDigit(char2) {
            str.insert(char, at: str.startIndex)
            return nil
        }
        double += parseDecimal(&str)
    }
    else if isDigit(char) {
        str.insert(char, at: str.startIndex)
        if let parsedInt = parseInt(&str) {
            double += Double(parsedInt)
        }
        else { return nil }
        if str.isEmpty { return double }
        char = str.remove(at: str.startIndex)
        if char == "." { double += parseDecimal(&str) }
        else { str.insert(char, at: str.startIndex) }
    }
    else {
        str.insert(char, at: str.startIndex)
        return nil
    }
    if str.isEmpty { return double }
    char = str.remove(at: str.startIndex)
    if char != "E" && char != "e" {
        str.insert(char, at: str.startIndex)
        return double
    }
    if let parsedExponent = parseExponent(&str) {
        double *= pow(10.0, Double(parsedExponent))
    }
    else {
        str.insert(char, at: str.startIndex)
    }
    return double
}

func parseExponent(_ str: inout String) -> Int? {
    if str.isEmpty { return nil }
    let char = str.remove(at: str.startIndex)
    switch char {
    case "+":
        if let parsedInt = parseInt(&str) {
            return parsedInt
        }
        str.insert(char, at: str.startIndex)
    case "-":
        if let parsedInt = parseInt(&str) {
            return -parsedInt
        }
        str.insert(char, at: str.startIndex)
    default:
        str.insert(char, at: str.startIndex)
        if let parsedInt = parseInt(&str) {
            return parsedInt
        }
    }
    return nil
}

// Return 0 if first character is a non-digit
func parseDecimal(_ str: inout String) -> Double {
    if str.isEmpty { return 0 }
    var decimal = 0.0
    var multiplier = 0.1
    var char = str.remove(at: str.startIndex)
    if !isDigit(char) {
        str.insert(char, at: str.startIndex)
        return 0
    }
    repeat {
        decimal += multiplier*Double(toNumber(char)!)
        multiplier *= 0.1
        if str.isEmpty { break }
        char = str.remove(at: str.startIndex)
    }
    while isDigit(char)
    if !isDigit(char) {
        str.insert(char, at: str.startIndex)
    }
    return decimal
}

func parseInt(_ str: inout String) -> Int? {
    if str.isEmpty { return nil }
    var int = 0
    var char = str.remove(at: str.startIndex)
    if !isDigit(char) {
        str.insert(char, at: str.startIndex)
        return nil
    }
    repeat {
        int = 10*int + toNumber(char)!
        if str.isEmpty { break }
        char = str.remove(at: str.startIndex)
    }
    while isDigit(char)
    if !isDigit(char) {
        str.insert(char, at: str.startIndex)
    }
    return int
}

func isDigit(_ digit: Character) -> Bool {
    return "0" <= digit && digit <= "9"
}

func isAlphanumeric(_ char: Character) -> Bool {
    return isDigit(char)
        || "a" <= char && char <= "z"
        || "A" <= char && char <= "Z"
        || char == "_"
}

func toNumber(_ digit: Character) -> Int? {
    switch digit {
    case "0": return 0
    case "1": return 1
    case "2": return 2
    case "3": return 3
    case "4": return 4
    case "5": return 5
    case "6": return 6
    case "7": return 7
    case "8": return 8
    case "9": return 9
    default: break
    }
    return nil
}

enum ParseError: Error {
    case NotEnoughOperands
    case TooManyOperands
    case UnbalancedParenthesis
    case InvalidNumber
    case InvalidOperation
    case ParseStackFailure
    case EmptyExpression
}

class Parser {
    var operands  =  [Double]()
    var operators =  [String]()

    // If the last thing pushed on a stack is an operator
    // If true, "-" becomes a unary negation operator "M"
    var operatorPushed = true

    class func parsedString(from str: String)
        -> (success: Bool, string: String, value: Double) {
        do {
            if let parsed = try Parser().parse(string: str) {
                return (true, String(parsed), parsed)
            }
            else {
                return (false, "Empty string", 0)
            }
        }
        catch ParseError.NotEnoughOperands {
            return (false, "Not enough operands", 0)
        }
        catch ParseError.TooManyOperands {
            return (false, "Too many operands", 0)
        }
        catch ParseError.UnbalancedParenthesis {
            return (false, "Unbalanced parenthesis", 0)
        }
        catch ParseError.InvalidNumber {
            return (false, "Invalid number", 0)
        }
        catch ParseError.InvalidOperation {
            return (false, "Invalid operation", 0)
        }
        catch ParseError.ParseStackFailure {
            return (false, "Stack failure", 0)
        }
        catch ParseError.EmptyExpression {
            return (false, "", 0)
        }
        catch {
            return (false, "Unknown error", 0)
        }
    }

    // Take an operator popped from the operators stack, apply it to the
    // appropriate number of arguments from the operands stack, and push the
    // result back into the operands stack
    func apply(_ operatorName: String) throws {
        switch operatorName {

        // Binary operators
        case "^", "*", "/", "+", "-":
            let result: Double
            guard let operand2 = operands.popLast() else {
                throw ParseError.NotEnoughOperands
            }
            guard let operand1 = operands.popLast() else {
                throw ParseError.NotEnoughOperands
            }
            switch operatorName {
            case "^":
                result = pow(operand1, operand2)
            case "*":
                result = operand1*operand2
            case "/":
                result = operand1/operand2
            case "+":
                result = operand1 + operand2
            case "-":
                result = operand1 - operand2
            default:
                throw ParseError.InvalidOperation
            }
            operands.append(result)

        // Unary functions
        case "sin", "cos", "tan", "ln", "log", "sqrt", "cbrt", "abs", "unary-":
            let result: Double
            guard let operand = operands.popLast() else {
                throw ParseError.NotEnoughOperands
            }
            switch operatorName {
            case "sin":
                result = sin(operand*π/180)
            case "cos":
                result = cos(operand*π/180)
            case "tan":
                result = tan(operand*π/180)
            case "ln":
                result = log(operand)
            case "log":
                result = log10(operand)
            case "sqrt":
                result = sqrt(operand)
            case "cbrt":
                result = cbrt(operand)
            case "abs":
                result = abs(operand)
            case "unary-":
                result = -operand
            default:
                throw ParseError.InvalidOperation
            }
            operands.append(result)

        default:
            throw ParseError.InvalidOperation
        }
    }

    func parse(string str: String) throws -> Double! {
        if str.isEmpty { throw ParseError.EmptyExpression }
        var str = str
        var char: Character
        while !str.isEmpty {
            char = str.remove(at: str.startIndex)

            // If it is a number, push it on the operands stack
            if isDigit(char) || char == "." {
                str.insert(char, at: str.startIndex)
                if let parsedDouble = parseDouble(&str) {
                    operands.append(parsedDouble)
                }
                else { throw ParseError.InvalidNumber }
                operatorPushed = false
            }
            // If it is not a number, then it must be an operator
            else {
                switch char {
                case "^", "*", "/", "+", "-":
                    var char: String = String(char)
                    // Case where "-" is treated as a unary operator
                    if char == "-" && operatorPushed { char = "unary-" }
                    if operators.count == 0 {
                        operators.append(char)
                    }
                    else {
                        let comparison = compareOperators(char,
                                operators[operators.count - 1])
                        if comparison >= 0 {
                            operators.append(char)
                        }
                        else {
                            guard let operatorName = operators.popLast() else {
                                throw ParseError.TooManyOperands
                            }
                            try apply(operatorName)
                            operators.append(char)
                        }
                    }
                    operatorPushed = true
                case "(":
                    operators.append(String(char))
                    operatorPushed = true

                // Ignore whitespace
                case " ":
                    continue

                // Pop all operators until "(" is found
                case ")":
                    while true {
                        guard let operatorName = operators.popLast() else {
                            throw ParseError.UnbalancedParenthesis
                        }
                        if operatorName == "(" { break }
                        try apply(operatorName)
                    }
                    operatorPushed = false

                // The operator is a function
                default:
                    str.insert(char, at: str.startIndex)
                    let functionName = read(functionName: &str)

                    // If a constant "p", "e", or "d" is read
                    switch functionName {
                    case "p", "e", "d":
                        operatorPushed = false
                        switch functionName {
                        case "p": operands.append(M_PI)
                        case "e": operands.append(M_E)
                        case "d": operands.append(sqrt(2))
                        default: break
                        }
                        continue
                    default: break
                    }
                    // Otherwise, a function name is read
                    operators.append(functionName)
                    operatorPushed = true
                }
            }
        }
        // Clear the stacks
        while operators.count != 0 {
            guard let operatorName = operators.popLast() else {
                throw ParseError.ParseStackFailure
            }
            try apply(operatorName)
        }
        let double = operands.popLast()
        if operands.count != 0 || operators.count != 0 {
            throw ParseError.ParseStackFailure
        }
        return double
    }
}

func read(functionName str: inout String) -> String {
    var name = ""
    var char: Character
    while !str.isEmpty {
        char = str.remove(at: str.startIndex)
        if !isAlphanumeric(char) {
            str.insert(char, at: str.startIndex)
            break
        }
        name += String(char)
    }
    return name
}

func compareOperators(_ operator1: String, _ operator2: String) -> Int {
    return precedence(operator1) - precedence(operator2)
}

func precedence(_ operatorName: String) -> Int {
    switch operatorName {
    case "^":
        return 50
    case "*", "/":
        return 40
    case "unary-":
        return 30
    case "+", "-":
        return 20
    case "(":
        return 10
    default:
        return 100
    }
}
