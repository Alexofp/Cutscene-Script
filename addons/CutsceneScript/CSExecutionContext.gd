extends RefCounted
class_name CSExecutionContext

var interpreter:CSInterpreter

func pause():
	interpreter.pause()

func resume():
	interpreter.unpause()

func hasLabel(_label:String) -> bool:
	return interpreter.scriptToExecute.labels.has(_label)

func gotoLabel(_label:String) -> bool:
	return interpreter.gotoLabel(_label)

func pushError(_text:String):
	interpreter.pushError(interpreter.scriptToExecute.statements[interpreter.curStatementIndx], _text)

func stopScript():
	interpreter.stopScript()
