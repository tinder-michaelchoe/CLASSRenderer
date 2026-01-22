//
//  Document+JSON.swift
//  ScalsRendererFramework
//
//  Provides JSON parsing initializers for Document.
//

import Foundation

// MARK: - Parse Error

public enum DocumentParseError: Error, LocalizedError {
    case invalidEncoding
    case decodingError(DecodingError)

    public var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Invalid string encoding"
        case .decodingError(let error):
            return "JSON decoding error: \(error.localizedDescription)"
        }
    }
    
    /// Returns a detailed, human-readable description of a parsing error
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - jsonString: The original JSON string (for context)
    /// - Returns: A detailed error description with location info
    public static func detailedDescription(error: Error, jsonString: String) -> String {
        var output = ""
        
        if let parseError = error as? DocumentParseError {
            switch parseError {
            case .invalidEncoding:
                return "Invalid UTF-8 encoding in JSON string"
                
            case .decodingError(let decodingError):
                output += formatDecodingError(decodingError, jsonString: jsonString)
            }
        } else if let decodingError = error as? DecodingError {
            output += formatDecodingError(decodingError, jsonString: jsonString)
        } else {
            output += "Unknown error: \(error.localizedDescription)"
        }
        
        return output
    }
    
    private static func formatDecodingError(_ error: DecodingError, jsonString: String) -> String {
        var output = ""
        
        switch error {
        case .typeMismatch(let type, let context):
            output += "Type Mismatch:\n"
            output += "  Expected: \(type)\n"
            output += "  Path: \(formatCodingPath(context.codingPath))\n"
            output += "  \(context.debugDescription)\n"
            
        case .valueNotFound(let type, let context):
            output += "Value Not Found:\n"
            output += "  Expected: \(type)\n"
            output += "  Path: \(formatCodingPath(context.codingPath))\n"
            output += "  \(context.debugDescription)\n"
            
        case .keyNotFound(let key, let context):
            output += "Missing Required Key:\n"
            output += "  Key: \"\(key.stringValue)\"\n"
            output += "  Path: \(formatCodingPath(context.codingPath))\n"
            output += "  \(context.debugDescription)\n"
            
        case .dataCorrupted(let context):
            output += "Data Corrupted:\n"
            output += "  Path: \(formatCodingPath(context.codingPath))\n"
            output += "  \(context.debugDescription)\n"
            if let underlyingError = context.underlyingError {
                output += "  Underlying: \(underlyingError.localizedDescription)\n"
            }
            
        @unknown default:
            output += "Unknown decoding error: \(error.localizedDescription)\n"
        }
        
        // Add context from JSON if we can find the location
        if let lineInfo = findErrorLocation(in: jsonString, error: error) {
            output += "\nNear line \(lineInfo.line):\n"
            output += "  \(lineInfo.content)\n"
        }
        
        return output
    }
    
    private static func formatCodingPath(_ path: [CodingKey]) -> String {
        if path.isEmpty { return "root" }
        return path.map { key in
            if let intValue = key.intValue {
                return "[\(intValue)]"
            }
            return key.stringValue
        }.joined(separator: ".")
    }
    
    private static func findErrorLocation(in jsonString: String, error: DecodingError) -> (line: Int, content: String)? {
        // Extract the path from the error
        let path: [CodingKey]
        switch error {
        case .typeMismatch(_, let context): path = context.codingPath
        case .valueNotFound(_, let context): path = context.codingPath
        case .keyNotFound(_, let context): path = context.codingPath
        case .dataCorrupted(let context): path = context.codingPath
        @unknown default: return nil
        }
        
        guard !path.isEmpty else { return nil }
        
        // Try to find the last key in the JSON
        let lastKey = path.last?.stringValue ?? ""
        let lines = jsonString.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            if line.contains("\"\(lastKey)\"") {
                return (line: index + 1, content: line.trimmingCharacters(in: .whitespaces))
            }
        }
        
        return nil
    }
}

// MARK: - JSON Initializers

extension Document.Definition {
    /// Initialize a Document.Definition from a JSON string
    /// - Parameter jsonString: The JSON string to parse
    /// - Throws: `DocumentParseError` if parsing fails
    public init(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw DocumentParseError.invalidEncoding
        }
        try self.init(jsonData: data)
    }

    /// Initialize a Document.Definition from JSON data
    /// - Parameter jsonData: The JSON data to parse
    /// - Throws: `DocumentParseError` if parsing fails
    public init(jsonData: Data) throws {
        let decoder = JSONDecoder()
        do {
            self = try decoder.decode(Document.Definition.self, from: jsonData)
        } catch let error as DecodingError {
            throw DocumentParseError.decodingError(error)
        }
    }
}
