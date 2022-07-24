extends Spatial



signal keyboard_key_pressed(key_string)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_InteractableAreaButton_button_pressed(button):
	var button_text = button.get_node("KeyLabel3D").text # Replace with function body.
	emit_signal("keyboard_key_pressed", button_text)
