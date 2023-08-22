//
//  DTOModel.swift
//
//
//  Created by Yakov Shapovalov on 10.06.2023.
//

import SharedModels
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DTOModelError: CustomStringConvertible, Error {

    case noPropertiesOrInitPresent

    var description: String {
        switch self {
        case .noPropertiesOrInitPresent: return "No '@DTOProperty' or '@DTOInit' markers found"
        }
    }
}

enum DTOModelDiagnostic: String, DiagnosticMessage {

    case bothPropertiesAndInitPresent
    case expectPurpose
    case noPropertiesOrInitFound
    case onlyApplicableToBasicModel
    case onlyApplicableToClass

    var severity: DiagnosticSeverity {

        switch self {
        case .noPropertiesOrInitFound: return .warning
        case .bothPropertiesAndInitPresent,
             .expectPurpose,
             .onlyApplicableToBasicModel,
             .onlyApplicableToClass: return .error
        }
    }

    var message: String {
        switch self {
        case .bothPropertiesAndInitPresent: return "`@DTOProperty` and `@DTOInit` macros can't be used for the same `DTOPurpose`. Remove either one or another."
        case .expectPurpose: return "Expected DTOModelPurpose as a first parameter"
        case .noPropertiesOrInitFound: return "'@DTOModel' without both '@DTOProperty' or '@DTOInit' variables does nothing. Consider marking up properties or inits,–or removing the macro altogether"
        case .onlyApplicableToBasicModel: return "@DTOModel can only be applied to a BasicModel instance"
        case .onlyApplicableToClass: return "@DTOModel can only be applied to a class"
        }
    }

    var diagnosticID: MessageID {
        .init(domain: "TableMacros", id: rawValue)
    }

    // TODO: Suggest removing @DTOModel

}

// TODO: Make Create model from primary init (maybe marked up one)
// Maybe Update as well

public struct DTOModelMacro: MemberMacro {

    struct Property: DTOPropertyProtocol {
        var pattern: PatternSyntax,
            typeAnnotation: TypeAnnotationSyntax
    }

    static let propertyMacroName: String = "DTOProperty"
    static let initMacroName: String = "DTOInit"

