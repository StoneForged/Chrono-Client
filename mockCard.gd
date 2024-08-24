extends Control

var id = null
var strength
var durability
var mousedOver = false
var zoom = false
var chain = false
var confront = false
var clicked = false
var committed = false
var root
var depleted = false



# Called when the node enters the scene tree for the first time.
func _ready():
	root = get_parent().get_parent()
	pass # Replace with function body.

func updateArt():
	$Art.texture_normal = load("res://Card Art/" + id.split("_")[0] + ".jpg")
	$Art.scale.x = 0.73
	$Art.scale.y = 0.73
	
func updateStats():
	$Strength.show()
	$Durability.show()
	$Strength.text = str(strength)
	$Durability.text = str(durability)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if depleted and rotation_degrees < 90:
		rotation_degrees += 5
	if !depleted and rotation_degrees > 0:
		rotation_degrees -= 5
		if rotation_degrees < 0:
			rotation_degrees = 0
	if clicked:
		global_position = get_global_mouse_position()
	if Input.is_action_just_released("Click") and clicked:
		if global_position.y > 700:
			root.removeChain(self)
		else:
			position = Vector2(0, 0)
			scale.x = 1
			scale.y = 1
			clicked = false
	if Input.is_action_just_pressed("Right Click") and mousedOver == true and id != null and zoom == false:
		zoom = true
		var zoomCard = self.duplicate()
		zoomCard.rotation = 0
		zoomCard.z_index = 1
		get_parent().get_parent().get_node("Zoom").add_child(zoomCard)
	pass


func _on_mouse_entered():
	mousedOver = true
	pass # Replace with function body.


func _on_mouse_exited():
	mousedOver = false
	if zoom:
		zoom = false
		get_parent().get_parent().get_node("Zoom").get_child(0).queue_free()
	pass # Replace with function body.

func _on_art_button_down():
	if (confront or chain) and id != null and !committed:
		clicked = true
		scale.x = 4
		scale.y = 4
	pass # Replace with function body.


func _on_art_pressed():
	if get_parent().get_parent().targeting and !get_parent().get_parent().wait:
		print("hi")
		get_parent().get_parent().rpc_id(1, "target", get_parent().get_parent().targetingCard, get_parent().get_parent().targetingIndex, id)
	pass # Replace with function body.
