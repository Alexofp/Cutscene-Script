extends RefCounted
class_name CSParser

const MAX_ERRORS := 10

class ParseContext:
	var hadErrors:bool = false
	var errors:Array[String]

var curI:int
var curResult:ParseContext
var curLen:int
var curLexerResult:CSLexer.ParseResult
func parseStandaloneExpression(_result:CSLexer.ParseResult) -> CSExpression:
	curResult = ParseContext.new()
	curI = 0
	curLexerResult = _result
	curLen = curLexerResult.tokens.size()
	
	return parseExpression()

func parseStandaloneScript(_result:CSLexer.ParseResult) -> CSExpression.CSScript:
	curResult = ParseContext.new()
	curI = 0
	curLexerResult = _result
	curLen = curLexerResult.tokens.size()
	
	return parseScript()


func handleUnexpectedToken():
	if(!pushError("Unexpected token")):
		consume() # pushError returns false if it didn't consume any tokens, this is a safe-guard

func checkEOL() -> bool:
	if(currType() == CSLexer.TOKEN.EOL):
		consume()
		return true
	return false

func checkEOF() -> bool:
	if(currType() == CSLexer.TOKEN.EOF):
		consume()
		if(!isEOF()):
			pushError("Got tokens after the END OF FILE token.")
		return true
	return false

func skipUntilNewLine() -> bool:
	var didAnyConsumes:bool = false
	while(!isEOF()):
		var curToken:int = currType()
		
		if(curToken == CSLexer.TOKEN.EOL):
			consume()
			didAnyConsumes = true
			break
		consume()
		didAnyConsumes = true
	return didAnyConsumes

func curr() -> CSLexer.ParseToken:
	if(curI >= curLen):
		return null
	return curLexerResult.tokens[curI]

func currType() -> int:
	if(curI >= curLen):
		return -1
	return curLexerResult.tokens[curI].type

func next(_howFar:int = 1) -> CSLexer.ParseToken:
	if((curI+_howFar) >= curLen):
		return null
	return curLexerResult.tokens[curI+_howFar]

func nextType(_howFar:int = 1) -> int:
	if((curI+_howFar) >= curLen):
		return -1
	return curLexerResult.tokens[curI+_howFar].type

func consume() -> CSLexer.ParseToken:
	curI += 1
	return next(-1)

func isEOF() -> bool:
	return curI >= curLen

const SKIP_UNTIL_NEW_LINE := 0
const SKIP_DISABLE := 1

func pushError(_error:String, _skipPolicy:int = SKIP_UNTIL_NEW_LINE) -> bool:
	curResult.hadErrors = true
	if(curResult.errors.size() < MAX_ERRORS):
		var curToken := curr()
		
		if(curToken):
			internal_addError(curToken.getErrorDebugString()+": "+_error)
		else:
			internal_addError(_error)
		if(curResult.errors.size() == MAX_ERRORS):
			internal_addError("TOO MANY ERRORS, IGNORING THE REST")
	
	if(_skipPolicy == SKIP_UNTIL_NEW_LINE):
		return skipUntilNewLine()
	else:
		return true

func internal_addError(_text:String):
	curResult.errors.append(_text)
	printerr("(CSParser) "+_text)


func parseScript() -> CSExpression.CSScript:
	var theStatements:Array[CSExpression.CSStatementBase] = []
	while(!isEOF()):
		if(checkEOL() || checkEOF()):
			continue
		
		var theStatement := parseStatement()
		if(!theStatement):
			return null
		theStatements.append(theStatement)
	
	return CSExpression.CSScript.create(theStatements)

