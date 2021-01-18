extends Node

var resource_path

export(String) remote var player_name = "杰克" setget _on_player_name_set
func _on_player_name_set(v):
	player_name = v
	
	if is_network_master():
		update_ui()

var Cat = preload("res://cat/Cat.tscn")
var cat:Node = null

var enable_input:bool = true

func _ready():
	if not get_tree().is_network_server():
		return
	var ps = get_tree().get_nodes_in_group("cat_spawn_point")
	if ps.size() == 0:
		printerr("There is no cat spawn point!")
		return
	
	# Spawn a cat
	var c = Cat.instance()
	c.resource_path = Cat.resource_path
	randomize()
	var pos = ps[randi()%ps.size()]
	c.player_manager = self
	get_parent().add_child(c)
	c.global_position = pos.global_position
	cat = c
	

func _exit_tree():
	if not get_tree().is_network_server():
		return
	
	cat.queue_free()


func _physics_process(delta):
	fetch_input(delta)
	
#----- Methods -----
func synchronize(pid):
	rpc_id(pid, "rpc_set_player_name", player_name)
	rpc_id(pid, "rpc_set_network_master", get_network_master())
	
	GameSystem.set_remote_node_reference(pid, self, "cat", cat)
func update_ui():
	GameSystem.game_manager.player_name_label.text = "玩家名: "+player_name

func fetch_input(delta):
	if not enable_input:
		return
	var input_vec = Vector2.ZERO
	if is_network_master():
		input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_vec.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		
		cat.process_with_input(input_vec, delta)
		
	if not get_tree().is_network_server():
		rpc_id(	1, "rpc_recieve_movement", input_vec, delta)
#----- RPCs -----
remote func rpc_set_player_name(p_name):
	player_name = p_name
	if get_tree().is_network_server():
		GameSystem.send_boardcast("玩家"+player_name+"正式加入了游戏")
remote func rpc_set_network_master(pid):
	set_network_master(pid)
	print("网络大师", pid, "<=" if is_network_master() else "")
	if is_network_master():
		player_name = GameSystem.player_name
		rpc("rpc_set_player_name", GameSystem.player_name)
		GameSystem.main_player_manager = self
		update_ui()

remote func rpc_recieve_movement(input_vec, delta):
	cat.process_with_input(input_vec, delta)
#----- Signals -----
