extends KinematicBody2D


var resource_path

var think_time_stamp = 0
var think_time = 5000

var move_direction = Vector2.UP
var move_speed = 2
var move_time_stamp = 0
var move_time = 5000

func _ready():
	if not $NetworkIdentifier.network_manager.is_server():
		$StateMachine.auto_start = false
		$StateMachine.enable = false
#----- Methods -----
func serialize(client_proxy:ClientProxy):
	client_proxy.put_var(global_position)

func deserialize(network_manager:NetworkManager):
	global_position = network_manager.get_var()
	

func get_new_think_time():
	return (randi()%3+2)*1000

func get_new_move_time():
	return get_new_think_time()

func get_random_move_direction():
	return move_direction.rotated(deg2rad(randi()%360))

func start_think():
	think_time = get_new_think_time()
	think_time_stamp = OS.get_ticks_msec()

func start_move():
	move_time = get_new_move_time()
	move_direction = get_random_move_direction()
	move_time_stamp = OS.get_ticks_msec()

func is_think_time_out():
	return OS.get_ticks_msec() - think_time_stamp >= think_time

func is_move_time_out():
	return OS.get_ticks_msec() - move_time_stamp >= move_time

func move():
	move_and_collide(move_direction * move_speed)
