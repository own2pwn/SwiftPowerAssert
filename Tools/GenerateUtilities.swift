#!/usr/bin/env xcrun swift

import Foundation

var cases = ""

let data = try! String(contentsOf: URL(string: "https://www.unicode.org/Public/UNIDATA/EastAsianWidth.txt")!)
data.enumerateLines { (line, stop) in
    let commentRemoved = line.replacingOccurrences(of: "\\#.*", with: "", options: .regularExpression)

    let regex = try! NSRegularExpression(pattern: "([0-9a-fA-F]+)\\.\\.([0-9a-fA-F]+);([a-zA-Z]+)")
    let result = regex.firstMatch(in: commentRemoved, range: NSRange(commentRemoved.startIndex..., in: commentRemoved))
    if let result = result {
        let from = String(commentRemoved[Range(result.range(at: 1), in: commentRemoved)!])
        let to = String(commentRemoved[Range(result.range(at: 2), in: commentRemoved)!])
        let property = String(commentRemoved[Range(result.range(at: 3), in: commentRemoved)!])

        switch property {
        case "F", "W": cases += "        case 0x\(from)...0x\(to): return 2\n"
        case "A": cases += "        case 0x\(from)...0x\(to): return inEastAsian ? 2 : 1\n"
        default: break
        }
    } else {
        let regex = try! NSRegularExpression(pattern: "([0-9a-fA-F]+);([a-zA-Z]+)")
        let result = regex.firstMatch(in: commentRemoved, range: NSRange(commentRemoved.startIndex..., in: commentRemoved))
        if let result = result {
            let codePoint = String(commentRemoved[Range(result.range(at: 1), in: commentRemoved)!])
            let property = String(commentRemoved[Range(result.range(at: 2), in: commentRemoved)!])

            switch property {
            case "F", "W": cases += "        case 0x\(codePoint): return 2\n"
            case "A": cases += "        case 0x\(codePoint): return inEastAsian ? 2 : 1\n"
            default: break
            }
        }
    }
}

var header = """
    //===----------------------------------------------------------------------===//
    // Automatically Generated From Tools/GenerateUtilities.swift
    //===----------------------------------------------------------------------===//

    import Foundation
    import XCTest

    public struct __Util {}

    """

var displayWidth = """
    extension __Util {
        public static func displayWidth(of s: String, inEastAsian: Bool = false) -> Int {
            return s.unicodeScalars.reduce(0) { $0 + displayWidth(of: $1, inEastAsian: inEastAsian) }
        }
        private static func displayWidth(of s: UnicodeScalar, inEastAsian: Bool) -> Int {
            switch s.value {
    \(cases)        default: return 1
            }
        }
    }

    """

