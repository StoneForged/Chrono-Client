extends Button
var toggle = false

var index = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if toggle:
		get_parent().show()
	pass


func _on_mouse_entered():
	toggle = true
	pass # Replace with function body.


func _on_mouse_exited():
	toggle = false
	get_parent().hide()
	pass # Replace with function body.


func _on_pressed():
	get_parent().get_parent().get_parent().get_parent().rpc_id(1, "deplete", get_parent().get_parent().id, get_parent().get_parent().get_parent().get_parent().username)
	toggle = false
	get_parent().hide()
	pass # Replace with function body.



