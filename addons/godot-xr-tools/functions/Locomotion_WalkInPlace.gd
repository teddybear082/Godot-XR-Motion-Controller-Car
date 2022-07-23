# this implementation of step detection is based on the Paper:
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6165345/pdf/sensors-18-02832.pdf
# @article{author = {Lee, Juyoung and Ahn, Sang and Hwang, Jae-In},
#          year = {2018},
#          month = {08},
#          title = {A Walking-in-Place Method for Virtual Reality Using Position and Orientation Tracking},
#          journal = {Sensors}}
#
# See also the python jupyter notebook in the godot_oculus_quest_toolkit repository
# for the data analysis that was used to define the constants below
# This is a port of NeoSparks' excellent work on this prototype for OQ-Toolkit for Godot to the OpenXR-Tools package
# found here: https://github.com/NeoSpark314/godot_oculus_quest_toolkit/tree/master/OQ_Toolkit/OQ_ARVROrigin
# I just changed the terminology to work with XR Tools, found here: 

class_name Locomotion_WalkInPlace
extends MovementProvider




## Movement provider order
export var order := 5



const _height_ringbuffer_size := 15; # full ring buffer is 15; lower latency can be achieved by accessing only a subset
var _height_ringbuffer_pos := 0;
var _height_ringbuffer := Array()

const _num_steps_for_step_estimate := 5;
const _num_steps_for_height_estimate := 15; 


const _step_local_detect_threshold := 0.04; # local difference, original value .04
const _step_height_min_detect_threshold := 0.008; # This might need some tweaking now to avoid missed steps, original value .01
const _step_height_max_detect_threshold := 0.1; # This might need some tweaking now to avoid missed steps, original value .1

const _step_up_min_detect_threshold := 0.012; # This might need some tweaking now to avoid missed steps, original value .012
const _step_up_max_detect_threshold := 0.1; # This might need some tweaking now to avoid missed steps, original value .1

const _variance_height_detect_threshold = 0.001;

var _had_high_step_after_low := false;

var _last_step_time_s := 0.0; # time elapsed after the last step was detected
const _fastest_step_s := 10.0/72.0; # faster then this will not detect a new step
const _slowest_step_s := 25.0/72.0; # slower than this will not detect a high point step

var _current_height_estimate := 0.0;

var step_low_just_detected := false;
var step_high_just_detected := false;

var _last_step_min := 0.0;
var _last_step_max := 0.0;

# external object that can be set to check if walkinplace can actually move
var move_checker = null;

##New TB code, create global variables for ARVROrigin, Camera and Controllers in case needed in code.  At some point should make these export node variables instead for more modularity.
export (NodePath) var fpcontroller_path = null
export (NodePath) var arvrcamera_path = null
export (NodePath) var l_controller_path = null
export (NodePath) var r_controller_path = null


signal step_low;
signal step_high;

var fp_controller = null
var vr_camera = null
var l_controller = null
var r_controller = null
var player_body = null

func _ready():
	fp_controller = get_node(fpcontroller_path)
	vr_camera = get_node(arvrcamera_path)
	l_controller = get_node(l_controller_path)
	r_controller = get_node(r_controller_path)
	player_body = fp_controller.get_node("PlayerBody")
	
	_height_ringbuffer.resize(_height_ringbuffer_size);
	_current_height_estimate = player_body.camera_node.transform.origin.y + player_body.player_radius
	#TB Code: if the above equation doesn't work, note this used to be a reference to 
	#func get_current_player_height():
	#return vrCamera.global_transform.origin.y - vrOrigin.global_transform.origin.y;
	#so could try headset_height = player_body.camera_node.global_transform.origin.y - fp_controller.global_transform.origin.y;
	
	for i in range(0, _height_ringbuffer_size):
		_height_ringbuffer[i] = _current_height_estimate;



func _store_height_in_buffer(y):
	_height_ringbuffer[_height_ringbuffer_pos] = y;
	_height_ringbuffer_pos = (_height_ringbuffer_pos + 1) % _height_ringbuffer_size;
 
func _get_buffered_height(i):
	return _height_ringbuffer[(_height_ringbuffer_pos - i + _height_ringbuffer_size) % _height_ringbuffer_size];

# theses constansts were manually tweaked inside the jupyter notebook
# they reflect the correction needed for the quest on my head; more test data would be needed
# how well they fit to other peoples necks and movement
const Cup = -0.06;    
const Cdown = -0.177;

# this is required to adjust for the different headset height based on if the user is looking up, down or straight
func _get_viewdir_corrected_height(h, viewdir_y):
	if (viewdir_y >= 0.0):
		return h + Cup * viewdir_y;
	else:
		return h + Cdown * viewdir_y;


enum {
	NO_STEP,
	STEP_LOW,
	STEP_HIGH,
}


var _time_since_last_step = 0.0;