func parseStatement() -> CSExpression.CSStatementBase:
	if(currType() == CSLexer.TOKEN.MATH_MORE):
		consume()
		
		if(currType() != CSLexer.TOKEN.WORD):
			pushError("Expected a label name after >")
			return null
		var theLabelName := consume()
		
		if(!checkEOL() && !checkEOF()):
			pushError("Expected end of line after label name")
			return null
		return CSExpression.CSLabel.create(theLabelName.value, theLabelName.line)
	
	if(currType() == CSLexer.TOKEN.IF):
		consume()
		
		var theExpr := parseExpression()
		if(!theExpr):
			return null
		
		if(currType() != CSLexer.TOKEN.TWO_DOTS):
			pushError("Expected a : after IF condition")
			return null
		consume()
		
		var theStmt := parseStatement()
		if(!theStmt):
			return null
		
		checkEOL()
		var theElse:CSExpression.CSStatementBase
		if(currType() == CSLexer.TOKEN.ELSE):
			consume()
			if(currType() != CSLexer.TOKEN.TWO_DOTS):
				pushError("Expected : after else")
				return null
			consume()
			
			theElse = parseStatement()
			if(!theElse):
				return null
			checkEOL()
		
		return CSExpression.CSIfStatement.create(theExpr, theStmt, theElse)
	
	if(currType() == CSLexer.TOKEN.WORD):
		var theWord := consume()
		
		#if(theWord.value == "goto"):
			#if(currType() == CSLexer.TOKEN.WORD):
				#var theLabelWord := consume()
				#return CSExpression.CSGoto.create(theLabelWord.value, theLabelWord.line)
			#else:
				#pushError("Expected a label after goto")
				#return null
		
		var theWord2:CSLexer.ParseToken
		if(currType() == CSLexer.TOKEN.DOT):
			consume()
			if(currType() != CSLexer.TOKEN.WORD):
				pushError("Expected another word after .")
				return null
			theWord2 = consume()
		
		var theArgs:Array[CSExpression] = []
		
		if(checkEOL() || checkEOF()):
			pass
		elif(currType() != CSLexer.TOKEN.EOL):
			var theFirstArg := parseExpression()
			if(!theFirstArg):
				return null
			theArgs.append(theFirstArg)
			
			while(currType() == CSLexer.TOKEN.COMMA):
				consume()
				var theArg := parseExpression()
				if(!theArg):
					return null
				theArgs.append(theArg)
				
				if(checkEOL() || checkEOF()):
					break
		if(theWord2):
			return CSExpression.CSStatement.create(theWord.value, theWord2.value, theArgs, theWord.line)
		return CSExpression.CSStatement.create("", theWord.value, theArgs, theWord.line)
	
	pushError("BAD STATEMENT")
	return null


func parseExpression() -> CSExpression:
	var theEquality := parseLogicOr()
	if(!theEquality):
		return null
	
	# Ternary
	if(currType() == CSLexer.TOKEN.IF):
		consume()
		
		var theConditionExpr := parseExpression()
		if(!theConditionExpr):
			return null
		if(currType() != CSLexer.TOKEN.ELSE):
			pushError("Expected 'else'", SKIP_UNTIL_NEW_LINE)
			return null
		consume()
		
		var falseExpr := parseExpression()
		if(!falseExpr):
			return null
		var theTern := CSExpression.Ternary.create(theConditionExpr, theEquality, falseExpr)
		return theTern
	
	return theEquality

func parseLogicOr() -> CSExpression:
	var expr := parseLogicAnd()
	if(!expr):
		return null

	while(currType() == CSLexer.TOKEN.OR):
		var theToken := consume()
		var right := parseLogicAnd()
		if(!right):
			return null
		expr = CSExpression.Binary.create(expr, CSExpression.tokenToOperator(theToken.type), right)
	
	return expr

func parseLogicAnd() -> CSExpression:
	var expr := parseEquality()
	if(!expr):
		return null

	while(currType() == CSLexer.TOKEN.AND):
		var theToken := consume()
		var right := parseEquality()
		if(!right):
			return null
		expr = CSExpression.Binary.create(expr, CSExpression.tokenToOperator(theToken.type), right)
	
	return expr

func parseEquality() -> CSExpression:
	var expr := parseComparison()
	if(!expr):
		return null
	
	while(currType() in [CSLexer.TOKEN.MATH_EQUALEQUAL, CSLexer.TOKEN.MATH_BANGEQUAL]):
		var theToken := consume()
		var right := parseComparison()
		if(!right):
			return null
		expr = CSExpression.Binary.create(expr, CSExpression.tokenToOperator(theToken.type), right)
	
	return expr

func parseComparison() -> CSExpression:
	var expr := parseTerm()
	if(!expr):
		return null
	
	while(currType() in [CSLexer.TOKEN.MATH_MORE, CSLexer.TOKEN.MATH_LESS, CSLexer.TOKEN.MATH_MOREOREQUAL, CSLexer.TOKEN.MATH_LESSOREQUAL]):
		var theToken := consume()
		var right := parseTerm()
		if(!right):
			return null
		expr = CSExpression.Binary.create(expr, CSExpression.tokenToOperator(theToken.type), right)
	
	return expr

func parseTerm() -> CSExpression:
	var expr := parseFactor()
	if(!expr):
		return null
	
	while(currType() in [CSLexer.TOKEN.MATH_PLUS, CSLexer.TOKEN.MATH_MINUS]):
		var theToken := consume()
		var right := parseFactor()
		if(!right):
			return null
		expr = CSExpression.Binary.create(expr, CSExpression.tokenToOperator(theToken.type), right)
	
	return expr

