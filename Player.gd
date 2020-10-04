extends KinematicBody

signal failed

# Normal speed jump
export(float) var JumpSpeed = 1.0
# Jump post speed (delta added while key is held down
export(float) var JumpPostSpeed = 0.1
export(float) var Gravity = -9.8
export(float) var CoyoteTime = 0.2
export(float) var JumpPressTime = 0.5
export(float) var SpeedScale = 1.0

export(NodePath) var RotationReference = ""

export(float) var AnimationSpeed = 0.0

var is_jumping = false
var is_coyote_on_floor = true
var coyote_count = CoyoteTime
var jump_press_count = JumpPressTime

var current_speed = Vector3()

var current_anim = ""

onready var Arm = get_node(RotationReference)
onready var Anims = get_node("Knight/AnimationPlayer")

func _ready():
	set_physics_process(false)
	SetAnimation("Idle")

func _physics_process(delta):
	
	# COYOTE TIME
	# If touching floor, safe ground
	if is_on_floor():
		coyote_count = CoyoteTime
		is_coyote_on_floor = true
		current_speed.y = Gravity * 0.1 * delta # small gravity just to keep contact with floor

	# Not on floor: falling
	else:
		current_speed.y += Gravity * delta
	
		# Not on floor, but coyote time not elapsed yet, fake ground
		if coyote_count > 0:
			coyote_count -= delta
			# If just elapsed, now we fall
			if coyote_count <= 0:
				coyote_count = 0.0
				is_coyote_on_floor = false
	
		
	# JUMP
	# If we are on floor (real or fake)
	if is_coyote_on_floor:
		# Were we jumping?
		if is_jumping:
			is_jumping = false
			
			
		# Otherwise, are we trying to jump?
		elif Input.is_action_just_pressed("jump"):
			# Player jumping
			current_speed.y += JumpSpeed
			#jump_impulse = Vector3(0.0, JumpSpeed, 0.0)
			is_jumping = true
			is_coyote_on_floor = false
			coyote_count = 0.0
			jump_press_count = JumpPressTime
			SetAnimation("Jump")
	
	# Not on floor and during a jump, check if key is help pressed
	elif is_jumping:
		# Check jump press time window
		if jump_press_count > 0:
			# Still inside the window
			
			# countdown
			jump_press_count -= delta
			
			# Check if jump still pressed
			if Input.is_action_pressed("jump"):
				current_speed.y += JumpPostSpeed * jump_press_count

	# current_speed is in local coordinates
	# we need global coordinates for move_and_slide
	var rotated_speed = Arm.to_global(current_speed)
	var rotated_up = Arm.to_global(Vector3(0.0, 1.0, 0.0))
			
	var result = move_and_slide(rotated_speed * SpeedScale, rotated_up, false, 4, PI/4, false)
			
	
	if not is_jumping:
		if AnimationSpeed > 0:
			SetAnimation("Run")
		else:
			SetAnimation("Idle")
	Anims.playback_speed = AnimationSpeed

	# If distance to center of disc is smaller than 112 (surface of lava is 115)
	if translation.length() < 112.0:
		emit_signal("failed")
		set_physics_process(false)
		
	# If left screen area
	elif translation.x < -90:
		emit_signal("failed")
		set_physics_process(false)

# Sets the current playing animation only if not the same as
# the one already playing
func SetAnimation(anim_name):
	if anim_name != current_anim:
		Anims.play(anim_name)
		current_anim = anim_name
