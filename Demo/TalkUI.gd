extends Control

@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var button_container: VBoxContainer = %ButtonContainer
@onready var name_label: Label = %NameLabel

var buttons:Array[Button]

signal onButtonPressed(_label:String)
signal onTextAdvance

func hideUI():
	visible = false

func startText(_text:String, _name:String = ""):
	rich_text_label.text = _text
	name_label.text = _name
	name_label.visible = !_name.is_empty()
	visible = true
	clearButtons()

func addButton(_text:String, _label:String):
	var newButton := Button.new()
	newButton.text = _text
	newButton.pressed.connect(onButtonPressedCallback.bind(_label))
	button_container.add_child(newButton)
	buttons.append(newButton)

func addDisabledButton(_text:String):
	var newButton := Button.new()
	newButton.text = _text
	newButton.disabled = true
	button_container.add_child(newButton)
	buttons.append(newButton)

func onButtonPressedCallback(_label:String):
	onButtonPressed.emit(_label)

func clearButtons():
	for button in buttons:
		button.queue_free()
	buttons.clear()

func _on_gui_input(event: InputEvent) -> void:
	if(event is InputEventMouseButton):
		if(event.pressed):
			onTextAdvance.emit()
