import GrammarModels

public class Expression: Equatable, CustomStringConvertible {
    /// `true` if this expression sub-tree contains only literal-based sub-expressions.
    /// Literal based sub-expressions include: `.constant`, as well as `.binary`,
    /// `.unary`, `.prefix`, `.parens`, and `.ternary` which only feature
    /// literal sub-expressions.
    ///
    /// For ternary expressions, the test expression to the left of the question
    /// mark operand does not affect the result of literal-based tests.
    public var isLiteralExpression: Bool {
        return false
    }
    
    /// `true` if this expression node requires parenthesis for unary, prefix, and
    /// postfix operations.
    public var requiresParens: Bool {
        return false
    }
    
    public var description: String {
        return ""
    }
    
    /// Returns an array of sub-expressions contained within this expression, in
    /// case it is an expression formed of other expressions.
    public var subExpressions: [Expression] {
        return []
    }
    
    /// Accepts the given visitor instance, calling the appropriate visiting method
    /// according to this expression's type.
    ///
    /// - Parameter visitor: The visitor to accept
    /// - Returns: The result of the visitor's `visit-` call when applied to this
    /// expression
    public func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitExpression(self)
    }
    
    public static func ==(lhs: Expression, rhs: Expression) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs === rhs
    }
    
    fileprivate func cast<T>() -> T? {
        return self as? T
    }
}

public class AssignmentExpression: Expression {
    public var lhs: Expression
    public var op: SwiftOperator
    public var rhs: Expression
    
    public override var subExpressions: [Expression] {
        return [lhs, rhs]
    }
    
    public override var description: String {
        // With spacing
        if op.requiresSpacing {
            return "\(lhs.description) \(op) \(rhs.description)"
        }
        
        // No spacing
        return "\(lhs.description)\(op)\(rhs.description)"
    }
    
    public init(lhs: Expression, op: SwiftOperator, rhs: Expression) {
        self.lhs = lhs
        self.op = op
        self.rhs = rhs
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitAssignment(self)
    }
    
    public static func ==(lhs: AssignmentExpression, rhs: AssignmentExpression) -> Bool {
        return lhs.lhs == rhs.lhs && lhs.op == rhs.op && lhs.rhs == rhs.rhs
    }
}
public extension Expression {
    public var asAssignment: AssignmentExpression? {
        return cast()
    }
}

public class BinaryExpression: Expression {
    public var lhs: Expression
    public var op: SwiftOperator
    public var rhs: Expression
    
    public override var subExpressions: [Expression] {
        return [lhs, rhs]
    }
    
    public override var description: String {
        // With spacing
        if op.requiresSpacing {
            return "\(lhs.description) \(op) \(rhs.description)"
        }
        
        // No spacing
        return "\(lhs.description)\(op)\(rhs.description)"
    }
    
    public init(lhs: Expression, op: SwiftOperator, rhs: Expression) {
        self.lhs = lhs
        self.op = op
        self.rhs = rhs
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitBinary(self)
    }
    
    public static func ==(lhs: BinaryExpression, rhs: BinaryExpression) -> Bool {
        return lhs.lhs == rhs.lhs && lhs.op == rhs.op && lhs.rhs == rhs.rhs
    }
}
extension Expression {
    public var asBinary: BinaryExpression? {
        return cast()
    }
}

public class UnaryExpression: Expression {
    public var op: SwiftOperator
    public var exp: Expression
    
    public override var subExpressions: [Expression] {
        return [exp]
    }
    
    public override var description: String {
        // Parenthesized
        if exp.requiresParens {
            return "\(op)(\(exp))"
        }
        
        return "\(op)\(exp)"
    }
    
    public init(op: SwiftOperator, exp: Expression) {
        self.op = op
        self.exp = exp
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitUnary(self)
    }
    
    public static func ==(lhs: UnaryExpression, rhs: UnaryExpression) -> Bool {
        return lhs.op == rhs.op && lhs.exp == rhs.exp
    }
}
extension Expression {
    public var asUnary: UnaryExpression? {
        return cast()
    }
}

public class PrefixExpression: Expression {
    public var op: SwiftOperator
    public var exp: Expression
    
    public override var subExpressions: [Expression] {
        return [exp]
    }
    
    public override var description: String {
        // Parenthesized
        if exp.requiresParens {
            return "\(op)(\(exp))"
        }
        
        return "\(op)\(exp)"
    }
    
