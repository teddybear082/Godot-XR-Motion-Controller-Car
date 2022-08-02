extends Spatial



export var MAX_LAPS = 10

var proper_start = false
var proper_direction = false
var lapCount = 0

#func _ready():
#	pass


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
