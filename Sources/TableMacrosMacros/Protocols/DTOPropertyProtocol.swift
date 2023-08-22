//
//  DTOPropertyProtocol.swift
//
//
//  Created by Yakov Shapovalov on 22.06.2023.
//

import SwiftSyntax

protocol DTOPropertyProtocol {

    var pattern: PatternSyntax { get }
    var typeAnnotation: TypeAnnotationSyntax { get }

}
