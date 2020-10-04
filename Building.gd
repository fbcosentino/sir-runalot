extends Spatial

# Range used for random distribution
export(float) var MaxScaleChange = 0.05
# Clamp value to avoid unjumpable steps - must be lower than MaxScaleChange
export(float) var ScaleClamp = 0.01

# Base and top nodes used for scaling
onready var BasePart = get_node("Base")
onready var TopPart = get_node("Top")

# List of base and top children (only one child will be set visible)
onready var BaseModels = get_node("Base").get_children()
onready var TopModels = get_node("Top").get_children()

# Holds the trigger Area node from Main scene
var MainTrigger = null

# Index of currently used base model
var CurrentBaseModel = 0

# Index of currently used top model
# "TopModel" is not what you are thinking...
var CurrentTopModel = 0


# Enables or disables a shape
func SetShapeState(object, enabled):
	if enabled:
		object.show()
	else:
		object.hide()
	object.get_node("StaticBody/CollisionShape").disabled = not enabled


# Makes one set of base/top visible and hides the rest, by index
func SetModelByIndex(base_index, top_index):
	for i in range(BaseModels.size()):
		if i == base_index:
			SetShapeState(BaseModels[i], true)
		else:
			SetShapeState(BaseModels[i], false)
			
	for i in range(TopModels.size()):
		if i == top_index:
			TopModels[i].show()
		else:
			TopModels[i].hide()

# Mainly called when this plaftorm hits the MainTrigger from main scene
# Also may be called when the node enters the scene due to small overlapping
# between platforms, and this should be ignored
func _on_RotationTrigger_area_entered(area):
	# Checking the source is important since platforms may overlap
	# triggering eachother
	if area == MainTrigger:
		# The MainTrigger in Main scene is triggering this building
		Setup()

# Reconfigures the platform (base and top) to something random
func Setup(start_model = false):
	# Scale of base/top parts in the last building
	var last_base_scale = 1.0
	# Indices for base and top models in previous building
	var last_base_model = 0
	var last_top_model = 0 
	
	# Scale of base / top parts in this building
	# Range is always 1.0 - 1.2
	var new_base_scale = 1.1
	# Indices for base / top models in this building
	var new_base_model = 0
	var new_top_model = 0
	
	# If we are in the start run, force model and scale
	if start_model:
		new_base_scale = 1.1
		new_base_model = 0
		new_top_model = 0

	# If we have a previous building:
	elif Manager.LastBuilding != null:
		last_base_scale = Manager.LastBuilding.BasePart.scale.y
		last_base_model = Manager.LastBuilding.CurrentBaseModel
		last_top_model = Manager.LastBuilding.CurrentTopModel
		
		# Sets next scale
		# If last buiding was too high, force next one down
		if last_base_scale > 1.2:
			new_base_scale = last_base_scale + (randf() * MaxScaleChange) - MaxScaleChange
		# If last buiding was too low, force next one up
		elif last_base_scale <= 1.0:
			new_base_scale = last_base_scale + (randf() * MaxScaleChange)
		# Otherwise, both directions are possible
		else:
			new_base_scale = last_base_scale + (randf() * 2.0*MaxScaleChange) - MaxScaleChange
			
		# Clamp scale based on previous to avoid unjumpable steps
		new_base_scale = clamp(new_base_scale, last_base_scale-ScaleClamp, last_base_scale+ScaleClamp)


		# === Random models, with constraints
		# If previous model ended in a big gap and is low, 
		# we can't start with a big gap
		# that is, base index 2 cannot be followed by index 1
		# unless last model is high
		# So, if the last model has the gap:
		if (last_base_model == 2):
			# if it's low, we avoid the next gap
			if (last_base_scale <= 1.1):
				new_base_model = randi() % BaseModels.size()-1
				if new_base_model >= 1:
					new_base_model += 1
			# If it's high, we make sure next is low
			elif (last_base_scale - new_base_scale) < 0.1:
				new_base_scale = last_base_scale - 0.1
		
		# Otherwise, all next models are ok
		else:
			new_base_model = randi() % BaseModels.size()

		# Top parts have no constraints
		new_top_model = randi() % TopModels.size()

		# A sequence of connected parts forces same scale
		# Connected parts (indices):
		#   - 0 -> 0
		#   - 0 -> 2
		#   - 1 -> 0
		#   - 1 -> 2
		# indices [0,1] end connected, indices [0,2] start connected
		if ((last_base_model in [0, 1]) and (new_base_model in [0, 2])):
			new_base_scale = last_base_scale
			
	# Otherwise first building is always index 0 and scale 1.1
	# so the player has always an easy start
	else:
		new_base_model = 0
		new_base_scale = 1.1

	SetModelByIndex(new_base_model, new_top_model)
		
	BasePart.scale.y = new_base_scale
	BasePart.scale.x = new_base_scale
	TopPart.scale.y = new_base_scale
	TopPart.scale.x = new_base_scale
	
	# Set this building as the last one in Manager
	# So next building can access it
	Manager.LastBuilding = self
