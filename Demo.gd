extends Spatial



export var MAX_LAPS = 10

var proper_start = false
var proper_direction = false
var lapCount = 0

func _ready():
	
	#handle haptics  - connect to each controller's pickup function and then connect it to haptic pulse function
	$Player/LeftHandController/Function_Pickup.connect("has_picked_up", self, "haptic_pulse_on_pickup")
	$Player/RightHandController/Function_Pickup.connect("has_picked_up", self, "haptic_pulse_on_pickup")
	
	SilentWolf.configure({
			  "api_key": "VIDPkHWCKq7aJsvYQ5FcN3K0Z677PtO4Tn9bJ2m3",
			  "game_id": "GodotXRMoCoDemo",
			  "game_version": "1.0.2",
			  "log_level": 0
			})

func haptic_pulse_on_pickup(what):
	#What is passed as a parameter by the has_picked_up signal and is the object pickable, in turn that has a _by_controller property that yield the picked up controller
	what.by_controller.set_rumble(0.2)
	yield(get_tree().create_timer(0.2), "timeout")
	what.by_controller.set_rumble(0.0)

func _on_StartingLine_area_entered(area):
	if proper_start == true and proper_direction == true:
		if area.collision_layer == 512:
		#used for distinguishing between cars at some point, not currently used
			var car_number = area.get_parent().car_number
			
			var ldboard_name = "main"
			var metadata = {
				"LAP ": $CounterTimer.counter_time
			}
			
			if lapCount >= 1:
				SilentWolf.Scores.persist_score(Global.playerName, $CounterTimer.seconds, ldboard_name, metadata)
			
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


func _on_VRVehicleManager_player_in_vehicle(player_node, vehicle_node):
	pass# Replace with function body.


func _on_VRVehicleManager_player_left_vehicle(player_node, vehicle_node):
	pass # Replace with function body.
