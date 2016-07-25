import Darwin

// String passed into this function must start with "." or a digit
func parseDouble(str: String) -> (number: Double, remaining: String)? {
    var str = str
    var double = 0.0
    var char = str.removeAtIndex(str.startIndex)
    if char == "." {
        if str.isEmpty { return nil }
        char = str.removeAtIndex(str.startIndex)

        // Naked "."
        if !isDigit(char) {
            return nil
        }
        str.insert(char, atIndex: str.startIndex)
        let parsedDecimal = parseDecimal(str)
        double += parsedDecimal.number
        str = parsedDecimal.remaining
    }
    else {
        if !isDigit(char) { return nil }
        str.insert(char, atIndex: str.startIndex)
        if let parsedInt = parseInt(str) {
            double += Double(parsedInt.number)
            str = parsedInt.remaining
        }
        else {
            return nil
        }
        if str.isEmpty {
            return (double, str)
        }
        char = str.removeAtIndex(str.startIndex)
        if char == "." {
            let parsedDecimal = parseDecimal(str)
            double += parsedDecimal.number
            str = parsedDecimal.remaining
        }
        else {
            str.insert(char, atIndex: str.startIndex)
        }
    }
    if str.isEmpty {
        return (double, str)
    }
    char = str.removeAtIndex(str.startIndex)
    if char != "E" && char != "e" {
        str.insert(char, atIndex: str.startIndex)
        return (double, str)
    }
    if let parsedExponent = parseExponent(str) {
        double *= pow(10.0, Double(parsedExponent.number))
        str = parsedExponent.remaining
    }
    return (number: double, remaining: str)
}

func parseExponent(str: String) -> (number: Int, remaining: String)? {
    if str.isEmpty { return nil }
    var str = str
    let char = str.removeAtIndex(str.startIndex)
    switch char {
    case "+":
        if let parsedInt = parseInt(str) {
            return (number: parsedInt.number, remaining: parsedInt.remaining)
        }
        else { break }
    case "-":
        if let parsedInt = parseInt(str) {
            return (number: -parsedInt.number, remaining: parsedInt.remaining)
        }
        else { break }
    default:
        str.insert(char, atIndex: str.startIndex)
        if let parsedInt = parseInt(str) {
            return (number: parsedInt.number, remaining: parsedInt.remaining)
        }
        else { break }
    }
    return nil
}

// Return 0 if first character is a non-digit
func parseDecimal(str: String) -> (number: Double, remaining: String) {
    if str.isEmpty { return (0, str) }
    var str = str
    var decimal = 0.0
    var multiplier = 0.1
    var char = str.removeAtIndex(str.startIndex)
    if !isDigit(char) {
        str.insert(char, atIndex: str.startIndex)
        return (0, str)
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
    return (decimal, str)
}

func parseInt(str: String) -> (number: Int, remaining: String)? {
    if str.isEmpty { return nil }
    var str = str
    var int = 0
    var char = str.removeAtIndex(str.startIndex)
    if !isDigit(char) { return nil }
    repeat {
        int = 10*int + toNumber(char)!
        if str.isEmpty { break }
        char = str.removeAtIndex(str.startIndex)
    }
    while isDigit(char)
    if !isDigit(char) {
        str.insert(char, atIndex: str.startIndex)
    }
    return (int, str)
}

func isDigit(digit: Character) -> Bool {
    switch digit {
    case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
        return true
    default:
        break
    }
    return false
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
