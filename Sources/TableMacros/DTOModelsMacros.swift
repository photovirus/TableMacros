//
//  DTOModelsMacros.swift
//
//
//  Created by Yakov Shapovalov on 10.06.2023.
//

import BridgesModelProtocols
import SharedModels

@attached(member, names: named(DTOCreate), named(DTOUpdate), named(DTOOutput))
@attached(extension, names: named(Create), named(init(with:)), conformances: CreateableModel)
public macro DTOModel(_ purpose: DTOModelPurpose) = #externalMacro(module: "TableMacrosMacros", type: "DTOModelMacro")

@attached(peer)
public macro DTOProperty(_ purpose: DTOModelPurpose, _ require: DTOPropertyRequired? = nil) = #externalMacro(module: "TableMacrosMacros", type: "DTOPropertyMacro")

@attached(peer)
public macro DTOInit(_ purpose: DTOModelPurpose) = #externalMacro(module: "TableMacrosMacros", type: "DTOInitMacro")
