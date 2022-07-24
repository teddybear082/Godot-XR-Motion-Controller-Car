extends Spatial
##This is an attempt at creating a physical keyboard
##for use when "faux physics hands" or perhaps someday real physics hands, are used in a game
##The understanding for how this might be possible came from MalcolmNixon's VirtualKeyboard
##included in XR-Tools.  That keyboard uses a Viewport2Dto3D node and hand pointers to work.
##This physical keyboard uses the new Label3D functionality in Godot 3.5+ to obviate the need for
##viewports, and uses the FollowBone3D approach to faux physics hands to physically click the buttons.
##The basis for the buttons is MalcolmNixon's push buttons in the experiemental XR-tools-interactables repository.
##By default, the keys have a layer of 19.  The idea is that the physics hands fingers would have a mask of 18 and 19.
##While the physics hands palms would just have a mask of 18.
#Mask 18 would be thus be used for all non-keyboard items the player wants to interact with by poking them.
#This allows both palms and fingers to be used for those items.
#Mask 19 would be used for JUST the keyboard.  This prevents the physics palms from interfering while typing.


## Variable to determine if keyboard will make sounds or not
export var keys_make_clicking_sound := true
var keyboard_keys = null
var keyboard_mode = "regular"
var changed_state = false
var key_scene = null
var key_instance = null
var qwerty_and_numeric_key_nodes = []

# Called when the node enters the scene tree for the first time.
func _ready():
	key_scene = load("res://addons/godot-xr-tools/objects/PhysicalKeyboard3-5/Key.tscn")
	generate_keys()
	keyboard_keys = get_tree().get_nodes_in_group("Keys")  
	for key in keyboard_keys:  
		key.connect("keyboard_key_pressed", self, "on_keyboard_key_pressed") # Replace with function body.

func on_keyboard_key_pressed(key_text):
	#Generate clicking sound if enabled
	if keys_make_clicking_sound == true:
		$KeySounds.play()
	
	#assign easy keys their values
	var scan_code := OS.find_scancode_from_string(key_text)
	var unicode = null
	
	#Deal with abnormal keys
	if key_text == "BKSP":
		scan_code = OS.find_scancode_from_string("BackSpace")
		
	if key_text == "<":
		scan_code = OS.find_scancode_from_string("Less")
		unicode = 60
		
	if key_text == ">":
		scan_code = OS.find_scancode_from_string("Greater")
		unicode = 62
		
	if key_text == ",":
		scan_code = OS.find_scancode_from_string("Comma")
		unicode = 44
		
	if key_text == ".":
		scan_code = OS.find_scancode_from_string("Period")
		unicode = 46
		
	if key_text == "!":
		scan_code = OS.find_scancode_from_string("Exclam")
		unicode = 33
		
	if key_text == "@":
		scan_code = OS.find_scancode_from_string("At")
		unicode = 64
		
	if key_text == "#":
		scan_code = OS.find_scancode_from_string("NumberSign")
		unicode = 35
	
	if key_text == "$":
		scan_code = OS.find_scancode_from_string("Dollar")
		unicode = 36
		
	if key_text == "%":
		scan_code = OS.find_scancode_from_string("Percent")
		unicode = 37
		
	if key_text == "^":
		scan_code = OS.find_scancode_from_string("AsciiCircum")
		unicode = 94
	
	if key_text == "&":
		scan_code = OS.find_scancode_from_string("Ampersand")
		unicode = 38
	
	if key_text == "*":
		scan_code = OS.find_scancode_from_string("Asterisk")
		unicode = 42
	
	if key_text == "(":
		scan_code = OS.find_scancode_from_string("ParenLeft")
		unicode = 40
	
	if key_text == ")":
		scan_code = OS.find_scancode_from_string("ParenRight")
		unicode = 41
	
	if key_text == "?":
		scan_code = OS.find_scancode_from_string("Question")
		unicode = 63
	
	#lower case letters won't show with scan codes which appear to be case insensitive, so have to assign separate unicodes to them
	if key_text == "a":
		unicode = 97
	
	if key_text == "b":
		unicode = 98
		
	if key_text == "c":
		unicode = 99
		
	if key_text == "d":
		unicode = 100
		
	if key_text == "e":
		unicode = 101
		
	if key_text == "f":
		unicode = 102
		
	if key_text == "g":
		unicode = 103
		
	if key_text == "h":
		unicode = 104
		
	if key_text == "i":
		unicode = 105
		
	if key_text == "j":
		unicode = 106
		
	if key_text == "k":
		unicode = 107
		
	if key_text == "l":
		unicode = 108
		
	if key_text == "m":
		unicode = 109
		
	if key_text == "n":
		unicode = 110
	
	if key_text == "o":
		unicode = 111
		
	if key_text == "p":
		unicode = 112
		
	if key_text == "q":
		unicode = 113
		
	if key_text == "r":
		unicode = 114
		
	if key_text == "s":
		unicode = 115
		
	if key_text == "t":
		unicode = 116
		
	if key_text == "u":
		unicode = 117
		
	if key_text == "v":
		unicode = 118
		
	if key_text == "w":
		unicode = 119
		
	if key_text == "x":
		unicode = 120
		
	if key_text == "y":
		unicode = 121
		
	if key_text == "z":
		unicode = 122
	
	
	#if Next key pressed, change keyboard keys to alternative mode
	if key_text == "Next":
		if keyboard_mode == "regular":
			keyboard_mode = "alternate"
			for each_node in qwerty_and_numeric_key_nodes:
				each_node.queue_free()
			qwerty_and_numeric_key_nodes =[]
			generate_keys()
			keyboard_keys = get_tree().get_nodes_in_group("Keys")  
			for key in keyboard_keys:  
				key.connect("keyboard_key_pressed", self, "on_keyboard_key_pressed")
			return
		else:
			keyboard_mode = "regular"
			for each_node in qwerty_and_numeric_key_nodes:
				each_node.queue_free()
			qwerty_and_numeric_key_nodes = []
			generate_keys()
			keyboard_keys = get_tree().get_nodes_in_group("Keys")  
			for key in keyboard_keys:  
				key.connect("keyboard_key_pressed", self, "on_keyboard_key_pressed")
			return
		
	# Create the InputEventKey
	var input := InputEventKey.new()
	input.physical_scancode = scan_code
	input.unicode = unicode if unicode else scan_code
	input.pressed = true
	input.scancode = scan_code
	

	# Dispatch the input event
	Input.parse_input_event(input)

