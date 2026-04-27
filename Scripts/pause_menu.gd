extends CanvasLayer

@onready var MainMenu = "res://Scenes/MainMenu.tscn"
@onready var TestMap = "res://Scenes/TestMap.tscn"

func _on_resume_pressed():
	visible = false
	get_tree().paused = false


func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file(MainMenu)


func _on_close_pressed():
	get_tree().quit()


func _on_new_game_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file(TestMap)
