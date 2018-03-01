import Foundation
import SwiftRewriterLib
import SwiftAST
import GrammarModels

public class IntentionCollectionBuilder {
    var intentions = IntentionCollection()
    
    public init() {
        
    }
    
    @discardableResult
    public func createFileWithClass(named name: String, initializer: (TypeBuilder<ClassGenerationIntention>) -> Void = { _ in }) -> IntentionCollectionBuilder {
        createFile(named: "\(name).swift") { builder in
            builder.createClass(withName: name, initializer: initializer)
        }
        
        return self
    }
    
    @discardableResult
    public func createFile(named name: String, initializer: (FileIntentionBuilder) -> Void = { _ in }) -> IntentionCollectionBuilder {
        let builder = FileIntentionBuilder(fileNamed: name)
        
        initializer(builder)
        
        let file = builder.build()
        
        intentions.addIntention(file)
        
        return self
    }
    
    public func build(typeChecked: Bool = false) -> IntentionCollection {
        if typeChecked {
            let system = IntentionCollectionTypeSystem(intentions: intentions)
            let resolver = ExpressionTypeResolver(typeSystem: system)
            
            let invoker = DefaultTypeResolverInvoker(typeResolver: resolver)
            
            invoker.resolveAllExpressionTypes(in: intentions)
        }
        
        return intentions
    }
}

public class FileIntentionBuilder {
    var intention: FileGenerationIntention
    
    public init(fileNamed name: String) {
        intention = FileGenerationIntention(sourcePath: name, targetPath: name)
    }
    
    @discardableResult
    public func createGlobalVariable(withName name: String,
                                     type: SwiftType,
                                     ownership: Ownership = .strong,
                                     isConstant: Bool = false,
                                     accessLevel: AccessLevel = .internal) -> FileIntentionBuilder {
        let storage =
            ValueStorage(type: type, ownership: ownership, isConstant: isConstant)
        
        return createGlobalVariable(withName: name, storage: storage, accessLevel: accessLevel)
    }
    
    @discardableResult
    public func createGlobalVariable(withName name: String,
                                     storage: ValueStorage,
                                     accessLevel: AccessLevel = .internal) -> FileIntentionBuilder {
        let varIntention =
            GlobalVariableGenerationIntention(name: name,
                                              storage: storage,
                                              accessLevel: accessLevel)
        
        intention.addGlobalVariable(varIntention)
        
        return self
    }
    
    @discardableResult
    public func createClass(withName name: String, initializer: (TypeBuilder<ClassGenerationIntention>) -> Void = { _ in }) -> FileIntentionBuilder {
        let classIntention = ClassGenerationIntention(typeName: name)
        
        innerBuildTypeWithClosure(type: classIntention, initializer: initializer)
        
        return self
    }
    
    @discardableResult
    public func createExtension(forClassNamed name: String, categoryName: String = "", initializer: (TypeBuilder<ClassExtensionGenerationIntention>) -> Void = { _ in }) -> FileIntentionBuilder {
        let classIntention = ClassExtensionGenerationIntention(typeName: name)
        
        innerBuildTypeWithClosure(type: classIntention, initializer: initializer)
        
        return self
    }
    
    @discardableResult
    public func createEnum(withName name: String, rawValue: SwiftType, initializer: (EnumTypeBuilder) -> Void = { _ in }) -> FileIntentionBuilder {
        let enumIntention = EnumGenerationIntention(typeName: name, rawValueType: rawValue)
        let builder = EnumTypeBuilder(targetEnum: enumIntention)
        
        initializer(builder)
        
        intention.addType(builder.build())
        
        return self
    }
    
    private func innerBuildTypeWithClosure<T: TypeGenerationIntention>(type: T, initializer: (TypeBuilder<T>) -> Void) {
        let builder = TypeBuilder(targetType: type)
        initializer(builder)
        intention.addType(builder.build())
    }
    
    public func build() -> FileGenerationIntention {
        return intention
    }
}

public class MemberBuilder<T: MemberGenerationIntention> {
    var targetMember: T
    
    public init(targetMember: T) {
        self.targetMember = targetMember
    }
    
    public func setAccessLevel(_ accessLevel: AccessLevel) {
        targetMember.accessLevel = accessLevel
    }
    
    public func build() -> T {
        return targetMember
    }
}

public extension MemberBuilder where T: MethodGenerationIntention {
    @discardableResult
    public func setBody(_ body: CompoundStatement) -> MemberBuilder<T> {
        targetMember.functionBody = FunctionBodyIntention(body: body)
        
        return self
    }
}

