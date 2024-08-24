extends Node

var port = 0
var rising = false
var network = ENetMultiplayerPeer.new()
var deck = ""
var username
var oppusername
var isActive
var attackToken
var combat = false
var blocking = false
var maxBlockers = 0
var currBlockers = 0
var attacker = false
var mulligan = []
var mulligans = true
var targeting = false
var targetingCard = ""
var targetingIndex = 0
var wait = false

func _ready():
	#Prints info abotu conections and dissconetions from the servers
	multiplayer.peer_connected.connect(func(id): print("Player connected. ID: ", id))
	multiplayer.peer_disconnected.connect(func(id): print("Player dissconected. ID: ", id))
	connecttoServer()
	
func connecttoServer():
	#creates a client object and connects it ot the server
	network.create_client("127.0.0.1", port)
	multiplayer.multiplayer_peer = network
	
@rpc("authority", "call_remote", "reliable", 0)
func passUsernames(p1, p2):
	#Gets and sets both players user name from the game server
	username = p1
	oppusername = p2
	$Player1.text = username
	$Player2.text = oppusername
	pass

@rpc("any_peer", "call_remote", "reliable")
func updateLobby():
	pass
	
@rpc("any_peer", "call_remote", "reliable", 0)
func setDivers(divers, diverStats):
	#Sets the allied and enemy diver art, stats, and depelte abilities
	var zones = [$p1Diver1, $p1Diver2, $p2Diver1, $p2Diver2]
	for i in range(0,2):
		var newCard = load("res://card.tscn").instantiate()
		newCard.zone = "diver" + str(i + 1)
		newCard.id = divers[i]
		newCard.updateArt()
		newCard.strength = diverStats[i][0]
		newCard.durability = diverStats[i][1]
		newCard.z_index = -1
		newCard.depleteEffects = diverStats[i][2]
		newCard.updateStats()
		zones[i].add_child(newCard)
	#Split into two halves as enemy cards are repersented iwth the "mackCard scene" whie allied cards are repersented with the "card" scene
	for i in range(2,4):
		var newCard = load("res://mockCard.tscn").instantiate()
		newCard.id = divers[i] + str(i - 1)
		newCard.updateArt()
		newCard.strength = diverStats[i][0]
		newCard.durability = diverStats[i][1]
		newCard.z_index = -1
		newCard.updateStats()
		zones[i].add_child(newCard)
	
@rpc("any_peer", "call_remote", "reliable")
func updateCard(hand):
	#list of cards currently displayed by thr client
	var currentHand = $Hand.get_children()
	#adds a new card to hand for each missing card in the servers hand that is not in the clients
	for i in range(0, hand.size()-currentHand.size()):
		var newCard = load("res://card.tscn").instantiate()
		newCard.zone = "hand"
		$Hand.add_child(newCard)
	currentHand = $Hand.get_children()
	#updates arts of all cards in hand to match server
	for i in range(0, hand.size()):
		if hand[i] != currentHand[i].id:
			currentHand[i].id = hand[i]
			currentHand[i].updateArt()
	pass
	
@rpc("any_peer", "call_remote", "reliable", 0)
func updateMulligans(mulligans):
	#loads mulligan card arts on load in to game
	var index = 0
	for i in mulligans:
		var newCard = load("res://mulliganCard.tscn").instantiate()
		newCard.id = i
		newCard.updateArt()
		newCard.index = index
		index += 1
		$Mulligan.add_child(newCard)
	
@rpc("any_peer", "call_remote", "reliable")
func getClientInfo():
	#sends username, deck, and id to the server
	rpc_id(1, "getClientInfo", get_parent().username, deck, multiplayer.get_unique_id())
	
@rpc("any_peer", "call_remote", "reliable")
func logUserInfo():
	pass
	
@rpc("any_peer", "call_remote", "reliable", 0)
func recieveClientData(data):
	#prints info from the sever ()used for debug purposes
	print(data)
	pass
	
@rpc("authority", "call_remote", "reliable", 0)
func joinGameServer():
	pass
	
@rpc("any_peer", "call_remote", "reliable", 0)
func createGameServer():
	pass
	
@rpc("authority", "call_remote", "reliable", 0)
func playCard(index, diver):
	#moves a card to play once the server has confimered it can be played
	$Queue.get_children()[0].play()
	pass
	
@rpc("authority", "call_remote", "reliable", 0)
func cancel(error):
	#moves card to hand if server fails to play card (ie, not enough enrgy to play card)
	$Queue.get_children()[0].cancel()
	get_node("RichTextLabel10").text = error
	
