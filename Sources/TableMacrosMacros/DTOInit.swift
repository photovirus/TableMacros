//
//  DTOInit.swift
//
//
//  Created by Yakov Shapovalov on 27.06.2023.
//

import SharedModels
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DTOInitDiagnostic: String, DiagnosticMessage {

    case expectPurpose
    case onlyApplicableToInits
    case onlyApplicableToDTOModelInits

    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .expectPurpose: return "Expected DTOModelPurpose as a first parameter"
        case .onlyApplicableToInits: return "@DTOInit can only be applied to an initializer"
        case .onlyApplicableToDTOModelInits: return "@DTOInit can only used in a @DTOModel class"
        }
    }

    var diagnosticID: MessageID {
        .init(domain: "TableMacros", id: rawValue)
    }

}

public struct DTOInitMacro: PeerMacro {

    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingPeersOf declaration: Declaration, in context: Context) throws -> [DeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {

        var initDiagnostics = [DiagnosticMessage]()

        if declaration.as(InitializerDeclSyntax.self) == nil {
            initDiagnostics.append(DTOInitDiagnostic.onlyApplicableToInits)
        }

        if let argumentsTuple = LabeledExprListSyntax(node.arguments),
           let memberAccess = MemberAccessExprSyntax(argumentsTuple.first?.expression),
           let _ = DTOModelPurpose(rawValue: memberAccess.declName.baseName.text) {} else {
               initDiagnostics.append(DTOInitDiagnostic.expectPurpose)
        }

        print(declaration.parent)
//        if let classParent = ClassDeclSyntax(declaration.parent?.parent?.parent?.parent),
//           let attributes = AttributeListSyntax(classParent.attributes),
//           let isCalledInDTOModel = attributes.compactMap({ AttributeSyntax($0) }).reduce(into: false, { result, attribute in
//               if IdentifierTypeSyntax(attribute.attributeName)?.name.description == "DTOModel" { result = true }
//           }),
//           isCalledInDTOModel {} else {
//               initDiagnostics.append(DTOInitDiagnostic.onlyApplicableToDTOModelInits)
//           }

        let diagNode = node.as(Syntax.self)!
        initDiagnostics.forEach { initDiagnostic in
            let diagnostic = Diagnostic(node: diagNode, message: initDiagnostic)
            context.diagnose(diagnostic)
        }

        return []
    }

}