func parseFactor() -> CSExpression:
	var expr := parseUnary()
	if(!expr):
		return null
	
	while(currType() in [CSLexer.TOKEN.MATH_DIV, CSLexer.TOKEN.MATH_MULT]):
		var theToken := consume()
		var right := parseUnary()
		if(!right):
			return null
		expr = CSExpression.Binary.create(expr, CSExpression.tokenToOperator(theToken.type), right)
	
	return expr

func parseUnary() -> CSExpression:
	var theType := currType()
	if(theType == CSLexer.TOKEN.MATH_MINUS || theType == CSLexer.TOKEN.BANG):
		var theToken := consume()
		var right := parseUnary()
		if(!right):
			return null
		return CSExpression.Unary.create(CSExpression.tokenToOperator(theToken.type), right)
	
	return parseCall()

func parseCall() -> CSExpression:
	var expr := parsePrimary()
	if(!expr):
		return null
	
	while(true):
		var theType := currType()
		
		if(theType == CSLexer.TOKEN.PAREN_LEFT):
			consume()
			
			var args:Array[CSExpression]
			# Arguments
			while(currType() != CSLexer.TOKEN.PAREN_RIGHT):
				var anArg := parseExpression()
				if(!anArg):
					return null
				args.append(anArg)
				
				if(currType() == CSLexer.TOKEN.COMMA):
					consume()
			
			if(currType() == CSLexer.TOKEN.PAREN_RIGHT):
				consume()
				
				#if(expr is CSExpression.Variable):
					#expr = CSExpression.CallDirect.create(expr.name, args, expr.line)
				#elif(expr is CSExpression.Property):
					#if(expr.left is CSExpression.Variable):
						#expr = CSExpression.CallDirectOn.create(expr.left.name, expr.property, args, expr.line)
					#else:
						#expr = CSExpression.CallOn.create(expr.left, expr.property, args)
				#elif(expr is CSExpression.PropertyDirect):
					#expr = CSExpression.CallDirectOn.create(expr.target, expr.property, args, expr.line)
				#else:
					#expr = CSExpression.Call.create(expr, args)
				expr = CSExpression.Call.create(expr, args)
			else:
				pushError("Expected ')' after arguments of the function call", SKIP_UNTIL_NEW_LINE)
				return null
		elif(theType == CSLexer.TOKEN.DOT):
			consume()
			
			if(currType() == CSLexer.TOKEN.WORD):
				var theVal := consume()
				#if(expr is CSExpression.Variable):
				#	expr = CSExpression.PropertyDirect.create(expr.name, theVal.value, expr.line)
				#else:
				expr = CSExpression.Property.create(expr, theVal.value)
			else:
				pushError("Expected an ID after a dot", SKIP_UNTIL_NEW_LINE)
				return null
		else:
			break
	
	return expr
	
func parsePrimary() -> CSExpression:
	var theType := currType()
	if(theType == CSLexer.TOKEN.FALSE):
		return CSExpression.Literal.create(false, consume().line)
	if(theType == CSLexer.TOKEN.TRUE):
		return CSExpression.Literal.create(true, consume().line)
	if(theType == CSLexer.TOKEN.INT):
		var theVal := consume()
		return CSExpression.Literal.create(theVal.value, theVal.line)
	if(theType == CSLexer.TOKEN.STRING):
		var theVal := consume()
		return CSExpression.Literal.create(theVal.value, theVal.line)
	if(theType == CSLexer.TOKEN.FLOAT):
		var theVal := consume()
		return CSExpression.Literal.create(theVal.value, theVal.line)
	
	if(theType == CSLexer.TOKEN.WORD):
		var theVal := consume()
		
		#if(currType() == CSLexer.TOKEN.PAREN_LEFT):
			#consume()
			#
			#var args:Array[CSExpression]
			## Arguments
			#while(currType() != CSLexer.TOKEN.PAREN_RIGHT):
				#var anArg := parseExpression()
				#if(!anArg):
					#return null
				#args.append(anArg)
			#
			#if(currType() == CSLexer.TOKEN.PAREN_RIGHT):
				#consume()
				#
				#return CSExpression.CallDirect.create(theVal.value, args, theVal.line)
			#else:
				#pushError("Expected ')' after arguments of the function call", SKIP_UNTIL_NEW_LINE)
				#return null
		
		return CSExpression.Variable.create(theVal.value, theVal.line)
	
	if(theType == CSLexer.TOKEN.PAREN_LEFT):
		consume()
		var expr := parseExpression()
		if(!expr):
			return null
		if(currType() != CSLexer.TOKEN.PAREN_RIGHT):
			pushError("Expected ')' after expression", SKIP_UNTIL_NEW_LINE)
			return null
		consume()
		return CSExpression.Grouping.create(expr)
	
	pushError("Expected expression", SKIP_UNTIL_NEW_LINE)
	return null
