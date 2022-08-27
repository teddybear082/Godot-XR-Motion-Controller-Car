extends VehicleBody


############################################################
#Vehicle number for customization or tracking multiple cars
export var car_number = 7

# Steering

export var MAX_STEER_ANGLE = 30
export var SPEED_STEER_ANGLE = 10
export var MAX_STEER_SPEED = 120.0
export var MAX_STEER_INPUT = 90.0
export var STEER_SPEED = 1.0

onready var max_steer_angle_rad = deg2rad(MAX_STEER_ANGLE)
onready var speed_steer_angle_rad = deg2rad(SPEED_STEER_ANGLE)
onready var max_steer_input_rad = deg2rad(MAX_STEER_INPUT)
export (Curve) var steer_curve = null

var steer_target = 0.0
var steer_angle = 0.0

var player_is_seated = false
var last_gear = 0
signal VR_vehicle_entered(vehicle_node)
signal VR_vehicle_exited(vehicle_node)

var _gas_controller: ARVRController
var _brake_controller: ARVRController


# shift button state
var _gas_button: bool = false
var _brake_button: bool = false

## enum our buttons, should find a way to put this more central
enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15
}

## enum car gas and brake controllers
enum Gas_Controller {
	LEFT,		# Use left controller
	RIGHT,		# Use right controler
}

enum Brake_Controller {
	LEFT,		# Use left controller
	RIGHT,		# Use right controler
}

## Car gas and brake buttons assignment
export (Buttons) var gas_button_id = Buttons.VR_BUTTON_AX
export (Buttons) var brake_button_id = Buttons.VR_BUTTON_AX

## Car shfiting gears controllers assignment
export (Gas_Controller) var gas_controller: int = Gas_Controller.RIGHT
export (Brake_Controller) var brake_controller: int = Brake_Controller.LEFT
export (NodePath) var l_controller_path = null
export (NodePath) var r_controller_path = null
var _left_controller
var _right_controller

############################################################
# Speed and drive direction

export var MAX_ENGINE_FORCE = 200.0
export var MAX_BRAKE_FORCE = 5.0

export (Array) var gear_ratios = [ 4.3, 3.8, 2.7, 1.5, 1.2, 1.0 ] 
export (float) var reverse_ratio = -2.8
export (float) var final_drive_ratio = 3.38
export (float) var max_engine_rpm = 8000.0
export (Curve) var power_curve = null

var current_gear = 0 # -1 reverse, 0 = neutral, 1 - 6 = gear 1 to 6.
var clutch_position : float = 1.0 # 0.0 = clutch engaged
var current_speed_mps = 0.0
onready var last_pos = translation

var gear_shift_time = 0.3
var gear_timer = 0.0

func get_speed_kph():
	return current_speed_mps * 3600.0 / 1000.0

# calculate the RPM of our engine based on the current velocity of our car
func calculate_rpm() -> float:
	# if we are in neutral, no rpm
	if current_gear == 0:
		return 0.0
	
	var wheel_circumference : float = 2.0 * PI * $right_rear.wheel_radius
	var wheel_rotation_speed : float = 60.0 * current_speed_mps / wheel_circumference
	var drive_shaft_rotation_speed : float = wheel_rotation_speed * final_drive_ratio
	if current_gear == -1:
		# we are in reverse
		return drive_shaft_rotation_speed * -reverse_ratio
	elif current_gear <= gear_ratios.size():
		return drive_shaft_rotation_speed * gear_ratios[current_gear - 1]
	else:
		return 0.0

############################################################
# Input

func _ready():
	_left_controller = get_node(l_controller_path)
	_right_controller = get_node(r_controller_path)
	
		# Get the shifting controllers
	if gas_controller == Gas_Controller.LEFT:
		_gas_controller = _left_controller
	else:
		_gas_controller = _right_controller

	if brake_controller == Brake_Controller.LEFT:
		_brake_controller = _left_controller
	else:
		_brake_controller = _right_controller

	#Set Car Number Decal; set to "" if none is wanted
	$CarNumber.text = str(car_number)


func _process_gear_inputs(delta : float):
	if gear_timer > 0.0:
		gear_timer = max(0.0, gear_timer - delta)
		clutch_position = 0.0
#	else:
#		if get_shift_down() and current_gear > -1: #if shifting down and not in reverse already, do the following
#			current_gear = current_gear - 1
#			gear_timer = gear_shift_time
#			clutch_position = 0.0
#		elif get_shift_up() and current_gear < gear_ratios.size(): #if shifting up and not at max gear do the following
#			current_gear = current_gear + 1
#			gear_timer = gear_shift_time
#			clutch_position = 0.0
#		else: #if either not shifting or in reverse, do the following
#			clutch_position = 1.0
	#current_gear = get_gear()
	#if gear_timer > 0.0:
	#	gear_timer = max(0.0, gear_timer - delta)
	#	clutch_position = 0.0
	else:
		current_gear = get_gear()
		if last_gear != current_gear and current_gear < gear_ratios.size() and current_gear > -1:
			gear_timer = gear_shift_time
			clutch_position = 0.0
			last_gear = current_gear
		else:
			clutch_position = 1.0

