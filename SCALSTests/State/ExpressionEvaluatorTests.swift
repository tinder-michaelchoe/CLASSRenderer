//
//  ExpressionEvaluatorTests.swift
//  SCALSTests
//
//  Unit tests for ExpressionEvaluator.
//

import Testing
@testable import SCALS

// MARK: - Mock State Reader

/// Mock implementation of StateValueReading for testing
struct MockStateReader: StateValueReading {
    var values: [String: Any] = [:]
    var arrays: [String: [Any]] = [:]

    func getValue(_ keypath: String) -> Any? {
        // Check for array indexing like "items[0]"
        if let openBracket = keypath.firstIndex(of: "["),
           let closeBracket = keypath.lastIndex(of: "]"),
           openBracket < closeBracket {
            let arrayName = String(keypath[..<openBracket])
            let indexStr = String(keypath[keypath.index(after: openBracket)..<closeBracket])

            if let index = Int(indexStr),
               let array = arrays[arrayName],
               index >= 0 && index < array.count {
                return array[index]
            }
            return nil
        }

        // Regular value lookup
        return values[keypath]
    }

    func getArray(_ keypath: String) -> [Any]? {
        arrays[keypath]
    }

    func arrayContains(_ keypath: String, value: Any) -> Bool {
        guard let array = arrays[keypath] else { return false }
        return array.contains { item in
            if let itemStr = item as? String, let valueStr = value as? String {
                return itemStr == valueStr
            }
            if let itemInt = item as? Int, let valueInt = value as? Int {
                return itemInt == valueInt
            }
            return false
        }
    }

    func getArrayCount(_ keypath: String) -> Int {
        arrays[keypath]?.count ?? 0
    }
}

// MARK: - Arithmetic Tests

struct ExpressionEvaluatorArithmeticTests {
    let evaluator = ExpressionEvaluator()

    @Test func additionWithPositiveNumbers() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("${count} + 3", using: state)
        #expect(result as? Int == 8)
    }

    @Test func additionWithZero() {
        var state = MockStateReader()
        state.values["count"] = 0

        let result = evaluator.evaluate("${count} + 1", using: state)
        #expect(result as? Int == 1)
    }

    @Test func subtractionWithPositiveResult() {
        var state = MockStateReader()
        state.values["count"] = 10

        let result = evaluator.evaluate("${count} - 3", using: state)
        #expect(result as? Int == 7)
    }

    @Test func subtractionWithNegativeResult() {
        var state = MockStateReader()
        state.values["count"] = 0

        let result = evaluator.evaluate("${count} - 1", using: state)
        #expect(result as? Int == -1)
    }

    @Test func subtractionFromNegativeNumber() {
        var state = MockStateReader()
        state.values["count"] = -5

        let result = evaluator.evaluate("${count} - 3", using: state)
        #expect(result as? Int == -8)
    }

    @Test func additionToNegativeNumber() {
        var state = MockStateReader()
        state.values["count"] = -5

        let result = evaluator.evaluate("${count} + 3", using: state)
        #expect(result as? Int == -2)
    }

    @Test func subtractionResultingInZero() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("${count} - 5", using: state)
        #expect(result as? Int == 0)
    }

    @Test func modulo() {
        var state = MockStateReader()
        state.values["count"] = 7

        let result = evaluator.evaluate("${count} % 3", using: state)
        #expect(result as? Int == 1)
    }

    @Test func moduloWithZeroResult() {
        var state = MockStateReader()
        state.values["count"] = 9

        let result = evaluator.evaluate("${count} % 3", using: state)
        #expect(result as? Int == 0)
    }

    @Test func moduloForCycling() {
        var state = MockStateReader()
        state.values["currentImageIndex"] = 2

        let result = evaluator.evaluate("(currentImageIndex + 1) % 3", using: state)
        #expect(result as? Int == 0)
    }

    @Test func multiplication() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("${count} * 3", using: state)
        #expect(result as? Int == 15)
    }

    @Test func multiplicationByZero() {
        var state = MockStateReader()
        state.values["count"] = 7

        let result = evaluator.evaluate("${count} * 0", using: state)
        #expect(result as? Int == 0)
    }

    @Test func division() {
        var state = MockStateReader()
        state.values["count"] = 15

        let result = evaluator.evaluate("${count} / 3", using: state)
        #expect(result as? Int == 5)
    }

    @Test func divisionWithRemainder() {
        var state = MockStateReader()
        state.values["count"] = 7

        let result = evaluator.evaluate("${count} / 2", using: state)
        #expect(result as? Int == 3)
    }
}

