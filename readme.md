# swift-macro-init

Swift Macro for synthesizing `init()` functions.

## How to use

1. Add `.package(url: "https://github.com/fizker/swift-macro-init.git", branch: "main")` to the list of dependencies in your Package.swift file.
2. Add `.product(name: "InitMacro", package: "swift-macro-init")` to the dependencies of the targets that need to use the models.
3. Ensure that `platforms: []` contains the required minimum for macros to function. The following is the minimum for the various Apple platforms:
   - `.iOS(.v13)`
   - `.macCatalyst(.v13)`
   - `.macOS(.v10_15)`
   - `.tvOS(.v13)`
   - `.watchOS(.v6)`


## Examples

The following includes a `public init()` that includes all properties

```swift
import InitMacro

@Init
public struct Foo {
	var a: String
	var b: MyType
	var c = 2
}
```

In this example, the `init()` will have the following implementation:

```swift
public init(a: String, b: MyType, c: Int = 2) {
	self.a = a
	self.b = b
	self.c = c
}
```

By default, the `init()` will have the same access modifier as the type. This can be overridden:

```swift
@Init(access: .internal)
public struct Foo {
}
```
