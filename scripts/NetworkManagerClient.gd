extends NetworkManager

class_name NetworkManagerClient

signal connected_to_server
signal connection_failed
signal server_disconnected

export(String) var server_address = "localhost"


export(String) var player_name = "杰克"

func _ready():
	.init()
	init()

func _process(delta):
	._process(delta)


#----- Methods -----
func init():
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_client(server_address, port)
	if error != 0:
		GameSystem.send_msg("Can't connect server on "+server_address+":"+str(port)+"!")
		return error
		
	get_tree().network_peer = peer
	return OK
	

func connected_to_server():
	emit_signal("connected_to_server")
	GameSystem.send_msg("Connect to server "+server_address+":"+str(port)+" successfully!")


func connection_failed():
	emit_signal("connection_failed")
	GameSystem.send_msg("Connect to server "+server_address+":"+str(port)+" fail!")

func server_disconnected():
	emit_signal("server_disconnected")
