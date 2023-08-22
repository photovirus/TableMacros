//
//  DTOModelsMacros.swift
//
//
//  Created by Yakov Shapovalov on 10.06.2023.
//

import SharedModels

@attached(extension, names: named(CreateableModel))
@attached(member, names: named(DTOCreate), named(DTOUpdate), named(DTOOutput))
public macro DTOModel(_ purpose: DTOModelPurpose) = #externalMacro(module: "TableMacrosMacros", type: "DTOModelMacro")

@attached(peer)
public macro DTOProperty(_ purpose: DTOModelPurpose, _ require: DTOPropertyRequired? = nil) = #externalMacro(module: "TableMacrosMacros", type: "DTOPropertyMacro")

@attached(peer)
public macro DTOInit(_ purpose: DTOModelPurpose) = #externalMacro(module: "TableMacrosMacros", type: "DTOInitMacro")
