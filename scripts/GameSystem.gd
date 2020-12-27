extends Node

signal game_start

var game_manager:Node = null
var chat_display:Node = null



var linking_context:LinkingContext = LinkingContext.new()

func send_msg(s):
	chat_display.add_label(s)



func start_game():
	emit_signal("game_start")
