extends Node

var resource_path

export(String) remote var player_name = "杰克" setget _on_player_name_set
func _on_player_name_set(v):
	player_name = v
	
	if is_network_master():
		update_ui()


func _ready():
	pass
#----- Methods -----
func synchronize(pid):
	rpc_id(pid, "rpc_set_network_master", get_network_master(), player_name)
func update_ui():
	GameSystem.game_manager.player_name_label.text = "玩家名: "+player_name
#----- RPCs -----
remote func rpc_set_player_name(p_name):
	player_name = p_name
	if get_tree().is_network_server():
		GameSystem.send_msg("玩家"+player_name+"正式加入了游戏")
remote func rpc_set_network_master(pid, p_name):
	set_network_master(pid)
	print("网络大师", pid, "<=" if is_network_master() else "")
	if is_network_master():
		player_name = GameSystem.player_name
		rpc("rpc_set_player_name", player_name)
		GameSystem.main_player_manager = self
		update_ui()
	else:
		player_name = p_name
#----- Signals -----
