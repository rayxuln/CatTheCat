extends Node

signal game_start

var game_manager:Node = null
var chat_display:Node = null
var main_player_manager:Node = null
var player_name = "999"
var game_started = false

var linking_context:LinkingContext = LinkingContext.new()


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

func is_game_started():
	return game_started
#----- CMDs -----
func cmd_say(args):
	send_msg(args[0])
func cmd_list(args):
	var ps = get_tree().get_nodes_in_group("player_manager")
	var l = ">=====| 玩家列表 [%d] |=====<\n" % ps.size()
	for p in ps:
		l += p.player_name
		l += "(%d)\n" % p.get_network_master()
	send_msg(l)
#----- RPCs -----
remote func rpc_add_node(resource_path, nid):
	var n = load(resource_path).instance()
	n.get_node("NetworkIdentifier").network_id = nid
	linking_context.add_node(n, nid)
	game_manager.world.add_child(n)
	

remote func rpc_remove_node(nid):
	var n = linking_context.get_node(nid)
	if n:
		linking_context.remove_node(nid)
		n.queue_free()

remotesync func rpc_send_msg(sender_nid, msg):
	var sender = linking_context.get_node(sender_nid)
	if sender:
		var m = "[%s(%d)]" % [sender.player_name, sender.get_network_master()]
		send_msg(m + msg)
#----- Signals -----