    public init(op: SwiftOperator, exp: Expression) {
        self.op = op
        self.exp = exp
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitPrefix(self)
    }
    
    public static func ==(lhs: PrefixExpression, rhs: PrefixExpression) -> Bool {
        return lhs.op == rhs.op && lhs.exp == rhs.exp
    }
}
extension Expression {
    public var asPrefix: PrefixExpression? {
        return cast()
    }
}

public class PostfixExpression: Expression {
    public var exp: Expression
    public var op: Postfix
    
    public override var subExpressions: [Expression] {
        switch op {
        case .subscript(let s):
            return [exp, s]
        case .functionCall(let args):
            return [exp] + args.map { $0.expression }
        default:
            return [exp]
        }
    }
    
    public override var description: String {
        // Parenthesized
        if exp.requiresParens {
            return "(\(exp))\(op)"
        }
        
        return "\(exp)\(op)"
    }
    
    public init(exp: Expression, op: Postfix) {
        self.exp = exp
        self.op = op
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitPostfix(self)
    }
    
    public static func ==(lhs: PostfixExpression, rhs: PostfixExpression) -> Bool {
        return lhs.exp == rhs.exp && lhs.op == rhs.op
    }
}
extension Expression {
    public var asPostfix: PostfixExpression? {
        return cast()
    }
}

public class ConstantExpression: Expression, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public var constant: Constant
    
    public override var description: String {
        return constant.description
    }
    
    public init(constant: Constant) {
        self.constant = constant
    }
    
    public required init(stringLiteral value: String) {
        constant = .string(value)
    }
    public required init(integerLiteral value: Int) {
        constant = .int(value)
    }
    public required init(floatLiteral value: Float) {
        constant = .float(value)
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitConstant(self)
    }
    
    public static func ==(lhs: ConstantExpression, rhs: ConstantExpression) -> Bool {
        return lhs.constant == rhs.constant
    }
}
public extension Expression {
    public var asConstant: ConstantExpression? {
        return self as? ConstantExpression
    }
}

public class ParensExpression: Expression {
    public var exp: Expression
    
    public override var subExpressions: [Expression] {
        return [exp]
    }
    
    public override var description: String {
        return "(" + exp.description + ")"
    }
    
    public init(exp: Expression) {
        self.exp = exp
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitParens(self)
    }
    
    public static func ==(lhs: ParensExpression, rhs: ParensExpression) -> Bool {
        return lhs.exp == rhs.exp
    }
}
public extension Expression {
    public var asParens: ParensExpression? {
        return cast()
    }
}

public class IdentifierExpression: Expression {
    public var identifier: String
    
    public override var description: String {
        return identifier
    }
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitIdentifier(self)
    }
    
    public static func ==(lhs: IdentifierExpression, rhs: IdentifierExpression) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
public extension Expression {
    public var asIdentifier: IdentifierExpression? {
        return cast()
    }
}

public class CastExpression: Expression {
    public var exp: Expression
    public var type: SwiftType
    
    public override var subExpressions: [Expression] {
        return [exp]
    }
    
    public override var description: String {
        let cvt = TypeMapper(context: TypeContext())
        
        return "\(exp) as? \(cvt.typeNameString(for: type))"
    }
    
    public override var requiresParens: Bool {
        return true
    }
    
    public init(exp: Expression, type: SwiftType) {
        self.exp = exp
        self.type = type
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitCast(self)
    }
    
    public static func ==(lhs: CastExpression, rhs: CastExpression) -> Bool {
        return lhs.exp == rhs.exp && lhs.type == rhs.type
    }
}
public extension Expression {
    public var asCast: CastExpression? {
        return cast()
    }
}

public class ArrayLiteralExpression: Expression {
    public var items: [Expression]
    
    public override var subExpressions: [Expression] {
        return items
    }
    
    public override var description: String {
        return "[\(items.map { $0.description }.joined(separator: ", "))]"
    }
    
    public init(items: [Expression]) {
        self.items = items
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitArray(self)
    }
    
    public static func ==(lhs: ArrayLiteralExpression, rhs: ArrayLiteralExpression) -> Bool {
        return lhs.items == rhs.items
    }
}
public extension Expression {
    public var asArray: ArrayLiteralExpression? {
        return cast()
    }
}

public class DictionaryLiteralExpression: Expression {
    public var pairs: [ExpressionDictionaryPair]
    
    public override var subExpressions: [Expression] {
        return pairs.flatMap { [$0.key, $0.value] }
    }
    
