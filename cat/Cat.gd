extends KinematicBody2D


var resource_path

remote var player_manager:Node = null

var move_speed = 10

var last_position_stamp = 0
var position_buffer:Array = []
var interpolation_offset = 100

func _ready():
	if not get_tree().is_network_server():
		$SyncPositionTimer.stop()
		$SyncPositionTimer.autostart = false

func _physics_process(delta):
	if get_tree().is_network_server():
		return
	_process_client(delta)


func _process_client(delta):
	var render_time = OS.get_system_time_msecs() - interpolation_offset
	if position_buffer.size() > 1:
		while position_buffer.size() > 2 and render_time > position_buffer[2][1]:
			position_buffer.pop_front()
		if position_buffer.size() > 2:
			var i_divider = float(position_buffer[2][1] - position_buffer[1][1])
			if i_divider == 0:
				i_divider = 1
			var interpolation_factor = float(render_time - position_buffer[1][1]) / i_divider
			interpolation_factor = clamp(interpolation_factor, 0, 1)
			global_position = lerp(position_buffer[1][0], position_buffer[2][0], interpolation_factor)
		elif render_time > position_buffer[1][1]:
			var i_divider = float(position_buffer[1][1] - position_buffer[0][1])
			if i_divider == 0:
				i_divider = 1
			var extrapolation_factor = float(render_time - position_buffer[0][1]) / i_divider
			extrapolation_factor = clamp(extrapolation_factor, 0, 1)
			extrapolation_factor -= 1.00
			var position_delta = position_buffer[1][0] - position_buffer[0][0]
			global_position = position_buffer[1][0] + position_delta * extrapolation_factor

var last_position = Vector2.ZERO
func _process(delta):
	if player_manager:
		if $NameLabel.text != player_manager.player_name:
			$NameLabel.text = player_manager.player_name
	
#----- Methods -----
func synchronize(pid):
	rpc_id(pid, "rpc_init_global_position", global_position)
	GameSystem.set_remote_node_reference(pid, self, "player_manager", player_manager)

func process_with_input(input_vec, delta):
	move_and_slide(input_vec * delta * move_speed)
	rpc_unreliable("rpc_set_global_position", global_position, OS.get_system_time_msecs())

#----- RPCs -----
remote func rpc_init_global_position(gp):
	global_position = gp

# receive new  position from server
remote func rpc_set_global_position(gp, stamp):
	if last_position_stamp > stamp:
		return
	last_position_stamp = stamp
	position_buffer.append([gp, stamp])
	


func _on_SyncPositionTimer_timeout():
	pass
	#rpc_unreliable("rpc_set_global_position", global_position, OS.get_system_time_msecs())


func _on_SpeedCalcTimer_timeout():
	var pos_delta = global_position - last_position
	pos_delta = pos_delta.length()
	$SpeedLabel.text = str(pos_delta/$SpeedCalcTimer.wait_time) + "m/s"
	last_position = global_position
