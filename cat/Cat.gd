extends KinematicBody2D


var resource_path

remote var player_manager:Node = null

var move_speed = 10

var last_position_stamp = 0

var target_global_position = Vector2.ZERO
var has_target_global_position = false

func _ready():
	if not get_tree().is_network_server():
		$SyncPositionTimer.stop()
		$SyncPositionTimer.autostart = false

func _physics_process(delta):
	if get_tree().is_network_server():
		return
	_process_client(delta)


func _process_client(delta):
	if has_target_global_position:
		global_position = lerp(global_position, target_global_position, 0.3)

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
	move_and_slide(input_vec * delta * 1000 * move_speed)
	target_global_position = global_position
	rpc_unreliable("rpc_set_global_position", global_position, OS.get_system_time_msecs())

#----- RPCs -----
remote func rpc_init_global_position(gp):
	global_position = gp

# receive new  position from server
remote func rpc_set_global_position(gp, stamp):
	if last_position_stamp > stamp:
		return
	last_position_stamp = stamp
	has_target_global_position = true
	target_global_position = gp
	

func _on_SpeedCalcTimer_timeout():
	var pos_delta = global_position - last_position
	pos_delta = pos_delta.length()
	$SpeedLabel.text = str(pos_delta/$SpeedCalcTimer.wait_time) + "m/s"
	last_position = global_position
