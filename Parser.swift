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
    switch digit {
    case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
        return true
    default:
        return false
    }
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
