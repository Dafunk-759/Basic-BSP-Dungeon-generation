extends Camera2D

const speed := 200
const min_zoom := 0.5
const max_zoom := 4
const zoom_delta := Vector2(0.05, 0.05)

func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		zoom_in()
	if event.is_action_pressed("zoom_out"):
		zoom_out()


func zoom_in():
	if zoom.x > min_zoom:
		zoom -= zoom_delta


func zoom_out():
	if zoom.x < max_zoom:
		zoom += zoom_delta


func _physics_process(delta):
	var camera_move_dir = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	position += camera_move_dir * speed * delta