    public override var description: String {
        if pairs.count == 0 {
            return "[:]"
        }
        
        return "[" + pairs.map { $0.description }.joined(separator: ", ") + "]"
    }
    
    public init(pairs: [ExpressionDictionaryPair]) {
        self.pairs = pairs
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitDictionary(self)
    }
    
    public static func ==(lhs: DictionaryLiteralExpression, rhs: DictionaryLiteralExpression) -> Bool {
        return lhs.pairs == rhs.pairs
    }
}
public extension Expression {
    public var asDictionary: DictionaryLiteralExpression? {
        return cast()
    }
}

public class TernaryExpression: Expression {
    public var exp: Expression
    public var ifTrue: Expression
    public var ifFalse: Expression
    
    public override var subExpressions: [Expression] {
        return [exp, ifTrue, ifFalse]
    }
    
    public override var description: String {
        return exp.description + " ? " + ifTrue.description + " : " + ifFalse.description
    }
    
    public override var requiresParens: Bool {
        return true
    }
    
    public init(exp: Expression, ifTrue: Expression, ifFalse: Expression) {
        self.exp = exp
        self.ifTrue = ifTrue
        self.ifFalse = ifFalse
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitTernary(self)
    }
    
    public static func ==(lhs: TernaryExpression, rhs: TernaryExpression) -> Bool {
        return lhs.exp == rhs.exp && lhs.ifTrue == rhs.ifTrue && lhs.ifFalse == rhs.ifFalse
    }
}
public extension Expression {
    public var asTernary: TernaryExpression? {
        return cast()
    }
}

public class BlockLiteralExpression: Expression {
    public var parameters: [BlockParameter]
    public var returnType: SwiftType
    public var body: CompoundStatement
    
    public override var description: String {
        let cvt = TypeMapper(context: TypeContext())
        
        var buff = "{ "
        
        buff += "("
        buff += parameters.map { $0.description }.joined(separator: ", ")
        buff += ") -> "
        buff += cvt.typeNameString(for: returnType)
        buff += " in "
        
        buff += "< body >"
        
        buff += " }"
        
        return buff
    }
    
    public override var requiresParens: Bool {
        return true
    }
    
    public init(parameters: [BlockParameter], returnType: SwiftType, body: CompoundStatement) {
        self.parameters = parameters
        self.returnType = returnType
        self.body = body
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitBlock(self)
    }
    
    public static func ==(lhs: BlockLiteralExpression, rhs: BlockLiteralExpression) -> Bool {
        return lhs.parameters == rhs.parameters &&
            lhs.returnType == rhs.returnType &&
            lhs.body == rhs.body
    }
}
public extension Expression {
    public var asBlock: BlockLiteralExpression? {
        return cast()
    }
}

public class UnknownExpression: Expression {
    public var context: UnknownASTContext
    
    public override var description: String {
        return context.description
    }
    
    public init(context: UnknownASTContext) {
        self.context = context
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitUnknown(self)
    }
    
    public static func ==(lhs: UnknownExpression, rhs: UnknownExpression) -> Bool {
        return true
    }
}
public extension Expression {
    public var asUnknown: UnknownExpression? {
        return cast()
    }
}

/// Helper static creators
public extension Expression {
    public static func assignment(lhs: Expression, op: SwiftOperator, rhs: Expression) -> AssignmentExpression {
        return AssignmentExpression(lhs: lhs, op: op, rhs: rhs)
    }
    
    public static func binary(lhs: Expression, op: SwiftOperator, rhs: Expression) -> BinaryExpression {
        return BinaryExpression(lhs: lhs, op: op, rhs: rhs)
    }
    
    public static func unary(op: SwiftOperator, _ exp: Expression) -> UnaryExpression {
        return UnaryExpression(op: op, exp: exp)
    }
    
    public static func prefix(op: SwiftOperator, _ exp: Expression) -> PrefixExpression {
        return PrefixExpression(op: op, exp: exp)
    }
    
    public static func postfix(_ exp: Expression, _ op: Postfix) -> PostfixExpression {
        return PostfixExpression(exp: exp, op: op)
    }
    
    public static func constant(_ constant: Constant) -> ConstantExpression {
        return ConstantExpression(constant: constant)
    }
    
    public static func parens(_ exp: Expression) -> ParensExpression {
        return ParensExpression(exp: exp)
    }
    
