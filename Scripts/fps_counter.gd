extends Label

func _process(_delta):
	var fps: float = Engine.get_frames_per_second() # Why is this float?
	text = "FPS: " + str(fps)
