extends Node

var network_manager:NetworkManager = null
onready var world:Node = $World

func _ready():
	GameSystem.game_manager = self
	
	show_ui()
	hide_hud()
	
	get_tree().connect("node_added", self, "_on_node_added")
	get_tree().connect("node_removed", self, "_on_node_removed")

func _process(delta):
	if Input.is_action_just_pressed("display_chat"):
		GameSystem.chat_display.show_history(not GameSystem.chat_display.is_history_visible())

#----- Methods -----
func hide_ui():
	$Control/ServerButton.visible = false
	$Control/ClientButton.visible = false

func show_ui():
	$Control/ServerButton.visible = true
	$Control/ClientButton.visible = true

func hide_hud():
	$Control/HUD.visible = false

func show_hud():
	$Control/HUD.visible = true
#----- Signals -----
func _on_ServerButton_pressed():
	if network_manager == null:
		network_manager = NetworkManagerServer.new()
		
		network_manager.connect("server_started", self, "_on_server_started")
		network_manager.connect("server_fail", self, "_on_server_fail")
		
		add_child(network_manager)
	else:
		GameSystem.send_msg("可能还在连接服务器，请稍后尝试")

func _on_ClientButton_pressed():
	if network_manager == null:
		GameSystem.send_msg("正在连接服务器...")
		network_manager = NetworkManagerClient.new()
		
		network_manager.connect("connected_to_server", self, "_on_connected_to_server")
		network_manager.connect("connection_failed", self, "_on_connection_failed")
		network_manager.connect("server_disconnected", self, "_on_server_disconnected")
		
		add_child(network_manager)
	else:
		GameSystem.send_msg("还在等待服务器回应中...")

func _on_connected_to_server():
	hide_ui()
	show_hud()
	GameSystem.send_msg("连接到服务器成功！")

func _on_connection_failed():
	show_ui()
	GameSystem.send_msg("连接到服务器失败！")
	network_manager.queue_free()
	network_manager = null
func _on_server_disconnected():
	show_ui()
	hide_hud()
	GameSystem.send_msg("与服务器的连接断开!")
	network_manager.queue_free()
	network_manager = null

func _on_server_fail():
	GameSystem.send_msg("创建服务器失败！")
	show_ui()
	network_manager.queue_free()
	network_manager = null

func _on_server_started():
	GameSystem.send_msg("创建服务器成功！")
	hide_ui()
	show_hud()
	GameSystem.start_game()

func _on_node_added(node):
	if not network_manager:
		return
	if not network_manager.is_server():
		return
	if node.is_in_group("network"):
		for c in network_manager.client_proxy_map.values():
			if not c.is_server:
				c.send_rep_create(node.get_node("NetworkIdentifier").network_id)
			

func _on_node_removed(node):
	if not network_manager:
		return
	if not network_manager.is_server():
		return
	if node.is_in_group("network"):
		var nid = node.get_node("NetworkIdentifier").network_id
		GameSystem.linking_context.remove_node(nid)
		for c in network_manager.client_proxy_map.values():
			if not c.is_server:
				c.send_rep_destruct(nid)
