extends Node

var network_manager:NetworkManager = null
onready var world:Node = $World
onready var player_name_label:Label = $Control/HUD/PlayerNameLabel
onready var player_health_label:Label = $Control/HUD/HealthNameLabel
onready var set_player_name_dialog:AcceptDialog = $Control/SetPlayerNameDialog
onready var player_name_edit:LineEdit = $Control/SetPlayerNameDialog/LineEdit

func _ready():
	GameSystem.game_manager = self
	
	
	
	show_ui()
	hide_hud()
	

func _process(delta):
	if Input.is_action_just_pressed("display_chat"):
		GameSystem.chat_display.show_history(not GameSystem.chat_display.is_history_visible())
		if GameSystem.main_player_manager:
			GameSystem.main_player_manager.enable_input = not GameSystem.chat_display.is_history_visible()
		

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

func choose(a:Array):
	return a[randi()%a.size()]
#----- Signals -----
func _on_ServerButton_pressed():
	if network_manager == null:
		randomize()
		player_name_edit.text = choose(["你好", "帅哥杰克", "汤姆猫米", "巴拉巴拉"])
		set_player_name_dialog.popup_centered()
		yield(set_player_name_dialog, "popup_hide")
		GameSystem.player_name = player_name_edit.text
		
		network_manager = NetworkManagerServer.new()
		network_manager.name = "NetworkManagerServer"
		
		network_manager.connect("server_started", self, "_on_server_started")
		network_manager.connect("server_fail", self, "_on_server_fail")
		
		add_child(network_manager)
	else:
		GameSystem.send_msg("可能还在连接服务器，请稍后尝试")

func _on_ClientButton_pressed():
	if network_manager == null:
		randomize()
		player_name_edit.text = choose(["你好", "帅哥杰克", "汤姆猫米", "巴拉巴拉"])
		set_player_name_dialog.popup_centered()
		yield(set_player_name_dialog, "popup_hide")
		GameSystem.player_name = player_name_edit.text
		
		GameSystem.send_msg("正在连接服务器...")
		network_manager = NetworkManagerClient.new()
		network_manager.name = "NetworkManagerClient"
		
		network_manager.connect("connected_to_server", self, "_on_connected_to_server")
		network_manager.connect("connection_failed", self, "_on_connection_failed")
		network_manager.connect("server_disconnected", self, "_on_server_disconnected")
		
		add_child(network_manager)
	else:
		GameSystem.send_msg("还在等待服务器回应中...")

func _on_connected_to_server():
	hide_ui()
	show_hud()
	GameSystem.start_game()
	GameSystem.send_msg("连接到服务器成功！")

func _on_connection_failed():
	show_ui()
	GameSystem.send_msg("连接到服务器失败！")
	network_manager.queue_free()
	network_manager = null
func _on_server_disconnected():
	show_ui()
	hide_hud()
	GameSystem.stop_game()
	GameSystem.send_msg("与服务器的连接断开!")
	
	# remove all network objects
	var ns = get_tree().get_nodes_in_group("network")
	for n in ns:
		n.queue_free()
		
	network_manager.queue_free()
	network_manager = null

func _on_server_fail():
	GameSystem.stop_game()
	GameSystem.send_msg("创建服务器失败！")
	show_ui()
	network_manager.queue_free()
	network_manager = null
	

func _on_server_started():
	GameSystem.send_msg("创建服务器成功！")
	hide_ui()
	show_hud()
	GameSystem.start_game()

