extends Control

var id
var mulligan = false
var index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func updateArt():
	$Art.texture_normal = load("res://Card Art/" + id.split("_")[0] + ".jpg")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_texture_button_pressed():
	if mulligan:
		get_parent().get_parent().mulligan.remove_at(get_parent().get_parent().mulligan.find(index))
		$ColorRect.hide()
	else:
		get_parent().get_parent().mulligan.append(index)
		$ColorRect.show()
	mulligan = !mulligan
	pass # Replace with function body.
