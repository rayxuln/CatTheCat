extends Control


var live_time = 10000 #ms
var label_list = []
var max_history_size = 100

onready var default_container = $DefaultVBoxContainer
onready var history_container = $HistoryPanelContainer/HistoryVBoxContainer
onready var history_panel = $HistoryPanelContainer


func _ready():
	GameSystem.chat_display = self
	
	history_panel.visible = false
	history_panel.rect_size.y = 0

func _process(delta):
	var new_list = []
	for l in label_list:
		if OS.get_ticks_msec() - l.stamp < live_time:
			new_list.append(l)
		else:
			l.label.queue_free()
	
	label_list = new_list


#----- Methods ----
func add_label(s):
	var l = Label.new()
	l.text = s
	label_list.append({"label":l, "stamp":OS.get_ticks_msec()})
	default_container.add_child(l)
	
	l = Label.new()
	l.text = s
	history_container.add_child(l)
	
	if history_container.get_child_count() > 100:
		history_container.get_child(	0).queue_free()
		
	if history_container.get_child_count() > 10 and not history_panel.scroll_vertical_enabled:
		history_panel.rect_size.y = history_container.rect_size.y
		history_panel.rect_position.y = rect_size.y - history_panel.rect_size.y
		history_panel.scroll_vertical_enabled = true
	
	if history_panel.scroll_vertical_enabled:
		yield(get_tree(), "idle_frame")
		history_panel.scroll_vertical = history_container.rect_size.y - history_panel.rect_size.y

func is_history_visible():
	return history_panel.visible

func show_history(display):
	default_container.visible = not display
	history_panel.visible = display
	
	if display:
		history_panel.grab_focus()
		history_panel.rect_position.y = rect_size.y - history_panel.rect_size.y
		yield(get_tree(), "idle_frame")
		history_panel.scroll_vertical = history_container.rect_size.y - history_panel.rect_size.y
#----- Signals -----
