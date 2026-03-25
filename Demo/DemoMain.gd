extends Node3D

var variables:Dictionary[String, Variant]

const STATE_NOTHING := 0
const STATE_WAITING_TEXT := 1
const STATE_WAITING_CHOICE := 2
var currentState:int = STATE_NOTHING

@onready var talk_ui: Control = %TalkUI
@onready var player: CharacterBody3D = %Player
@onready var money_label: Label = %MoneyLabel

var scriptRunner := CSRunner.new()

func doStatement(_target:String, _statement:String, _args:Array[Variant], _context:CSExecutionContext) -> bool:
	if(_target.is_empty()):
		# say "rahi", "Meow-meow-meow!"
		# say "Something happened!"
		if(_statement == "say"):
			if(_args.size() > 1):
				talk_ui.startText(_args[1], _args[0])
			else:
				talk_ui.startText(_args[0])
			currentState = STATE_WAITING_TEXT
			_context.pause()
			return true
		
		# ask "How are you?"
		# answer "I'm fine", label1
		# answer "Very tired", label2
		# disabledAnswer "Can't pick this!"
		# waitAnswer
		if(_statement == "ask"):
			if(_args.size() > 1):
				talk_ui.startText(_args[1], _args[0])
			else:
				talk_ui.startText(_args[0])
			return true
		if(_statement == "answer"):
			talk_ui.addButton(_args[0], _args[1])
			return true
		if(_statement == "disabledAnswer"):
			talk_ui.addDisabledButton(_args[0])
			return true
		if(_statement == "waitAnswer"):
			currentState = STATE_WAITING_CHOICE
			_context.pause()
			return true
		
		# >label
		# jump label
		if(_statement == "jump"):
			if(!_context.hasLabel(_args[0])):
				_context.pushError("Label with name '"+str(_args[0])+"' is not found.")
				return true
			_context.gotoLabel(_args[0])
			return true
		# print "meow"
		if(_statement == "print"):
			print(CSUtil.joinAsStrings(_args))
			return true
		# sleep 5.5
		if(_statement == "sleep"):
			_context.pause()
			var theTimer := get_tree().create_timer(_args[0]) # Sleep for _args[0] seconds
			theTimer.timeout.connect(func(): _context.resume()) # Resume the execution
			return true
		
		if(_statement == "stopScript"):
			_context.stopScript()
			return true
		if(_statement == "killRahi"):
			$UseZone3.queue_free()
			return true
	# set.someVar 5
	# set.someVar 123+get.someVar
	# print get.someVar
	if(_target == "set"):
		variables[_statement] = _args[0]
		return true
	if(_target == "inc"):
		variables[_statement] += _args[0]
		return true
	return false

func getExpressionValue(_target:String, _statement:String, _args:Array[Variant], _context:CSExecutionContext) -> Variant:
	if(_target == "RNG"):
		if(_statement == "chance"):
			return _args[0] >= (randf() * 100.0)
	if(_target == "get"):
		return variables.get(_statement, null)
	if(_target.is_empty()):
		if(_statement == "str"):
			return str(_args[0])
		# Each label is also a string variable that returns itself
		if(_context.hasLabel(_statement)):
			return _statement
	return null

func _ready() -> void:
	variables["money"] = 0
	variables["moneyATM"] = 100
	#scriptRunner.runScript(CSUtil.readFile("res://Demo/Scripts/ETest.txt"), self)
	pass

func _process(_delta: float) -> void:
	money_label.text = "Money: "+str(variables["money"])+"$"

func _on_talk_ui_on_button_pressed(_label:String) -> void:
	if(currentState == STATE_WAITING_CHOICE):
		currentState = STATE_NOTHING
		talk_ui.hideUI()
		scriptRunner.interpreter.gotoLabel(_label)
		scriptRunner.interpreter.unpause()

func _on_talk_ui_on_text_advance() -> void:
	if(currentState == STATE_WAITING_TEXT):
		currentState = STATE_NOTHING
		talk_ui.hideUI()
		scriptRunner.interpreter.unpause()

func runScript(_path:String):
	scriptRunner.runScript(CSUtil.readFile(_path), self)
