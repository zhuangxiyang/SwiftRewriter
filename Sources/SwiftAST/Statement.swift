public class Statement: SyntaxNode, Codable, Equatable {
    /// Returns `true` if this statement resolve to an unconditional jump out
    /// of the current context.
    ///
    /// Returns true for `.break`, `.continue` and `.return` statements.
    public var isUnconditionalJump: Bool {
        false
    }
    
    /// This statement label's (parsed from C's goto labels), if any.
    public var label: String?
    
    override public init() {
        super.init()
    }
    
    public init(label: String) {
        self.label = label
        
        super.init()
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        
        super.init()
    }
    
    @inlinable
    open override func copy() -> Statement {
        fatalError("Must be overriden by subclasses")
    }
    
    /// Accepts the given visitor instance, calling the appropriate visiting method
    /// according to this statement's type.
    ///
    /// - Parameter visitor: The visitor to accept
    /// - Returns: The result of the visitor's `visit-` call when applied to this
    /// statement
    @inlinable
    public func accept<V: StatementVisitor>(_ visitor: V) -> V.StmtResult {
        visitor.visitStatement(self)
    }
    
    public func isEqual(to other: Statement) -> Bool {
        false
    }
    
    public static func == (lhs: Statement, rhs: Statement) -> Bool {
        if lhs === rhs {
            return true
        }
        if lhs.label != rhs.label {
            return false
        }
        
        return lhs.isEqual(to: rhs)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(label, forKey: .label)
    }
    
    @usableFromInline
    final func cast<T: Statement>() -> T? {
        self as? T
    }
    
    private enum CodingKeys: String, CodingKey {
        case label
    }
}

public extension Statement {
    static func compound(_ cpd: [Statement]) -> CompoundStatement {
        CompoundStatement(statements: cpd)
    }
    static func `if`(_ exp: Expression,
                            body: CompoundStatement,
                            else elseBody: CompoundStatement?) -> IfStatement {
        
        IfStatement(exp: exp, body: body, elseBody: elseBody, pattern: nil)
    }
    static func ifLet(_ pattern: Pattern,
                             _ exp: Expression,
                             body: CompoundStatement,
                             else elseBody: CompoundStatement?) -> IfStatement {
        
        IfStatement(exp: exp, body: body, elseBody: elseBody, pattern: pattern)
    }
    static func `while`(_ exp: Expression, body: CompoundStatement) -> WhileStatement {
        WhileStatement(exp: exp, body: body)
    }
    static func doWhile(_ exp: Expression, body: CompoundStatement) -> DoWhileStatement {
        DoWhileStatement(exp: exp, body: body)
    }
    static func `for`(_ pattern: Pattern, _ exp: Expression, body: CompoundStatement) -> ForStatement {
        ForStatement(pattern: pattern, exp: exp, body: body)
    }
    static func `switch`(_ exp: Expression,
                                cases: [SwitchCase],
                                default defaultCase: [Statement]?) -> SwitchStatement {
        
        SwitchStatement(exp: exp, cases: cases, defaultCase: defaultCase)
    }
    static func `do`(_ stmt: CompoundStatement) -> DoStatement {
        DoStatement(body: stmt)
    }
    static func `defer`(_ stmt: CompoundStatement) -> DeferStatement {
        DeferStatement(body: stmt)
    }
    static func `return`(_ exp: Expression?) -> ReturnStatement {
        ReturnStatement(exp: exp)
    }
    static func `break`() -> BreakStatement {
        BreakStatement()
    }
    static func `break`(targetLabel: String?) -> BreakStatement {
        BreakStatement(targetLabel: targetLabel)
    }
    static var `fallthrough`: FallthroughStatement {
        FallthroughStatement()
    }
    static func `continue`() -> ContinueStatement {
        ContinueStatement()
    }
    static func `continue`(targetLabel: String?) -> ContinueStatement {
        ContinueStatement(targetLabel: targetLabel)
    }
    static func expressions(_ exp: [Expression]) -> ExpressionsStatement {
        ExpressionsStatement(expressions: exp)
    }
    static func variableDeclarations(_ decl: [StatementVariableDeclaration]) -> VariableDeclarationsStatement {
        VariableDeclarationsStatement(decl: decl)
    }
    static func unknown(_ context: UnknownASTContext) -> UnknownStatement {
        UnknownStatement(context: context)
    }
    static func expression(_ expr: Expression) -> Statement {
        .expressions([expr])
    }
    
    static func variableDeclaration(identifier: String,
                                    type: SwiftType,
                                    ownership: Ownership = .strong,
                                    isConstant: Bool = false,
                                    initialization: Expression?) -> Statement {
        
        .variableDeclarations([
            StatementVariableDeclaration(identifier: identifier,
                                         type: type,
                                         ownership: ownership,
                                         isConstant: isConstant,
                                         initialization: initialization)
        ])
    }
}

public extension Statement {
    
    @inlinable
    func copyMetadata(from other: Statement) -> Self {
        self.label = other.label
        
        return self
    }
    
    /// Labels this statement with a given label, and returns this instance.
    func labeled(_ label: String?) -> Self {
        self.label = label
        
        return self
    }
    
}
