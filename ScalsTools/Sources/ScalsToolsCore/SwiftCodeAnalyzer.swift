//
//  SwiftCodeAnalyzer.swift
//  ScalsToolsCore
//
//  Utilities for analyzing Swift code using SwiftSyntax
//

import Foundation
import SwiftSyntax
import SwiftParser

/// Analyzes Swift source code to extract information about types, properties, and methods
public struct SwiftCodeAnalyzer {
    public init() {}

    public func analyze(sourceCode: String) throws -> CodeAnalysis {
        let sourceFile = Parser.parse(source: sourceCode)
        let analyzer = CodeVisitor(viewMode: .sourceAccurate)
        analyzer.walk(Syntax(sourceFile))
        return analyzer.analysis
    }

    public func analyzeFile(at url: URL) throws -> CodeAnalysis {
        let source = try String(contentsOf: url, encoding: .utf8)
        return try analyze(sourceCode: source)
    }
}

/// Results of code analysis
public struct CodeAnalysis {
    public var structs: [StructInfo] = []
    public var classes: [ClassInfo] = []
    public var enums: [EnumInfo] = []
    public var protocols: [ProtocolInfo] = []
    public var functions: [FunctionInfo] = []
    public var properties: [PropertyInfo] = []
}

public struct StructInfo {
    public let name: String
    public let properties: [PropertyInfo]
    public let methods: [FunctionInfo]
    public let conformances: [String]

    public init(name: String, properties: [PropertyInfo], methods: [FunctionInfo], conformances: [String]) {
        self.name = name
        self.properties = properties
        self.methods = methods
        self.conformances = conformances
    }
}

public struct ClassInfo {
    public let name: String
    public let properties: [PropertyInfo]
    public let methods: [FunctionInfo]
    public let conformances: [String]
    public let isPublic: Bool
}

public struct EnumInfo {
    public let name: String
    public let cases: [String]
    public let conformances: [String]
}

public struct ProtocolInfo {
    public let name: String
    public let requirements: [String]
}

public struct FunctionInfo {
    public let name: String
    public let parameters: [ParameterInfo]
    public let returnType: String?
    public let isPublic: Bool
}

public struct ParameterInfo {
    public let name: String
    public let type: String
}

public struct PropertyInfo {
    public let name: String
    public let type: String
    public let isPublic: Bool
    public let isStatic: Bool
    public let isConstant: Bool
}

/// Visitor to traverse Swift syntax tree and extract information
private class CodeVisitor: SyntaxVisitor {
    var analysis = CodeAnalysis()

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        var properties: [PropertyInfo] = []
        var methods: [FunctionInfo] = []

        // Extract members
        for member in node.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                properties.append(contentsOf: extractProperties(from: varDecl))
            } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                methods.append(extractFunction(from: funcDecl))
            }
        }

        let conformances = extractConformances(from: node.inheritanceClause)

        analysis.structs.append(StructInfo(
            name: name,
            properties: properties,
            methods: methods,
            conformances: conformances
        ))

        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        let isPublic = node.modifiers.contains { $0.name.text == "public" }
        var properties: [PropertyInfo] = []
        var methods: [FunctionInfo] = []

        for member in node.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                properties.append(contentsOf: extractProperties(from: varDecl))
            } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                methods.append(extractFunction(from: funcDecl))
            }
        }

        let conformances = extractConformances(from: node.inheritanceClause)

        analysis.classes.append(ClassInfo(
            name: name,
            properties: properties,
            methods: methods,
            conformances: conformances,
            isPublic: isPublic
        ))

        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        var cases: [String] = []

        for member in node.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    cases.append(element.name.text)
                }
            }
        }

        let conformances = extractConformances(from: node.inheritanceClause)

        analysis.enums.append(EnumInfo(
            name: name,
            cases: cases,
            conformances: conformances
        ))

        return .visitChildren
    }

    private func extractProperties(from node: VariableDeclSyntax) -> [PropertyInfo] {
        let isPublic = node.modifiers.contains { $0.name.text == "public" }
        let isStatic = node.modifiers.contains { $0.name.text == "static" }
        let isConstant = node.bindingSpecifier.text == "let"

        return node.bindings.compactMap { binding in
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation else {
                return nil
            }

            return PropertyInfo(
                name: pattern.identifier.text,
                type: typeAnnotation.type.description.trimmingCharacters(in: .whitespaces),
                isPublic: isPublic,
                isStatic: isStatic,
                isConstant: isConstant
            )
        }
    }

    private func extractFunction(from node: FunctionDeclSyntax) -> FunctionInfo {
        let isPublic = node.modifiers.contains { $0.name.text == "public" }
        let name = node.name.text

        let parameters = node.signature.parameterClause.parameters.map { param in
            ParameterInfo(
                name: param.secondName?.text ?? param.firstName.text,
                type: param.type.description.trimmingCharacters(in: .whitespaces)
            )
        }

        let returnType = node.signature.returnClause?.type.description.trimmingCharacters(in: .whitespaces)

        return FunctionInfo(
            name: name,
            parameters: parameters,
            returnType: returnType,
            isPublic: isPublic
        )
    }

    private func extractConformances(from clause: InheritanceClauseSyntax?) -> [String] {
        guard let clause = clause else { return [] }
        return clause.inheritedTypes.map { $0.type.description.trimmingCharacters(in: .whitespaces) }
    }
}