    public static func identifier(_ ident: String) -> IdentifierExpression {
        return IdentifierExpression(identifier: ident)
    }
    
    public static func cast(_ exp: Expression, type: SwiftType) -> CastExpression {
        return CastExpression(exp: exp, type: type)
    }
    
    public static func arrayLiteral(_ array: [Expression]) -> ArrayLiteralExpression {
        return ArrayLiteralExpression(items: array)
    }
    
    public static func dictionaryLiteral(_ pairs: [ExpressionDictionaryPair]) -> DictionaryLiteralExpression {
        return DictionaryLiteralExpression(pairs: pairs)
    }
    
    public static func ternary(_ exp: Expression, `true` ifTrue: Expression, `false` ifFalse: Expression) -> TernaryExpression {
        return TernaryExpression(exp: exp, ifTrue: ifTrue, ifFalse: ifFalse)
    }
    
    public static func block(parameters: [BlockParameter], `return` returnType: SwiftType, body: CompoundStatement) -> BlockLiteralExpression {
        return BlockLiteralExpression(parameters: parameters, returnType: returnType, body: body)
    }
    
    public static func unknown(_ exp: UnknownASTContext) -> UnknownExpression {
        return UnknownExpression(context: exp)
    }
}

public struct BlockParameter: Equatable {
    var name: String
    var type: SwiftType
    
    public init(name: String, type: SwiftType) {
        self.name = name
        self.type = type
    }
}

public struct ExpressionDictionaryPair: Equatable {
    public var key: Expression
    public var value: Expression
    
    public init(key: Expression, value: Expression) {
        self.key = key
        self.value = value
    }
}

/// A postfix expression type
public indirect enum Postfix: Equatable {
    case optionalAccess
    case member(String)
    case `subscript`(Expression)
    case functionCall(arguments: [FunctionArgument])
}

/// A function argument kind
public enum FunctionArgument: Equatable {
    case labeled(String, Expression)
    case unlabeled(Expression)
    
    public var expression: Expression {
        switch self {
        case .labeled(_, let exp), .unlabeled(let exp):
            return exp
        }
    }
    
    public var label: String? {
        switch self {
        case .labeled(let label, _):
            return label
        case .unlabeled:
            return nil
        }
    }
    
    public var isLabeled: Bool {
        switch self {
        case .labeled:
            return true
        case .unlabeled:
            return false
        }
    }
}

/// One of the recognized constant values
public enum Constant: Equatable {
    case float(Float)
    case boolean(Bool)
    case int(Int)
    case binary(Int)
    case octal(Int)
    case hexadecimal(Int)
    case string(String)
    case rawConstant(String)
    case `nil`
    
    /// Returns an integer value if this constant represents one, or nil, in case
    /// it does not.
    public var integerValue: Int? {
        switch self {
        case .int(let i), .binary(let i), .octal(let i), .hexadecimal(let i):
            return i
        default:
            return nil
        }
    }
    
    /// Returns `true` if this constant represents an integer value.
    public var isInteger: Bool {
        switch self {
        case .int, .binary, .octal, .hexadecimal:
            return true
        default:
            return false
        }
    }
}

/// Describes an operator across one or two operands
public enum SwiftOperator: String {
    /// If `true`, a spacing is suggested to be placed in between operands.
    /// True for most operators except range operators.
    public var requiresSpacing: Bool {
        switch self {
        case .openRange, .closedRange:
            return false
        default:
            return true
        }
    }
    
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    
    case mod = "%"
    
    case addAssign = "+="
    case subtractAssign = "-="
    case multiplyAssign = "*="
    case divideAssign = "/="
    
    case negate = "!"
    case and = "&&"
    case or = "||"
    
    case bitwiseAnd = "&"
    case bitwiseOr = "|"
    case bitwiseXor = "^"
    case bitwiseNot = "~"
    case bitwiseShiftLeft = "<<"
    case bitwiseShiftRight = ">>"
    
    case bitwiseAndAssign = "&="
    case bitwiseOrAssign = "|="
    case bitwiseXorAssign = "^="
    case bitwiseNotAssign = "~="
    case bitwiseShiftLeftAssign = "<<="
    case bitwiseShiftRightAssign = ">>="
    
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
    
    case assign = "="
    case equals = "=="
    case unequals = "!="
    
    case nullCoallesce = "??"
    
    case openRange = "..<"
    case closedRange = "..."
    
