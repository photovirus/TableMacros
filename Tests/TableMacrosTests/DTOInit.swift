//
//  DTOInit.swift
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
// #if canImport(TableMacrosMacros)
// #else
//   throw XCTSkip("macros are only supported when running tests for the host platform")
// #endif

final class DTOInitMacroTests: XCTestCase {

    static let testMacros: [String: Macro.Type] = [
        "DTOInit": DTOInitMacro.self,
    ]

    func testCreateSuccess() {
        assertMacroExpansion(
            """
            @DTOModel(.create)
            class TestModel: BasicModel {

                var createOptionalVariable: TestType
                var createRequiredVariable: TestType2
                var notCreateVariable: TestType3

                @DTOInit(.create)
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

    func testNoPurposeError() {
        let inputCodeBlocks = [
                """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    var createOptionalVariable: TestType

                    @DTOInit()
                    init(
                        createOptionalVariable: TestType,
                    )
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
                    init(
                        createOptionalVariable: TestType,
                    )
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Expected DTOModelPurpose as a first parameter", line: 5, column: 5),
                ],
                macros: Self.testMacros
            )
        }
    }

    func testApplicableToInitsError() {
        let inputCodeBlocks = [
                """
                @DTOModel(.create)
                class TestModel: BasicModel {
                    @DTOInit(.create)
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
                    DiagnosticSpec(message: "@DTOInit can only be applied to an initializer", line: 3, column: 5),
                ],
                macros: Self.testMacros
            )
        }
    }

//    func testApplicableToDTOModelError() {
//        let inputCodeBlocks = [
//                """
//                class TestModel: BasicModel {
//                    var createOptionalVariable: TestType
//
//                    @DTOInit(.create)
//                    init(
//                        createOptionalVariable: TestType,
//                    )
//                }
//                """
//        ]
//        inputCodeBlocks.forEach { block in
//            assertMacroExpansion(
//                block,
//                expandedSource: """
//                class TestModel: BasicModel {
//                    var createOptionalVariable: TestType
//                    init(
//                        createOptionalVariable: TestType,
//                    )
//                }
//                """,
//                diagnostics: [
//                    DiagnosticSpec(message: "@DTOInit can only used in a @DTOModel class", line: 4, column: 5),
//                ],
//                macros: Self.testMacros
//            )
//        }
//    }


}
