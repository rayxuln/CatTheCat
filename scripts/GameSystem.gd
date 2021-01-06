extends Node

signal game_start
signal game_stop

var game_manager:Node = null
var chat_display:Node = null
var main_player_manager:Node = null
var player_name = "999"
var game_started = false

var linking_context:LinkingContext = LinkingContext.new()

func _ready():
	linking_context.connect("network_node_added", self, "_on_network_node_added")
#----- Methods -----
func send_msg(s):
	chat_display.add_label(s)

func send_cmd(s):
	chat_display.add_history(s)
	var parsed_cmd = parse_cmd(s)
	if not parsed_cmd:
		if main_player_manager:
			var nid = main_player_manager.get_node("NetworkIdentifier").network_id
			rpc("rpc_send_msg", nid, s)
		else:
			send_msg(s)
		return 
		
	if parsed_cmd.size() < 1:
		send_msg("无法识别的指令: "+s)
	
	var cmd = "cmd_" + parsed_cmd[0]
	if has_method(cmd):
		call(cmd, parsed_cmd[1])
	else:
		send_msg("未定义的指令: " + parsed_cmd[0])

func parse_cmd(s):
	if s == "":
		return null
	if s[0] != "/":
		return null
	s = s.substr(1)
	var ss = s.split(" ")
	
	var args = []
	var i=1;
	while i<ss.size():
		args.append(ss[i])
		i += 1
	
	return [ss[0], args]

func start_game():
	emit_signal("game_start")
	game_started = true

func stop_game():
	emit_signal("game_stop")
	game_started = false

func is_game_started():
	return game_started

func set_remote_node_reference(pid, target:Node, property, value:Node):
	var t_nid = target.get_node("NetworkIdentifier").network_id
	var v_nid = value.get_node("NetworkIdentifier").network_id
	rpc_id(pid, "rpc_set_node_reference", t_nid, property, v_nid)
#----- CMDs -----
func cmd_say(args):
	send_msg(args[0])
func cmd_list(_args):
	var ps = get_tree().get_nodes_in_group("player_manager")
	var l = ">=====| 玩家列表 [%d] |=====<\n" % ps.size()
	for p in ps:
		l += "[%d]%s(%d)\n" % [p.get_node("NetworkIdentifier").network_id, p.player_name, p.get_network_master()]
	send_msg(l)
#----- RPCs -----
remote func rpc_add_node(resource_path, nid):
	if linking_context.get_node(nid):
		return
	var n = load(resource_path).instance()
	n.get_node("NetworkIdentifier").network_id = nid
	
	game_manager.world.add_child(n)
	linking_context.add_node(n, nid)
	
remote func rpc_add_rpc_hook(nid, rpc:String, args:Array=[]):
	linking_context.append_rpc(nid, rpc, args)

remote func rpc_remove_node(nid):
	var n = linking_context.get_node(nid)
	if n:
		n.queue_free()

remote func rpc_set_node_reference(t_nid, property, v_nid):
	var target = linking_context.get_node(t_nid)
	var value = linking_context.get_node(v_nid)
	target.set(property, value)

remotesync func rpc_send_msg(sender_nid, msg):
	var sender = linking_context.get_node(sender_nid)
	if sender:
		var m = "[%s(%d)]" % [sender.player_name, sender.get_network_master()]
		send_msg(m + msg)


#----- Signals -----
func _on_network_node_added(nide, node:Node):
	linking_context.invoke_rpc_hooks(node)


