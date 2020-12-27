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
	rpc_id(pid, "rpc_set_player_name", player_name)
	rpc_id(pid, "rpc_set_network_master", get_network_master())
func update_ui():
	GameSystem.game_manager.player_name_label.text = "玩家名: "+player_name
#----- RPCs -----
remotesync func rpc_set_player_name(p_name):
	player_name = p_name
	if get_tree().is_network_server():
		GameSystem.send_msg("玩家"+player_name+"正式加入了游戏")
remotesync func rpc_set_network_master(pid):
	set_network_master(pid)
	print("网络大师", pid, "<=" if is_network_master() else "")
	if is_network_master():
		rpc("rpc_set_player_name", GameSystem.player_name)
		GameSystem.main_player_manager = self
		update_ui()
#----- Signals -----
