import HeapStorageMacro

struct MyStruct {
    @HeapStorage var valueWithDefault: Int = 26
    @HeapStorage var value: Int

    init(value: Int) {
        self.value = value
    }
}