@rpc("authority", "call_remote", "reliable", 0)
func updateClient(p1health, p2health, p1energy, p2energy, p1energyReserve, p2energyReserve, timeline, activePlayer, p1attackToken, p2attackToken, cardsinHand, battlefield, battlefield2, p2diver1, p2diver2, attacking, blocking, isCombat, blocked):
	#the monstrosity
	#updates a bunch of genral info
	#activeplayer, player health, energy, and energy reserve, timeline and attack token
	isActive = activePlayer == username
	$p1health.text = "Health:\n" + str(p1health)
	$p2health.text = "Health:\n" +str(p2health)
	$p1energy.text = "Energy: " + str(p1energy)
	$p2energy.text = "Energy: " + str(p2energy)
	$p1energyReserve.text = "Energy Reserve: " + str(p1energyReserve)
	$p2energyReserve.text = "Energy Reserve: " + str(p2energyReserve)
	$Timeline.text = "Timeline: " + timeline
	$"Active Player".text = activePlayer
	if p1attackToken:
		$p1attacktoken.color = "0cff00"
		attackToken = true
	else:
		$p1attacktoken.color = "ef0000"
		attackToken = false
	if p2attackToken:
		$p2attacktoken.color = "0cff00"
	else:
		$p2attacktoken.color = "ef0000"
	#updates number if cards shown in opponents hand
	if cardsinHand > $OpponentHand.get_child_count():
		for i in range($OpponentHand.get_child_count(), cardsinHand):
			$OpponentHand.add_child(load("res://mockCard.tscn").instantiate())
	if cardsinHand < $OpponentHand.get_child_count():
		for i in range(cardsinHand, $OpponentHand.get_child_count()):
			$OpponentHand.get_children()[i].queue_free()
	#updates the opponents diver
	if p2diver1 == null and $p2Diver1.get_child_count() > 0:
		$p2Diver1.get_children()[0].queue_free()
	if p2diver2 == null and $p2Diver2.get_child_count() > 0:
		$p2Diver2.get_children()[0].queue_free()
	#updates enemy attackin/blockign zones when not attacking or blocking
	if !isActive:
		if !attacker:
			#updates enemy attacking zone (Blocking is just where enemy cards appear wether they are attacking or blocking)
			if attacking.size() > $Blocking.get_children().size():
				for i in $p2battfield2.get_children():
					if attacking.has(i.id):
						i.reparent($Blocking)
			elif attacking.size() < $Blocking.get_children().size():
				for i in $Blocking.get_children():
					if battlefield2.has(i.id):
						i.reparent($p2battfield2)
		else:
			#updates blocking
			if combat:
				#gets a list of non blank blocking spaces
				var trueBlocking = []
				for i in blocking:
					if i != "NONE":
						trueBlocking.append(i)
				#if less blockers then server says there should be, delete a blank placeholder and move blocking card to the index
				if trueBlocking.size() > getBlockingId().size():
					for i in $p2battfield2.get_children():
						if blocking.has(i.id):
							var index = 0
							for x in $Blocking.get_children():
								if x.id == null:
									index = $Blocking.get_children().find(x)
									x.queue_free()
									break
							i.reparent($Blocking)
							$Blocking.move_child(i, index)
				#if more blockers then server says, return the card to oppoent battlefield and create a new placeholder where it was
				elif trueBlocking.size() < getBlockingId().size():
					var index = 0
					for i in $Blocking.get_children():
						if battlefield2.has(i.id):
							index = $Blocking.get_children().find(i)
							$Blocking.add_child(load("res://place_holder.tscn").instantiate())
							$Blocking.move_child($Blocking.get_child(-1), index)
							$Blocking.get_child(index + 1).reparent($p2battfield2)
	#moves cards battlefield to attacking zone if under the players control
	if attacking.size() < $Attacking.get_children().size():
		for i in $Attacking.get_children():
			if battlefield.has(i.id):
				i.reparent($p1battlefield)
	#updates the battlefield
	var currentBf = $p1battlefield.get_children()
	if currentBf.size() > battlefield.size():
		for i in range(0, currentBf.size()):
			if !battlefield.has(currentBf[i].id):
				currentBf[i].queue_free()
	#adds new cards to allied battlefield if missing
	elif currentBf.size() < battlefield.size():
		for i in battlefield:
			if !getBattlefieldId().has(i):
				var newCard = load("res://card.tscn").instantiate()
				newCard.id = i
				newCard.zone = "battlefield"
				newCard.updateArt()
				$p1battlefield.add_child(newCard)
	var oppBf = $p2battfield2.get_children()
	#adds new cards to oppoent battlefield if missing
	if oppBf.size() > battlefield2.size():
		for i in range(0, oppBf.size()):
			if !battlefield2.has(oppBf[i].id):
				oppBf[i].queue_free()
	#removes crds from opponet battlefield that shouldn't be there
	elif oppBf.size() < battlefield2.size():
		oppBf = getOppbattlefieldId()
		for i in battlefield2:
			if !oppBf.has(i):
				var newCard = load("res://mockCard.tscn").instantiate()
				newCard.id = i
				newCard.updateArt()
				$p2battfield2.add_child(newCard)
	#disabled ability to pass if you are not the active players
	if !mulligans:
		$Button.disabled = !isActive
	#updates flages relating to combat
	combat = isCombat
	blocking = blocked
	#updates action button depending on 
	if combat and !blocking and isActive:
		$Button.text = "Block"
	for i in $p1battlefield.get_children():
		i.zone = "battlefield"
	pass
	
