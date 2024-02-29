import ComposableArchitecture

/// A wrapper for values/objects that should be stored in the heap.
@ObservableState
@propertyWrapper public struct StoredOnHeap<Value> {

    /// Private storage for the wrapped value.
    private var storage: [Value]

    /// Desginated initializer. Creates a new `StoredOnHeap` value.
    /// - Parameter wrappedValue: The value/object to store on the heap.
    public init(wrappedValue: Value) {
        storage = [wrappedValue]
    }

    /// The underlying stored value.
    public var wrappedValue: Value {
        get { storage[0] }
        set { storage[0] = newValue }
    }
}

extension StoredOnHeap: Equatable where Value: Equatable { }
