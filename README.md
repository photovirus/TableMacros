# TableMacros
A tiny macros library for Bridges+Vapor projects. It offers semi-automated creation of DTO structs.

## How to use
The package has a `@DTOModel` macro which must be applied to a `Table`-compliant class. Its only parameter must be one of: `.create`, `.update`, and `.output`. They'll make the macro create `DTOCreate`, `DTOUpdate`, or `DTOOutput` structs, as well as extending the model to comply with [BridgesModelProtocols](https://github.com/photovirus/BridgesModelProtocols).

`@DTOModel` works in pair with one of two other macros:

- `@DTOProperty` is applied to individual properties and can be used to make any DTO struct;
- `@DTOInit` is applied to an initializer and is used to create a `DTOCreate` from that. Much faster than marking properties, but can be used only for `DTOCreate`.

### Usage example

(`BasicModel` is `Table`-compliant)

```swift
@DTOModel(.create)
@DTOModel(.update)
@DTOModel(.output)
public final class Shop: BasicModel {

    public static var tableName: String { "shops" }

    @DTOProperty(.output)
    @Column("id")
    public var id: UUID

    @DTOProperty(.update, .required)
    @DTOProperty(.output)
    @Column("name")
    public var name: String

    @DTOProperty(.update, .required)
    @DTOProperty(.output)
    @Column("logo")
    public var image: UUID

    @DTOProperty(.output)
    @Column("createdAt")
    public var createdAt: Date

    @DTOProperty(.output)
    @Column("updatedAt")
    public var updatedAt: Date

    @Column("deletedAt")
    public var deletedAt: Date?

    public init () {}

    @DTOInit(.create)
    public init(
        id: UUID,
        name: String,
        image: UUID
    ) {
        let now = Date()
        self.id = id
        self.name = name
        self.image = image
        createdAt = now
        updatedAt = now
    }

}
```

This code will expand to:

```swift
public struct DTOCreate {
    public let id: UUID
    public let name: String
    public let image: UUID
    public init(id: UUID, name: String, image: UUID) {
        self.id = id
        self.name = name
        self.image = image
    }
}

public struct DTOUpdate {
    public let name: String
    public let image: UUID
    public init(name: String, image: UUID) {
        self.name = name
        self.image = image
    }
}

public struct DTOOutput {
    public let id: UUID
    public let name: String
    public let image: UUID
    public let createdAt: Date
    public let updatedAt: Date
    public typealias Model = Shop
    public init(id: UUID, name: String, image: UUID, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.image = image
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    public init(with model: Model) {
        self.init(id: model.id, name: model.name, image: model.image, createdAt: model.createdAt, updatedAt: model.updatedAt)
    }
}
```
