extends Spatial

const EPSILON = 0.00001
const WAIT_TIME_PAD = 0.06 #animations take a couple of ticks to start playing

class AnimStateTransition:
#	var destination_state : String
#	var next_state : String
#	var xfade : float
#	var auto_adv : bool
	var index : int
	var transition : AnimationNodeStateMachineTransition
	var from : String
	var to : String

class StatePath:
	var state : String
	var path : ImmediateGeometry
	var points : Array

onready var animation_tree : AnimationTree = $AnimationTree
onready var look_from = $LookFrom
onready var travel_marker = $Armature/Skeleton/BoneAttachment/TravelMarker
onready var state_marker = $Armature/Skeleton/BoneAttachment/StateMarker
onready var anim_stop_timer = $AnimStopTimer
onready var anim_xfade_timer = $AnimXfadeTimer
onready var travel_paths : Spatial = $TravelPaths
onready var state_paths : Spatial = $StatePaths

enum ANIM_STATE {INIT, PLAYING_NO_BLEND, BLEND_TO_NEXT, STOPPED}
onready var current_anim_state = ANIM_STATE.INIT
onready var previous_anim_state = ANIM_STATE.INIT

onready var animation_desc = ["360deg 0.5sec", "360deg 1.0sec","360deg 2.0sec", "270deg 0.5sec", "270deg 1.0sec", "270deg 2.0sec"]
onready var animation_names = ["threesixty_12", "threesixty_24","threesixty_48", "twoseventy_12", "twoseventy_24", "twoseventy_48"]


var state_colour_dict = {
	"Idle" : Color(1.0, 0.0, 1.0, 1.0),  #magenta
	"Ready" : Color(1.0, 1.0, 0.0, 1.0), #yellow
	"Swing" : Color(0.0, 1.0, 0.0, 1.0)  #green
}

var anim_tree_travelling = false
var time_start = 0.0
var delta_sum = 0.0

var anim_state_machine

onready var destination_state : String = "Idle"
onready var new_destination_state : String = "Idle"

var previous_travel_pos : Vector3

var anim_state_transition_array = []

var anim_state_transition_dict = {
	"Idle": {
		"destination" : "Idle",
		"xfade" : 0.0,
		"auto_adv" : false}, 
	"Ready": {
		"destination" : "",
		"xfade" : 0.0,
		"auto_adv" : false}, 
	"Swing": {
		"destination" : "",
		"xfade" : 0.0,
		"auto_adv" : false}
}

var path_control : int = Global.PATH_CONTROL.ADD
var state_paths_array : Array = []
var travel_path : ImmediateGeometry
var travel_points : Array

onready var log_text : String = ""
onready var new_log_text : String = ""


func _ready():
	anim_state_machine = animation_tree["parameters/playback"]
	anim_state_machine.start("Idle")
	init_travel_path()
	build_transistion_rules()


func init_travel_path() -> void:
	var travel_mat = SpatialMaterial.new()
	travel_mat.flags_unshaded = true
	travel_mat.albedo_color = Color(1.0, 0.0, 0.0, 0.0)
	travel_path = ImmediateGeometry.new()
	travel_path.material_override = travel_mat
	travel_paths.add_child(travel_path)


func build_transistion_rules() -> void:
	var state_machine : AnimationNodeStateMachine = animation_tree.tree_root
	var transition_count = state_machine.get_transition_count()
	
	for i in transition_count:
		var new_ast = AnimStateTransition.new()
		new_ast.index = i
		new_ast.transition = state_machine.get_transition(i)
		new_ast.from = state_machine.get_transition_from(i)
		new_ast.to = state_machine.get_transition_to(i)
		anim_state_transition_array.push_back(new_ast)
		
		match new_ast.from:
#			"Idle":
#				anim_state_transition_dict["Idle"]["destination"] = new_ast.to
#				anim_state_transition_dict["Idle"]["xfade"] = new_ast.transition.xfade_time
#				anim_state_transition_dict["Idle"]["auto_adv"] = new_ast.transition.auto_advance
			"Ready":
				anim_state_transition_dict["Ready"]["destination"] = new_ast.to
				anim_state_transition_dict["Ready"]["xfade"] = new_ast.transition.xfade_time
				anim_state_transition_dict["Ready"]["auto_adv"] = new_ast.transition.auto_advance
			"Swing":
				anim_state_transition_dict["Swing"]["destination"] = new_ast.to
				anim_state_transition_dict["Swing"]["xfade"] = new_ast.transition.xfade_time
				anim_state_transition_dict["Swing"]["auto_adv"] = new_ast.transition.auto_advance


