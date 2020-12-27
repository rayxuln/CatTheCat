extends Node

class_name NetworkManager

export(int) var port = 25578

var peer:NetworkedMultiplayerENet = null

var current_connection_status = NetworkedMultiplayerENet.CONNECTION_DISCONNECTED
var last_connection_status = NetworkedMultiplayerENet.CONNECTION_DISCONNECTED


var _is_server = false

enum {
	PACKET_HELLO,
	PACKET_WELCOME,
	PACKET_ALIVE,
	PACKET_REPLICATION
}

enum {
	REP_CREATE,
	REP_UPDATE,
	REP_DESTRUCT
}

func _process(delta):
	update_connection_status()
	
	if peer and has_packet():
		packet_arrived(get_packet_sender())
	
func _exit_tree():
	peer = null
#----- Methods -----
func init():
	pass
	

func update_connection_status():
	if not peer:
		last_connection_status = current_connection_status
		current_connection_status = NetworkedMultiplayerENet.CONNECTION_DISCONNECTED
		return

	peer.poll()
	
	last_connection_status = current_connection_status
	current_connection_status = peer.get_connection_status()
	
	
	if not is_server():
		if last_connection_status == NetworkedMultiplayerENet.CONNECTION_CONNECTING:
			if current_connection_status == NetworkedMultiplayerENet.CONNECTION_CONNECTED:
				connected_to_server()
			if current_connection_status == NetworkedMultiplayerENet.CONNECTION_DISCONNECTED:
				connection_failed()
		if last_connection_status == NetworkedMultiplayerENet.CONNECTION_CONNECTED:
			if current_connection_status == NetworkedMultiplayerENet.CONNECTION_DISCONNECTED:
				server_disconnected()

func enable_reliable():
	peer.transfer_mode = NetworkedMultiplayerENet.TRANSFER_MODE_RELIABLE

func enable_unreliable():
	peer.transfer_mode = NetworkedMultiplayerENet.TRANSFER_MODE_UNRELIABLE

func enable_unreliable_ordered():
	peer.transfer_mode = NetworkedMultiplayerENet.TRANSFER_MODE_UNRELIABLE_ORDERED

func put_var(var v, var id=NetworkedMultiplayerENet.TARGET_PEER_SERVER):
	peer.set_target_peer(id)
	peer.put_var(v)

func has_packet():
	return peer.get_available_packet_count() > 0

func get_packet_sender():
	return peer.get_packet_peer()

func get_var():
	return peer.get_var()
	

func packet_arrived(var id):
	GameSystem.send_msg("var from "+str(id)+": "+get_var())

func network_peer_connected(var id):
	pass

func network_peer_disconnected(var id):
	pass

func is_server():
	return _is_server
	
func connected_to_server():
	pass
func connection_failed():
	pass
func server_disconnected():
	pass
