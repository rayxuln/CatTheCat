extends Node

class_name ClientProxy

var network_manager:Node = null

var player_name = ""
var peer_id

var is_server = false

var alive_time_stamp = 0
var max_live_time = 10000 #ms


func _process(delta):
	if not is_server:
		if OS.get_ticks_msec() - alive_time_stamp >= max_live_time:
			network_manager.remove_client_proxy(self)
			return
		
		var ns = get_tree().get_nodes_in_group("network")
		for n in ns:
			send_rep_update(n.get_node("NetworkIdentifier").network_id)
	

#----- Methods ------
func put_var(v):
	network_manager.put_var(v, peer_id)

func send_rep_create(nid):
	var n = GameSystem.linking_context.get_node(nid)
	put_var(NetworkManager.PACKET_REPLICATION)
	put_var(NetworkManager.REP_CREATE)
	put_var(nid)
	put_var(n.resource_path)
	n.serialize(self)

func send_rep_update(nid):
	var n = GameSystem.linking_context.get_node(nid)
	put_var(NetworkManager.PACKET_REPLICATION)
	put_var(NetworkManager.REP_UPDATE)
	put_var(nid)
	n.serialize(self)

func send_rep_destruct(nid):
	if not network_manager.peer:
		return
	put_var(NetworkManager.PACKET_REPLICATION)
	put_var(NetworkManager.REP_DESTRUCT)
	put_var(nid)
