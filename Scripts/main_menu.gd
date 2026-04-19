extends Control

@onready var TestMap = "res://Scenes/TestMap.tscn"

func _on_new_game_pressed():
	pass # Replace with function body.


func _on_load_game_pressed():
	#TEMPORARY
	get_tree().change_scene_to_file(TestMap)


func _on_settings_pressed():
	pass # Replace with function body.


func _on_exit_pressed():
	get_tree().quit()
