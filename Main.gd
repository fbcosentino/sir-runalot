extends Spatial

export(float) var RotationSpeed = 0.1
export(float) var CurrentSpeed = 1.0
export(float) var Acceleration = 0.01
export(bool) var Running = false
export(bool) var Accelerating = false


onready var CameraAnim = get_node("Arm/Camera/AnimationPlayer")


onready var Map = get_node("Map")
onready var Arm = get_node("Arm")
onready var Buildings = get_node("Map/Buildings").get_children()
onready var MainTrigger = get_node("Arm/MainRotationTrigger")
onready var Player = get_node("Arm/Player")

onready var DistanceLabel = get_node("Interface/DistanceLabel")
onready var DistanceLabelEnd = get_node("Interface/Panel/DistanceLabel")
onready var EndPanel = get_node("Interface/Panel")
onready var EndPanelAnims = get_node("Interface/Panel/AnimationPlayer")

var distance = 0.0

# main startup method
func _ready():
	# Hide end panel
	EndPanel.hide()
	# Randomize the RNG
	randomize()
	# Start a run
	Start()
	
func Start():
	# Reset map
	Manager.LastBuilding = null
	Arm.rotation.z = 0
	distance = 0.0

	# Configure each building
	var i = 0
	for building in Buildings:
		building.MainTrigger = MainTrigger
		# First 2 blocks are starting runway
		if i < 2:
			building.Setup(true)
		else:
			building.Setup(false)
		i += 1

	# Start game
	Player.translation = Vector3(0.0, 136.0, 0.0)
	yield(get_tree(), "idle_frame")
	Player.set_physics_process(true)
	CameraAnim.play("Start")

# Fixed process method at 60Hz
func _physics_process(delta):
	if Running:
		# Rotate arm containing player and camera
		Arm.rotation.z -= delta * CurrentSpeed * RotationSpeed
		# Calculate and display distance
		distance += delta * CurrentSpeed * RotationSpeed * 75.4 # average 12m diameter
		DistanceLabel.text = str(int(round(distance)))+" m"
		DistanceLabelEnd.text = DistanceLabel.text
		if Accelerating:
			CurrentSpeed += Acceleration*delta
			Player.AnimationSpeed = CurrentSpeed
	

# Called if player fell or left screen
func _on_Player_failed():
	# Stop game
	Running = false
	Accelerating = false
	# Play zoom out animation
	CameraAnim.play("End")
	# Show score
	EndPanelAnims.play("Show")
	

# Called on any input
func _input(event):
	# If end panel is visible
	if EndPanel.visible:
		# If event is any keyboard key or touch
		if (event is InputEventKey) or (event is InputEventMouseButton) or (event is InputEventScreenTouch):
			# Hide panel
			EndPanelAnims.play("Hide")
			# Restart game
			Start()
