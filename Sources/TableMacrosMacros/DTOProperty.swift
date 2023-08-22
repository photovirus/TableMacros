//
//  DTOProperty.swift
//  
//
//  Created by Yakov Shapovalov on 12.06.2023.
//

import SharedModels
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DTOPropertyDiagnostic: String, DiagnosticMessage {

    case expectPurpose
    case expectRequired
    case onlyApplicableToVariables
    case onlyApplicableToDTOModelVars

    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .expectPurpose: return "Expected DTOModelPurpose as a first parameter"
        case .expectRequired: return "Expected DTOPropertyRequired as a second parameter"
        case .onlyApplicableToVariables: return "@DTOProperty can only be applied to a variable"
        case .onlyApplicableToDTOModelVars: return "@DTOProperty can only used in a @DTOModel class"
        }
    }

    var diagnosticID: MessageID {
        .init(domain: "TableMacros", id: rawValue)
    }
}

public struct DTOPropertyMacro: PeerMacro {

    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingPeersOf declaration: Declaration, in context: Context) throws -> [DeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {

        var propertyDiagnostics = [DiagnosticMessage]()

        if declaration.as(VariableDeclSyntax.self) == nil {
            propertyDiagnostics.append( DTOPropertyDiagnostic.onlyApplicableToVariables)
        }

        if let argumentsTuple = LabeledExprListSyntax(node.arguments),
           let memberAccessFirst = MemberAccessExprSyntax(argumentsTuple.first?.expression),
           let purpose = DTOModelPurpose(rawValue: memberAccessFirst.declName.baseName.text) {
            if purpose != .output {
                if let memberAccessLast = MemberAccessExprSyntax(argumentsTuple.last?.expression),
                   DTOPropertyRequired(rawValue: memberAccessLast.declName.baseName.text) != nil {} else {
                    propertyDiagnostics.append( DTOPropertyDiagnostic.expectRequired)
                }
            }
        } else {
               propertyDiagnostics.append( DTOPropertyDiagnostic.expectPurpose)
        }

//        if let classParent = ClassDeclSyntax(declaration.parent?.parent?.parent?.parent),
//           let attributes = AttributeListSyntax(classParent.attributes),
//           let isCalledInDTOModel = attributes.compactMap({ AttributeSyntax($0) }).reduce(into: false, { result, attribute in
//               if IdentifierTypeSyntax(attribute.attributeName)?.name.text == "DTOModel" { result = true }
//           }),
//           isCalledInDTOModel {} else {
//               propertyDiagnostics.append( DTOPropertyDiagnostic.onlyApplicableToDTOModelVars)
//           }

        let diagNode = node.as(Syntax.self)!
        propertyDiagnostics.forEach { propertyDiagnostic in
            let diagnostic = Diagnostic(node: diagNode, message: propertyDiagnostic)
            context.diagnose(diagnostic)
        }

        return []
    }
}

