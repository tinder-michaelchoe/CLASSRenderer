//
//  ExpressionEvaluator.swift
//  SCALS
//
//  Evaluates expressions and interpolates template strings.
//  Extracted from StateStore for clarity and testability.
//

import Foundation

// MARK: - State Reading Protocol

/// Protocol for reading state values, used by ExpressionEvaluator.
/// This allows the evaluator to work with any state source.
public protocol StateValueReading {
    /// Get a value at the given keypath
    func getValue(_ keypath: String) -> Any?

    /// Get an array at the given keypath
    func getArray(_ keypath: String) -> [Any]?

    /// Check if an array contains a value
    func arrayContains(_ keypath: String, value: Any) -> Bool

    /// Get the count of an array
    func getArrayCount(_ keypath: String) -> Int
}

// MARK: - Expression Evaluator

/// Evaluates expressions and interpolates template strings against state.
///
/// Supports:
/// - Simple keypaths: `"count"`, `"user.name"`
/// - Array access: `"items[0]"`, `"items[currentIndex]"`, `"items[0].name"`
/// - Array properties: `"items.count"`, `"items.isEmpty"`, `"items.first"`, `"items.last"`
/// - Array methods: `"items.contains(\"value\")"`, `"items.contains(varName)"`
/// - Ternary: `"condition ? 'trueValue' : 'falseValue'"`
/// - Arithmetic: `"count + 1"`, `"count - 1"`, `"count * 2"`, `"count / 2"`, `"count % 3"`
/// - Complex arithmetic: `"(index + 1) % 3"`, `"(a + b) * c"`, `"count + 1 - 2"`
/// - Template interpolation: `"Hello ${name}!"`, `"Image ${(index + 1)}/3"`
///
/// Example:
/// ```swift
/// let evaluator = ExpressionEvaluator()
///
/// // With a state reader
/// let result = evaluator.evaluate("(count + 1) % 3", using: stateStore)
/// let url = evaluator.evaluate("imageUrls[currentIndex]", using: stateStore)
/// let message = evaluator.interpolate("Hello ${name}!", using: stateStore)
/// ```
public struct ExpressionEvaluator {

    public init() {}

    // MARK: - Main Evaluation

    /// Evaluate an expression against state.
    ///
    /// - Parameters:
    ///   - expression: The expression to evaluate
    ///   - stateReader: Source for reading state values
    /// - Returns: The evaluated result
    public func evaluate(_ expression: String, using stateReader: StateValueReading) -> Any {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)

        // Check for ternary expression first
        if let ternaryResult = evaluateTernary(trimmed, using: stateReader) {
            return ternaryResult
        }

        // Check for array expressions (before arithmetic to handle items[index])
        if let arrayResult = evaluateArrayExpression(trimmed, using: stateReader) {
            return arrayResult
        }

        // Check if it's a template string with ${...}
        // Process templates BEFORE arithmetic check to avoid false positives from operators inside ${...}
        if containsTemplates(trimmed) {
            let interpolated = interpolate(trimmed, using: stateReader)
            // If the interpolated result looks like an arithmetic expression, evaluate it
            if isArithmeticExpression(interpolated), !containsTemplates(interpolated) {
                return evaluateArithmetic(interpolated, using: stateReader)
            }
            return interpolated
        }

        // Check if it's a simple arithmetic expression (no templates)
        if isArithmeticExpression(trimmed) {
            return evaluateArithmetic(expression, using: stateReader)
        }

        // Try to get value directly from state (bare variable name)
        if let value = stateReader.getValue(trimmed) {
            return value
        }

