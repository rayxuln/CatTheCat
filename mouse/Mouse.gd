extends KinematicBody2D


var resource_path

var think_time_stamp = 0
var think_time = 5000

var move_direction = Vector2.UP
var move_speed = 2
var move_time_stamp = 0
var move_time = 5000

# 对象复制，只同步变化
# 在复制开始阶段先一次性同步一遍
# 然后剩下的只同步要同步的属性
# 状态机不同步，状态机只在服务器上工作，然后状态机中负责同步相应的属性
func _ready():
	if not $NetworkIdentifier.network_manager.is_server():
		$StateMachine.auto_start = false
		$StateMachine.enable = false
		
		$Timer.autostart = false
		$Timer.stop()
	
	rset_config("global_position", MultiplayerAPI.RPC_MODE_REMOTE)
	rset_config("modulate", MultiplayerAPI.RPC_MODE_REMOTE)
#----- Methods -----
func synchronize(pid):
	rset_id(pid, "global_position", global_position)

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
	rset_unreliable("global_position", global_position)

#----- RPCs -----

#----- Signals -----
func _on_Timer_timeout():
	GameSystem.send_msg(name+"要死了")
	queue_free()
