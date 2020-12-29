extends Reference

class_name LinkingContext

signal network_node_added(nid, node)

var id_node_map = {}

var network_id_count = 0

# [{rpc:String, args:[]}]
var id_rpc_map = {}

func get_new_network_id():
	var res = network_id_count
	network_id_count += 1
	return res

func add_node(n:Node, id=-1):
	if id == -1:
		id = get_new_network_id()
		n.get_node("NetworkIdentifier").network_id = id
	id_node_map[id] = n
	
	emit_signal("network_node_added", id, n)

func invoke_rpc_hooks(n:Node):
	var nid = n.get_node("NetworkIdentifier").network_id
	if id_rpc_map.has(nid):
		var rpcs = id_rpc_map[nid]
		for r in rpcs:
			n.callv(r.rpc, r.args)
		id_rpc_map.erase(nid)

func remove_node(id):
	id_node_map.erase(id)

func get_node(id):
	if id_node_map.has(id):
		return id_node_map[id]
	return null

func append_rpc(nid, rpc:String, args:Array):
	if not id_rpc_map.has(nid):
		id_rpc_map[nid] = []
	
	id_rpc_map[nid].append({"rpc":rpc, "args":args})
	
	
	
	
	
