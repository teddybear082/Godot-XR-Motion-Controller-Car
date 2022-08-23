extends Control



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Submit_pressed():
	if $Panel/TextEdit.text != null:
		Global.playerName = $Panel/TextEdit.text
		$Panel/Label.text = Global.playerName + " signed in."
		$Panel/Submit.visible = false
			
