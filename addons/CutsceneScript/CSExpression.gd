extends RefCounted
class_name CSExpression

enum OPERATOR {
	PLUS,
	MINUS,
	MULT,
	DIV,
	BANG,
	MORE,
	LESS,
	MORE_OR_EQUAL,
	LESS_OR_EQUAL,
	EQUAL,
	NOT_EQUAL,
	AND,
	OR,
}

const TOKEN_MAP:Dictionary[int, int] = {
	CSLexer.TOKEN.MATH_PLUS: OPERATOR.PLUS,
	CSLexer.TOKEN.MATH_MINUS: OPERATOR.MINUS,
	CSLexer.TOKEN.MATH_MULT: OPERATOR.MULT,
	CSLexer.TOKEN.MATH_DIV: OPERATOR.DIV,
	CSLexer.TOKEN.BANG: OPERATOR.BANG,
	CSLexer.TOKEN.MATH_MORE: OPERATOR.MORE,
	CSLexer.TOKEN.MATH_LESS: OPERATOR.LESS,
	CSLexer.TOKEN.MATH_MOREOREQUAL: OPERATOR.MORE_OR_EQUAL,
	CSLexer.TOKEN.MATH_LESSOREQUAL: OPERATOR.LESS_OR_EQUAL,
	CSLexer.TOKEN.MATH_EQUALEQUAL: OPERATOR.EQUAL,
	CSLexer.TOKEN.MATH_BANGEQUAL: OPERATOR.NOT_EQUAL,
	CSLexer.TOKEN.AND: OPERATOR.AND,
	CSLexer.TOKEN.OR: OPERATOR.OR,
}
static func tokenToOperator(_token:int) -> int:
	return TOKEN_MAP.get(_token, -1)

var line:int = 0

func setLine(_l:int) -> CSExpression:
	line = _l
	return self
func getName() -> String:
	return "CHANGE ME"

class CSScript extends CSStatementBase:
	var statements:Array[CSStatementBase]
	var labels:Dictionary[String, int] # name -> line number
	static func create(_statements:Array[CSStatementBase], _line:int = -1) -> CSScript:
		var newExpr := CSScript.new()
		newExpr.statements = _statements
		
		# Finding the labels
		var _i:int = 0
		for theStatement in _statements:
			if(theStatement is CSExpression.CSLabel):
				newExpr.labels[theStatement.name] = _i
			_i += 1
		
		newExpr.line = _line
		return newExpr
	func getName() -> String:
		return "CSScript"
	const ExprName := "CSScript"

class QuestionAnswer:
	var textExpr:CSExpression
	var labelName:String
	var visibleExpr:CSExpression
	var enabledExpr:CSExpression

class CSQuestion extends CSStatementBase:
	var textExpr:CSExpression
	var answers:Array[QuestionAnswer]
	
	static func create(_text:CSExpression, _answers:Array[QuestionAnswer]) -> CSQuestion:
		var newExpr := CSQuestion.new()
		newExpr.textExpr = _text
		newExpr.answers = _answers
		newExpr.line = _text.line
		return newExpr
	func getName() -> String:
		return "CSQuestion"
	const ExprName := "CSQuestion"

class CSLabel extends CSStatementBase:
	var name:String
	static func create(_name:String, _line:int = -1) -> CSLabel:
		var newExpr := CSLabel.new()
		newExpr.name = _name
		newExpr.line = _line
		return newExpr
	func getName() -> String:
		return "CSLabel"
	const ExprName := "CSLabel"

class CSIfStatement extends CSStatementBase:
	var condition:CSExpression
	var statement:CSExpression.CSStatementBase
	var elseStatement:CSExpression.CSStatementBase
	static func create(_cond:CSExpression, _stmt:CSExpression.CSStatementBase, _else:CSExpression.CSStatementBase) -> CSIfStatement:
		var newExpr := CSIfStatement.new()
		newExpr.condition = _cond
		newExpr.statement = _stmt
		newExpr.elseStatement = _else
		newExpr.line = _cond.line
		return newExpr
	func getName() -> String:
		return "CSIfStatement"
	const ExprName := "CSIfStatement"

#class CSGoto extends CSStatementBase:
	#var label:String
	#static func create(_label:String, _line:int = -1) -> CSGoto:
		#var newExpr := CSGoto.new()
		#newExpr.label = _label
		#newExpr.line = _line
		#return newExpr
	#func getName() -> String:
		#return "CSGoto"
	#const ExprName := "CSGoto"

class CSStatement extends CSStatementBase:
	var target:String
	var word:String
	var args:Array[CSExpression]
	static func create(_target:String, _word:String, _args:Array[CSExpression], _line:int = -1) -> CSStatement:
		var newExpr := CSStatement.new()
		newExpr.target = _target
		newExpr.word = _word
		newExpr.args = _args
		newExpr.line = _line
		return newExpr
	func getName() -> String:
		return "CSStatement"
	const ExprName := "CSStatement"

class CSStatementBase extends CSExpression:
	pass

