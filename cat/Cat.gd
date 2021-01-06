extends KinematicBody2D


var resource_path

var player_manager:Node = null

var move_speed = 20

remote var new_position = Vector2.ZERO

func _ready():
	rset_config("global_position", MultiplayerAPI.RPC_MODE_REMOTE)

func _physics_process(delta):
	global_position = global_position.linear_interpolate(new_position, 0.3)
#----- Methods -----
func synchronize(pid):
	rset("global_position", global_position)
	rset("new_position", global_position)

func process_with_input(input_vec, delta):
	move_and_slide(input_vec * delta*1000 * move_speed)
	
	rpc("rpc_set_global_position", global_position)
#----- RPCs -----
remotesync func rpc_set_global_position(gp):
	global_position = new_position
	new_position = gp
