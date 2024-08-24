extends Button
#A button created to sybolize another player in the lobby

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	var client = get_parent().get_parent().get_parent()
	#Calls lobby server to spawn a game server process
	client.rpc_id(1, "createGameServer", text, client.username)
	get_parent().get_parent().hide()
	pass # Replace with function body.
