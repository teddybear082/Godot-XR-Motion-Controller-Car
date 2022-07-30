extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var MAX_LAPS = 10
var original_transform_basis = null
var proper_start = false
var proper_direction = false
# Called when the node enters the scene tree for the first time.
func _ready():
	#keep track of player's orientation at start to avoid problems when exiting car
	original_transform_basis = $Player.transform.basis

var lapCount = 0
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
		arvrorigin.global_transform.origin = exit_car_camera.global_transform.origin
		arvrorigin.transform.basis = original_transform_basis
		playerbodynode.enabled = true
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,true)
		enable_player_controls(true)
		car_already_entered = false
		
	
func enable_player_controls(boolean_value):
	var functions = get_tree().get_nodes_in_group("movement_providers")
	for each_function in functions:
		each_function.enabled = boolean_value

##Use Viper's enhanced signals to demonstrate how passing the car node in the signal could allow various playable cars
##in one scene
func _on_Viper_car_entered(car_node):
		if car_already_entered == false:
			car_already_entered = true
			var arvrorigin = $Player
			var arvrcamera = $Player/ARVRCamera
			var seatcamera = car_node.get_node("PlayerCameraPosition")
			var playerbodynode = $Player/PlayerBody
			playerbodynode.enabled = false
			enable_player_controls(false)
			remove_child(arvrorigin)
			car_node.add_child(arvrorigin)
			arvrorigin.global_transform = seatcamera.global_transform
			ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,false)
			car_already_exited = false
		 # Replace with function body.


func _on_Viper_car_exited(car_node):
		
	if car_already_exited == false:
		car_already_exited = true
		var arvrorigin = car_node.get_node("Player")
		var arvrcamera = car_node.get_node("Player/ARVRCamera")
		var playerbodynode = car_node.get_node("Player/PlayerBody")
		var exit_car_camera = car_node.get_node("ExitPlayerCamera")
		car_node.remove_child(arvrorigin)
		add_child(arvrorigin)
		arvrorigin.global_transform.origin = exit_car_camera.global_transform.origin
		arvrorigin.transform.basis = original_transform_basis
		playerbodynode.enabled = true
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,true)
		enable_player_controls(true)
		car_already_entered = false
		 # Replace with function body.


func _on_vehicle_GodotBike_bike_entered(bike_node):
	if car_already_entered == false:
		car_already_entered = true
		var arvrorigin = get_node("Player")
		var seatcamera = bike_node.get_node("PlayerCameraPosition")
		var playerbodynode = arvrorigin.get_node("PlayerBody")
		playerbodynode.enabled = false
		enable_player_controls(false)
		remove_child(arvrorigin)
		bike_node.add_child(arvrorigin)
		arvrorigin.global_transform = seatcamera.global_transform
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,false)
		car_already_exited = false


func _on_vehicle_GodotBike_bike_exited(bike_node):
	if car_already_exited == false:
		car_already_exited = true
		var arvrorigin = bike_node.get_node("Player")
		var playerbodynode = bike_node.get_node("Player/PlayerBody")
		var exit_bike_camera = bike_node.get_node("ExitPlayerCamera")
		bike_node.remove_child(arvrorigin)
		add_child(arvrorigin)
		arvrorigin.global_transform.origin = exit_bike_camera.global_transform.origin
		arvrorigin.transform.basis = original_transform_basis
		playerbodynode.enabled = true
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,true)
		enable_player_controls(true)
		car_already_entered = false

func _on_StartingLine_area_entered(area):
	if proper_start == true and proper_direction == true:
		if area.collision_layer == 512:
		#used for distinguishing between cars at some point, not currently used
			var car_number = area.get_parent().car_number
			
			$LapChime.play()
			$CounterTimer.reset()
			$CounterTimer.start()
			lapCount += 1
			if lapCount > MAX_LAPS:
				lapCount = 1
			proper_direction = false
			
func _update_lap_scores():
	if lapCount == 1:
		$Track_v2/Cylinder001/LapLabel1.text = str($CounterTimer.counter_time)
	if lapCount == 2:
		$Track_v2/Cylinder001/LapLabel2.text = str($CounterTimer.counter_time)
	if lapCount == 3:
		$Track_v2/Cylinder001/LapLabel3.text = str($CounterTimer.counter_time)
	if lapCount == 4:
		$Track_v2/Cylinder001/LapLabel4.text = str($CounterTimer.counter_time)
	if lapCount == 5:
		$Track_v2/Cylinder001/LapLabel5.text = str($CounterTimer.counter_time)
	if lapCount == 6:
		$Track_v2/Cylinder001/LapLabel6.text = str($CounterTimer.counter_time)
	if lapCount == 7:
		$Track_v2/Cylinder001/LapLabel7.text = str($CounterTimer.counter_time)
	if lapCount == 8:
		$Track_v2/Cylinder001/LapLabel8.text = str($CounterTimer.counter_time)
	if lapCount == 9:
		$Track_v2/Cylinder001/LapLabel9.text = str($CounterTimer.counter_time)
	if lapCount == 10:
		$Track_v2/Cylinder001/LapLabel10.text = str($CounterTimer.counter_time)	
	
func _process(delta):
	_update_lap_scores()


func _on_StartingBlock_area_exited(area):
	if area.collision_layer == 512:
		proper_start = true
		proper_direction = true # Replace with function body.
		if $StartingBlock/StartingBlockMesh.visible == true:
			$StartingBlock/StartingBlockMesh.visible = false
		if $StartingBlock/StartingLabel3D.visible == true:
			$StartingBlock/StartingLabel3D.visible = false