func _detect_step(dt):
	var min_value = _get_buffered_height(0);
	var max_value = min_value;
	var average = min_value;
	
	_time_since_last_step += dt;


	# find min and max for step detection
	var min_val_pos = 0;
	var max_val_pos = 0;
	for i in range(1, _num_steps_for_step_estimate):
		var val = _get_buffered_height(i);
		if (val < min_value):
			min_value = val;
			min_val_pos = i;
		if (val > max_value):
			max_value = val;
			max_val_pos = i;

	# compute average and variance for current height estimation
	for i in range(1, _num_steps_for_height_estimate):
		var val = _get_buffered_height(i);
		average += val;
	average = average / _num_steps_for_height_estimate;
	var variance = 0.0;
	for i in range(0, _num_steps_for_height_estimate):
		var val = _get_buffered_height(i);
		variance = variance + abs(average - val);
	variance = variance / _num_steps_for_height_estimate;
	
	# if there is not much variation in the last _height_ringbuffer_size values we take the average as our current heigh
	# assuming that we are not in a step process then
	if (variance <= _variance_height_detect_threshold):
		_current_height_estimate = average;
		
	
	var dist_max = max_value - _current_height_estimate;
	
	if (max_val_pos == _num_steps_for_step_estimate / 2 
		and dist_max > _step_up_min_detect_threshold
		and dist_max < _step_up_max_detect_threshold
		and _time_since_last_step <= _slowest_step_s
		and _had_high_step_after_low
		#and (_get_buffered_height(0) - min_value) > _step_local_detect_threshold # this can avoid some local mis predicitons
		): 
		_last_step_max = max_value;
		_had_high_step_after_low = false;
		_current_height_estimate = (_current_height_estimate + (_last_step_max + _last_step_min) * 0.5) * 0.5;
		return STEP_HIGH;
	
	# this is now the actual step detection based on that the center value of the ring buffer is the actual minimum (the turning point)
	# and also the defined thresholds to minimize false detections as much as possible
	var dist_min = _current_height_estimate - min_value;
	if (min_val_pos == _num_steps_for_step_estimate / 2 
		and dist_min > _step_height_min_detect_threshold
		and dist_min < _step_height_max_detect_threshold
		and _time_since_last_step >= _fastest_step_s
		and (_get_buffered_height(0) - min_value) > _step_local_detect_threshold # this can avoid some local mis predicitons
		): 
		_time_since_last_step = 0.0;
		_last_step_min = min_value;
		_had_high_step_after_low = true
		return STEP_LOW;

	return NO_STEP;


const step_duration := 20.0 / 72.0; # I had ~ 30 frames between steps...
var _step_time := 0.0;

var speed_walking := 10.0 / 3.6; # km/h TB note: was 5.0 / 3.6, felt too slow
var speed_jogging := 15.0 / 3.6; # km/h TB note: was 10.0 / 3.6, felt too slow

var num_steps_till_jogging := 2;

var _continous_step_count := 0;
const _time_until_continous_step_reset = 1.0; #was 2.0

# indicator to check if currently in a moving state (means steps detected)
# not actually moving; this depends still on the move_cheker
var is_moving = false;


func is_jogging() -> bool:
	return _continous_step_count > num_steps_till_jogging;

func _move(dt):
	var view_dir = -vr_camera.global_transform.basis.z;
	view_dir.y = 0.0;
	view_dir = view_dir.normalized();
	
	var speed = speed_walking;
	
	if (is_jogging()):
		 speed = speed_jogging;
	
	
	var actual_translation = view_dir * speed * dt;
	if (move_checker):
		actual_translation = move_checker.oq_walk_in_place_check_move(actual_translation, speed);
	
	fp_controller.translation += actual_translation;
#TB note: could try instead of the line above: 
	#player_body.ground_control_velocity += actual_translation
#TB note: or could try 
	#player_body.ground_control_velocity.y += speed * dt {note: this threw an error for mixing vectors and floats}
	#player_body.velocity += actual_translation * 10 {note: this seemed too slow without a modifier}
	
#TB note: I don't understand why we're not moving the player body instead of the origin translation...but the above code seems to work so leaving it for someone smarter to figure out.

# NOTE: this needs to be in the _process as all the values are tied to the actual display framerate of 72hz
#       at the moment

#Add'l TB note - maybe this should be physics_process??
func _process(dt):
	if (!enabled): return;
		
	var headset_height = player_body.camera_node.transform.origin.y + player_body.player_radius;
	#TB Code: if the above equation doesn't work, note this used to be a reference to 
	#func get_current_player_height():
	#return vrCamera.global_transform.origin.y - vrOrigin.global_transform.origin.y;
	#so could try headset_height = player_body.camera_node.global_transform.origin.y - fp_controller.global_transform.origin.y;
	
	var corrected_height = _get_viewdir_corrected_height(headset_height, -vr_camera.transform.basis.z.y);
	_store_height_in_buffer(corrected_height);
	
	var step = _detect_step(dt);
	step_low_just_detected = false;
	step_high_just_detected = false;
	
	if (step == STEP_LOW):
		_step_time = step_duration;
		step_low_just_detected = true;
		_continous_step_count += 1;
		emit_signal("step_low");
	elif (step == STEP_HIGH):
		_step_time = step_duration;
		step_high_just_detected = true;
		emit_signal("step_high");
	else:
		_step_time -= dt;
		
		

	if (_step_time > 0.0):
		is_moving = true;
		_move(dt);
	else:
		is_moving = false;
		#if (_step_time < -_time_until_continous_step_reset):
		_continous_step_count = 0;
	
	#Debug code	
#	if (is_moving):
#		if (is_jogging()):
#			print("WalkInPlace", "Jogging: %.3f" % _step_time);
#		else:
#			print("WalkInPlace", "Walking: %.3f" % _step_time);
#	else:
#			print("WalkInPlace", "Standing: %.3f" % _step_time);
			
func _get_configuration_warning():
	# Check the ARVROrigin node
	var test_origin = get_parent()
	if !test_origin or !test_origin is ARVROrigin:
		return "Unable to find ARVR Origin node - Must place as child of ARVROrigin/FPController"

	# Call base class
	return ._get_configuration_warning()