// MARK: - Comprehensive Arithmetic Tests

struct ExpressionEvaluatorComprehensiveArithmeticTests {
    let evaluator = ExpressionEvaluator()

    // MARK: Variable + Number Operations

    @Test func variablePlusNumber() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("count + 3", using: state)
        #expect(result as? Int == 8)
    }

    @Test func variableMinusNumber() {
        var state = MockStateReader()
        state.values["count"] = 10

        let result = evaluator.evaluate("count - 3", using: state)
        #expect(result as? Int == 7)
    }

    @Test func variableTimesNumber() {
        var state = MockStateReader()
        state.values["count"] = 4

        let result = evaluator.evaluate("count * 5", using: state)
        #expect(result as? Int == 20)
    }

    @Test func variableDividedByNumber() {
        var state = MockStateReader()
        state.values["count"] = 20

        let result = evaluator.evaluate("count / 4", using: state)
        #expect(result as? Int == 5)
    }

    @Test func variableModuloNumber() {
        var state = MockStateReader()
        state.values["count"] = 7

        let result = evaluator.evaluate("count % 3", using: state)
        #expect(result as? Int == 1)
    }

    // MARK: Number + Variable Operations

    @Test func numberPlusVariable() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("3 + count", using: state)
        #expect(result as? Int == 8)
    }

    @Test func numberMinusVariable() {
        var state = MockStateReader()
        state.values["count"] = 3

        let result = evaluator.evaluate("10 - count", using: state)
        #expect(result as? Int == 7)
    }

    @Test func numberTimesVariable() {
        var state = MockStateReader()
        state.values["count"] = 4

        let result = evaluator.evaluate("5 * count", using: state)
        #expect(result as? Int == 20)
    }

    @Test func numberDividedByVariable() {
        var state = MockStateReader()
        state.values["count"] = 4

        let result = evaluator.evaluate("20 / count", using: state)
        #expect(result as? Int == 5)
    }

    @Test func numberModuloVariable() {
        var state = MockStateReader()
        state.values["count"] = 3

        let result = evaluator.evaluate("7 % count", using: state)
        #expect(result as? Int == 1)
    }

    // MARK: Variable + Variable Operations

    @Test func variablePlusVariable() {
        var state = MockStateReader()
        state.values["a"] = 5
        state.values["b"] = 3

        let result = evaluator.evaluate("a + b", using: state)
        #expect(result as? Int == 8)
    }

    @Test func variableMinusVariable() {
        var state = MockStateReader()
        state.values["a"] = 10
        state.values["b"] = 3

        let result = evaluator.evaluate("a - b", using: state)
        #expect(result as? Int == 7)
    }

    @Test func variableTimesVariable() {
        var state = MockStateReader()
        state.values["a"] = 4
        state.values["b"] = 5

        let result = evaluator.evaluate("a * b", using: state)
        #expect(result as? Int == 20)
    }

    @Test func variableDividedByVariable() {
        var state = MockStateReader()
        state.values["a"] = 20
        state.values["b"] = 4

        let result = evaluator.evaluate("a / b", using: state)
        #expect(result as? Int == 5)
    }

    @Test func variableModuloVariable() {
        var state = MockStateReader()
        state.values["a"] = 7
        state.values["b"] = 3

        let result = evaluator.evaluate("a % b", using: state)
        #expect(result as? Int == 1)
    }

    // MARK: Chained Operations (Multiple Operators)

    @Test func additionAndSubtraction() {
        var state = MockStateReader()
        state.values["count"] = 10

        let result = evaluator.evaluate("count + 5 - 3", using: state)
        #expect(result as? Int == 12)
    }

    @Test func multipleAdditions() {
        var state = MockStateReader()
        state.values["a"] = 1
        state.values["b"] = 2
        state.values["c"] = 3

        let result = evaluator.evaluate("a + b + c", using: state)
        #expect(result as? Int == 6)
    }

    @Test func multiplicationAndDivision() {
        var state = MockStateReader()
        state.values["count"] = 10

        let result = evaluator.evaluate("count * 2 / 5", using: state)
        #expect(result as? Int == 4)
    }

    @Test func complexChainedExpression() {
        var state = MockStateReader()
        state.values["a"] = 10
        state.values["b"] = 5
        state.values["c"] = 2

        let result = evaluator.evaluate("a + b - c * 2", using: state)
        // Note: This evaluates left-to-right, not with proper precedence
        // 10 + 5 = 15, 15 - 2 = 13, 13 * 2 = 26
        #expect(result as? Int == 26)
    }

    // MARK: Operations with Parentheses

    @Test func parenthesesAdditionThenModulo() {
        var state = MockStateReader()
        state.values["index"] = 2

        let result = evaluator.evaluate("(index + 1) % 3", using: state)
        #expect(result as? Int == 0)
    }

    @Test func parenthesesMultiplication() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("(count + 2) * 3", using: state)
        #expect(result as? Int == 21)
    }

    @Test func parenthesesWithSpaces() {
        var state = MockStateReader()
        state.values["value"] = 10

        let result = evaluator.evaluate("( value - 5 ) / 5", using: state)
        #expect(result as? Int == 1)
    }

    // MARK: Different Spacing Variations

    @Test func noSpacesAroundOperator() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("count+3", using: state)
        #expect(result as? Int == 8)
    }

    @Test func extraSpacesAroundOperator() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("count   +   3", using: state)
        #expect(result as? Int == 8)
    }

    @Test func spacesAtStartAndEnd() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("  count + 3  ", using: state)
        #expect(result as? Int == 8)
    }

    // MARK: Template Strings with Arithmetic

    @Test func templateWithArithmeticInside() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.evaluate("${count} + 1", using: state)
        #expect(result as? Int == 6)
    }

    @Test func templateWithMultipleVariables() {
        var state = MockStateReader()
        state.values["a"] = 10
        state.values["b"] = 3

        let result = evaluator.evaluate("${a} - ${b}", using: state)
        #expect(result as? Int == 7)
    }

    @Test func interpolateWithArithmetic() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.interpolate("Result: ${(count * 2)}", using: state)
        #expect(result == "Result: 10")
    }

    @Test func interpolateComplexArithmetic() {
        var state = MockStateReader()
        state.values["count"] = 5

        let result = evaluator.interpolate("Double: ${(count * 2)}, Half: ${(count / 2)}", using: state)
        #expect(result == "Double: 10, Half: 2")
    }

    // MARK: Property Access in Arithmetic

    @Test func propertyAccessInArithmetic() {
        var state = MockStateReader()
        state.values["user.age"] = 25

        let result = evaluator.evaluate("user.age + 5", using: state)
        #expect(result as? Int == 30)
    }

    // MARK: Edge Cases That Should NOT Match Arithmetic

    @Test func hyphenatedText() {
        var state = MockStateReader()

        let result = evaluator.evaluate("5-star rating", using: state)
        // Should return as-is, not try to evaluate as arithmetic
        #expect(result as? String == "5-star rating")
    }

    @Test func emailAddress() {
        var state = MockStateReader()

        let result = evaluator.evaluate("user@domain.com", using: state)
        #expect(result as? String == "user@domain.com")
    }

    @Test func justText() {
        var state = MockStateReader()

        let result = evaluator.evaluate("Hello World", using: state)
        #expect(result as? String == "Hello World")
    }

    @Test func textWithOperatorButNoOperands() {
        var state = MockStateReader()

        let result = evaluator.evaluate("Price: $10 + tax", using: state)
        // Should not match arithmetic pattern
        #expect(result as? String == "Price: $10 + tax")
    }

    // MARK: Zero and Boundary Cases

    @Test func divisionResultingInZero() {
        var state = MockStateReader()
        state.values["count"] = 2

        let result = evaluator.evaluate("count / 5", using: state)
        #expect(result as? Int == 0)
    }

    @Test func moduloResultingInOriginalNumber() {
        var state = MockStateReader()
        state.values["count"] = 2

        let result = evaluator.evaluate("count % 5", using: state)
        #expect(result as? Int == 2)
    }

    @Test func multiplicationResultingInLargeNumber() {
        var state = MockStateReader()
        state.values["count"] = 1000

        let result = evaluator.evaluate("count * 1000", using: state)
        #expect(result as? Int == 1000000)
    }

    // MARK: Parentheses in the Middle Tests (Bug Fix)

    @Test func parenthesesInMiddleWithModulo() {
        var state = MockStateReader()
        state.values["currentImageIndex"] = 2

        let result = evaluator.evaluate("(currentImageIndex + 1) % 3", using: state)
        #expect(result as? Int == 0)
    }

    @Test func parenthesesInMiddleWithMultiplication() {
        var state = MockStateReader()
        state.values["value"] = 5

        let result = evaluator.evaluate("(value + 2) * 3", using: state)
        #expect(result as? Int == 21)
    }

    @Test func nestedParenthesesExpression() {
        var state = MockStateReader()
        state.values["a"] = 10
        state.values["b"] = 5

        let result = evaluator.evaluate("(a + b) - 3", using: state)
        #expect(result as? Int == 12)
    }
}

