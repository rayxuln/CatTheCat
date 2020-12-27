extends NetworkManager

class_name NetworkManagerClient

signal connected_to_server
signal connection_failed
signal server_disconnected

export(String) var server_address = "localhost"

var has_been_welcome = false

export(String) var player_name = "杰克"

func _ready():
	.init()
	init()
	init_client()

func _process(delta):
	._process(delta)


#----- Methods -----
func init_client():
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_client(server_address, port)
	if error != 0:
		GameSystem.send_msg("Can't connect server on "+server_address+":"+str(port)+"!")
		return error
	
	return OK

func send_hello():
	var timer = Timer.new()
	add_child(timer)
	has_been_welcome = false
	while not has_been_welcome:
		put_var(PACKET_HELLO)
		put_var(player_name)
		timer.start(3)
		yield(timer, "timeout")
	
	timer.queue_free()

func send_alive():
	var timer = Timer.new()
	add_child(timer)
	while true:
		put_var(PACKET_ALIVE)
		timer.start(5)
		yield(timer, "timeout")
	
	timer.queue_free()

func packet_arrived(var id):
	var packet_type = get_var()
	match packet_type:
		PACKET_WELCOME:
			has_been_welcome = true
			var welcome_msg = get_var()
			GameSystem.send_msg(welcome_msg)
			send_alive()
		PACKET_REPLICATION:
			var rep_type = get_var()
			match rep_type:
				REP_CREATE:
					var nid = get_var()
					var resource_path = get_var()
					var n = load(resource_path).instance()
					GameSystem.game_manager.world.add_child(n)
					GameSystem.linking_context.add_node(n, nid)
					n.deserialize(self)
				REP_UPDATE:
					var nid = get_var()
					var n = GameSystem.linking_context.get_node(nid)
					if n:
						n.deserialize(self)
				REP_DESTRUCT:
					var nid = get_var()
					var n = GameSystem.linking_context.get_node(nid)
					if n:
						GameSystem.linking_context.remove_node(nid)
						n.queue_free()
			
	

func connected_to_server():
	emit_signal("connected_to_server")
	GameSystem.send_msg("Connect to server "+server_address+":"+str(port)+" successfully!")
	
	send_hello()
	
func connection_failed():
	emit_signal("connection_failed")
	GameSystem.send_msg("Connect to server "+server_address+":"+str(port)+" fail!")

func server_disconnected():
	emit_signal("server_disconnected")
