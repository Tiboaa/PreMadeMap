extends Control

@onready var MainMenuBtn = $CanvasLayer/MainMenuBtn/Button
@onready var MainMenu = "res://Scenes/MainMenu.tscn"
# Called when the node enters the scene tree for the first time.

func _on_exit_to_main_menu():
	get_tree().change_scene_to_file(MainMenu)