// MARK: - Interpolation Tests

struct ExpressionEvaluatorInterpolationTests {
    let evaluator = ExpressionEvaluator()

    @Test func simpleInterpolation() {
        var state = MockStateReader()
        state.values["name"] = "John"

        let result = evaluator.interpolate("Hello ${name}!", using: state)
        #expect(result == "Hello John!")
    }

    @Test func multipleInterpolations() {
        var state = MockStateReader()
        state.values["firstName"] = "John"
        state.values["lastName"] = "Doe"

        let result = evaluator.interpolate("${firstName} ${lastName}", using: state)
        #expect(result == "John Doe")
    }

    @Test func integerInterpolation() {
        var state = MockStateReader()
        state.values["count"] = 42

        let result = evaluator.interpolate("Count: ${count}", using: state)
        #expect(result == "Count: 42")
    }

    @Test func missingValueInterpolation() {
        let state = MockStateReader()

        let result = evaluator.interpolate("Value: ${missing}", using: state)
        #expect(result == "Value: ")
    }

    @Test func noInterpolation() {
        let state = MockStateReader()

        let result = evaluator.interpolate("Plain text", using: state)
        #expect(result == "Plain text")
    }
}

// MARK: - Ternary Expression Tests

struct ExpressionEvaluatorTernaryTests {
    let evaluator = ExpressionEvaluator()

