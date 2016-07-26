import Darwin

// String passed into this function must start with "." or a digit
func parseDouble(inout str: String) -> Double? {
    var double = 0.0
    var char = str.removeAtIndex(str.startIndex)
    if char == "." {
        if str.isEmpty {
            str.insert(char, atIndex: str.startIndex)
            return nil
        }
        let char2 = str[str.startIndex]

        // Naked "."
        if !isDigit(char2) {
            str.insert(char, atIndex: str.startIndex)
            return nil
        }
        double += parseDecimal(&str)
    }
    else if isDigit(char) {
        str.insert(char, atIndex: str.startIndex)
        if let parsedInt = parseInt(&str) {
            double += Double(parsedInt)
        }
        else { return nil }
        if str.isEmpty { return double }
        char = str.removeAtIndex(str.startIndex)
        if char == "." { double += parseDecimal(&str) }
        else { str.insert(char, atIndex: str.startIndex) }
    }
    else {
        str.insert(char, atIndex: str.startIndex)
        return nil
    }
    if str.isEmpty { return double }
    char = str.removeAtIndex(str.startIndex)
    if char != "E" && char != "e" {
        str.insert(char, atIndex: str.startIndex)
        return double
    }
    if let parsedExponent = parseExponent(&str) {
        double *= pow(10.0, Double(parsedExponent))
    }
    else {
        str.insert(char, atIndex: str.startIndex)
    }
    return double
}

func parseExponent(inout str: String) -> Int? {
    if str.isEmpty { return nil }
    let char = str.removeAtIndex(str.startIndex)
    switch char {
    case "+":
        if let parsedInt = parseInt(&str) {
            return parsedInt
        }
        str.insert(char, atIndex: str.startIndex)
    case "-":
        if let parsedInt = parseInt(&str) {
            return -parsedInt
        }
        str.insert(char, atIndex: str.startIndex)
    default:
        str.insert(char, atIndex: str.startIndex)
        if let parsedInt = parseInt(&str) {
            return parsedInt
        }
    }
    return nil
}

// Return 0 if first character is a non-digit
func parseDecimal(inout str: String) -> Double {
    if str.isEmpty { return 0 }
    var decimal = 0.0
    var multiplier = 0.1
    var char = str.removeAtIndex(str.startIndex)
    if !isDigit(char) {
        str.insert(char, atIndex: str.startIndex)
        return 0
    }
    repeat {
        decimal += multiplier*Double(toNumber(char)!)
        multiplier *= 0.1
        if str.isEmpty { break }
        char = str.removeAtIndex(str.startIndex)
    }
    while isDigit(char)
    if !isDigit(char) {
        str.insert(char, atIndex: str.startIndex)
    }
    return decimal
}

func parseInt(inout str: String) -> Int? {
    if str.isEmpty { return nil }
    var int = 0
    var char = str.removeAtIndex(str.startIndex)
    if !isDigit(char) {
        str.insert(char, atIndex: str.startIndex)
        return nil
    }
    repeat {
        int = 10*int + toNumber(char)!
        if str.isEmpty { break }
        char = str.removeAtIndex(str.startIndex)
    }
    while isDigit(char)
    if !isDigit(char) {
        str.insert(char, atIndex: str.startIndex)
    }
    return int
}

func isDigit(digit: Character) -> Bool {
    return "0" <= digit && digit <= "9"
}

func isAlphanumeric(char: Character) -> Bool {
    return isDigit(char)
        || "a" <= char && char <= "z"
        || "A" <= char && char <= "Z"
        || char == "_"
}

func toNumber(digit: Character) -> Int? {
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

enum ParseError: ErrorType {
    case NotEnoughOperands
    case TooManyOperands
    case UnbalancedParenthesis
    case InvalidNumber
    case InvalidOperation
    case ParseStackFailure
    case EmptyExpression
}

class ShuntingYard {
    var operands:  [Double]
    var operators: [String]

    // If the last thing pushed on a stack is an operator
    // If true, "-" becomes a unary negation operator "M"
    var operatorPushed = true

    init() {
        operands  = []
        operators = []
    }

    // Take an operator popped from the operators stack, apply it to the
    // appropriate number of arguments from the operands stack, and push the
    // result back into the operands stack
    func apply(operatorName: String) throws {
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

    func parse(str: String) throws -> Double! {
        if str.isEmpty { throw ParseError.EmptyExpression }
        var str = str
        var char: Character
        while !str.isEmpty {
            char = str.removeAtIndex(str.startIndex)

            // If it is a number, push it on the operands stack
            if isDigit(char) || char == "." {
                str.insert(char, atIndex: str.startIndex)
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
                    str.insert(char, atIndex: str.startIndex)
                    let functionName = readFunctionName(&str)

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

func readFunctionName(inout str: String) -> String {
    var name = ""
    var char: Character
    while !str.isEmpty {
        char = str.removeAtIndex(str.startIndex)
        if !isAlphanumeric(char) {
            str.insert(char, atIndex: str.startIndex)
            break
        }
        name += String(char)
    }
    return name
}

func compareOperators(operator1: String, _ operator2: String) -> Int {
    return precedence(operator1) - precedence(operator2)
}

func precedence(operatorName: String) -> Int {
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
