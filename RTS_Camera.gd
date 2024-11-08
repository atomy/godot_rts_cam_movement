extends Node3D

# camera_move
@export_range(0, 100, 1) var camera_move_speed: float = 20.0

# camera_pan
@export_range(0, 32, 4) var camera_automatic_pan_margin: int = 16
@export_range(0, 20, 0.5) var camera_automatic_pan_speed: float = 12

# camera_zoom
var camera_zoom_direction: float = 0
@export_range(0, 100, 1) var camera_zoom_speed = 40.0
@export_range(0, 100, 1) var camera_zoom_min = 1.0
@export_range(0, 100, 1) var camera_zoom_max = 25.0
@export_range(0, 2, 0.1) var camera_zoom_speed_damp: float = 0.92

# Flags
var camera_can_process: bool = true
var camera_can_move_base: bool = true
var camera_can_zoom: bool = true
var camera_can_automatic_pan: bool = true

# Nodes
@onready var camera_socket: Node3D = $camera_socket
@onready var camera: Camera3D = $camera_socket/Camera3D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !camera_can_process: return
		
	camera_base_move(delta)
	camera_zoom_update(delta)
	camera_automatic_pan(delta)
	
func _unhandled_input(event: InputEvent) -> void:
	# Camera Zoom
	if event.is_action("camera_zoom_in"):
		camera_zoom_direction = -1
	elif event.is_action("camera_zoom_out"):
		camera_zoom_direction = 1
	
# Moves the base of the camera with WASD
func camera_base_move(delta: float) -> void:
	if !camera_can_move_base: return
	var velocity_direction: Vector3 = Vector3.ZERO
	
	if Input.is_action_pressed("camera_forward"): 	velocity_direction -= transform.basis.z
	if Input.is_action_pressed("camera_backward"): 	velocity_direction += transform.basis.z
	if Input.is_action_pressed("camera_right"): 	velocity_direction += transform.basis.x
	if Input.is_action_pressed("camera_left"): 		velocity_direction -= transform.basis.x
	
	position += velocity_direction.normalized() * camera_move_speed * delta

# Controls the zoom of the camera
func camera_zoom_update(delta: float) -> void:
	if !camera_can_zoom: return
	
	var new_zoom: float = clamp(camera.position.z + camera_zoom_speed * camera_zoom_direction * delta, camera_zoom_min, camera_zoom_max)
	camera.position.z = new_zoom
	camera_zoom_direction *= camera_zoom_speed_damp

func camera_automatic_pan(delta: float) -> void:
	if !camera_can_automatic_pan or !is_mouse_in_viewport():
		return  # Stop panning if automatic pan is disabled or mouse is outside the viewport
	
	# Check if the viewport has focus (i.e., if the window is active)
	var viewport_current: Viewport = get_viewport()
	if !viewport_current.has_focus():
		return
		
	var pan_direction: Vector2 = Vector2(-1, -1) # Starts negative values
	var viewport_visible_rectangle: Rect2i = Rect2i( viewport_current.get_visible_rect() )
	var viewport_size: Vector2i = viewport_visible_rectangle.size
	var current_mouse_position: Vector2 = viewport_current.get_mouse_position()
	var margin: float = camera_automatic_pan_margin # Shortcut var
	
	var zoom_factor: float = camera.position.z * 0.1
	
	# X Pan
	if ( (current_mouse_position.x < margin) or (current_mouse_position.x > viewport_size.x - margin)):
		if current_mouse_position.x > viewport_size.x / 2:
			pan_direction.x = 1
			
		translate( Vector3(pan_direction.x * delta * camera_automatic_pan_speed * zoom_factor, 0, 0) )

	# Y Pan
	if ( (current_mouse_position.y < margin) or (current_mouse_position.y > viewport_size.y - margin)):
		if current_mouse_position.y > viewport_size.y / 2:
			pan_direction.y = 1
			
		translate( Vector3(0, 0, pan_direction.y * delta * camera_automatic_pan_speed * zoom_factor) )

# Function to check if the mouse is within the viewport bounds
func is_mouse_in_viewport() -> bool:
	var viewport_current: Viewport = get_viewport()
	var viewport_size: Vector2 = viewport_current.get_visible_rect().size
	var current_mouse_position: Vector2 = viewport_current.get_mouse_position()

	# Check if mouse position is within viewport boundaries
	return current_mouse_position.x >= 0 and current_mouse_position.x <= viewport_size.x \
		   and current_mouse_position.y >= 0 and current_mouse_position.y <= viewport_size.y

	