    @Test func ternaryWithTrueCondition() {
        var state = MockStateReader()
        state.values["isActive"] = true

        let result = evaluator.evaluate("isActive ? 'ON' : 'OFF'", using: state)
        #expect(result as? String == "ON")
    }

    @Test func ternaryWithFalseCondition() {
        var state = MockStateReader()
        state.values["isActive"] = false

        let result = evaluator.evaluate("isActive ? 'ON' : 'OFF'", using: state)
        #expect(result as? String == "OFF")
    }

    @Test func ternaryWithNegation() {
        var state = MockStateReader()
        state.values["isActive"] = true

        let result = evaluator.evaluate("!isActive ? 'OFF' : 'ON'", using: state)
        #expect(result as? String == "ON")
    }

    @Test func ternaryWithDoubleQuotes() {
        var state = MockStateReader()
        state.values["isActive"] = true

        let result = evaluator.evaluate("isActive ? \"yes\" : \"no\"", using: state)
        #expect(result as? String == "yes")
    }

    @Test func ternaryWithLiteralTrue() {
        let state = MockStateReader()

        let result = evaluator.evaluate("true ? 'yes' : 'no'", using: state)
        #expect(result as? String == "yes")
    }

    @Test func ternaryWithLiteralFalse() {
        let state = MockStateReader()

        let result = evaluator.evaluate("false ? 'yes' : 'no'", using: state)
        #expect(result as? String == "no")
    }
}

// MARK: - Array Expression Tests

struct ExpressionEvaluatorArrayTests {
    let evaluator = ExpressionEvaluator()

    @Test func arrayCount() {
        var state = MockStateReader()
        state.arrays["items"] = ["a", "b", "c"]

        let result = evaluator.evaluate("items.count", using: state)
        #expect(result as? Int == 3)
    }

    @Test func arrayCountEmpty() {
        var state = MockStateReader()
        state.arrays["items"] = []

        let result = evaluator.evaluate("items.count", using: state)
        #expect(result as? Int == 0)
    }

    @Test func arrayIsEmptyTrue() {
        var state = MockStateReader()
        state.arrays["items"] = []

        let result = evaluator.evaluate("items.isEmpty", using: state)
        #expect(result as? Bool == true)
    }

    @Test func arrayIsEmptyFalse() {
        var state = MockStateReader()
        state.arrays["items"] = ["a"]

        let result = evaluator.evaluate("items.isEmpty", using: state)
        #expect(result as? Bool == false)
    }

    @Test func arrayFirst() {
        var state = MockStateReader()
        state.arrays["items"] = ["first", "second", "third"]

        let result = evaluator.evaluate("items.first", using: state)
        #expect(result as? String == "first")
    }

    @Test func arrayLast() {
        var state = MockStateReader()
        state.arrays["items"] = ["first", "second", "third"]

        let result = evaluator.evaluate("items.last", using: state)
        #expect(result as? String == "third")
    }

    @Test func arrayContainsWithStringLiteral() {
        var state = MockStateReader()
        state.arrays["tags"] = ["swift", "ios", "clads"]

        let result = evaluator.evaluate("tags.contains(\"swift\")", using: state)
        #expect(result as? Bool == true)
    }

