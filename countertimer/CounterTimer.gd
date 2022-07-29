extends Node

#// export(bool) var Checkbox_is_pressed : bool = false    - NOT IN USE YET
export var counter_type : String = "Countup"
export var time_value  = 10 #//In minutes

var time_value_
var _countertimer = preload("res://addons/countertimer/CounterTimer.tscn")
var countertimer

var counter_time
var time = 60 * time_value
var timer_om = false
var timer : Node

var base_seconds_count : int = 0
var base_milliseconds_count: int
var _milliseconds = 1000
var milliseconds = 0
var minutes : int
var seconds : int

func _ready():
	counter_type = correct_spelling(counter_type)
	countertimer = _countertimer.instance()
	add_child(countertimer)
	timer = countertimer.get_node("Timer")
	timer.connect("timeout", self, "_on_timer_timeout")
	timer.wait_time = 1
	set_time_vars()

func set_time_vars():
	if counter_type == "Countdown":
		time_value_ = time_value #* 60
		minutes = time_value_
		seconds = 60
	elif counter_type == "Countup":
		time_value_= time_value / 60
		minutes = 0
		seconds = 0
		
func _process(delta):
	if timer_om:
		if counter_type == "Countdown":
			counter_time = countdown()
		elif counter_type == "Countup":
			counter_time = countup()

func ms():

	base_milliseconds_count = OS.get_system_time_msecs() - OS.get_system_time_secs() * 1000
	if base_milliseconds_count < 1000:
		milliseconds += 1
	return base_milliseconds_count
	
func countdown():
	milliseconds = 1000 - ms()
	var _milliseconds = milliseconds
	var _seconds = seconds
	var _minutes = minutes
	return "%02d : %02d : %02d" % [_minutes, _seconds, _milliseconds]
	
func countup():
	milliseconds = ms()
	var _milliseconds = ms()
	var _seconds = seconds
	var _minutes = minutes
	return "%02d : %02d : %02d" % [_minutes, _seconds, _milliseconds]

func start():
	timer_om = true
	timer.start()
	
func reset():
	timer_om = false
	timer.stop()
	base_seconds_count = 0
	counter_time = 0
	base_milliseconds_count = 0
	_milliseconds = 0
	milliseconds = 0
	minutes = 0
	seconds = 0

	
func stop():
	timer_om = false
	timer.stop()
	
func _on_timer_timeout() -> void:
	base_seconds_count += 1
	if base_seconds_count == 60:
		base_seconds_count += 1

	if counter_type == "Countdown":
		seconds -= 1
		if seconds == 0:
			minutes -= 1
			seconds = 60
		if minutes == 0:
			stop()
		base_seconds_count = 0
		
	if counter_type == "Countup":
		seconds += 1
		if seconds == 60:
			minutes += 1
			seconds = 0
		if minutes == time_value:
			stop()
		base_seconds_count = 0

#// Checks the Counter_Type variable to make sure it is capitalized		
func correct_spelling(_val):
	var ct = _val.capitalize()
	return ct