func get_swing_animation_id() -> int:
	var state_machine : AnimationNodeStateMachine = animation_tree.tree_root
	var swing_node  : AnimationNodeBlendTree = state_machine.get_node("Swing")
	var anim_node : AnimationNodeAnimation = swing_node.get_node("Animation")
	return Global.animation_dict[anim_node.animation]


func set_swing_animation(p_anim : String) -> void:
	var state_machine : AnimationNodeStateMachine = animation_tree.tree_root
	var swing_node  : AnimationNodeBlendTree = state_machine.get_node("Swing")
	var anim_node : AnimationNodeAnimation = swing_node.get_node("Animation")
	anim_node.animation = p_anim


func set_path_control(p_path_control : int) -> void:
	path_control = p_path_control


func get_swing_timescale() -> float:
	return animation_tree["parameters/Swing/TimeScale/scale"]


func set_swing_timescale(p_timescale : float) -> void:
	animation_tree["parameters/Swing/TimeScale/scale"] = p_timescale


func get_swing_seek() -> float:
	return animation_tree["parameters/Swing/Seek/seek_position"]


func set_swing_seek(p_seek : float) -> void:
	animation_tree["parameters/Swing/Seek/seek_position"] = p_seek


func change_anim_state(p_new_state : int) -> void:
	#INIT, PLAYING_NO_BLEND, BLEND_TO_NEXT, STOPPED
	
	previous_anim_state = current_anim_state
	current_anim_state = p_new_state
	
	match current_anim_state:
		ANIM_STATE.INIT:
			change_anim_state(ANIM_STATE.PLAYING_NO_BLEND)
		ANIM_STATE.PLAYING_NO_BLEND:
			if previous_anim_state == ANIM_STATE.BLEND_TO_NEXT:
				destination_state = new_destination_state
		ANIM_STATE.BLEND_TO_NEXT:
			pass
		ANIM_STATE.STOPPED:
			anim_tree_travelling = false
			get_parent().enable_options()
			
			new_log_text += str("\n", "------------------------------------------------------------------------", "\n\n")
			log_text += new_log_text
			get_parent().set_log_text(log_text)


func _process(delta):
	if anim_tree_travelling:
		var new_travel_pos = travel_marker.global_transform.origin
		var travel_delta = new_travel_pos.distance_to(previous_travel_pos)
		var anim_tree_state = anim_state_machine.get_current_node()
		
		match current_anim_state:
			ANIM_STATE.PLAYING_NO_BLEND:
				if anim_state_transition_dict[anim_tree_state]["auto_adv"] == false and anim_tree_state == destination_state:
					# state machine will not auto transition any more, start checking if
					# the stick is moving. If it has not moved in several ticks then stop.
					
					if anim_stop_timer.is_stopped():
						delta_sum = 0.0
						anim_stop_timer.start()
					else:
						delta_sum += travel_delta
					
				elif anim_state_transition_dict[anim_tree_state]["auto_adv"] == true and anim_tree_state == destination_state:
					# state machine will auto advance so we need to change the destination
					# to the transistion auto_adv destination after the xfade time.
					
					new_destination_state = anim_state_transition_dict[anim_tree_state]["destination"]
					
					# now wait the fade time and change the anim state to indicate we are waiting
					var wt = anim_state_transition_dict[anim_tree_state]["xfade"] + WAIT_TIME_PAD
					if wt > 0.0:
						anim_xfade_timer.wait_time = wt
						anim_xfade_timer.start()
						change_anim_state(ANIM_STATE.BLEND_TO_NEXT)
					else:
						# immediatly move on if no timer required
						destination_state = new_destination_state
			ANIM_STATE.BLEND_TO_NEXT:
				pass
		
		
		travel_points.push_back(new_travel_pos)
		previous_travel_pos = new_travel_pos
		
		var state_pos = state_marker.global_transform.origin
		
		if !state_paths_array.empty():
			if state_paths_array.back().state == anim_tree_state:
				state_paths_array.back().points.push_back(state_pos)
			else:
				# push final point to previous state
				state_paths_array.back().points.push_back(state_pos)
				
				# new state so create a new path
				var new_state_path = create_new_state_path(anim_tree_state)
				new_state_path.points.push_back(state_pos)
				state_paths_array.push_back(new_state_path)
		else:
			# new state so create a new path
			var new_state_path = create_new_state_path(anim_tree_state)
			new_state_path.points.push_back(state_pos)
			state_paths_array.push_back(new_state_path)
		
		
		var time_taken = OS.get_ticks_msec() - time_start
		look_from.look_at(travel_marker.global_transform.origin, Vector3.UP)
		var angle = convert_to_threesixty(look_from.rotation_degrees.y)
		new_log_text += str(str(time_taken), "	", anim_tree_state, "	", str(angle), "	", str(new_travel_pos), "\n")
		
		draw_travel_path()
		draw_state_paths()


