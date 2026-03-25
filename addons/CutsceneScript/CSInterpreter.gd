extends RefCounted
class_name CSInterpreter

var target:Variant
var context:CSExecutionContext
var errors:Array[String]
var errored:bool = false

var scriptToExecute:CSExpression.CSScript
var curStatementIndx:int = 0
var paused:bool = false

func prepare(_target:Variant = null):
	errors.clear()
	target = _target
	context = CSExecutionContext.new()
	context.interpreter = self
	scriptToExecute = null
	curStatementIndx = 0

func pause():
	if(paused):
		assert(false, "TRYING TO PAUSE WHEN WE'RE ALREADY PAUSED!")
		return
	paused = true

func unpause():
	if(!paused):
		assert(false, "TRYING TO UNPAUSE WHEN WE'RE NOT PAUSED!")
		return
	paused = false
	executeStatements()

func executeStatements():
	if(paused):
		return
	var stAm:int = scriptToExecute.statements.size()
	while(scriptToExecute && curStatementIndx < stAm):
		curStatementIndx += 1
		#var statementToExecute := statementsToExecute.pop_front()
		var statementToExecute := scriptToExecute.statements[curStatementIndx-1]
		execute(statementToExecute)
		if(hadErrors()): # Let errors happen, continue anyway
			clearErrorFlag()
		if(paused):
			return
	if(scriptToExecute && curStatementIndx >= stAm):
		stopScript() # Reached the end of the script
	
func stopScript():
	scriptToExecute = null
	curStatementIndx = 0
	paused = false

func gotoLabel(_label:String) -> bool:
	if(!scriptToExecute):
		return false
	if(!scriptToExecute.labels.has(_label)):
		pushError(scriptToExecute.statements[curStatementIndx], "Label "+_label+" is not found!")
		return false
	curStatementIndx = scriptToExecute.labels[_label]
	return true
	
func execute(_expr:CSExpression) -> Variant:
	if(!_expr):
		pushError(_expr, "Null expression found")
		assert(false, "Null expression found")
		return null
	
	if(_expr is CSExpression.CSScript):
		scriptToExecute = _expr # push to a stack of scripts instead?
		curStatementIndx = 0
		paused = false
		return null
		
	if(_expr is CSExpression.CSStatement):
		var theArgs:Array[Variant] = []
		for theArgExpression in _expr.args:
			var theValue:Variant = execute(theArgExpression)
			if(hadErrors()):
				return null
			theArgs.append(theValue)
		
		if(!target.doStatement(_expr.target, _expr.word, theArgs, context)):
			pushError(_expr, "Unhandled statement: "+((_expr.target+".") if !_expr.target.is_empty() else "")+_expr.word+" ARGS="+str(theArgs)+" (Don't forget to return true in doStatement())")
		return null
	if(_expr is CSExpression.CSLabel):
		return null
	
	#if(_expr is CSExpression.CSGoto):
	#	gotoLabel(_expr.label)
	#	return null
	
	if(_expr is CSExpression.CSIfStatement):
		var theCondVal:Variant = execute(_expr.condition)
		if(hadErrors()):
			return null
		if(theCondVal):
			execute(_expr.statement)
		elif(_expr.elseStatement):
			execute(_expr.elseStatement)
		return null
	
	if(_expr is CSExpression.Property):
		if(_expr.left is CSExpression.Variable):
			return target.getExpressionValue(_expr.left.name, _expr.property, [], context)
		pushError(_expr, "This kind of property isn't supported")
		return null
	
	if(_expr is CSExpression.Variable):
		return target.getExpressionValue("", _expr.name, [], context)
	
	if(_expr is CSExpression.Call):
		var theArgs:Array[Variant] = []
		for theArgExpression in _expr.arguments:
			var theValue:Variant = execute(theArgExpression)
			if(hadErrors()):
				return null
			theArgs.append(theValue)
		
		if(_expr.left is CSExpression.Variable):
			return target.getExpressionValue("", _expr.left.name, theArgs, context)
		if(_expr.left is CSExpression.Property):
			var theProperty:CSExpression.Property = _expr.left
			if(theProperty.left is CSExpression.Variable):
				return target.getExpressionValue(theProperty.left.name, theProperty.property, theArgs, context)
		
		pushError(_expr, "This kind of call isn't supported")
		return null
	
	if(_expr is CSExpression.Literal):
		return _expr.value
	if(_expr is CSExpression.Grouping):
		var theRes:Variant = execute(_expr.expression)
		if(hadErrors()):
			return null
		return theRes
	
	if(_expr is CSExpression.Variable):
		pushError(_expr, "NOT IMPLEMENTED")
		return null
		#var theRes := getValueProperty(_expr.name)
		#if(theRes.hadError):
			#pushError(_expr, theRes.error)
			#return null
		#var someVal:Variant = theRes.value
		#if(someVal == null):
			#pushError(_expr, "Received null")
			#return null
		#return someVal
