//
//  DTOModelPurpose.swift
//
//
//  Created by Yakov Shapovalov on 22.08.2023.
//

public enum DTOModelPurpose: String {
    case create, update, output

    public var structName: String { get {
        return switch self {
        case .create: "DTOCreate"
        case .update: "DTOUpdate"
        case .output: "DTOOutput"
        }
    }}
}