func generate_keys():
	create_qwerty_keys()
	create_numeric_keys()
	
	

func create_qwerty_keys():
	var first_row = []
	var second_row = []
	var third_row = []
	var qwertynode = $PickableKeyboard/QwertyKeys
	var first_row_transform = qwertynode.global_transform
	var second_row_transform = first_row_transform.translated(Vector3(.030,0,.07))
	var third_row_transform = first_row_transform.translated(Vector3(.060,0,.14))
	
	if keyboard_mode == "regular":
		first_row = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
		second_row = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
		third_row = ["Z", "X", "C", "V", "B", "N", "M", ",","."]
		
	
	if keyboard_mode == "alternate":
		first_row = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
		second_row = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
		third_row = ["z", "x", "c", "v", "b", "n", "m","<", ">"]

	create_keys(first_row, first_row_transform, qwertynode)
	create_keys(second_row, second_row_transform, qwertynode)
	create_keys(third_row, third_row_transform, qwertynode)
	
	
func create_numeric_keys():
	var numeric_row = []
	var numeric_node = $PickableKeyboard/NumericKeys
	var numeric_row_transform = numeric_node.global_transform
	if keyboard_mode == "regular":
		numeric_row = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	if keyboard_mode == "alternate":
		numeric_row = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "?"]
	create_keys(numeric_row, numeric_row_transform, numeric_node)


func create_keys(list_of_keys, row_transform, parent_node):
	var last_key_transform = null
	var num_of_keys = list_of_keys.size()
	for each_key in num_of_keys:
		key_instance = key_scene.instance()
		parent_node.add_child(key_instance)
		if each_key == 0:
			key_instance.global_transform = row_transform
		else:
			key_instance.global_transform = last_key_transform.translated(Vector3(.065,0,0))
		key_instance.get_node("Button/KeyLabel3D").text = list_of_keys[each_key]
		last_key_transform = key_instance.global_transform
		qwerty_and_numeric_key_nodes.append(key_instance)




# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#Sample unicode values - difference of 32 between upper and lower
#Upper Q = 81
#Lower Q = 113
#Upper A = 65
#Lower A = 97
#Upper M = 77
#LowerM =  109
