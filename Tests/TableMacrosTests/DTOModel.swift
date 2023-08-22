//
//  DTOModel.swift
//  
//
//  Created by Yakov Shapovalov on 25.07.2023.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(TableMacrosMacros)
import TableMacrosMacros
#endif

// TODO: implement pragma marks for checking imports

final class DTOModelMacroTests: XCTestCase {

    static let testMacros: [String: Macro.Type] = [
        "DTOModel": DTOModelMacro.self,
        "DTOProperty": DTOPropertyMacro.self,
        "DTOInit": DTOInitMacro.self
    ]

    func testDTOCreateFromProperties() {
        assertMacroExpansion(
            """
            @DTOModel(.create)
            public class TestModel: BasicModel {

                @DTOProperty(.create, .optional)
                public var createOptionalVariable: TestType

                @DTOProperty(.create, .required)
                public var createRequiredVariable: TestType2

                public var notCreateVariable: TestType3

            }
            """,
            expandedSource: """

            public class TestModel: BasicModel {
                public var createOptionalVariable: TestType
                public var createRequiredVariable: TestType2

                public var notCreateVariable: TestType3

                public struct DTOCreate: Content {
                    public let createOptionalVariable: TestType?
                    public let createRequiredVariable: TestType2
                    public init(createOptionalVariable: TestType?, createRequiredVariable: TestType2) {
                        self.createOptionalVariable = createOptionalVariable
                        self.createRequiredVariable = createRequiredVariable
                    }
                }

            }
            """ ,
            macros: Self.testMacros
        )
    }

    func testDTOOutputFromProperties() {
        assertMacroExpansion(
            """
            @DTOModel(.output)
            public class TestModel: BasicModel {

                @DTOProperty(.output)
                public var outputVariable1: TestType1

                @DTOProperty(.output)
                public var outputVariable2: TestType2

                public var notOutputVariable: TestType3

            }
            """,
            expandedSource: """

            public class TestModel: BasicModel {
                public var outputVariable1: TestType1
                public var outputVariable2: TestType2

                public var notOutputVariable: TestType3

                public struct DTOOutput: Content {
                    public let outputVariable1: TestType1
                    public let outputVariable2: TestType2
                    public typealias Model = TestModel
                    public init(outputVariable1: TestType1, outputVariable2: TestType2) {
                        self.outputVariable1 = outputVariable1
                        self.outputVariable2 = outputVariable2
                    }
                    public init(with model: Model) {
                        self.init(outputVariable1: model.outputVariable1, outputVariable2: model.outputVariable2)
                    }
                }

            }
            """ ,
            macros: Self.testMacros
        )
    }

    func testEmptyPropertiesList() {
        assertMacroExpansion(
            """
            @DTOModel(.create)
            public class TestModel: BasicModel {

                public var createOptionalVariable: TestType
                public var createRequiredVariable: TestType2
                public var notCreateVariable: TestType3

            }
            """,
            expandedSource: """

            public class TestModel: BasicModel {

                public var createOptionalVariable: TestType
                public var createRequiredVariable: TestType2
                public var notCreateVariable: TestType3

            }
            """ ,
            diagnostics: [DiagnosticSpec(message: "'@DTOModel' without both '@DTOProperty' or '@DTOInit' variables does nothing. Consider marking up properties or inits,–or removing the macro altogether", line: 1, column: 1, severity: .warning)],
            macros: Self.testMacros
        )
    }

    func testDTOCreateFromInit() {
        assertMacroExpansion(
            """
            @DTOModel(.create)
            public class TestModel: BasicModel {

                public var createOptionalVariable: TestType
                public var createRequiredVariable: TestType2
                public var notCreateVariable: TestType3

                @DTOInit(.create)
                init(
                    with createOptionalVariable: TestType?,
                    createRequiredVariable: TestType2
                ) {}

            }
            """,
            expandedSource: """

            public class TestModel: BasicModel {

                public var createOptionalVariable: TestType
                public var createRequiredVariable: TestType2
                public var notCreateVariable: TestType3
                init(
                    with createOptionalVariable: TestType?,
                    createRequiredVariable: TestType2
                ) {}
            
                public struct DTOCreate: Content {
                    public let createOptionalVariable: TestType?
                    public let createRequiredVariable: TestType2
                    public init(createOptionalVariable: TestType?, createRequiredVariable: TestType2) {
                        self.createOptionalVariable = createOptionalVariable
                        self.createRequiredVariable = createRequiredVariable
                    }
                }

            }
            """ ,
            macros: Self.testMacros
        )
    }
}
