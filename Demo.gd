extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var car_already_entered = false
var car_already_exited = false

func _on_Car_car_entered():
	#	print("Car entered signal received by main scene")
	
	if car_already_entered == false:
		car_already_entered = true
		var arvrorigin = $Player
		var arvrcamera = $Player/ARVRCamera
		var seatcamera = $Car/PlayerCameraPosition
		var playerbodynode = $Player/PlayerBody
		playerbodynode.enabled = false
		enable_player_controls(false)
		remove_child(arvrorigin)
		$Car.add_child(arvrorigin)
		arvrorigin.global_transform = seatcamera.global_transform
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,false)
		car_already_exited = false
		


func _on_Car_car_exited():
	#	print("Car entered signal received by main scene") # Replace with function body.
	
	if car_already_exited == false:
		car_already_exited = true
		var arvrorigin = $Car/Player
		var arvrcamera = $Car/Player/ARVRCamera
		var playerbodynode = $Car/Player/PlayerBody
		var exit_car_camera = $Car/ExitPlayerCamera
		$Car.remove_child(arvrorigin)
		add_child(arvrorigin)
		arvrorigin.global_transform = exit_car_camera.global_transform
		playerbodynode.enabled = true
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,true)
		enable_player_controls(true)
		car_already_entered = false
		
	
func enable_player_controls(boolean_value):
	var functions = get_tree().get_nodes_in_group("movement_providers")
	for each_function in functions:
		each_function.enabled = boolean_value
