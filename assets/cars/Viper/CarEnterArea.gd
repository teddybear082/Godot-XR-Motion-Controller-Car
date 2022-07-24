extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#signal entered_car

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


#func _on_CarEnterArea_body_entered(body):
#	if body.is_in_group("right_hand") or body.is_in_group("left_hand"):
#		var controller = body._find_physics_hand().get_parent()
#		var arvrorigin = controller.get_parent()
#		get_tree().current_scene.remove_child(arvrorigin)
#		get_parent().add_child(arvrorigin)
#		arvrorigin.global_transform.origin = get_parent().get_node("interior").global_transform.origin
#		ARVRServer.center_on_hmd(ARVRServer.RESET_FULL_ROTATION, false)
#		emit_signal("entered_car")