@rpc("authority", "call_remote", "reliable", 0)
#updates zones with placeholders depending on wether or not that player is attacking
func attacksDeclared(numAttacking, player):
	if player != username:
		for i in range(0, numAttacking):
			maxBlockers += 1
			$Attacking.add_child(load("res://place_holder.tscn").instantiate())
	else:
		for i in range(0, numAttacking):
			maxBlockers += 1
			$Blocking.add_child(load("res://place_holder.tscn").instantiate())
	pass
	
@rpc("any_peer", "call_remote", "reliable", 0)
#Switches the position of an attackign agent
func switchAttacks(id, index):
	for i in $Blocking.get_children():
		if i.id == id:
			$Blocking.move_child(i, index)
			break
	pass
	
#switches the position of a blocking agent
@rpc("any_peer", "call_remote", "reliable", 0)
func switchBlocks(id, index):
	for i in $Blocking.get_children():
		if i.id == id:
			$Blocking.move_child(i, index)
			break
	pass
	
#resets all attackers and blockers to either the graveyard or respective batlefields
@rpc("authority", "call_remote", "reliable", 0)
func endCombat(battlefield1, battlefield2):
	attacker = false
	blocking = false
	combat = false
	for i in $Attacking.get_children():
		if battlefield1.has(i.id):
			i.zone = "battlefield"
			i.reparent($p1battlefield)
		else:
			i.queue_free()
	for i in $Blocking.get_children():
		if battlefield2.has(i.id):
			i.reparent($p2battfield2)
		else:
			i.queue_free()
	$RichTextLabel10.text = "Combat Eneded!"
	
#updates deplete effects and stats of cards on both battlefields and the players hand
@rpc("authority", "call_remote", "reliable", 0)
func updateCards(battlefield1, battlefield2, hand):
	for i in range(0, battlefield1.size()):
		if battlefield1 != null:
			$p1battlefield.get_child(i).strength = battlefield1[i][0]
			$p1battlefield.get_child(i).durability = battlefield1[i][1]
			$p1battlefield.get_child(i).depleteEffects = battlefield1[i][2]
			$p1battlefield.get_child(i).updateStats()
	for i in range(0, battlefield2.size()):
		if battlefield2[i] != null:
			$p2battfield2.get_child(i).strength = battlefield2[i][0]
			$p2battfield2.get_child(i).durability = battlefield2[i][1]
			$p2battfield2.get_child(i).updateStats()
	for i in range(0, hand.size()):
		if hand[i] != null:
			$Hand.get_child(i).strength = hand[i][0]
			$Hand.get_child(i).durability = hand[i][1]
			$Hand.get_child(i).updateStats()
	pass
	
#updates actions placed on the chain that are not commited
@rpc("any_peer", "call_remote", "reliable", 0)
func alliedPreChain(preChain, interactable):
	for i in preChain:
		if !getChainIds().has(i):
			var newCard = load("res://mockCard.tscn").instantiate()
			newCard.id = i
			newCard.chain = interactable
			newCard.updateArt()
			$Chain.add_child(newCard)
	if $Queue.get_child_count() > 0:
		$Queue.get_child(0).queue_free()
	$Button.text = "Commit"
	targeting = false
	pass
	
#displays number of non-cmitted actions put on the chain by an opponent
@rpc("any_peer", "call_remote", "reliable", 0)
func enemyPreChain(preChainSize):
	if getChainIds().size() < preChainSize:
		for i in range(($Chain.get_child_count() - preChainSize), $Chain.get_child_count()):
			$Chain.add_child(load("res://mockCard.tscn").instantiate())
	elif getChainIds().size() > preChainSize:
		for i in range(($Chain.get_child_count() - preChainSize), $Chain.get_child_count()):
			$Chain.get_child(-1).queue_free()
	pass
	
@rpc("any_peer", "call_remote", "reliable", 0)
func cancelChain():
	pass
	
