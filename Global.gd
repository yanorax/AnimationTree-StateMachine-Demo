extends Node


var animation_desc = ["360deg 0.5sec", "360deg 1.0sec","360deg 2.0sec", "270deg 0.5sec", "270deg 1.0sec", "270deg 2.0sec"]
var animation_names = ["threesixty_12", "threesixty_24","threesixty_48", "twoseventy_12", "twoseventy_24", "twoseventy_48"]
var animation_dict = {
	"threesixty_12" : 0, 
	"threesixty_24" : 1,
	"threesixty_48" : 2, 
	"twoseventy_12" : 3, 
	"twoseventy_24" : 4, 
	"twoseventy_48" : 5
}

enum PATH_CONTROL {ADD, NEW}
var path_control_array = ["Add", "New"]