public extension MemberBuilder where T: InitGenerationIntention {
    @discardableResult
    public func setBody(_ body: CompoundStatement) -> MemberBuilder<T> {
        targetMember.functionBody = FunctionBodyIntention(body: body)
        
        return self
    }
}


public class TypeBuilder<T: TypeGenerationIntention> {
    var targetType: T
    
    public init(targetType: T) {
        self.targetType = targetType
    }
    
    /// Marks the target type for this type builder as coming from an interface
    /// declaration, if it supports such annotations.
    @discardableResult
    public func setAsInterfaceSource() -> TypeBuilder {
        if let cls = targetType as? BaseClassIntention {
            cls.source = ObjcClassInterface()
        }
        
        return self
    }
    
    /// Marks the target type for this type builder as coming from a category
    /// extension interface declaration, if it supports such annotations.
    @discardableResult
    public func setAsCategoryInterfaceSource() -> TypeBuilder {
        if let cls = targetType as? BaseClassIntention {
            cls.source = ObjcClassCategoryInterface()
        }
        
        return self
    }
    
    @discardableResult
    public func createProperty(named name: String, type: SwiftType, attributes: [PropertyAttribute] = []) -> TypeBuilder {
        return createProperty(named: name, type: type, mode: .asField, attributes: attributes)
    }
    
    @discardableResult
    public func createProperty(named name: String,
                               type: SwiftType,
                               mode: PropertyGenerationIntention.Mode,
                               attributes: [PropertyAttribute] = [],
                               builder: (MemberBuilder<PropertyGenerationIntention>) -> () = { _ in }) -> TypeBuilder {
        let storage = ValueStorage(type: type, ownership: .strong, isConstant: false)
        
        let prop = PropertyGenerationIntention(name: name, storage: storage, attributes: attributes)
        prop.mode = mode
        
        let mbuilder = MemberBuilder(targetMember: prop)
        
        builder(mbuilder)
        
        targetType.addProperty(mbuilder.build())
        
        return self
    }
    
    @discardableResult
    public func createConstructor(withParameters parameters: [ParameterSignature] = [],
                                  builder: (MemberBuilder<InitGenerationIntention>) -> () = { _ in }) -> TypeBuilder {
        let ctor = InitGenerationIntention(parameters: parameters)
        let mbuilder = MemberBuilder(targetMember: ctor)
        
        builder(mbuilder)
        
        targetType.addConstructor(mbuilder.build())
        
        return self
    }
    
    @discardableResult
    public func createVoidMethod(named name: String, builder: (MemberBuilder<MethodGenerationIntention>) -> () = { _ in }) -> TypeBuilder {
        let signature = FunctionSignature(name: name, parameters: [])
        
        return createMethod(signature, builder: builder)
    }
    
    @discardableResult
    public func createMethod(named name: String,
                             returnType: SwiftType = .void,
                             parameters: [ParameterSignature] = [],
                             isStatic: Bool = false,
                             builder: (MemberBuilder<MethodGenerationIntention>) -> () = { _ in }) -> TypeBuilder {
        let signature = FunctionSignature(name: name, parameters: parameters, returnType: returnType, isStatic: isStatic)
        
        return createMethod(signature, builder: builder)
    }
    
    @discardableResult
    public func createMethod(_ signature: FunctionSignature, builder: (MemberBuilder<MethodGenerationIntention>) -> () = { _ in }) -> TypeBuilder {
        let method = MethodGenerationIntention(signature: signature)
        method.functionBody = FunctionBodyIntention(body: [])
        
        let mbuilder = MemberBuilder(targetMember: method)
        builder(mbuilder)
        
        targetType.addMethod(mbuilder.build())
        
        return self
    }
    
    public func build() -> T {
        return targetType
    }
}

public extension TypeBuilder where T: BaseClassIntention {
    @discardableResult
    public func createInstanceVariable(named name: String, type: SwiftType) -> TypeBuilder {
        let storage = ValueStorage(type: type, ownership: .strong, isConstant: false)
        
        let ivar = InstanceVariableGenerationIntention(name: name, storage: storage)
        targetType.addInstanceVariable(ivar)
        
        return self
    }
}

public class EnumTypeBuilder {
    var targetEnum: EnumGenerationIntention
    
    public init(targetEnum: EnumGenerationIntention) {
        self.targetEnum = targetEnum
    }
    
    @discardableResult
    public func createCase(name: String, expression: Expression? = nil) -> EnumTypeBuilder {
        let caseIntention = EnumCaseGenerationIntention(name: name, expression: expression)
        
        targetEnum.addCase(caseIntention)
        
        return self
    }
    
    public func build() -> EnumGenerationIntention {
        return targetEnum
    }
}