    public static func expansion<Declaration, Context>(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax]
    where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            let classOnlyError = Diagnostic(node: node.as(Syntax.self)!, message: DTOModelDiagnostic.onlyApplicableToClass)
            context.diagnose(classOnlyError)
            return []
        }

        guard let purpose = Self.getPurpose(from: node, context: context) else {
            return []
        }

        // TODO: check if init or properties used for this macro

        let properties = Self.getPropertiesFromDTOProperties(from: classDecl, context: context, purpose: purpose)

        let initProperties = Self.getPropertiesFromDTOInit(from: classDecl, context: context, purpose: purpose)

        let structDecl: StructDeclSyntax
        switch (!properties.isEmpty, !initProperties.isEmpty) {
        case (true, true):
            let bothPropertiesError = Diagnostic(node: node.as(Syntax.self)!, message: DTOModelDiagnostic.bothPropertiesAndInitPresent)
            context.diagnose(bothPropertiesError)
            return []
        case (true, false):
            structDecl = try Self.makeStructDecl(from: properties, purpose: purpose, classDecl: classDecl)
        case (false, true):
            structDecl = try Self.makeStructDecl(from: initProperties, purpose: purpose, classDecl: classDecl)
        case (false, false):
            let emptyPropertiesWarning = Diagnostic(node: node.as(Syntax.self)!, message: DTOModelDiagnostic.noPropertiesOrInitFound)
            context.diagnose(emptyPropertiesWarning)
            return []
        }

        return [structDecl.as(DeclSyntax.self)!]
    }

    static func getPurpose<Context: MacroExpansionContext>(from node: AttributeSyntax, context: Context) -> DTOModelPurpose? {
        guard let memberName = node.arguments?.as(LabeledExprListSyntax.self)?
            .first?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName,
              let purpose = DTOModelPurpose(rawValue: memberName.text) else {
            let noPurposeError = Diagnostic(node: node.as(Syntax.self)!, message: DTOModelDiagnostic.expectPurpose)
            context.diagnose(noPurposeError)
            return nil
        }
        return purpose
    }

    static func getPropertiesFromDTOProperties<Context: MacroExpansionContext>(from classDecl: ClassDeclSyntax, context: Context, purpose: DTOModelPurpose) -> [Self.Property] {
        let memberList = classDecl.memberBlock.members
        let varList: [VariableDeclSyntax] = memberList.compactMap { member in
            return VariableDeclSyntax(member.decl)
        }
        let properties = varList.reduce(into: [Property]()) { result, varDecl in
            guard let attribute = varDecl.attributes.first(where: { attribute in
                guard let attribute = attribute.as(AttributeSyntax.self),
                      "\(attribute.attributeName)" == Self.propertyMacroName,
                      let attributePurpose = Self.getPurpose(from: attribute, context: context),
                      purpose == attributePurpose else { return false }
                return true
            })
            else { return }

            guard let binding = varDecl.bindings.first,
                  var typeAnnotation = binding.typeAnnotation else { return }

            switch purpose {
            case .output:
                break
            default:
                guard let memberName = attribute.as(AttributeSyntax.self)?
                    .arguments?.as(LabeledExprListSyntax.self)?
                    .last?.expression.as(MemberAccessExprSyntax.self)?
                    .declName.baseName,
                      let required = DTOPropertyRequired(rawValue: memberName.text) else { return }

                if let simpleTypeAnnotation = typeAnnotation.type.as(IdentifierTypeSyntax.self),
                   required == .optional {
                    typeAnnotation = TypeAnnotationSyntax(type: OptionalTypeSyntax(wrappedType: simpleTypeAnnotation))
                }
            }

            result.append(Property(
                pattern: binding.pattern,
                typeAnnotation: typeAnnotation
            ))
        }
        return properties
    }

    static func getPropertiesFromDTOInit<Context: MacroExpansionContext>(from classDecl: ClassDeclSyntax, context: Context, purpose: DTOModelPurpose) -> [Self.Property] {
        let inits: [InitializerDeclSyntax] = classDecl.memberBlock.members.compactMap { member in
            guard let initDeclDTO = member.decl.as(InitializerDeclSyntax.self),
                  let _ = initDeclDTO.attributes.first(where: { attribute in
                      guard let attribute = attribute.as(AttributeSyntax.self),
                            "\(attribute.attributeName)" == Self.initMacroName,
                            let attributePurpose = Self.getPurpose(from: attribute, context: context),
                            purpose == attributePurpose else { return false }
                      return true
                  }) else { return nil }
            return initDeclDTO
        }

        let initDecl = inits.first(where: { initDecl in
            guard let attr = initDecl.attributes.compactMap({ attr in
                attr.as(AttributeSyntax.self)
            }).first(where: { "\($0.attributeName)" == Self.initMacroName }),
                  Self.getPurpose(from: attr, context: context) == purpose
            else { return false }
            return true
        })

        let initProperties = initDecl?.signature.parameterClause.parameters.compactMap { param in
            let token = param.secondName?.text ?? param.firstName.text,
                pattern = PatternSyntax(stringLiteral: "\(token)"),
                typeAnnotation = TypeAnnotationSyntax(type: param.type)
            return Property(
                pattern: pattern,
                typeAnnotation: typeAnnotation
            )
        } ?? [Self.Property]()
        return initProperties
    }

    static func makeStructDecl(from properties: [some DTOPropertyProtocol], purpose: DTOModelPurpose, classDecl: ClassDeclSyntax) throws -> StructDeclSyntax {
        var structMembers: [MemberBlockItemSyntax] = properties.compactMap { property in
                .init(decl: VariableDeclSyntax(modifiers: [DeclModifierSyntax(name: .keyword(.public))], .let, name: property.pattern, type: property.typeAnnotation))
        }

        var structInitDecls = [InitializerDeclSyntax]()
        structInitDecls.append(try Self.makeInitDecl(properties: properties))
        if purpose == .output {
            structInitDecls.append(try makeOutputInitDecl(properties: properties))
        }

        if purpose == .output {
            structMembers.append(.init(decl: makeOutputTypealiasDecl(classDecl: classDecl)))
        }
        structMembers += structInitDecls.map { initDecl in  MemberBlockItemSyntax(decl: initDecl)
        }

        let structDecl = StructDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .init(stringLiteral: purpose.structName),
            inheritanceClause: InheritanceClauseSyntax(inheritedTypesBuilder: {
                .init(type: TypeSyntax(stringLiteral: "Content"))
            }),
            memberBlock: .init(members: .init(structMembers))
        )

        return structDecl
    }

    static func makeInitDecl<P: DTOPropertyProtocol>(properties: [P]) throws -> InitializerDeclSyntax {
        let funcPropsString = "public init(" + properties.map { property -> String in
            "\(property.pattern)\(property.typeAnnotation)"
        }.joined(separator: ", ") + ")"
        let structInitDecl = try InitializerDeclSyntax(SyntaxNodeString("\(raw: funcPropsString)")) {
            CodeBlockItemListSyntax(
                properties.compactMap { property in
                    CodeBlockItemSyntax(
                        item: .expr("self.\(property.pattern) = \(property.pattern)")
                    )
                }
            )
        }
        return structInitDecl
    }

    static func makeOutputTypealiasDecl(classDecl: ClassDeclSyntax) -> TypeAliasDeclSyntax {
        TypeAliasDeclSyntax(modifiers: [DeclModifierSyntax(name: .keyword(.public))], name: .init(stringLiteral: "Model"), initializer: TypeInitializerClauseSyntax(value: TypeSyntax(stringLiteral: classDecl.name.text)))
    }

    static func makeOutputInitDecl<P: DTOPropertyProtocol>(properties: [P]) throws -> InitializerDeclSyntax {
        let funcString = "public init(with model: Model)"

        let structInitDecl = try InitializerDeclSyntax(SyntaxNodeString("\(raw: funcString)")) {
            CodeBlockItemListSyntax(
                arrayLiteral: CodeBlockItemSyntax(
                    item: .expr(FunctionCallExprSyntax(callee: ExprSyntax(stringLiteral: "self.init"), argumentList: {
                        .init(properties.compactMap ({ property in
                            LabeledExprSyntax(label: "\(property.pattern)", expression: ExprSyntax(stringLiteral: "model.\(property.pattern)"))
                        }))
                    }).as(ExprSyntax.self)!)
                )
            )
        }
        return structInitDecl
    }
}
