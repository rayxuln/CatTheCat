extends NetworkManager

class_name NetworkManagerServer

signal server_started
signal server_fail
signal client_connected
signal client_disconnected

var client_proxy_map:Dictionary = {}

func _ready():
	.init()
	var error = init()
	if error == OK:
		GameSystem.send_msg("Create server on port: "+str(port)+" successuflly!")

func _process(delta):
	._process(delta)
	
	

#----- Methods -----
func init():
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_server(port)
	if error != 0:
		GameSystem.send_msg("Can't create server on "+str(port)+"!")
		emit_signal("server_fail")
		return error
	
	get_tree().network_peer = peer
	emit_signal("server_started")
	
	var c = ClientProxy.new()
	c.peer_id = peer.get_unique_id()
	add_client_proxy(c)
	c.player_manager.player_name = GameSystem.player_name
	GameSystem.main_player_manager = c.player_manager
	return OK

func add_client_proxy(client_proxy:ClientProxy):
	client_proxy.network_manager = self
	client_proxy_map[client_proxy.peer_id] = client_proxy
	add_child(client_proxy)

func remove_client_proxy(client_proxy):
	network_peer_disconnected(client_proxy.peer_id)
	client_proxy_map.erase(client_proxy.peer_id)
	client_proxy.queue_free()

func network_peer_connected(var id):
	if client_proxy_map.has(id):
		return
	var client_proxy:ClientProxy = ClientProxy.new()
	client_proxy.peer_id = id
	add_client_proxy(client_proxy)
	GameSystem.send_msg("客户端("+str(id)+")连接")
	emit_signal("client_connected", client_proxy)
	
func network_peer_disconnected(var id):
	if not client_proxy_map.has(id):
		return
	var client_proxy:ClientProxy = client_proxy_map[id]
	
	GameSystem.send_msg("客户端("+str(id)+")"+client_proxy.player_manager.player_name+"断开连接")
	client_proxy.queue_free()
	
	emit_signal("client_disconnected", client_proxy)