#
	#if(_expr is CSExpression.PropertyDirect):
		#var theRes := getValuePropertyOn(_expr.target, _expr.property)
		#if(theRes.hadError):
			#pushError(_expr, theRes.error)
			#return null
		#var someVal:Variant = theRes.value
		#if(someVal == null):
			#pushError(_expr, "Received null")
			#return null
		#return someVal
#
	#if(_expr is CSExpression.CallDirect):
		#var theArgs:Array = []
		#for theArgExpr in _expr.arguments:
			#var newArgVal:Variant = execute(theArgExpr)
			#if(hadErrors()):
				#return null
			#theArgs.append(newArgVal)
		#
		#var theRes := getValueCallDirect(_expr.functionName, theArgs)
		#if(theRes.hadError):
			#pushError(_expr, theRes.error)
			#return null
		#var someVal:Variant = theRes.value
		#if(someVal == null):
			#pushError(_expr, "Received null")
			#return null
		#return someVal
#
	#if(_expr is CSExpression.CallDirectOn):
		#var theArgs:Array = []
		#for theArgExpr in _expr.arguments:
			#var newArgVal:Variant = execute(theArgExpr)
			#if(hadErrors()):
				#return null
			#theArgs.append(newArgVal)
		#
		#var theRes := getValueCallDirectOn(_expr.target, _expr.functionName, theArgs)
		#if(theRes.hadError):
			#pushError(_expr, theRes.error)
			#return null
		#var someVal:Variant = theRes.value
		#if(someVal == null):
			#pushError(_expr, "Received null")
			#return null
		#return someVal
	
	if(_expr is CSExpression.Unary):
		var rightValue:Variant = execute(_expr.right)
		if(hadErrors()):
			return null
		
		if(_expr.operator == CSExpression.OPERATOR.MINUS):
			if((rightValue is int) || (rightValue is float)):
				return -rightValue
			else:
				pushError(_expr, "Trying to make a non-number value negative: "+str(rightValue))
		elif(_expr.operator == CSExpression.OPERATOR.BANG):
			return !rightValue
		
		pushError(_expr, "Unknown unary operand")
		return null
	
	if(_expr is CSExpression.Binary):
		var leftValue:Variant = execute(_expr.left)
		if(hadErrors()):
			return null
		var rightValue:Variant = execute(_expr.right)
		if(hadErrors()):
			return null
		
		var theOp:int = _expr.operator
		if(theOp == CSExpression.OPERATOR.PLUS):
			return leftValue + rightValue
		elif(theOp == CSExpression.OPERATOR.MINUS):
			return leftValue - rightValue
		elif(theOp == CSExpression.OPERATOR.MULT):
			return leftValue * rightValue
		elif(theOp == CSExpression.OPERATOR.DIV):
			return leftValue / rightValue
		elif(theOp == CSExpression.OPERATOR.LESS):
			return leftValue < rightValue
		elif(theOp == CSExpression.OPERATOR.MORE):
			return leftValue > rightValue
		elif(theOp == CSExpression.OPERATOR.LESS_OR_EQUAL):
			return leftValue <= rightValue
		elif(theOp == CSExpression.OPERATOR.MORE_OR_EQUAL):
			return leftValue >= rightValue
		elif(theOp == CSExpression.OPERATOR.EQUAL):
			return leftValue == rightValue
		elif(theOp == CSExpression.OPERATOR.NOT_EQUAL):
			return leftValue != rightValue
		elif(theOp == CSExpression.OPERATOR.AND):
			return leftValue && rightValue
		elif(theOp == CSExpression.OPERATOR.OR):
			return leftValue || rightValue
		pushError(_expr, "Unknown binary operand")
		return null
	if(_expr is CSExpression.Ternary):
		var conditionResult:Variant = execute(_expr.condition)
		if(hadErrors()):
			return null
		if(conditionResult):
			var theVal:Variant = execute(_expr.trueExpr)
			if(hadErrors()):
				return null
			return theVal
		else:
			var theVal:Variant = execute(_expr.falseExpr)
			if(hadErrors()):
				return null
			return theVal
	
	pushError(_expr, "Unhandled expression (Not supported)")
	return null

class ResultOrError:
	var value:Variant
	var error:String
	var hadError:bool = false
	
	static func createError(_text:String) -> ResultOrError:
		var newRes := ResultOrError.new()
		newRes.hadError = true
		newRes.error = _text
		return newRes
	
	static func create(_val:Variant) -> ResultOrError:
		var newRes := ResultOrError.new()
		newRes.value = _val
		return newRes



func pushError(_expr:CSExpression, _str:String):
	errored = true
	if(!_expr):
		errors.append(_str)
		return
	var theErrorText:String = "Line "+str(_expr.line)+": "+_expr.getName()+": "+_str
	errors.append("Line "+str(_expr.line)+": "+_expr.getName()+": "+_str)
	printerr("(CSInterpreter) "+theErrorText)

func hadErrors() -> bool:
	return errored

func clearErrorFlag():
	errored = false

func hadErrorsAtAll() -> bool:
	return !errors.is_empty()
