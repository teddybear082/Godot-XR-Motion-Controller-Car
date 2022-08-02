extends Node
##This is a helper node to assist in the management of players entering and exiting VR Vehicles.
##The script expects a few things.  
## (1) That the vehicle node will be placed either as a child of the node OR  that the vehicle node will be assigned to the group "VR_vehicles"
## (2) That the vehicle node will have signals called "VR_vehicle_entered" and "VR_vehicle_exited" which are emitted when the player completes an action in the vehicle to do so.
## (3) That the vehicle node will have nodes for "PlayerCameraPosition" and "ExitPlayerCamera" that are Spatial derivative nodes that are the positions the camera should be to control the vehicle and position of camera when exiting.
## (4) The developer chooses an ARVROrigin in the inspector or assigns one to the arvrorigin and arvrorigin name variables through code before any signals need to be called
## (5) The developer is using XR Tools.
 
#needs assignment of ARVROrigin node to capture player
export (NodePath) var arvrorigin_path = null

var arvrorigin = null
var arvrorigin_name = null


#Variables to keep track of when player enters or exits any vehicle
var vehicle_already_entered = false
var vehicle_already_exited = false

#List variable of tracked VR Vehicles
#var vehicle_children = []
#var vehicle_group = []

#Variable to keep track of player's original transform in order to properly reset after exiting vehicle
var original_transform_basis = null

#signals to alert other scene nodes when player in vehicle as necessary
signal player_in_vehicle(player_node, vehicle_node)
signal player_left_vehicle(player_node, vehicle_node)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_arvr_origin()
	connect_vehicle_child_signals()
	connect_vehicle_group_signals()

# Called every frame. 'delta' is the elapsed time since the previous frame.

#func _process(delta):
#	pass
func set_arvr_origin():
	arvrorigin = get_node_or_null(arvrorigin_path)
	if arvrorigin != null:
		original_transform_basis = arvrorigin.transform.basis
		arvrorigin_name = arvrorigin.get_name()

#function to enable or disable player movement controls to be used when entering or exiting a vehicle
func enable_player_controls(boolean_value):
	var functions = get_tree().get_nodes_in_group("movement_providers")
	for each_function in functions:
		each_function.enabled = boolean_value


#function to connect to vehicle entry and exit signals where vehicles are children of node
func connect_vehicle_child_signals():
	var vehicles = get_children()
	for vehicle in vehicles:
		vehicle.connect("VR_vehicle_entered", self, "_on_vehicle_entered")
		vehicle.connect("VR_vehicle_exited", self, "_on_vehicle_exited")

#function to connect to vehicle entry and exit signals where vehicles are in a group called "VR_vehicles"
func connect_vehicle_group_signals():
	if get_tree().has_group("VR_vehicles"):
		var vehicle_group = get_tree().get_nodes_in_group("VR_vehicles")
		for vehicle in vehicle_group:
			vehicle.connect("VR_vehicle_entered", self, "_on_vehicle_entered")
			vehicle.connect("VR_vehicle_exited", self, "_on_vehicle_exited")
			
			
#function to connect to particular vehicle node's signals, to be called by developer as necessary
func connect_single_vehicle_signals(vehicle_node):
	vehicle_node.connect("VR_vehicle_entered", self, "_on_vehicle_entered")
	vehicle_node.connect("VR_vehicle_exited", self, "_on_vehicle_exited")
	
	
#function to properly set player view on entering vehicle signal recieved from vehicle
func _on_vehicle_entered(vehicle_node):
	if vehicle_already_entered == false:
		vehicle_already_entered = true
		arvrorigin = get_tree().get_current_scene().get_node(arvrorigin_name)
		var seatcamera = vehicle_node.get_node("PlayerCameraPosition")
		var playerbodynode = arvrorigin.get_node("PlayerBody")
		playerbodynode.enabled = false
		enable_player_controls(false)
		arvrorigin.get_parent().remove_child(arvrorigin)
		vehicle_node.add_child(arvrorigin)
		arvrorigin.global_transform = seatcamera.global_transform
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,false)
		vehicle_already_exited = false
		emit_signal("player_in_vehicle", arvrorigin, vehicle_node)


func _on_vehicle_exited(vehicle_node):
	if vehicle_already_exited == false:
		vehicle_already_exited = true
		arvrorigin = vehicle_node.get_node(arvrorigin_name)
		var playerbodynode = arvrorigin.get_node("PlayerBody")
		var exit_vehicle_camera = vehicle_node.get_node("ExitPlayerCamera")
		vehicle_node.remove_child(arvrorigin)
		get_tree().get_current_scene().add_child(arvrorigin)
		arvrorigin.global_transform.origin = exit_vehicle_camera.global_transform.origin
		arvrorigin.transform.basis = original_transform_basis
		playerbodynode.enabled = true
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT,true)
		enable_player_controls(true)
		vehicle_already_entered = false
		emit_signal("player_left_vehicle", arvrorigin, vehicle_node)