@rpc("any_peer", "call_remote", "reliable", 0)
func commitChain():
	pass
	
#revelas chain effects to opponet once they have been commited
@rpc("any_peer", "call_remote", "reliable", 0)
func enemyChain(chain):
	for i in range(($Chain.get_child_count() - chain.size()), $Chain.get_child_count()):
		var card = $Chain.get_child(i)
		card.chain = true
		card.committed = true
		card.id = chain[i - ($Chain.get_child_count() - chain.size())]
		card.updateArt()
	pass
	
#clears the chain after resolving
@rpc("any_peer", "call_remote", "reliable", 0)
func clearChain():
	for i in $Chain.get_children():
		i.queue_free()
	pass
	
#starts targeting for targeted effects
@rpc("any_peer", "call_remote", "reliable", 0)
func target(cardName, index, text):
	targeting = true
	wait = false
	targetingCard = cardName
	targetingIndex = index
	$RichTextLabel10.text = text
	$Button.text = "Cancel"
	pass
	
@rpc("any_peer", "call_remote", "reliable", 0)
func deplete():
	pass
	
#searches both the battlefield and attacking zone for the depleted card and undepletes it, also removes effects visual from chain
@rpc("any_peer", "call_remote", "reliable", 0)
func cancelDeplete(cardName):
	for i in $p1battlefield.get_children():
		if i.id == cardName:
			i.depleted = false
	for i in $Attacking.get_children():
		if i.id == cardName:
			i.depleted = false
	for i in $Chain.get_children():
		if i.id == cardName:
			i.queue_free()
	pass
	
#switches a cards visual deplete status
@rpc("any_peer", "call_remote", "reliable", 0)
func toggleDeplete(cardName):
	for i in $p2battfield2.get_children():
		if i.id == cardName:
			i.depleted = !i.depleted
	for i in $Blocking.get_children():
		if i.id == cardName:
			i.depleted = !i.depleted
	for i in $p1battlefield.get_children():
		if i.id == cardName:
			i.depleted = !i.depleted
	for i in $Attacking.get_children():
		if i.id == cardName:
			i.depleted = !i.depleted
	pass
	
#removes a non commited action fron the chain
func removeChain(card):
	rpc_id(1, "cancelChain", card.id, username)
	card.queue_free()
	if $Chain.get_child_count() == 1:
		$Button.text = "Pass"
		
	
#gets id of all non-committed cards in the chain
func getChainIds():
	var chain = []
	for i in $Chain.get_children():
		if !i.committed:
			chain.append(i.id)
	return chain

#gets ids of all cards on the opposing battlefield
func getOppbattlefieldId():
	var battlefield = []
	for i in $p2battfield2.get_children():
		battlefield.append(i.id)
	return battlefield
	
#gets ids of all cards on the allied battlefield
func getBattlefieldId():
	var battlefield = []
	for i in $p1battlefield.get_children():
		battlefield.append(i.id)
	return battlefield

#gets ids of all non placeholder blocking cards
func getBlockingId():
	var battlefield = []
	for i in $Blocking.get_children():
		if i.id != null:
			battlefield.append(i.id)
	return battlefield

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#makes hand raise when hovered over
	if rising == true and $Hand.position.y > 780:
		$Hand.position.y -= 10
	elif rising == false and $Hand.position.y < 965:
		$Hand.position.y += 10
	pass


func _on_button_pressed():
	#declares attacks
	if $Button.text == "Attack":
		attacker = true
		rpc_id(1, "recieveClientData", "ATTACK")
		$Button.text = "Pass"
	#declares blocks
	elif $Button.text == "Block":
		rpc_id(1, "recieveClientData", "BLOCK")
		$Button.text = "Pass"
	#confrims mulligans
	elif $Button.text == "Confirm":
		rpc_id(1, "updateMulligans", mulligan, username)
		$Button.text = "Pass"
		$Mulligan.queue_free()
		mulligans = false
		$Button.disabled = true
	#commits all current actions on chain to it
	elif $Button.text == "Commit":
		rpc_id(1, "commitChain", username)
		for i in $Chain.get_children():
			i.committed = true
		$Button.text = "Pass"
	#otherwise passes priority
	else:
		rpc_id(1, "recieveClientData", "PASS")
	pass # Replace with function body.

#targets player one if targeting
func _on_player_1_pressed():
	if targeting and !wait:
		wait = true
		rpc_id(1, "target", targetingCard, targetingIndex, "p1")
	pass # Replace with function body.

#targets player two if targeting
func _on_player_2_pressed():
	if targeting and !wait:
		wait = true
		rpc_id(1, "target", targetingCard, targetingIndex, "p2")
	pass # Replace with function body.