    @Test func arrayContainsWithSingleQuotes() {
        var state = MockStateReader()
        state.arrays["tags"] = ["swift", "ios", "clads"]

        let result = evaluator.evaluate("tags.contains('ios')", using: state)
        #expect(result as? Bool == true)
    }

    @Test func arrayContainsFalse() {
        var state = MockStateReader()
        state.arrays["tags"] = ["swift", "ios", "clads"]

        let result = evaluator.evaluate("tags.contains('android')", using: state)
        #expect(result as? Bool == false)
    }

    @Test func arrayContainsWithVariable() {
        var state = MockStateReader()
        state.arrays["tags"] = ["swift", "ios", "clads"]
        state.values["searchTag"] = "clads"

        let result = evaluator.evaluate("tags.contains(searchTag)", using: state)
        #expect(result as? Bool == true)
    }

    @Test func arrayCountInInterpolation() {
        var state = MockStateReader()
        state.arrays["items"] = ["a", "b", "c"]

        let result = evaluator.interpolate("You have ${items.count} items", using: state)
        #expect(result == "You have 3 items")
    }

    // MARK: Dynamic Array Indexing Tests

    @Test func dynamicArrayIndexWithLiteral() {
        var state = MockStateReader()
        state.arrays["items"] = ["apple", "banana", "cherry"]

        let result = evaluator.evaluate("items[1]", using: state)
        #expect(result as? String == "banana")
    }

    @Test func dynamicArrayIndexWithVariable() {
        var state = MockStateReader()
        state.arrays["items"] = ["apple", "banana", "cherry"]
        state.values["currentIndex"] = 2

        let result = evaluator.evaluate("items[currentIndex]", using: state)
        #expect(result as? String == "cherry")
    }

    @Test func dynamicArrayIndexWithArithmetic() {
        var state = MockStateReader()
        state.arrays["imageUrls"] = [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg",
            "https://example.com/image3.jpg"
        ]
        state.values["currentImageIndex"] = 1

        let result = evaluator.evaluate("imageUrls[currentImageIndex]", using: state)
        #expect(result as? String == "https://example.com/image2.jpg")
    }

    @Test func dynamicArrayIndexCycling() {
        var state = MockStateReader()
        state.arrays["items"] = ["a", "b", "c"]
        state.values["index"] = 2

        // Test cycling: (2 + 1) % 3 = 0
        let newIndex = evaluator.evaluate("(index + 1) % 3", using: state)
        #expect(newIndex as? Int == 0)

        // Update state with new index
        state.values["index"] = newIndex as! Int

        // Access array with cycled index
        let result = evaluator.evaluate("items[index]", using: state)
        #expect(result as? String == "a")
    }

    @Test func dynamicArrayIndexInInterpolation() {
        var state = MockStateReader()
        state.arrays["fruits"] = ["🍎 Apple", "🍌 Banana", "🍒 Cherry"]
        state.values["selected"] = 1

        let result = evaluator.interpolate("Selected: ${fruits[selected]}", using: state)
        #expect(result == "Selected: 🍌 Banana")
    }

    @Test func dynamicArrayIndexOutOfBounds() {
        var state = MockStateReader()
        state.arrays["items"] = ["a", "b", "c"]
        state.values["index"] = 10

        let result = evaluator.evaluate("items[index]", using: state)
        // Should return nil for out of bounds
        #expect(result == nil)
    }
}

// MARK: - Convenience Method Tests

struct ExpressionEvaluatorConvenienceTests {
    let evaluator = ExpressionEvaluator()

    @Test func containsExpressionTrue() {
        #expect(evaluator.containsExpression("Hello ${name}!") == true)
    }

    @Test func containsExpressionFalse() {
        #expect(evaluator.containsExpression("Hello World!") == false)
    }

    @Test func isPureExpressionTrue() {
        #expect(evaluator.isPureExpression("${count}") == true)
    }

    @Test func isPureExpressionWithWhitespace() {
        #expect(evaluator.isPureExpression("  ${count}  ") == true)
    }

    @Test func isPureExpressionFalse() {
        #expect(evaluator.isPureExpression("Count: ${count}") == false)
    }

    @Test func unwrapExpression() {
        let result = evaluator.unwrapExpression("${count}")
        #expect(result == "count")
    }

    @Test func unwrapExpressionWithWhitespace() {
        let result = evaluator.unwrapExpression("  ${user.name}  ")
        #expect(result == "user.name")
    }

    @Test func unwrapExpressionInvalid() {
        let result = evaluator.unwrapExpression("not an expression")
        #expect(result == nil)
    }
}
