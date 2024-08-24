extends Node

const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 9999
var network = ENetMultiplayerPeer.new()

var username
var playerList
var deck = "2_147 2_149 3_7 3_9 3_14 3_22 3_24 3_122 3_126 3_128 3_130 3_133 3_140 3_141 8 121"

func _ready():
	multiplayer.peer_connected.connect(func(id): print("Player connected. ID: ", id))
	multiplayer.peer_disconnected.connect(func(id): print("Player dissconected. ID: ", id))

func connecttoServer():
	network.create_client(DEFAULT_IP, DEFAULT_PORT)
	multiplayer.multiplayer_peer = network

@rpc("any_peer", "call_remote", "reliable")
func logUserInfo(id):
	rpc_id(1, "logUserInfo", id, username)

@rpc("any_peer", "call_remote", "reliable", 0)
func recieveClientData(data):
	print(data)
	pass

@rpc("any_peer", "call_remote", "reliable")
func getClientInfo():
	pass

@rpc("authority", "call_remote", "reliable")
func updateLobby(list):
	playerList = list.duplicate()
	var valid = []
	for i in $ScrollContainer/VBoxContainer.get_children():
		if !playerList.keys().has(i.name):
			i.queue_free()
		else:
			valid.append(i.name)
	for i in playerList.keys():
		if !valid.has(i) and i != username:
			var button = load("res://lobbyButton.tscn").instantiate()
			button.text = i
			button.name = i
			$ScrollContainer/VBoxContainer.add_child(button)
			
@rpc("any_peer", "call_remote", "reliable")
func updateClient():
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func updateCard():
	pass
			
@rpc("any_peer", "call_remote", "reliable", 0)
func createGameServer():
	pass
		
@rpc("authority", "call_remote", "reliable", 0)
func joinGameServer(port):
	multiplayer.multiplayer_peer = null
	var client = load("res://UI.tscn").instantiate()
	client.port = port
	client.deck = deck
	for i in get_children():
		i.hide()
	add_child(client)
	pass

func _on_button_pressed():
	username = $TextEdit.text
	connecttoServer()
	$Button.hide()
	$TextEdit.hide()
	$ScrollContainer.show()
	pass # Replace with function body.
