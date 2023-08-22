//
//  CompilerPlugin.swift
//
//
//  Created by Yakov Shapovalov on 10.06.2023.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TableMacrosPlugin: CompilerPlugin {

    let providingMacros: [Macro.Type] = [
        DTOModelMacro.self,
        DTOPropertyMacro.self,
        DTOInitMacro.self,
    ]

}