        // Fallback: return as-is (for strings without state values)
        return trimmed
    }

    // MARK: - Template Interpolation

    /// Interpolate template strings like "You pressed ${count} times".
    ///
    /// - Parameters:
    ///   - template: The template string with ${} placeholders
    ///   - stateReader: Source for reading state values
    /// - Returns: The interpolated string
    public func interpolate(_ template: String, using stateReader: StateValueReading) -> String {
        var result = template
        let pattern = #"\$\{([^}]+)\}"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return template
        }

        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))

        // Process matches in reverse to maintain string indices
        for match in matches.reversed() {
            guard let range = Range(match.range, in: template),
                  let keypathRange = Range(match.range(at: 1), in: template) else {
                continue
            }

            let expression = String(template[keypathRange])

            // Evaluate the expression (handles ternary, array expressions, etc.)
            let value = evaluateInterpolationExpression(expression, using: stateReader)

            let replacement = stringValue(from: value)
            result.replaceSubrange(range, with: replacement)
        }

        return result
    }

    /// Evaluate an expression found inside ${...} during interpolation
    private func evaluateInterpolationExpression(_ expression: String, using stateReader: StateValueReading) -> Any? {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)

        // Check for ternary expression
        if let ternaryResult = evaluateTernary(trimmed, using: stateReader) {
            return ternaryResult
        }

        // Check for array expressions
        if let arrayResult = evaluateArrayExpression(trimmed, using: stateReader) {
            return arrayResult
        }

        // Check for arithmetic expressions
        if trimmed.contains("+") || trimmed.contains("-") || trimmed.contains("%") || trimmed.contains("*") || trimmed.contains("/") {
            return evaluateArithmetic(trimmed, using: stateReader)
        }

        // Otherwise just get the value
        return stateReader.getValue(trimmed)
    }

    // MARK: - Ternary Expressions

    /// Evaluate ternary expressions: `condition ? 'trueValue' : 'falseValue'`
    private func evaluateTernary(_ expression: String, using stateReader: StateValueReading) -> Any? {
        // Find the ? and : positions, being careful about nested quotes
        guard let questionIndex = findTernaryOperator(expression, char: "?") else { return nil }
        guard let colonIndex = findTernaryOperator(expression[expression.index(after: questionIndex)...], char: ":") else { return nil }

        let conditionStr = String(expression[..<questionIndex]).trimmingCharacters(in: .whitespaces)
        let trueExprStart = expression.index(after: questionIndex)
        let trueExprEnd = colonIndex
        let falseExprStart = expression.index(after: colonIndex)

        let trueValue = String(expression[trueExprStart..<trueExprEnd]).trimmingCharacters(in: .whitespaces)
        let falseValue = String(expression[falseExprStart...]).trimmingCharacters(in: .whitespaces)

        // Evaluate the condition
        let conditionResult = evaluateCondition(conditionStr, using: stateReader)

        // Return the appropriate value (strip quotes if present)
        let result = conditionResult ? trueValue : falseValue
        return stripQuotes(result)
    }

    /// Find ternary operator position, ignoring those inside quotes.
    private func findTernaryOperator(_ str: some StringProtocol, char: Character) -> String.Index? {
        var inSingleQuote = false
        var inDoubleQuote = false

        for index in str.indices {
            let c = str[index]
            if c == "'" && !inDoubleQuote {
                inSingleQuote.toggle()
            } else if c == "\"" && !inSingleQuote {
                inDoubleQuote.toggle()
            } else if c == char && !inSingleQuote && !inDoubleQuote {
                return index
            }
        }
        return nil
    }

    /// Evaluate a condition expression.
    private func evaluateCondition(_ condition: String, using stateReader: StateValueReading) -> Bool {
        // Try array expressions that return bool
        if let arrayResult = evaluateArrayExpression(condition, using: stateReader) as? Bool {
            return arrayResult
        }

        // Try direct boolean state value
        if let boolValue = stateReader.getValue(condition) as? Bool {
            return boolValue
        }

        // Try string "true"/"false"
        if condition.lowercased() == "true" {
            return true
        }
        if condition.lowercased() == "false" {
            return false
        }

        // Check for negation
        if condition.hasPrefix("!") {
            let inner = String(condition.dropFirst()).trimmingCharacters(in: .whitespaces)
            return !evaluateCondition(inner, using: stateReader)
        }

        // Default to false for unknown conditions
        return false
    }

    /// Strip single or double quotes from a string.
    private func stripQuotes(_ str: String) -> String {
        if (str.hasPrefix("'") && str.hasSuffix("'")) ||
           (str.hasPrefix("\"") && str.hasSuffix("\"")) {
            return String(str.dropFirst().dropLast())
        }
        return str
    }

    // MARK: - Array Expressions

    /// Evaluate array-specific expressions.
    private func evaluateArrayExpression(_ expression: String, using stateReader: StateValueReading) -> Any? {
        // items[indexVar] - dynamic array indexing with variable
        if let match = matchDynamicArrayIndex(expression, using: stateReader) {
            return match
        }

        // items.count
        if expression.hasSuffix(".count") {
            let path = String(expression.dropLast(6))
            return stateReader.getArrayCount(path)
        }

        // items.isEmpty
        if expression.hasSuffix(".isEmpty") {
            let path = String(expression.dropLast(8))
            return stateReader.getArrayCount(path) == 0
        }

        // items.first
        if expression.hasSuffix(".first") {
            let path = String(expression.dropLast(6))
            return stateReader.getArray(path)?.first
        }

        // items.last
        if expression.hasSuffix(".last") {
            let path = String(expression.dropLast(5))
            return stateReader.getArray(path)?.last
        }

        // items.contains("value") or items.contains(varName)
        if let match = matchContainsExpression(expression, using: stateReader) {
            let (arrayPath, searchValue) = match
            return stateReader.arrayContains(arrayPath, value: searchValue)
        }

        return nil
    }

    /// Match dynamic array indexing expressions like `items[indexVar]` where indexVar is a state variable.
    private func matchDynamicArrayIndex(_ expression: String, using stateReader: StateValueReading) -> Any? {
        // Pattern: arrayName[indexExpression]
        guard let openBracket = expression.firstIndex(of: "["),
              let closeBracket = expression.lastIndex(of: "]"),
              openBracket < closeBracket else {
            return nil
        }

        let arrayName = String(expression[..<openBracket])
        let indexExpr = String(expression[expression.index(after: openBracket)..<closeBracket])

        // Try to parse as integer literal first
        if let literalIndex = Int(indexExpr) {
            // Direct array access with literal index
            return stateReader.getValue("\(arrayName)[\(literalIndex)]")
        }

        // Otherwise, evaluate the index expression to get the actual index
        let indexValue = evaluate(indexExpr, using: stateReader)

        // Convert the result to an integer index
        if let index = indexValue as? Int {
            // Build the keypath with the resolved index
            return stateReader.getValue("\(arrayName)[\(index)]")
        }

        return nil
    }

    /// Match expressions like `items.contains("value")` or `items.contains(varName)`.
    private func matchContainsExpression(_ expression: String, using stateReader: StateValueReading) -> (arrayPath: String, value: Any)? {
        // Pattern: path.contains("stringLiteral") or path.contains(variableName)
        guard let containsRange = expression.range(of: ".contains(") else { return nil }
        guard expression.hasSuffix(")") else { return nil }

        let arrayPath = String(expression[..<containsRange.lowerBound])
        let argsStart = containsRange.upperBound
        let argsEnd = expression.index(before: expression.endIndex)
        let args = String(expression[argsStart..<argsEnd])

        // Check if it's a string literal "value" or 'value'
        if (args.hasPrefix("\"") && args.hasSuffix("\"")) ||
           (args.hasPrefix("'") && args.hasSuffix("'")) {
            let value = String(args.dropFirst().dropLast())
            return (arrayPath, value)
        }

        // Otherwise treat as a variable reference
        if let varValue = stateReader.getValue(args) {
            return (arrayPath, varValue)
        }

        return nil
    }

    // MARK: - Arithmetic

    /// Evaluate simple arithmetic expressions.
    private func evaluateArithmetic(_ expression: String, using stateReader: StateValueReading) -> Any {
        var normalized = expression.trimmingCharacters(in: .whitespaces)

        // Strip outer parentheses if present
        if normalized.hasPrefix("(") && normalized.hasSuffix(")") {
            let inner = String(normalized.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            // Make sure we're not removing function call parens by checking for balanced parens
            var parenCount = 0
            var valid = true
            for char in inner {
                if char == "(" { parenCount += 1 }
                else if char == ")" { parenCount -= 1 }
                if parenCount < 0 { valid = false; break }
            }
            if valid && parenCount == 0 {
                normalized = inner
            }
        }

        // Normalize spacing around operators for easier parsing
        normalized = normalized.replacingOccurrences(of: "%", with: " % ")
        normalized = normalized.replacingOccurrences(of: "*", with: " * ")
        normalized = normalized.replacingOccurrences(of: "/", with: " / ")
        normalized = normalized.replacingOccurrences(of: "+", with: " + ")
        normalized = normalized.replacingOccurrences(of: "-", with: " - ")

        // Clean up multiple spaces
        while normalized.contains("  ") {
            normalized = normalized.replacingOccurrences(of: "  ", with: " ")
        }
        normalized = normalized.trimmingCharacters(in: .whitespaces)

        // Try modulo (highest precedence of these operators)
        if let modRange = normalized.range(of: " % ") {
            let left = String(normalized[..<modRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(normalized[modRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let leftNum = resolveIntValue(left, using: stateReader),
               let rightNum = resolveIntValue(right, using: stateReader),
               rightNum != 0 {
                return leftNum % rightNum
            }
        }

        // Try multiplication
        if let mulRange = normalized.range(of: " * ") {
            let left = String(normalized[..<mulRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(normalized[mulRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let leftNum = resolveIntValue(left, using: stateReader),
               let rightNum = resolveIntValue(right, using: stateReader) {
                return leftNum * rightNum
            }
        }

        // Try division
        if let divRange = normalized.range(of: " / ") {
            let left = String(normalized[..<divRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(normalized[divRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let leftNum = resolveIntValue(left, using: stateReader),
               let rightNum = resolveIntValue(right, using: stateReader),
               rightNum != 0 {
                return leftNum / rightNum
            }
        }

        // Try to evaluate as simple addition
        if let addRange = normalized.range(of: " + ") {
            let left = String(normalized[..<addRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(normalized[addRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let leftNum = resolveIntValue(left, using: stateReader),
               let rightNum = resolveIntValue(right, using: stateReader) {
                return leftNum + rightNum
            }
        }

        // Try to evaluate as simple subtraction
        if let subRange = normalized.range(of: " - ") {
            let left = String(normalized[..<subRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(normalized[subRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let leftNum = resolveIntValue(left, using: stateReader),
               let rightNum = resolveIntValue(right, using: stateReader) {
                return leftNum - rightNum
            }
        }

        return normalized
    }

    /// Resolve a string to an integer value - either parse as literal or look up in state
    private func resolveIntValue(_ string: String, using stateReader: StateValueReading) -> Int? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        // Remove parentheses if present
        var cleaned = trimmed
        if cleaned.hasPrefix("(") && cleaned.hasSuffix(")") {
            cleaned = String(cleaned.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        }

        // Try parsing as integer literal
        if let int = Int(cleaned) {
            return int
        }

        // Try recursively evaluating (for nested expressions)
        if cleaned.contains("+") || cleaned.contains("-") || cleaned.contains("*") || cleaned.contains("/") || cleaned.contains("%") {
            let result = evaluateArithmetic(cleaned, using: stateReader)
            if let int = result as? Int {
                return int
            }
        }

        // Try looking up as state variable
        if let value = stateReader.getValue(cleaned) {
            if let int = value as? Int {
                return int
            }
        }

        return nil
    }

    // MARK: - Helpers

    /// Check if a string contains template syntax ${...} using regex.
    /// Matches patterns like: "${count}", "Hello ${name}", "Item ${(index + 1)}"
    private func containsTemplates(_ string: String) -> Bool {
        let pattern = #"\$\{[^}]+\}"#

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(string.startIndex..., in: string)
            return regex.firstMatch(in: string, range: range) != nil
        } catch {
            return false
        }
    }

    /// Check if a string looks like an arithmetic expression using regex.
    /// Matches patterns like: "5 + 3", "count - 1", "(index + 1) % 3", "count + 1 - 3"
    private func isArithmeticExpression(_ string: String) -> Bool {
        // Pattern matches arithmetic expressions with one or more operations
        // Supports: operands (variables/numbers), operators (+,-,*,/,%), parentheses, and spaces
        // Examples: "5 + 3", "count - 1", "(index + 1) % 3", "a + b * c"

        // Simplified: just check if it contains at least one arithmetic operator surrounded by valid characters
        // This is more permissive but will catch expressions like "(a + b) % c"
        let pattern = #"[\w\.\)]\s*[\+\-\*/%]\s*[\w\.\(]"#

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(string.startIndex..., in: string)
            return regex.firstMatch(in: string, range: range) != nil
        } catch {
            return false
        }
    }

    /// Convert any value to a string representation.
    private func stringValue(from value: Any?) -> String {
        switch value {
        case let int as Int: return String(int)
        case let double as Double: return String(double)
        case let string as String: return string
        case let bool as Bool: return String(bool)
        case nil: return ""
        default: return String(describing: value)
        }
    }
}

// MARK: - Convenience Extensions

extension ExpressionEvaluator {
    /// Check if a string contains expression syntax (${...}).
    public func containsExpression(_ string: String) -> Bool {
        return string.contains("${") && string.contains("}")
    }

    /// Check if a string is a pure expression (starts with ${ and ends with }).
    public func isPureExpression(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("${") && trimmed.hasSuffix("}")
    }

    /// Extract the expression from a ${...} wrapper.
    public func unwrapExpression(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("${") && trimmed.hasSuffix("}") else { return nil }
        return String(trimmed.dropFirst(2).dropLast())
    }
}
