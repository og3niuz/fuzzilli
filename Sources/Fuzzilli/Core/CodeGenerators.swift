// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
// Code generators.
//
// These insert one or more instructions into a program.
//
public let CodeGenerators: [CodeGenerator] = [
    CodeGenerator("IntegerGenerator") { b in
        b.loadInt(b.genInt())
    },

    CodeGenerator("BigIntGenerator") { b in
        b.loadBigInt(b.genInt())
    },

    CodeGenerator("RegExpGenerator") { b in
        b.loadRegExp(b.genRegExp(), b.genRegExpFlags())
    },

    CodeGenerator("FloatGenerator") { b in
        b.loadFloat(b.genFloat())
    },

    CodeGenerator("StringGenerator") { b in
        b.loadString(b.genString())
    },

    CodeGenerator("BooleanGenerator") { b in
        b.loadBool(Bool.random())
    },

    CodeGenerator("UndefinedGenerator") { b in
        b.loadUndefined()
    },

    CodeGenerator("NullGenerator") { b in
        b.loadNull()
    },

    CodeGenerator("ObjectGenerator") { b in
        var initialProperties = [String: Variable]()
        for _ in 0..<Int.random(in: 0...10) {
            initialProperties[b.genPropertyNameForWrite()] = b.randVar()
        }
        b.createObject(with: initialProperties)
    },

    CodeGenerator("ArrayGenerator") { b in
        var initialValues = [Variable]()
        for _ in 0..<Int.random(in: 0...10) {
            initialValues.append(b.randVar())
        }
        b.createArray(with: initialValues)
    },

    CodeGenerator("ObjectWithSpreadGenerator") { b in
        var initialProperties = [String: Variable]()
        var spreads = [Variable]()
        for _ in 0..<Int.random(in: 0...10) {
            withProbability(0.5, do: {
                initialProperties[b.genPropertyNameForWrite()] = b.randVar()
            }, else: {
                spreads.append(b.randVar())
            })
        }
        b.createObject(with: initialProperties, andSpreading: spreads)
    },

    CodeGenerator("ArrayWithSpreadGenerator") { b in
        var initialValues = [Variable]()
        for _ in 0..<Int.random(in: 0...10) {
            initialValues.append(b.randVar())
        }
        
        // Pick some random inputs to spread.
        let spreads = initialValues.map({ _ in Bool.random() })
        
        b.createArray(with: initialValues, spreading: spreads)
    },

    CodeGenerator("BuiltinGenerator") { b in
        b.loadBuiltin(b.genBuiltinName())
    },

    // For functions, we always generate one random instruction and one return instruction as function body.
    // This ensures that generating one random instruction does not accidentially generate multiple instructions
    // (which increases the likelyhood of runtime exceptions), but also generates somewhat useful functions.

    CodeGenerator("PlainFunctionGenerator") { b in
        b.definePlainFunction(withSignature: FunctionSignature(withParameterCount: Int.random(in: 2...5), hasRestParam: probability(0.1))) { _ in
            b.generateRecursive()
            b.doReturn(value: b.randVar())
        }
    },

    CodeGenerator("StrictFunctionGenerator") { b in
        b.defineStrictFunction(withSignature: FunctionSignature(withParameterCount: Int.random(in: 2...5), hasRestParam: probability(0.1))) { _ in
            b.generateRecursive()
            b.doReturn(value: b.randVar())
        }
    },

    CodeGenerator("ArrowFunctionGenerator") { b in
        b.defineArrowFunction(withSignature: FunctionSignature(withParameterCount: Int.random(in: 2...5), hasRestParam: probability(0.1))) { _ in
            b.generateRecursive()
            b.doReturn(value: b.randVar())
        }
    },

    CodeGenerator("GeneratorFunctionGenerator") { b in
        b.defineGeneratorFunction(withSignature: FunctionSignature(withParameterCount: Int.random(in: 2...5), hasRestParam: probability(0.1))) { _ in
            b.generateRecursive()
            if probability(0.5) {
                b.yield(value: b.randVar())
            } else {
                b.yieldEach(value: b.randVar())
            }
            b.doReturn(value: b.randVar())
        }
    },

    CodeGenerator("AsyncFunctionGenerator") { b in
        b.defineAsyncFunction(withSignature: FunctionSignature(withParameterCount: Int.random(in: 2...5), hasRestParam: probability(0.1))) { _ in
            b.generateRecursive()
            b.await(value: b.randVar())
            b.doReturn(value: b.randVar())
        }
    },

    CodeGenerator("PropertyRetrievalGenerator", input: .object()) { b, obj in
        let propertyName = b.type(of: obj).randomProperty() ?? b.genPropertyNameForRead()
        b.loadProperty(propertyName, of: obj)
    },

    CodeGenerator("PropertyAssignmentGenerator", input: .object()) { b, obj in
        let propertyName: String
        // Either change an existing property or define a new one
        if probability(0.5) {
            propertyName = b.type(of: obj).randomProperty() ?? b.genPropertyNameForWrite()
        } else {
            propertyName = b.genPropertyNameForWrite()
        }
        let value = b.randVar()
        b.storeProperty(value, as: propertyName, on: obj)
    },

    CodeGenerator("PropertyRemovalGenerator", input: .object()) { b, obj in
        let propertyName = b.type(of: obj).randomProperty() ?? b.genPropertyNameForWrite()
        b.deleteProperty(propertyName, of: obj)
    },

    CodeGenerator("ElementRetrievalGenerator", input: .object()) { b, obj in
        let index = b.genIndex()
        b.loadElement(index, of: obj)
    },

    CodeGenerator("ElementAssignmentGenerator", input: .object()) { b, obj in
        let index = b.genIndex()
        let value = b.randVar()
        b.storeElement(value, at: index, of: obj)
    },

    CodeGenerator("ElementRemovalGenerator", input: .object()) { b, obj in
        let index = b.genIndex()
        b.deleteElement(index, of: obj)
    },

    CodeGenerator("ComputedPropertyRetrievalGenerator", input: .object()) { b, obj in
        let propertyName = b.randVar()
        b.loadComputedProperty(propertyName, of: obj)
    },

    CodeGenerator("ComputedPropertyAssignmentGenerator", input: .object()) { b, obj in
        let propertyName = b.randVar()
        let value = b.randVar()
        b.storeComputedProperty(value, as: propertyName, on: obj)
    },

    CodeGenerator("ComputedPropertyRemovalGenerator", input: .object()) { b, obj in
        let propertyName = b.randVar()
        b.deleteComputedProperty(propertyName, of: obj)
    },

    CodeGenerator("TypeTestGenerator", input: .anything) { b, val in
        let type = b.doTypeof(val)
        // Also generate a comparison here, since that's probably the only interesting thing you can do with the result.
        let rhs = b.loadString(chooseUniform(from: JavaScriptEnvironment.jsTypeNames))
        b.compare(type, rhs, with: .strictEqual)
    },

    CodeGenerator("InstanceOfGenerator", input: .anything) { b, val in
        let cls = b.randVar()
        b.doInstanceOf(val, cls)
    },

    CodeGenerator("InGenerator", input: .object()) { b, obj in
        let prop = b.randVar()
        b.doIn(prop, obj)
    },

    CodeGenerator("MethodCallGenerator", input: .object()) { b, obj in
        var methodName = b.type(of: obj).randomMethod()
        if methodName == nil {
            if b.mode == .conservative {
                return
            }
            methodName = b.genMethodName()
        }
        guard let arguments = b.generateCallArguments(forMethod: methodName!, on: obj) else { return }
        b.callMethod(methodName!, on: obj, withArgs: arguments)
    },

    CodeGenerator("FunctionCallGenerator", input: .function()) { b, f in
        guard let arguments = b.generateCallArguments(for: f) else { return }
        b.callFunction(f, withArgs: arguments)
    },

    CodeGenerator("ConstructorCallGenerator", input: .constructor()) { b, c in
        guard let arguments = b.generateCallArguments(for: c) else { return }
        b.construct(c, withArgs: arguments)
    },

    CodeGenerator("FunctionCallWithSpreadGenerator", input: .function()) { b, f in
        // Since we are spreading, the signature doesn't actually help, so ignore it completely
        guard let arguments = b.generateCallArguments(for: FunctionSignature.forUnknownFunction) else { return }
        
        // Pick some random arguments to spread.
        let spreads = arguments.map({ _ in Bool.random() })
        
        b.callFunction(f, withArgs: arguments, spreading: spreads)
    },

    CodeGenerator("FunctionReturnGenerator", inContext: .function, input: .anything) { b, val in
        assert(b.context.contains(.function))
        b.doReturn(value: val)
    },

    CodeGenerator("YieldGenerator", inContext: .generatorFunction, input: .anything) { b, val in
        assert(b.context.contains(.generatorFunction))
        if probability(0.5) {
            b.yield(value: val)
        } else {
            b.yieldEach(value: val)
        }
    },

    CodeGenerator("AwaitGenerator", inContext: .asyncFunction, input: .anything) { b, val in
        assert(b.context.contains(.asyncFunction))
        b.await(value: val)
    },

    CodeGenerator("UnaryOperationGenerator", input: .anything) { b, val in
        b.unary(chooseUniform(from: allUnaryOperators), val)
    },

    CodeGenerator("BinaryOperationGenerator", inputs: (.anything, .anything)) { b, lhs, rhs in
        b.binary(lhs, rhs, with: chooseUniform(from: allBinaryOperators))
    },

    CodeGenerator("PhiGenerator") { b in
        b.phi(b.randVar())
    },

    CodeGenerator("ReassignmentGenerator") { b in
        if let phi = b.randPhi() {
            let val = b.randVar()
            b.copy(val, to: phi)
        }
    },

    CodeGenerator("ComparisonGenerator", inputs: (.anything, .anything)) { b, lhs, rhs in
        b.compare(lhs, rhs, with: chooseUniform(from: allComparators))
    },

    CodeGenerator("IfElseGenerator", input: .boolean) { b, cond in
        let phi = b.phi(b.randVar())
        b.beginIf(cond) {
            b.generateRecursive()
            b.copy(b.randVar(), to: phi)
        }
        b.beginElse() {
            b.generateRecursive()
            b.copy(b.randVar(), to: phi)
        }
        b.endIf()
    },

    CodeGenerator("WhileLoopGenerator") { b in
        let start = b.loadInt(0)
        let end = b.loadInt(Int64.random(in: 0...10))
        let loopVar = b.phi(start)
        b.whileLoop(loopVar, .lessThan, end) {
            b.generateRecursive()
            let newLoopVar = b.unary(.Inc, loopVar)
            b.copy(newLoopVar, to: loopVar)
        }
    },

    CodeGenerator("DoWhileLoopGenerator") { b in
        let start = b.loadInt(0)
        let end = b.loadInt(Int64.random(in: 0...10))
        let loopVar = b.phi(start)
        b.doWhileLoop(loopVar, .lessThan, end) {
            b.generateRecursive()
            let newLoopVar = b.unary(.Inc, loopVar)
            b.copy(newLoopVar, to: loopVar)
        }
    },

    CodeGenerator("ForLoopGenerator") { b in
        let start = b.loadInt(0)
        let end = b.loadInt(Int64.random(in: 0...10))
        let step = b.loadInt(1)
        b.forLoop(start, .lessThan, end, .Add, step) { _ in
            b.generateRecursive()
        }
    },

    CodeGenerator("ForInLoopGenerator", input: .object()) { b, obj in
        b.forInLoop(obj) { _ in
            b.generateRecursive()
        }
    },

    CodeGenerator("ForOfLoopGenerator", input: .object()) { b, obj in
        b.forOfLoop(obj) { _ in
            b.generateRecursive()
        }
    },

    CodeGenerator("BreakGenerator", inContext: .loop) { b in
        assert(b.context.contains(.loop))
        b.doBreak()
    },

    CodeGenerator("ContinueGenerator", inContext: .loop) { b in
        assert(b.context.contains(.loop))
        b.doContinue()
    },

    CodeGenerator("TryCatchGenerator") { b in
        let v = b.phi(b.randVar())
        b.beginTry() {
            b.generateRecursive()
            b.copy(b.randVar(), to: v)
        }
        b.beginCatch() { _ in
            b.generateRecursive()
            b.copy(b.randVar(), to: v)
        }
        b.endTryCatch()
    },

    CodeGenerator("ThrowGenerator") { b in
        let v = b.randVar()
        b.throwException(v)
    },

    //
    // Language-specific Generators
    //

    CodeGenerator("TypedArrayGenerator") { b in
        let size = b.loadInt(Int64.random(in: 0...0x10000))
        let constructor = b.loadBuiltin(chooseUniform(from: ["Uint8Array", "Int8Array", "Uint16Array", "Int16Array", "Uint32Array", "Int32Array", "Float32Array", "Float64Array", "Uint8ClampedArray", "DataView"]))
        b.construct(constructor, withArgs: [size])
    },

    CodeGenerator("FloatArrayGenerator") { b in
        let value = b.loadFloat(13.37)
        b.createArray(with: Array(repeating: value, count: Int.random(in: 1...5)))
    },

    CodeGenerator("IntArrayGenerator") { b in
        let value = b.loadInt(1337)
        b.createArray(with: Array(repeating: value, count: Int.random(in: 1...5)))
    },

    CodeGenerator("ObjectArrayGenerator") { b in
        let value = b.createObject(with: [:])
        b.createArray(with: Array(repeating: value, count: Int.random(in: 1...5)))
    },

    CodeGenerator("WellKnownPropertyLoadGenerator", input: .object()) { b, obj in
        let Symbol = b.loadBuiltin("Symbol")
        let name = chooseUniform(from: ["isConcatSpreadable", "iterator", "match", "replace", "search", "species", "split", "toPrimitive", "toStringTag", "unscopables"])
        let pname = b.loadProperty(name, of: Symbol)
        b.loadComputedProperty(pname, of: obj)
    },

    CodeGenerator("WellKnownPropertyStoreGenerator", input: .object()) { b, obj in
        let Symbol = b.loadBuiltin("Symbol")
        let name = chooseUniform(from: ["isConcatSpreadable", "iterator", "match", "replace", "search", "species", "split", "toPrimitive", "toStringTag", "unscopables"])
        let pname = b.loadProperty(name, of: Symbol)
        let val = b.randVar()
        b.storeComputedProperty(val, as: pname, on: obj)
    },

    CodeGenerator("PrototypeAccessGenerator", input: .object()) { b, obj in
        b.loadProperty("__proto__", of: obj)
    },

    CodeGenerator("PrototypeOverwriteGenerator", inputs: (.object(), .object())) { b, obj, proto in
        b.storeProperty(proto, as: "__proto__", on: obj)
    },

    CodeGenerator("CallbackPropertyGenerator", inputs: (.object(), .function())) { b, obj, callback in
        // TODO add new callbacks like Symbol.toPrimitive?
        let propertyName = chooseUniform(from: ["valueOf", "toString"])
        b.storeProperty(callback, as: propertyName, on: obj)
    },

    CodeGenerator("PropertyAccessorGenerator", input: .object()) { b, obj in
        let propertyName = probability(0.5) ? b.loadString(b.genPropertyNameForWrite()) : b.loadInt(b.genIndex())
        
        var initialProperties = [String: Variable]()
        withEqualProbability({
            guard let getter = b.randVar(ofType: .function()) else { return }
            initialProperties["get"] = getter
        }, {
            guard let setter = b.randVar(ofType: .function()) else { return }
            initialProperties["set"] = setter
        }, {
            guard let getter = b.randVar(ofType: .function()) else { return }
            guard let setter = b.randVar(ofType: .function()) else { return }
            initialProperties["get"] = getter
            initialProperties["set"] = setter
        })
        let descriptor = b.createObject(with: initialProperties)
        
        let object = b.loadBuiltin("Object")
        b.callMethod("defineProperty", on: object, withArgs: [obj, propertyName, descriptor])
    },

    CodeGenerator("ProxyGenerator") { b in
        let target = b.randVar()
        
        var candidates = Set(["getPrototypeOf", "setPrototypeOf", "isExtensible", "preventExtensions", "getOwnPropertyDescriptor", "defineProperty", "has", "get", "set", "deleteProperty", "ownKeys", "apply", "call", "construct"])
        
        var handlerProperties = [String: Variable]()
        for _ in 0..<Int.random(in: 0..<candidates.count) {
            let hook = chooseUniform(from: candidates)
            candidates.remove(hook)
            handlerProperties[hook] = b.randVar(ofType: .function())
        }
        let handler = b.createObject(with: handlerProperties)
        
        let Proxy = b.loadBuiltin("Proxy")
        
        b.construct(Proxy, withArgs: [target, handler])
    },

    CodeGenerator("PromiseGenerator") { b in
        // This is just so the phis have the correct type. TODO could we have phis with a type in the operation itself, or do this some other way, e.g. a SetType operation?
        let f = b.definePlainFunction(withSignature: [.anything] => .unknown) { _ in }
        let resolveFunc = b.phi(f)
        let rejectFunc = b.phi(f)
        let handlerSignature = [.function([.anything] => .unknown), .function([.anything] => .unknown)] => .unknown
        let handler = b.definePlainFunction(withSignature: handlerSignature) { args in
            b.copy(args[0], to: resolveFunc)
            b.copy(args[1], to: rejectFunc)
        }
        let promiseConstructor = b.loadBuiltin("Promise")
        b.construct(promiseConstructor, withArgs: [handler])
    },

    // Tries to change the length property of some object
    CodeGenerator("LengthChangeGenerator", input: .object()) { b, obj in
        let newLength: Variable
        if probability(0.5) {
            // Shrink
            newLength = b.loadInt(Int64.random(in: 0..<3))
        } else {
            // (Probably) grow
            newLength = b.loadInt(b.genIndex())
        }
        b.storeProperty(newLength, as: "length", on: obj)
    },

    // Tries to change the element kind of an array
    CodeGenerator("ElementKindChangeGenerator", input: .object()) { b, obj in
        let value = b.randVar()
        b.storeElement(value, at: Int64.random(in: 0..<10), of: obj)
    },

    // Generates a JavaScript 'with' statement
    CodeGenerator("WithStatementGenerator", input: .object()) { b, obj in
        b.with(obj) {
            withProbability(0.5, do: { () -> Void in
                b.loadFromScope(id: b.genPropertyNameForRead())
            }, else: { () -> Void in
                let value = b.randVar()
                b.storeToScope(value, as: b.genPropertyNameForWrite())
            })
            b.generateRecursive()
        }
    },

    CodeGenerator("LoadFromScopeGenerator", inContext: .with) { b in
        precondition(b.context.contains(.with))
        b.loadFromScope(id: b.genPropertyNameForRead())
    },

    CodeGenerator("StoreToScopeGenerator", inContext: .with) { b in
        precondition(b.context.contains(.with))
        let value = b.randVar()
        b.storeToScope(value, as: b.genPropertyNameForWrite())
    },
]

extension Array where Element == CodeGenerator {
    public func get(_ name: String) -> CodeGenerator {
        for generator in self {
            if generator.name == name {
                return generator
            }
        }
        fatalError("Unknown code generator \(name)")
    }
}