    /// Gets the category for this operator
    public var category: SwiftOperatorCategory {
        switch self {
        // Arithmetic
        case .add, .subtract, .multiply, .divide, .mod:
            return .arithmetic
        
        // Logical
        case .and, .or, .negate:
            return .logical
            
        // Bitwise
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor, .bitwiseNot, .bitwiseShiftLeft,
             .bitwiseShiftRight:
            return .bitwise
            
        // Assignment
        case .assign, .addAssign, .subtractAssign, .multiplyAssign, .divideAssign,
             .bitwiseAndAssign, .bitwiseOrAssign, .bitwiseXorAssign, .bitwiseNotAssign,
             .bitwiseShiftLeftAssign, .bitwiseShiftRightAssign:
            return .assignment
            
        // Comparison
        case .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual,
             .equals, .unequals:
            return .comparison
            
        // Null-coallesce
        case .nullCoallesce:
            return .nullCoallesce
            
        // Range-making operators
        case .openRange, .closedRange:
            return .range
        }
    }
}

public enum SwiftOperatorCategory: Equatable {
    case arithmetic
    case comparison
    case logical
    case bitwise
    case nullCoallesce
    case assignment
    case range
}

// MARK: - String Conversion

extension ExpressionDictionaryPair: CustomStringConvertible {
    public var description: String {
        return key.description + ": " + value.description
    }
}

extension Postfix: CustomStringConvertible {
    public var description: String {
        switch self {
        case .optionalAccess:
            return "?"
        case .member(let mbm):
            return "." + mbm
        case .subscript(let subs):
            return "[" + subs.description + "]"
        case .functionCall(let arguments):
            return "(" + arguments.map { $0.description }.joined(separator: ", ") + ")"
        }
    }
}

extension BlockParameter: CustomStringConvertible {
    public var description: String {
        let cvt = TypeMapper(context: TypeContext())
        
        return "\(self.name): \(cvt.typeNameString(for: type))"
    }
}

extension FunctionArgument: CustomStringConvertible {
    public var description: String {
        switch self {
        case .labeled(let lbl, let exp):
            return "\(lbl): \(exp)"
        case .unlabeled(let exp):
            return exp.description
        }
    }
}

extension Constant: CustomStringConvertible {
    public var description: String {
        switch self {
        case .float(let fl):
            return fl.description
        case .boolean(let bool):
            return bool.description
        case .int(let int):
            return int.description
        case .binary(let int):
            return "0b" + String(int, radix: 2)
        case .octal(let int):
            return "0o" + String(int, radix: 8)
        case .hexadecimal(let int):
            return "0x" + String(int, radix: 16, uppercase: false)
        case .string(let str):
            return "\"\(str)\""
        case .rawConstant(let str):
            return str
        case .nil:
            return "nil"
        }
    }
}

extension SwiftOperator: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

// MARK: - Literal initialiation
extension Constant: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension Constant: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Float) {
        self = .float(value)
    }
}

extension Constant: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

extension Constant: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

// MARK: - Operator definitions
public extension Expression {
    public static func +(lhs: Expression, rhs: Expression) -> Expression {
        return .binary(lhs: lhs, op: .add, rhs: rhs)
    }
    
    public static func -(lhs: Expression, rhs: Expression) -> Expression {
        return .binary(lhs: lhs, op: .subtract, rhs: rhs)
    }
    
    public static func *(lhs: Expression, rhs: Expression) -> Expression {
        return .binary(lhs: lhs, op: .multiply, rhs: rhs)
    }
    
    public static func /(lhs: Expression, rhs: Expression) -> Expression {
        return .binary(lhs: lhs, op: .divide, rhs: rhs)
    }
    
    public static prefix func !(lhs: Expression) -> Expression {
        return .unary(op: .negate, lhs)
    }
    
    public static func &&(lhs: Expression, rhs: Expression) -> Expression {
        return .binary(lhs: lhs, op: .and, rhs: rhs)
    }
    
    public static func ||(lhs: Expression, rhs: Expression) -> Expression {
        return .binary(lhs: lhs, op: .or, rhs: rhs)
    }
    
    public static func |(lhs: Expression, rhs: Expression) -> Expression {
        return .binary(lhs: lhs, op: .bitwiseOr, rhs: rhs)
    }
    
    public static func &(lhs: Expression, rhs: Expression) -> Expression {
        return .binary(lhs: lhs, op: .bitwiseAnd, rhs: rhs)
    }
}
