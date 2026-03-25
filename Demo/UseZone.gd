extends Area3D

@export_file var scriptToRun:String
@onready var press_e_label: Label3D = %PressELabel

var main
var isInRange:bool = false

func _ready() -> void:
	main = get_parent()
	press_e_label.visible = false

func _process(_delta: float) -> void:
	if(isInRange && Input.is_action_just_pressed("player_use")):
		main.runScript(scriptToRun)
	
	press_e_label.visible = (isInRange && !main.scriptRunner.isRunningScript())
	
func _on_body_entered(_body: Node3D) -> void:
	isInRange = true

func _on_body_exited(_body: Node3D) -> void:
	isInRange = false
