extends Control

var clicked = false
var originalParent
var id = ""
var zone = ""
var preIndex = 0
var strength = 0
var durability = 0
var mousedOver = false
var zoom = false
var dud = false
var depleteEffects = []
var depleted = false
var committed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#if not a zoom card
	if !dud:
		#handles depletion visuals, subject to change if the "tapping" is unwanted
		if depleted and rotation_degrees < 90:
			rotation_degrees += 5
		if !depleted and rotation_degrees > 0:
			rotation_degrees -= 5
			if rotation_degrees < 0:
				rotation_degrees = 0
		#allows cards to be dragged
		if clicked == true:
			position = get_viewport().get_mouse_position()
		#displays the zoom card when right clikec
		if Input.is_action_just_pressed("Right Click") and mousedOver == true and clicked == false and zoom == false:
			zoom = true
			var zoomCard = self.duplicate()
			zoomCard.dud = true
			zoomCard.z_index = 1
			get_parent().get_parent().get_node("Zoom").add_child(zoomCard)
			#displays depleted effects if has any
			if depleteEffects.size() > 0 and (zone == "battlefield" or zone == "attacking" or zone == "blocking") and !depleted and get_parent().get_parent().isActive:
				$VBoxContainer.show()
			#cancels dpeleted if depleted 
			if depleted and !committed:
				zoom = false
				depleted = false
				get_parent().get_parent().get_node("Zoom").get_child(0).queue_free()
				get_parent().get_parent().rpc_id(1, "cancelDeplete", id)
				if zone == "battlefield":
					get_parent().get_parent().get_node("Button").text = "Pass"
				else:
					get_parent().get_parent().get_node("Button").text = "Attack"
		#ends dragging a card and moves to proper zone/location depending on location and phase of turn
		if Input.is_action_just_released("Click") and clicked == true:
			clicked = false
			$Art.disabled = true
			#plays a card from hand or a diver
			if get_viewport().get_mouse_position().x > 380 and get_viewport().get_mouse_position().y < 700 and (zone == "hand" or zone == "diver1" or zone == "diver2") and !get_parent().combat and !get_parent().blocking:
				reparent(get_parent().get_node("Queue"))
				if zone == "hand":
					get_parent().get_parent().rpc_id(1, "recieveClientData", "PLAY " + id)
				elif zone == "diver1":
					get_parent().get_parent().rpc_id(1, "recieveClientData", "PLAYDIVER " + id + " 1")
				elif zone == "diver2":
					get_parent().get_parent().rpc_id(1, "recieveClientData", "PLAYDIVER " + id + " 2")
				position = Vector2(0,0)
			#cancels an attacking card
			elif get_viewport().get_mouse_position().x > 380 and get_viewport().get_mouse_position().y > 700 and zone == "attacking":
				$Art.disabled = false
				zone = "battlefield"
				reparent(get_parent().get_node("p1battlefield"))
				position = Vector2(0,0)
				get_parent().get_parent().rpc_id(1, "recieveClientData", "REMATTACK " + id + " " + get_parent().get_parent().username)
				if get_parent().get_parent().get_node("Attacking").get_children().size() == 0:
					get_parent().get_parent().get_node("Button").text = "Pass"
			#switches an attacking cards position with another attackign card
			elif get_viewport().get_mouse_position().x > 380 and get_viewport().get_mouse_position().y < 700 and zone == "attacking" and get_parent().get_node("Attacking").get_child_count() > 0:
				$Art.disabled = false
				var index
				var minDist = 500000
				if get_viewport().get_mouse_position().x < get_parent().get_node("Attacking").get_children()[0].global_position.x:
					get_parent().rpc_id(1, "switchAttacks", id, 0, get_parent().username)
					reparent(get_parent().get_node("Attacking"))
					get_parent().get_parent().get_node("Attacking").move_child(self, 0)
				elif get_viewport().get_mouse_position().x > get_parent().get_node("Attacking").get_children()[-1].global_position.x:
					get_parent().rpc_id(1, "switchAttacks", id, -1, get_parent().username)
					reparent(get_parent().get_node("Attacking"))
				else:
					for i in  get_parent().get_node("Attacking").get_children():
						if abs(get_viewport().get_mouse_position().x - i.global_position.x) < minDist:
							minDist = abs(get_viewport().get_mouse_position().x - i.global_position.x)
							index = i
					index = get_parent().get_node("Attacking").get_children().find(index)
					if get_parent().get_node("Attacking").get_children()[index].global_position.x < get_viewport().get_mouse_position().x:
						index += 1
					get_parent().rpc_id(1, "switchAttacks", id, index, get_parent().username)
					reparent(get_parent().get_node("Attacking"))
					get_parent().get_parent().get_node("Attacking").move_child(self, index)
			#removes a blocker if declared as one
			elif get_viewport().get_mouse_position().x > 380 and get_viewport().get_mouse_position().y > 700 and zone == "blocking":
				get_parent().currBlockers -= 1
				$Art.disabled = false
				zone = "battlefield"
				reparent(get_parent().get_node("p1battlefield"))
				position = Vector2(0,0)
				get_parent().get_parent().get_node("Attacking").add_child(load("res://place_holder.tscn").instantiate())
				get_parent().get_parent().get_node("Attacking").move_child(get_parent().get_parent().get_node("Attacking").get_child(-1), preIndex)
				get_parent().get_parent().rpc_id(1, "recieveClientData", "REMBLOCK " + id + " " + get_parent().get_parent().username + " " + str(get_parent().get_children().find(self)))
			#switches position of a blcking card
			elif get_viewport().get_mouse_position().x > 380 and get_viewport().get_mouse_position().y < 700 and zone == "blocking":
				$Art.disabled = false
				var index
				var minDist = 500000
				if get_viewport().get_mouse_position().x < get_parent().get_node("Attacking").get_children()[0].global_position.x:
					get_parent().rpc_id(1, "switchBlocks", id, 0, get_parent().username)
					reparent(get_parent().get_node("Attacking"))
					get_parent().get_parent().get_node("Attacking").move_child(self, 0)
				elif get_viewport().get_mouse_position().x > get_parent().get_node("Attacking").get_children()[-1].global_position.x:
					get_parent().rpc_id(1, "switchBlocks", id, -1, get_parent().username)
					reparent(get_parent().get_node("Attacking"))
				else:
					for i in  get_parent().get_node("Attacking").get_children():
						if abs(get_viewport().get_mouse_position().x - i.global_position.x) < minDist:
							minDist = abs(get_viewport().get_mouse_position().x - i.global_position.x)
							index = i
					index = get_parent().get_node("Attacking").get_children().find(index)
					if get_parent().get_node("Attacking").get_children()[index].global_position.x < get_viewport().get_mouse_position().x:
						index += 1
					get_parent().rpc_id(1, "switchBlocks", id, index, get_parent().username)
					reparent(get_parent().get_node("Attacking"))
					get_parent().get_parent().get_node("Attacking").move_child(self, index)
				preIndex = get_parent().get_parent().get_node("Attacking").get_children().find(self)
			#otherwise returns card to previous zone
			else:
				cancel()
	pass