class Ternary extends CSExpression:
	var condition:CSExpression
	var trueExpr:CSExpression
	var falseExpr:CSExpression
	static func create(_cond:CSExpression, _trueExpr:CSExpression, _falseExpr:CSExpression) -> Ternary:
		var newExpr := Ternary.new()
		newExpr.condition = _cond
		newExpr.trueExpr = _trueExpr
		newExpr.falseExpr = _falseExpr
		newExpr.line = _cond.line
		return newExpr
	func getName() -> String:
		return "Ternary"
	const ExprName := "Ternary"

class Call extends CSExpression:
	var left:CSExpression
	var arguments:Array[CSExpression]
	static func create(_left:CSExpression, _args:Array[CSExpression]) -> Call:
		var newExpr := Call.new()
		newExpr.left = _left
		newExpr.arguments = _args
		newExpr.line = _left.line
		return newExpr
	func getName() -> String:
		return "Call"
	const ExprName := "Call"

class CallDirect extends CSExpression:
	var functionName:String
	var arguments:Array[CSExpression]
	static func create(_func:String, _args:Array[CSExpression], _line:int = -1) -> CallDirect:
		var newExpr := CallDirect.new()
		newExpr.functionName = _func
		newExpr.arguments = _args
		newExpr.line = _line
		return newExpr
	func getName() -> String:
		return "CallDirect"
	const ExprName := "CallDirect"

class CallOn extends CSExpression:
	var left:CSExpression
	var functionName:String
	var arguments:Array[CSExpression]
	static func create(_left:CSExpression, _func:String, _args:Array[CSExpression]) -> CallOn:
		var newExpr := CallOn.new()
		newExpr.left = _left
		newExpr.functionName = _func
		newExpr.arguments = _args
		newExpr.line = _left.line
		return newExpr
	func getName() -> String:
		return "CallOn"
	const ExprName := "CallOn"

class CallDirectOn extends CSExpression:
	var target:String
	var functionName:String
	var arguments:Array[CSExpression]
	static func create(_target:String, _func:String, _args:Array[CSExpression], _line:int = -1) -> CallDirectOn:
		var newExpr := CallDirectOn.new()
		newExpr.target = _target
		newExpr.functionName = _func
		newExpr.arguments = _args
		newExpr.line = _line
		return newExpr
	func getName() -> String:
		return "CallDirectOn"
	const ExprName := "CallDirectOn"

class PropertyDirect extends CSExpression:
	var target:String
	var property:String
	static func create(_target:String, _prop:String, _line:int = -1) -> PropertyDirect:
		var newExpr := PropertyDirect.new()
		newExpr.target = _target
		newExpr.property = _prop
		newExpr.line = _line
		return newExpr
	func getName() -> String:
		return "PropertyDirect"
	const ExprName := "PropertyDirect"

class Property extends CSExpression:
	var left:CSExpression
	var property:String
	static func create(_left:CSExpression, _prop:String) -> Property:
		var newExpr := Property.new()
		newExpr.left = _left
		newExpr.property = _prop
		newExpr.line = _left.line
		return newExpr
	func getName() -> String:
		return "Property"
	const ExprName := "Property"

class Variable extends CSExpression:
	var name:String
	static func create(_name:String, _line:int = -1) -> Variable:
		var newExpr := Variable.new()
		newExpr.name = _name
		newExpr.line = _line
		return newExpr
	func getName() -> String:
		return "Variable"
	const ExprName := "Variable"

class Unary extends CSExpression:
	var operator:int
	var right:CSExpression
	static func create(_op:int, _right:CSExpression) -> Unary:
		var newExpr := Unary.new()
		newExpr.operator = _op
		newExpr.right = _right
		newExpr.line = _right.line
		return newExpr
	func getName() -> String:
		return "Unary"
	const ExprName := "Unary"

class Logical extends CSExpression:
	var left: CSExpression
	var operator:int
	var right:CSExpression
	static func create(_left:CSExpression, _op:int, _right:CSExpression) -> Logical:
		var newExpr := Logical.new()
		newExpr.left = _left
		newExpr.operator = _op
		newExpr.right = _right
		newExpr.line = _left.line
		return newExpr
	func getName() -> String:
		return "Logical"
	const ExprName := "Logical"

class Literal extends CSExpression:
	var value:Variant
	static func create(_value:Variant, _lineNumber:int=-1) -> Literal:
		var newExpr := Literal.new()
		newExpr.value = _value
		newExpr.line = _lineNumber
		return newExpr
	func getName() -> String:
		return "Literal"
	const ExprName := "Literal"

class Grouping extends CSExpression:
	var expression:CSExpression
	static func create(_expression:CSExpression) -> Grouping:
		var newExpr := Grouping.new()
		newExpr.expression = _expression
		newExpr.line = _expression.line
		return newExpr
	func getName() -> String:
		return "Grouping"
	const ExprName := "Grouping"

class Binary extends CSExpression:
	var left: CSExpression
	var operator:int
	var right:CSExpression
	static func create(_left:CSExpression, _op:int, _right:CSExpression) -> Binary:
		var newExpr := Binary.new()
		newExpr.left = _left
		newExpr.operator = _op
		newExpr.right = _right
		newExpr.line = _left.line
		return newExpr
	func getName() -> String:
		return "Binary"
	const ExprName := "Binary"
