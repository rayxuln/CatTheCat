extends Node

class_name ClientProxy

var network_manager:Node = null

var player_manager:Node = null
var peer_id = -1

func _ready():
	#get_tree().connect("node_added", self, "_on_node_added")
	GameSystem.linking_context.connect("network_node_added", self, "_on_network_node_added")
	get_tree().connect("node_removed", self, "_on_node_removed")
	
	add_player_manager()
	add_exist_nodes([player_manager])
	


func _exit_tree():
	player_manager.queue_free()
#----- Methods ------
func is_server():
	return peer_id == 1
func add_player_manager():
	var PlayerManager = preload("res://player_manager/PlayerManager.tscn")
	player_manager = PlayerManager.instance()
	player_manager.resource_path = PlayerManager.resource_path
	player_manager.set_network_master(peer_id)
	GameSystem.game_manager.world.add_child(player_manager)
	


func add_exist_nodes(exclude=[]):
	if is_server():
		return
	
	var ns = get_tree().get_nodes_in_group("network")
	for node in ns:
		if not node in exclude:
			GameSystem.rpc_id(peer_id, "rpc_add_node", node.resource_path, node.get_node("NetworkIdentifier").network_id)
	for node in ns:
		if not node in exclude:
			node.synchronize(peer_id)
#----- Signals ------
func _on_network_node_added(nid, node:Node):
	if is_server():
		return
	print("[%d]添加网络节点 %s" % [peer_id, node.name])
	GameSystem.rpc_id(peer_id, "rpc_add_node", node.resource_path, nid)
	node.synchronize(peer_id)

func _on_node_removed(node:Node):
	if is_server():
		return
	if not node.is_in_group("network"):
		return
	GameSystem.rpc_id(peer_id, "rpc_remove_node", node.get_node("NetworkIdentifier").network_id)
