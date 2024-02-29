import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct HeapStorage {}

extension HeapStorage: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else { fatalError() }
        guard variable.isStored else { fatalError() }
        guard let type = variable.type?.type.trimmed else { fatalError() }

        if let initializer = variable.initializerValue {
            return ["private var _\(raw: variable.identifier): StoredOnHeap<\(raw: type)> = .init(wrappedValue: \(raw: initializer))"]
        } else {
            return ["private var _\(raw: variable.identifier): StoredOnHeap<\(raw: type)>"]
        }
    }
}

extension HeapStorage: AccessorMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else { fatalError() }
        guard variable.isStored else { fatalError() }
        if variable.initializerValue != nil {
            return [
                "get { _\(raw: variable.identifier).wrappedValue }",
                "set { _\(raw: variable.identifier).wrappedValue = newValue }"
            ]
        } else {
            return [
                """
                @storageRestrictions(initializes: _\(raw: variable.identifier))
                init(initialValue) {
                    _\(raw: variable.identifier) = .init(wrappedValue: initialValue)
                }
                """,
                "get { _\(raw: variable.identifier).wrappedValue }",
                "set { _\(raw: variable.identifier).wrappedValue = newValue }"
            ]
        }
    }
}

extension VariableDeclSyntax {
    public var isComputed: Bool {

        return bindings.contains {
            switch $0.accessorBlock?.accessors {
            case .none:
                return false
            case let .some(.accessors(list)):
                return !list.allSatisfy {
                    $0.accessorSpecifier.trimmed.text == "willSet"
                    || $0.accessorSpecifier.trimmed.text == "didSet"
                }
            case .getter:
                return true
            }
        }

        //return bindings.contains(where: { $0.accessorBlock?.is(CodeBlockSyntax.self) == true })
    }
    public var isStored: Bool {
        return !isComputed
    }
    public var isStatic: Bool {
        return modifiers.lazy.contains(where: { $0.name.tokenKind == .keyword(.static) }) == true
    }
    public var identifier: TokenSyntax {
        return bindings.lazy.compactMap({ $0.pattern.as(IdentifierPatternSyntax.self) }).first!
            .identifier
    }

    public var type: TypeAnnotationSyntax? {
        return bindings.lazy.compactMap(\.typeAnnotation).first
    }

    public var initializerValue: ExprSyntax? {
        return bindings.lazy.compactMap(\.initializer).first?.value
    }

    public var effectSpecifiers: AccessorEffectSpecifiersSyntax? {
        return bindings
            .lazy
            .compactMap(\.accessorBlock?.accessors)
            .compactMap({ accessor in
                switch accessor {
                case .accessors(let syntax):
                    return syntax.lazy.compactMap(\.effectSpecifiers).first
                case .getter:
                    return nil
                }
            })
            .first
    }
    public var isThrowing: Bool {
        return bindings
            .compactMap(\.accessorBlock?.accessors)
            .contains(where: { accessor in
                switch accessor {
                case .accessors(let syntax):
                    return syntax.contains(where: { $0.effectSpecifiers?.throwsSpecifier != nil })
                case .getter:
                    return false
                }
            })
    }
    public var isAsync: Bool {
        return bindings
            .compactMap(\.accessorBlock?.accessors)
            .contains(where: { accessor in
                switch accessor {
                case .accessors(let syntax):
                    return syntax.lazy.contains(where: { $0.effectSpecifiers?.asyncSpecifier != nil })
                case .getter:
                    return false
                }
            })
    }
}

@main
struct HeapStorageMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HeapStorage.self,
    ]
}
