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

func send_feedback(s, sender):
	if sender:
		var pid = sender.get_network_master()
		if pid == get_tree().get_network_unique_id():
			send_msg(s)
		else:
			rpc_id(pid, "rpc_send_msg", s)
	else:
		send_msg(s)

func send_chat(s, sender=null):
	if sender == null:
		sender = main_player_manager
	if sender:
		var nid = sender.get_node("NetworkIdentifier").network_id
		rpc("rpc_send_chat", nid, s)
	else:
		send_msg(s)

func send_boardcast(s):
	if not main_player_manager:
		send_msg(s)
		return
	if get_tree().is_network_server():
		send_msg(s)
		rpc("rpc_send_msg", s)
	else:
		rpc_id(1, "rpc_send_boardcast", s)

func send_cmd(s, sender=null):
	if not sender:
		chat_display.add_history(s)
		if main_player_manager and not get_tree().is_network_server():
			var nid = main_player_manager.get_node("NetworkIdentifier").network_id
			rpc_id(1, "rpc_send_cmd", nid, s)
			return
		
		if main_player_manager and get_tree().is_network_server():
			sender = main_player_manager
	
	
	var parsed_cmd = parse_cmd(s)
	if not parsed_cmd:
		var temp = sender if sender else main_player_manager
		send_chat(s, temp)
		return 
		
	if parsed_cmd.size() < 1:
		send_feedback("无法识别的指令: "+s, sender)
	
	var cmd = "cmd_" + parsed_cmd[0]
	if has_method(cmd):
		call(cmd, sender, parsed_cmd[1])
	else:
		send_feedback("未定义的指令: " + parsed_cmd[0], sender)

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
func cmd_say(sender, args):
	send_chat(args[0], sender)

func cmd_b(sender, args):
	send_boardcast(args[0])

func cmd_list(sender, args):
	var ps = get_tree().get_nodes_in_group("player_manager")
	var l = ">=====| 玩家列表 [%d] |=====<\n" % ps.size()
	for p in ps:
		l += "[%d]%s(%d)\n" % [p.get_node("NetworkIdentifier").network_id, p.player_name, p.get_network_master()]
	send_feedback(l, sender)
func cmd_damage(sender, args):
	if not sender:
		return
	var n = args.size()
	if n == 1:
		sender.cat.take_damage(int(args[0]))
	if n == 2:
		var victim = null
		var ps = get_tree().get_nodes_in_group("player_manager")
		for p in ps:
			if p.player_name == args[1] || p.get_network_master() == int(args[1]):
				victim = p
				break
		if victim:
			victim.cat.take_damage(int(args[0]))
			return
		send_feedback("未找到玩家 '%s'" % str(args[1]), sender)
#----- RPCs -----
remote func rpc_add_node(resource_path, nid):
	if linking_context.get_node(nid):
		return
	var n = load(resource_path).instance()
	n.get_node("NetworkIdentifier").network_id = nid
	
	linking_context.add_node(n, nid)
	game_manager.world.add_child(n)
	
	
remote func rpc_add_rpc_hook(nid, rpc:String, args:Array=[]):
	linking_context.append_rpc(nid, rpc, args)

remote func rpc_remove_node(nid):
	var n = linking_context.get_node(nid)
	if n:
		n.queue_free()

remote func rpc_set_node_reference(t_nid, property, v_nid):
	var target = linking_context.get_node(t_nid)
	var value = linking_context.get_node(v_nid)
	print(value)
	if value == null:
		print("value 为空， 添加%d的钩子" % v_nid)
		linking_context.append_property_hook(v_nid, target, property, v_nid, true)
	else:
		target.set(property, value)

remotesync func rpc_send_chat(sender_nid, msg):
	var sender = linking_context.get_node(sender_nid)
	if sender:
		var m = "[%s(%d)]" % [sender.player_name, sender.get_network_master()]
		send_msg(m + msg)
	

remote func rpc_send_msg(msg):
	send_msg(msg)

remote func rpc_send_cmd(sender_nid, cmd):
	var sender = linking_context.get_node(sender_nid)
	if sender:
		send_cmd(cmd, sender)

remote func rpc_send_boardcast(msg):
	send_msg(msg)
	rpc("rpc_send_msg", msg)
#----- Signals -----
func _on_network_node_added(nid, node:Node):
	print("执行%d的钩子" % nid)
	linking_context.invoke_property_hooks(node)
	linking_context.invoke_rpc_hooks(node)
	