func cancel():
	#reutrns card to previous zone
	reparent(originalParent)
	position = Vector2(0,0)
	z_index = 0
	if zone == "hand":
		get_parent().get_parent().rpc_id(1, "updateCard", getHandIds(), get_parent().multiplayer.get_unique_id())
	$Art.disabled = false
			
func play():
	#moves an agent card to the battlefield once confirmed it can be player by the server
	reparent(get_parent().get_parent().get_node("p1battlefield"))
	originalParent = get_parent()
	zone = "battlefield"
	$Art.disabled = false
	rotation = 180
	position = Vector2(0,0)
	
#updates strength, durability, and deplete effects of an agent
func updateStats():
	$Art.disabled = false
	$Strength.show()
	$Durability.show()
	$Strength.text = str(strength)
	$Durability.text = str(durability)
	if $VBoxContainer.get_child_count() < depleteEffects.size():
		for i in $VBoxContainer.get_children():
			i.queue_free()
		for i in depleteEffects:
			var index = 0
			var button = load("res://deplete_button.tscn").instantiate()
			button.text = i
			button.index = index
			$VBoxContainer.add_child(button)
			index += 1
	
#gets the card id of every card in hand
func getHandIds():
	var hand = []
	for i in get_parent().get_children():
		hand.append(str(i.id))
	return hand

#updates art based on id
func updateArt():
	$Art.texture_normal = load("res://Card Art/" + id.split("_")[0] + ".jpg")

func _on_sprite_2d_button_down():
	# if not targeting, not a zoom card, and you are the active player
	if !get_parent().get_parent().targeting:
		if !dud:
			if get_parent().get_parent().isActive:
				#begins dragging a card in hand
				if clicked == false and get_parent().get_parent().isActive and zone != "battlefield":
					if zone == "hand":
						get_parent().get_parent().rising = false
					originalParent = get_parent()
					clicked = true
					reparent(get_parent().get_parent())
				#declares an attacker on click of a card in play
				elif zone == "battlefield" and get_parent().get_parent().attackToken and get_parent().get_parent().combat == false:
					zone = "attacking"
					reparent(get_parent().get_parent().get_node("Attacking"))
					position = Vector2(0,0)
					get_parent().get_parent().get_node("Button").text = "Attack"
					get_parent().get_parent().rpc_id(1, "recieveClientData", "DECATTACK " + id + " " + get_parent().get_parent().username)
				#declares a blocker on click of a card in play
				elif zone == "battlefield" and get_parent().get_parent().combat == true and !get_parent().get_parent().blocking and get_parent().get_parent().currBlockers < get_parent().get_parent().maxBlockers:
					get_parent().get_parent().currBlockers += 1
					zone = "blocking"
					for i in get_parent().get_parent().get_node("Attacking").get_children():
						if i.id == null:
							reparent(get_parent().get_parent().get_node("Attacking"))
							get_parent().get_parent().get_node("Attacking").move_child(self, get_parent().get_parent().get_node("Attacking").get_children().find(i))
							position = Vector2(0,0)
							preIndex = get_parent().get_parent().get_node("Attacking").get_children().find(self)
							break
					for i in get_parent().get_parent().get_node("Attacking").get_children():
						if i.id == null:
							i.queue_free()
							break
					get_parent().get_parent().rpc_id(1, "recieveClientData", "DECBLOCK " + id + " " + get_parent().get_parent().username + " " + str(get_parent().get_children().find(self)))
	else:
		if !get_parent().get_parent().wait:
			get_parent().get_parent().rpc_id(1, "target", get_parent().get_parent().targetingCard, get_parent().get_parent().targetingIndex, id)
	pass # Replace with function body.



func _on_sprite_2d_mouse_entered():
	mousedOver = true
	if clicked == false and get_parent().name != "Node" and zone == "hand":
		z_index = 1
		get_parent().get_parent().rising = true
	pass # Replace with function body.


func _on_sprite_2d_mouse_exited():
	mousedOver = false
	$VBoxContainer.hide()
	if clicked == false and get_parent().name != "Node" and zone == "hand":
		z_index = 0
		get_parent().get_parent().rising = false
	if zoom:
		zoom = false
		get_parent().get_parent().get_node("Zoom").get_child(0).queue_free()
	pass # Replace with function body.
