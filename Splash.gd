extends Control

onready var Anims = get_node("AnimationPlayer")

# Startup
func _ready():
	Anims.play("Splash")

# Captures input
func _input(event):
	# Any input from keyboard or touch
	if (event is InputEventKey) or (event is InputEventMouseButton) or (event is InputEventScreenTouch):
		Skip()
		
		
func Skip():
	Anims.stop()
	get_tree().change_scene("res://Main.tscn")
