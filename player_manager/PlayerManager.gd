extends Node

var resource_path

export(String) remote var player_name = "杰克" setget _on_player_name_set
func _on_player_name_set(v):
	player_name = v
	
	if is_network_master():
		update_ui()

var Cat = preload("res://cat/Cat.tscn")
var cat:Node = null

var movement_list:Array = []

func _ready():
	if not get_tree().is_network_server():
		return
	var ps = get_tree().get_nodes_in_group("cat_spawn_point")
	if ps.size() == 0:
		printerr("There is no cat spawn point!")
		return
	
	var c = Cat.instance()
	c.resource_path = Cat.resource_path
	randomize()
	var pos = ps[randi()%ps.size()]
	c.player_manager = self
	get_parent().add_child(c)
	c.global_position = pos.global_position
	c.new_position = c.global_position
	cat = c
	
	print("I(%s) created a cat(%s)" % [name, c.name])

func _exit_tree():
	if not get_tree().is_network_server():
		return
	
	cat.queue_free()

func _process(delta):
	# Collect input information
	# continueing
	
	# immediating
	
	pass

func _physics_process(delta):
	if not is_network_master():
		return
	var input_vec = Vector2.ZERO
	input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if not is_equal_approx(input_vec.x, 0) or not is_equal_approx(input_vec.y, 0):
		movement_list.append([input_vec, delta])
#----- Methods -----
func synchronize(pid):
	rpc_id(pid, "rpc_set_player_name", player_name)
	rpc_id(pid, "rpc_set_network_master", get_network_master())
	
	GameSystem.set_remote_node_reference(pid, self, "cat", cat)
func update_ui():
	GameSystem.game_manager.player_name_label.text = "玩家名: "+player_name
#----- RPCs -----
remote func rpc_set_player_name(p_name):
	player_name = p_name
	if get_tree().is_network_server():
		GameSystem.send_msg("玩家"+player_name+"正式加入了游戏")
remote func rpc_set_network_master(pid):
	set_network_master(pid)
	print("网络大师", pid, "<=" if is_network_master() else "")
	if is_network_master():
		player_name = GameSystem.player_name
		rpc("rpc_set_player_name", GameSystem.player_name)
		GameSystem.main_player_manager = self
		update_ui()

remotesync func rpc_recieve_movement_list(ml:Array):
	for m in ml:
		cat.process_with_input(m[0], m[1])
#----- Signals -----
func _on_InputTimer_timeout():
	if not is_network_master():
		$InputTimer.stop()
		return
	if movement_list.size() <= 0:
		return
	rpc_id(	1, "rpc_recieve_movement_list", movement_list)
	movement_list.clear()
