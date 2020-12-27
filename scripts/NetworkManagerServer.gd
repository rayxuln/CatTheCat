extends NetworkManager

class_name NetworkManagerServer

signal server_started
signal server_fail
signal client_connected
signal client_disconnected

var client_proxy_map:Dictionary = {}

func _ready():
	.init()
	init()
	var error = init_server()
	if error == OK:
		GameSystem.send_msg("Create server on port: "+str(port)+" successuflly!")

func _process(delta):
	._process(delta)
	
	

#----- Methods -----
func init_server():
	_is_server = true
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_server(port)
	if error != 0:
		GameSystem.send_msg("Can't create server on "+str(port)+"!")
		emit_signal("server_fail")
		return error
	
	emit_signal("server_started")
	
	var c = ClientProxy.new()
	c.peer_id = peer.get_unique_id()
	c.player_name = "汤姆"
	c.is_server = true
	add_client_proxy(c)
	
	return OK

func send_welcome(var id, var player_name):
	put_var(PACKET_WELCOME, id)
	put_var("你好啊，"+player_name+"，欢迎加入游戏！", id)
	
	# send the network objects to the new client
	var ns = get_tree().get_nodes_in_group("network")
	for node in ns:
		client_proxy_map[id].send_rep_create(node.get_node("NetworkIdentifier").network_id)
	

func packet_arrived(var id):
	var packet_type = get_var()
	match packet_type:
		PACKET_HELLO:
			var player_name = get_var()
			if not client_proxy_map.has(id):
				var client_proxy = ClientProxy.new()
				client_proxy.peer_id = id
				client_proxy.player_name = player_name
				client_proxy.alive_time_stamp = OS.get_ticks_msec()
				add_client_proxy(client_proxy)
				
				network_peer_connected(id)
			send_welcome(id, player_name)
		PACKET_ALIVE:
			if client_proxy_map.has(id):
				client_proxy_map[id].alive_time_stamp = OS.get_ticks_msec()

func add_client_proxy(client_proxy:ClientProxy):
	client_proxy.network_manager = self
	client_proxy_map[client_proxy.peer_id] = client_proxy
	add_child(client_proxy)

func remove_client_proxy(client_proxy):
	network_peer_disconnected(client_proxy.peer_id)
	client_proxy_map.erase(client_proxy.peer_id)
	client_proxy.queue_free()

func network_peer_connected(var id):
	var client_proxy:ClientProxy = client_proxy_map[id]
	GameSystem.send_msg("玩家("+str(id)+")"+client_proxy.player_name+"加入了游戏")
	emit_signal("client_connected", client_proxy)
	
func network_peer_disconnected(var id):
	var client_proxy:ClientProxy = client_proxy_map[id]
	GameSystem.send_msg("玩家("+str(id)+")"+client_proxy.player_name+"离开了游戏")
	emit_signal("client_disconnected", client_proxy)