func convert_to_threesixty(p_angle : float) -> float:
	if p_angle > 0.0:
		if p_angle == 180.0:
			return 0.0
		else:
			return p_angle
	else:
		return 360.0 + p_angle


func travel_to_state(p_state : String) -> void:
	
	var anim_tree_state = anim_state_machine.get_current_node()
	
	if anim_tree_state == "Idle" and p_state != "Idle":
		if path_control == Global.PATH_CONTROL.NEW:
			clear_travel_path_array()
			clear_state_path_array()
			free_state_paths()
		elif path_control == Global.PATH_CONTROL.ADD:
			clear_travel_path_array()
	
	if anim_tree_state != p_state:
		destination_state = p_state
		previous_travel_pos = travel_marker.global_transform.origin
		time_start = OS.get_ticks_msec()
		delta_sum = 0.0
		new_log_text = str("Time", "	", "State", "	", "Rotation", "	", "Position\n")
		get_parent().disable_options()
		change_anim_state(ANIM_STATE.INIT)
		anim_tree_travelling = true
		anim_state_machine.travel(p_state)


func clear_travel_path_array() -> void:
	travel_points = []


func clear_state_path_array() -> void:
	state_paths_array = []


func free_travel_paths() -> void:
	for tp in travel_paths.get_children():
		tp.queue_free()


func free_state_paths() -> void:
	for sp in state_paths.get_children():
		sp.queue_free()


func clear_all_paths() -> void:
	clear_travel_path_array()
	clear_state_path_array()
	free_travel_paths()
	free_state_paths()
	
	init_travel_path()


func create_new_state_path(p_state : String) -> StatePath:
	var new_state_mat = SpatialMaterial.new()
	new_state_mat.flags_unshaded = true
	new_state_mat.albedo_color = state_colour_dict[p_state]
	var new_state_path : StatePath = StatePath.new()
	new_state_path.state = p_state
	new_state_path.points = []
	new_state_path.path = ImmediateGeometry.new()
	new_state_path.path.material_override = new_state_mat
	state_paths.add_child(new_state_path.path)
	return new_state_path


func draw_travel_path() -> void:
	travel_path.clear()
	
	travel_path.begin(PrimitiveMesh.PRIMITIVE_LINES, null)
	for i in range(travel_points.size()):
		if i + 1 < travel_points.size():
			var A = travel_points[i]
			var B = travel_points[i + 1]
			travel_path.add_vertex(A)
			travel_path.add_vertex(B)
	travel_path.end()


func draw_state_paths() -> void:
	
	for sp in state_paths_array:
	
		sp.path.clear()
		
		sp.path.begin(PrimitiveMesh.PRIMITIVE_LINES, null)
		for i in range(sp.points.size()):
			if i + 1 < sp.points.size():
				var A = sp.points[i]
				var B = sp.points[i + 1]
				sp.path.add_vertex(A)
				sp.path.add_vertex(B)
		sp.path.end()


func hide_travel_paths() -> void:
	travel_paths.hide()


func show_travel_paths() -> void:
	travel_paths.show()


func hide_state_paths() -> void:
	state_paths.hide()


func show_state_paths() -> void:
	state_paths.show()


func _on_AnimStopTimer_timeout():
	if delta_sum < EPSILON:
		#stick has not moved
		change_anim_state(ANIM_STATE.STOPPED)


func _on_AnimXfadeTimer_timeout():
	change_anim_state(ANIM_STATE.PLAYING_NO_BLEND)