var helperFunctions = """
    extension __Util {
        static func escapeString(_ s: String) -> String {
            return s
                .replacingOccurrences(of: "\\\\"", with: "\\\\\\\\\\\\"")
                .replacingOccurrences(of: "\\\\t", with: "\\\\\\\\t")
                .replacingOccurrences(of: "\\\\r", with: "\\\\\\\\r")
                .replacingOccurrences(of: "\\\\n", with: "\\\\\\\\n")
                .replacingOccurrences(of: "\\\\0", with: "\\\\\\\\0")
        }
        static func valueToString<T>(_ value: T?) -> String {
            switch value {
            case .some(let v) where v is String || v is Selector: return "\\\\"\\\\(__Util.escapeString("\\\\(v)"))\\\\""
            case .some(let v): return "\\\\(v)".replacingOccurrences(of: "\\\\n", with: " ")
            case .none: return "nil"
            }
        }
        static func align(_ message: inout String, current: inout Int, column: Int, string: String) {
            while current < column - 1 {
                message += " "
                current += 1
            }
            message += string
            current += __Util.displayWidth(of: string)
        }
    }
    class __ValueRecorder {
        let assertion: String
        let lineNumber: UInt
        let verbose: Bool
        let inUnitTests: Bool

        var result = true
        var originalMessage = ""
        var values = [__Value]()
        var errors = [Error]()

        init(assertion: String, lineNumber: UInt, verbose: Bool = false, inUnitTests: Bool = false) {
            self.assertion = assertion
            self.lineNumber = lineNumber
            self.verbose = verbose
            self.inUnitTests = inUnitTests
        }

        func assertBoolean(_ expression: @autoclosure () throws -> (Bool), _ op: (Bool, Bool) -> Bool) -> __ValueRecorder {
            do {
                let value = try expression()
                result = op(value, true)
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertBoolean(_ expression: @autoclosure () throws -> (Bool, message: String), _ op: (Bool, Bool) -> Bool) -> __ValueRecorder {
            do {
                let (value, message) = try expression()
                result = op(value, true)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertBoolean(_ expression: @autoclosure () throws -> (Bool, message: String, file: StaticString), _ op: (Bool, Bool) -> Bool) -> __ValueRecorder {
            do {
                let (value, message, _) = try expression()
                result = op(value, true)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertBoolean(_ expression: @autoclosure () throws -> (Bool, message: String, file: StaticString, line: UInt), _ op: (Bool, Bool) -> Bool) -> __ValueRecorder {
            do {
                let (value, message, _, _) = try expression()
                result = op(value, true)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }

        func assertEquality<T>(_ expression: @autoclosure () throws -> (T, T), _ op: (T, T) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs) = try expression()
                result = op(lhs, rhs)
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (T, T, message: String), _ op: (T, T) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (T, T, message: String, file: StaticString), _ op: (T, T) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (T, T, message: String, file: StaticString, line: UInt), _ op: (T, T) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }

        func assertEquality<T>(_ expression: @autoclosure () throws -> (T?, T?), _ op: (T?, T?) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs) = try expression()
                result = op(lhs, rhs)
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (T?, T?, message: String), _ op: (T?, T?) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (T?, T?, message: String, file: StaticString), _ op: (T?, T?) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (T?, T?, message: String, file: StaticString, line: UInt), _ op: (T?, T?) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }

        func assertEquality<T>(_ expression: @autoclosure () throws -> ([T], [T]), _ op: ([T], [T]) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs) = try expression()
                result = op(lhs, rhs)
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> ([T], [T], message: String), _ op: ([T], [T]) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> ([T], [T], message: String, file: StaticString), _ op: ([T], [T]) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> ([T], [T], message: String, file: StaticString, line: UInt), _ op: ([T], [T]) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }

        func assertEquality<T>(_ expression: @autoclosure () throws -> (ArraySlice<T>, ArraySlice<T>), _ op: (ArraySlice<T>, ArraySlice<T>) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs) = try expression()
                result = op(lhs, rhs)
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (ArraySlice<T>, ArraySlice<T>, message: String), _ op: (ArraySlice<T>, ArraySlice<T>) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (ArraySlice<T>, ArraySlice<T>, message: String, file: StaticString), _ op: (ArraySlice<T>, ArraySlice<T>) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (ArraySlice<T>, ArraySlice<T>, message: String, file: StaticString, line: UInt), _ op: (ArraySlice<T>, ArraySlice<T>) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }

        func assertEquality<T>(_ expression: @autoclosure () throws -> (ContiguousArray<T>, ContiguousArray<T>), _ op: (ContiguousArray<T>, ContiguousArray<T>) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs) = try expression()
                result = op(lhs, rhs)
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (ContiguousArray<T>, ContiguousArray<T>, message: String), _ op: (ContiguousArray<T>, ContiguousArray<T>) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (ContiguousArray<T>, ContiguousArray<T>, message: String, file: StaticString), _ op: (ContiguousArray<T>, ContiguousArray<T>) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T>(_ expression: @autoclosure () throws -> (ContiguousArray<T>, ContiguousArray<T>, message: String, file: StaticString, line: UInt), _ op: (ContiguousArray<T>, ContiguousArray<T>) -> Bool) -> __ValueRecorder where T: Equatable {
            do {
                let (lhs, rhs, message, _, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }

        func assertEquality<T, U>(_ expression: @autoclosure () throws -> ([T: U], [T: U]), _ op: ([T: U], [T: U]) -> Bool) -> __ValueRecorder where U : Equatable {
            do {
                let (lhs, rhs) = try expression()
                result = op(lhs, rhs)
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T, U>(_ expression: @autoclosure () throws -> ([T: U], [T: U], message: String), _ op: ([T: U], [T: U]) -> Bool) -> __ValueRecorder where U : Equatable {
            do {
                let (lhs, rhs, message) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T, U>(_ expression: @autoclosure () throws -> ([T: U], [T: U], message: String, file: StaticString), _ op: ([T: U], [T: U]) -> Bool) -> __ValueRecorder where U : Equatable {
            do {
                let (lhs, rhs, message, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertEquality<T, U>(_ expression: @autoclosure () throws -> ([T: U], [T: U], message: String, file: StaticString, line: UInt), _ op: ([T: U], [T: U]) -> Bool) -> __ValueRecorder where U : Equatable {
            do {
                let (lhs, rhs, message, _, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }

        func assertComparable<T>(_ expression: @autoclosure () throws -> (T, T), _ op: (T, T) -> Bool) -> __ValueRecorder where T: Comparable {
            do {
                let (lhs, rhs) = try expression()
                result = op(lhs, rhs)
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertComparable<T>(_ expression: @autoclosure () throws -> (T, T, message: String), _ op: (T, T) -> Bool) -> __ValueRecorder where T: Comparable {
            do {
                let (lhs, rhs, message) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertComparable<T>(_ expression: @autoclosure () throws -> (T, T, message: String, file: StaticString), _ op: (T, T) -> Bool) -> __ValueRecorder where T: Comparable {
            do {
                let (lhs, rhs, message, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertComparable<T>(_ expression: @autoclosure () throws -> (T, T, message: String, file: StaticString, line: UInt), _ op: (T, T) -> Bool) -> __ValueRecorder where T: Comparable {
            do {
                let (lhs, rhs, message, _, _) = try expression()
                result = op(lhs, rhs)
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }


        func assertNil(_ expression: @autoclosure () throws -> (Any?)) -> __ValueRecorder {
            do {
                let value = try expression()
                result = value == nil
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertNil(_ expression: @autoclosure () throws -> (Any?, message: String)) -> __ValueRecorder {
            do {
                let (value, message) = try expression()
                result = value == nil
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertNil(_ expression: @autoclosure () throws -> (Any?, message: String, file: StaticString)) -> __ValueRecorder {
            do {
                let (value, message, _) = try expression()
                result = value == nil
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertNil(_ expression: @autoclosure () throws -> (Any?, message: String, file: StaticString, line: UInt)) -> __ValueRecorder {
            do {
                let (value, message, _, _) = try expression()
                result = value == nil
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertNotNil(_ expression: @autoclosure () throws -> (Any?)) -> __ValueRecorder {
            do {
                let value = try expression()
                result = value != nil
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertNotNil(_ expression: @autoclosure () throws -> (Any?, message: String)) -> __ValueRecorder {
            do {
                let (value, message) = try expression()
                result = value != nil
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertNotNil(_ expression: @autoclosure () throws -> (Any?, message: String, file: StaticString)) -> __ValueRecorder {
            do {
                let (value, message, _) = try expression()
                result = value != nil
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }
        func assertNotNil(_ expression: @autoclosure () throws -> (Any?, message: String, file: StaticString, line: UInt)) -> __ValueRecorder {
            do {
                let (value, message, _, _) = try expression()
                result = value != nil
                originalMessage = message
            } catch {
                errors.append(error)
            }
            return self
        }

        func record<T>(expression: @autoclosure () throws -> T?, column: Int) -> __ValueRecorder {
            do {
                values.append(__Value(value: __Util.valueToString(try expression()), column: column))
            } catch {
                errors.append(error)
            }
            return self
        }
        func render() {
            if !result || verbose {
                var message = ""
                message += "\\\\(assertion)\\\\n"
                values.sort()
                var current = 0
                for value in values {
                    __Util.align(&message, current: &current, column: value.column, string: "|")
                }
                message += "\\\\n"
                while !values.isEmpty {
                    var current = 0
                    var index = 0
                    while index < values.count {
                        if index == values.count - 1 || ((values[index].column + values[index].value.count < values[index + 1].column) && values[index].value.unicodeScalars.filter({ !$0.isASCII }).isEmpty) {
                            __Util.align(&message, current: &current, column: values[index].column, string: values[index].value)
                            values.remove(at: index)
                        } else {
                            __Util.align(&message, current: &current, column: values[index].column, string: "|")
                            index += 1
                        }
                    }
                    message += "\\\\n"
                }
                if verbose || inUnitTests {
                    print(message, terminator: \"\")
                }
                if !result && !inUnitTests {
                    XCTFail("\\\\(originalMessage)\\\\n" + message, line: lineNumber)
                }
            }
        }
    }
    struct __Value {
        let value: String
        let column: Int
    }
    extension __Value: Comparable {
        static func <(lhs: __Value, rhs: __Value) -> Bool {
            return lhs.column < rhs.column
        }
        static func ==(lhs: __Value, rhs: __Value) -> Bool {
            return lhs.column == rhs.column
        }
    }

    """

let sourceCode = header + displayWidth + """
    extension __Util {
        public static var source: String {
            let source = \"\"\"
    \((header + displayWidth + helperFunctions).split(separator: "\n").map { String(repeating: " ", count: 4 * 3) + $0 }.joined(separator: "\n"))
                \"\"\"
            return source
        }
    }

    """

try! sourceCode.write(to: URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("../Sources/SwiftPowerAssertCore/Utilities.swift"), atomically: true, encoding: .utf8)
