//
//  DTOProperty.swift
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

final class DTOPropertyMacroTests: XCTestCase {

    static let testMacros: [String: Macro.Type] = [
        "DTOProperty": DTOPropertyMacro.self,
    ]

    func testCreateSuccess() {
        assertMacroExpansion(
            """
            @DTOModel(.create)
            class TestModel: BasicModel {

                @DTOProperty(.create, .optional)
                var createOptionalVariable: TestType

                @DTOProperty(.create, .required)
                var createRequiredVariable: TestType2

                var notCreateVariable: TestType3

                init(
                    createOptionalVariable: TestType,
                    createRequiredVariable: TestType2?,
                    notCreateVariable: TestType3
                ) {}
            }
            """,
            expandedSource: """
            @DTOModel(.create)
            class TestModel: BasicModel {
                var createOptionalVariable: TestType
                var createRequiredVariable: TestType2

                var notCreateVariable: TestType3

                init(
                    createOptionalVariable: TestType,
                    createRequiredVariable: TestType2?,
                    notCreateVariable: TestType3
                ) {}
            }
            """,
            macros: Self.testMacros
        )
    }

    func testOutputSuccess() {
        assertMacroExpansion(
            """
            @DTOModel(.output)
            class TestModel: BasicModel {

                @DTOProperty(.output)
                var createOptionalVariable: TestType

                @DTOProperty(.output)
                var createRequiredVariable: TestType2

                var notCreateVariable: TestType3

                init(
                    createOptionalVariable: TestType?,
                    createRequiredVariable: TestType2,
                    notCreateVariable: TestType3
                ) {}
            }
            """,
            expandedSource: """
            @DTOModel(.output)
            class TestModel: BasicModel {
                var createOptionalVariable: TestType
                var createRequiredVariable: TestType2

                var notCreateVariable: TestType3

                init(
                    createOptionalVariable: TestType?,
                    createRequiredVariable: TestType2,
                    notCreateVariable: TestType3
                ) {}
            }
            """,
            macros: Self.testMacros
        )
    }

    func testNoPurposeError() {
        let inputCodeBlocks = [
                """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    @DTOProperty(.optional)
                    var createOptionalVariable: TestType
                }
                """,
        ]
        inputCodeBlocks.forEach { block in
            assertMacroExpansion(
                block,
                expandedSource: """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    var createOptionalVariable: TestType
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Expected DTOModelPurpose as a first parameter", line: 3, column: 5),
                ],
                macros: Self.testMacros
            )
        }
    }

    func testNoParamsErrors() {
        let inputCodeBlocks = [
                """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    @DTOProperty
                    var createOptionalVariable: TestType
                }
                """,
        ]
        inputCodeBlocks.forEach { block in
            assertMacroExpansion(
                block,
                expandedSource: """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    var createOptionalVariable: TestType
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Expected DTOModelPurpose as a first parameter", line: 3, column: 5),
                ],
                macros: Self.testMacros
            )
        }
    }

    func testNoRequiredError() {
        let inputCodeBlocks = [
                """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    @DTOProperty(.create)
                    var createOptionalVariable: TestType
                }
                """
        ]
        inputCodeBlocks.forEach { block in
            assertMacroExpansion(
                block,
                expandedSource: """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    var createOptionalVariable: TestType
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Expected DTOPropertyRequired as a second parameter", line: 3, column: 5),
                ],
                macros: Self.testMacros
            )
        }
    }

    func testApplicableToVarsError() {
        let inputCodeBlocks = [
                """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    @DTOProperty(.create, .optional)
                    enum createEnum: TestType {}
                }
                """
        ]
        inputCodeBlocks.forEach { block in
            assertMacroExpansion(
                block,
                expandedSource: """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    enum createEnum: TestType {}
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "@DTOProperty can only be applied to a variable", line: 3, column: 5),
                ],
                macros: Self.testMacros
            )
        }
    }

//    func testApplicableToDTOModelError() {
//        let inputCodeBlocks = [
//                """
//                class TestModel: BasicModel {
//                    @DTOProperty(.create, .optional)
//                    var createOptionalVariable: TestType
//                }
//                """
//        ]
//        inputCodeBlocks.forEach { block in
//            assertMacroExpansion(
//                block,
//                expandedSource: """
//                class TestModel: BasicModel {
//                    var createOptionalVariable: TestType
//                }
//                """,
//                diagnostics: [
//                    DiagnosticSpec(message: "@DTOProperty can only used in a @DTOModel class", line: 2, column: 5),
//                ],
//                macros: Self.testMacros
//            )
//        }
//    }

}

