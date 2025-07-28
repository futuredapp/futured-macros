# FuturedMacros

Swift macros used by Futured.

## Features
- **EnumIdentable**
  - Can be applied to enum to add `Identifiable` conformance.
  - Example:
    ```swift
    @EnumIdentable
    enum Status {
        case loading
        case loaded(data: String)
        case error(Error)
    }
    // Status now conforms to Identifiable, Hashable, Equatable
    ```

- **ProxyMembers**
  - Exposes members of a property on the enclosing type by generating dynamic member lookup subscripts.
  - Reduces boilerplate when you want to access nested properties directly.
  - Example:
    ```swift
    struct InnerData {
        var value: String
    }

    @dynamicMemberLookup
    struct Container {
        @ProxyMembers var inner: InnerData
    }

    var container = Container(inner: .init(value: "Hello"))
    print(container.value) // Prints "Hello"
    container.value = "World" // Direct property access works too
    ```

## Installation

When using Swift package manager install using or add following line to your dependencies:

```swift
    .package(url: "https://github.com/futuredapp/futured-macros", from: "0.1.0")
```

## Contributions

All contributions are welcome.

Current maintainer and main contributor is [Šimon Šesták](https://github.com/ssestak), <simon.sestak@futured.app>.

## License

FuturedMacros is available under the MIT license. See the [LICENSE file](LICENSE) for more information.
