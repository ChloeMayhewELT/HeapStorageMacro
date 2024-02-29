// The Swift Programming Language
// https://docs.swift.org/swift-book

import ComposableArchitecture

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(_))
public macro HeapStorage() = #externalMacro(module: "HeapStorageMacroMacros", type: "HeapStorage")
