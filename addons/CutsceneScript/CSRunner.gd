extends RefCounted
class_name CSRunner

var lexer := CSLexer.new()
var parser := CSParser.new()
var interpreter := CSInterpreter.new()

var target:Variant

func runScript(_text:String, _target:Variant):
	var result := ExpressionResult.new()

	var theLexerResult := lexer.parse(_text)
	if(theLexerResult.hadErrors):
		result.hadErrors = true
		return result
	
	var theScript := parser.parseStandaloneScript(theLexerResult)
	if(!theScript):
		result.hadErrors = true
		return result

	interpreter.prepare(_target)
	interpreter.execute(theScript)
	interpreter.executeStatements()

func isRunningScript() -> bool:
	if(interpreter.scriptToExecute):
		return true
	return false

class ExpressionResult:
	var value:Variant
	var hadErrors:bool = false
	var errors:Array[String]

func runExpression(_str:String) -> ExpressionResult:
	var result := ExpressionResult.new()

	var theLexerResult := lexer.parse(_str)
	if(theLexerResult.hadErrors):
		result.hadErrors = true
		return result
	
	var theExpression := parser.parseStandaloneExpression(theLexerResult)
	if(!theExpression):
		result.hadErrors = true
		return result
	
	interpreter.prepare()
	result.value = interpreter.execute(theExpression)
	result.hadErrors = interpreter.hadErrorsAtAll()
	if(result.hadErrors):
		result.errors = interpreter.errors.duplicate()
	return result