func _process(delta : float):
	_process_gear_inputs(delta)
	
	var speed = get_speed_kph()
	var rpm = calculate_rpm()
	
	var info = 'Speed: %.0f, RPM: %.0f (gear: %d)'  % [ speed, rpm, current_gear ]
	
	$Info.text = info
	

func _physics_process(delta):
	# how fast are we going in meters per second?
	current_speed_mps = (translation - last_pos).length() / delta
	
	# get our joystick inputs
	var steer_val = get_steering_input()
	var throttle_val = get_throttle_input()
	var brake_val = get_brake_input()
	
	var rpm = calculate_rpm()
	var rpm_factor = clamp(rpm / max_engine_rpm, 0.0, 1.0)
	var power_factor = power_curve.interpolate_baked(rpm_factor)
	
	$EngineAudio.pitch_scale = clamp(rpm_factor, .6, 1.2)
	
	if current_gear == -1:
		engine_force = clutch_position * throttle_val * power_factor * reverse_ratio * final_drive_ratio * MAX_ENGINE_FORCE
	elif current_gear > 0 and current_gear <= gear_ratios.size():
		engine_force = clutch_position * throttle_val * power_factor * gear_ratios[current_gear - 1] * final_drive_ratio * MAX_ENGINE_FORCE
	else:
		engine_force = 0.0
	
	brake = brake_val * MAX_BRAKE_FORCE
	

	var max_steer_speed = MAX_STEER_SPEED * 1000.0 / 3600.0
	var steer_speed_factor = clamp(current_speed_mps / max_steer_speed, 0.0, 1.0)

	if (abs(steer_val) < 0.05):
		steer_val = 0.0
	elif steer_curve:
		if steer_val < 0.0:
			steer_val = -steer_curve.interpolate_baked(-steer_val)
		else:
			steer_val = steer_curve.interpolate_baked(steer_val)
	
	steer_angle = steer_val * lerp(max_steer_angle_rad, speed_steer_angle_rad, steer_speed_factor)
	steering = -steer_angle
	
	
	# remember where we are
	last_pos = translation

func get_gear():
	if player_is_seated == false:
		return 0
	if player_is_seated == true:
		#Get position of shifter
		var shifter_position = $CarShifter/SliderOrigin/InteractableSlider.slider_position
		#only move to reverse if shifting down is definitely deliberate (Require two steps back from neutral instead of just one)
		if shifter_position < .05:
			return -1
		#If shifter is either in neutral or slightly below, still treat as neutral
		elif shifter_position >= .05 and shifter_position  <= .1:
			return 0
		#Increase gears from 1-6 depending on position above .1
		elif shifter_position > .1:
			return (20*shifter_position) - 2
		
func get_steering_input():
	if player_is_seated == false:
		return 0
	if player_is_seated == true:
		if $CarSteeringWheel/HingeOrigin/InteractableHinge.hinge_position == 0:
			return 0
		else:
			return $CarSteeringWheel/HingeOrigin/InteractableHinge.hinge_position/360

func get_throttle_input():
	if player_is_seated == false:
		return 0
	if player_is_seated == true:
		if gas_button_id == Buttons.VR_TRIGGER:
			return _gas_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)
		
		elif _gas_controller.is_button_pressed(gas_button_id):
			return 1
			
		else:
			return 0
			
func get_brake_input():
	if player_is_seated == false:
		return 0
	if player_is_seated == true:
		if brake_button_id == Buttons.VR_TRIGGER:
			return _brake_controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)
		
		elif _brake_controller.is_button_pressed(brake_button_id):
			return 1
			
		else:
			return 0


func _on_CarEnterArea_body_entered(body):
	if body.is_in_group("right_hand") or body.is_in_group("left_hand"):
		player_is_seated = true
		$EngineAudio.play()
		$CarDoorAudio.play()
		emit_signal("VR_vehicle_entered", self)
		


func _on_CarExitArea_body_entered(body):
	if body.is_in_group("right_hand") or body.is_in_group("left_hand"):
		player_is_seated = false
		$EngineAudio.stop()
		$CarDoorAudio.play()
		emit_signal("VR_vehicle_exited", self)
		 

func _on_EnemyKillZone_body_entered(body):
	pass
#		if body.is_in_group("enemies"):
#			body.enemy_alive = false
#			body.queue_free()
