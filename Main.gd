extends Spatial


enum TRAVEL_STATE {IDLE, READY, SWING}
const travel_state_array = ["Idle", "Ready", "Swing"]

onready var swing_stick = $SwingStick


func _ready():
	init_gui()


func init_gui() -> void:
	($GUI/Panel/OptionButtonTravelTo as OptionButton).add_item("Idle", 0)
	($GUI/Panel/OptionButtonTravelTo as OptionButton).add_item("Ready", 1)
	($GUI/Panel/OptionButtonTravelTo as OptionButton).add_item("Swing", 2)
	($GUI/Panel/OptionButtonTravelTo as OptionButton).select(2)
	
	for index in Global.animation_desc.size():
		($GUI/Panel/OptionButtonAnims as OptionButton).add_item(Global.animation_desc[index], index)
	
	# fill from values saved in the AnimationTree.
	($GUI/Panel/OptionButtonAnims as OptionButton).select(swing_stick.get_swing_animation_id())
	$GUI/Panel/LineEditTimeScale.text = str(swing_stick.get_swing_timescale())
	$GUI/Panel/LineEditSeek.text = str(swing_stick.get_swing_seek())
	
	($GUI/Panel/OptionButtonPaths as OptionButton).add_item("Add", 0)
	($GUI/Panel/OptionButtonPaths as OptionButton).add_item("New", 1)


func disable_options() -> void:
	$GUI/Panel/OptionButtonTravelTo.disabled = true
	$GUI/Panel/ButtonTravelTo.disabled = true
	
	$GUI/Panel/OptionButtonAnims.disabled = true
	$GUI/Panel/LineEditTimeScale.editable = false
	$GUI/Panel/LineEditSeek.editable = false
	
	$GUI/Panel/ButtonClearPaths.disabled = true
	$GUI/Panel/OptionButtonPaths.disabled = true


func enable_options() -> void:
	$GUI/Panel/OptionButtonTravelTo.disabled = false
	$GUI/Panel/ButtonTravelTo.disabled = false
	
	$GUI/Panel/OptionButtonAnims.disabled = false
	$GUI/Panel/LineEditTimeScale.editable = true
	$GUI/Panel/LineEditSeek.editable = true
	
	$GUI/Panel/ButtonClearPaths.disabled = false
	$GUI/Panel/OptionButtonPaths.disabled = false
	
	#after using seek it will always reset to -1
	#restore the value saved in the GUI
	swing_stick.set_swing_seek(float($GUI/Panel/LineEditSeek.text))
	#$GUI/Panel/LineEditSeek.text = str(swing_stick.get_swing_seek())


func set_log_text(p_text : String) -> void:
	$GUI/PanelLogs/TextEditLogs.text = p_text


func _on_ButtonTravelTo_button_up():
	var state_id = ($GUI/Panel/OptionButtonTravelTo as OptionButton).selected
	swing_stick.travel_to_state(travel_state_array[state_id])


func _on_OptionButtonAnims_item_selected(index):
	swing_stick.set_swing_animation(Global.animation_names[index])


func _on_LineEditTimeScale_text_entered(new_text):
	var to_float = float(new_text)
	swing_stick.set_swing_timescale(to_float)
	$GUI/Panel/LineEditTimeScale.text = str(swing_stick.get_swing_timescale())


func _on_LineEditSeek_text_entered(new_text):
	var to_float = float(new_text)
	swing_stick.set_swing_seek(to_float)
	$GUI/Panel/LineEditSeek.text = str(swing_stick.get_swing_seek())


func _on_OptionButtonPaths_item_selected(index):
	swing_stick.set_path_control(index)


func _on_ButtonClearPaths_button_up():
	swing_stick.clear_all_paths()


func _on_ButtonLogs_toggled(button_pressed):
	if button_pressed:
		$GUI/PanelLogs.show()
		#stop camera moving when logs window is showing
		$Cameras/TrackballCamera.mouse_enabled = false
		$Cameras/TrackballCamera.zoom_enabled = false
	else:
		$GUI/PanelLogs.hide()
		$Cameras/TrackballCamera.mouse_enabled = true
		$Cameras/TrackballCamera.zoom_enabled = true
