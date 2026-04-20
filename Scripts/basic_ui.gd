extends Control

signal axe_changed(pressed: bool)
signal pickaxe_changed(pressed: bool)
signal pumpjack_changed(pressed: bool)
signal rocket_changed(pressed: bool)
signal attack_changed(pressed: bool)

@onready var FpsCounter = $CanvasLayer/Fps
@onready var AxeBtn = $%Axe
@onready var PickaxeBtn = $%Pickaxe
@onready var PumpjackBtn = $%Pumpjack
@onready var RocketBtn = $%Rocket
@onready var AttackBtn = $%Attack

@onready var BasicAtkBtn = $%BasicAtk
@onready var AreaAtkBtn = $%AreaAtk
@onready var HeavyAtkBtn = $%HeavyAtk

@onready var Shadow = $%Shadow
@onready var Needle = $%Needle
@onready var Compass = $%Compass

@onready var main_scene = get_tree().current_scene

@onready var axe = preload("res://Art/Ui/85x85_ui_buttons_1.png")
@onready var axe_clicked = preload("res://Art/Ui/85x85_ui_buttons_clicked_1.png")
@onready var pickaxe = preload("res://Art/Ui/85x85_ui_buttons_2.png")
@onready var pickaxe_clicked = preload("res://Art/Ui/85x85_ui_buttons_clicked_2.png")
@onready var pumpjack = preload("res://Art/Ui/85x85_ui_buttons_3.png")
@onready var pumpjack_clicked = preload("res://Art/Ui/85x85_ui_buttons_clicked_3.png")
@onready var rocket = preload("res://Art/Ui/85x85_ui_buttons_4.png")
@onready var rocket_clicked = preload("res://Art/Ui/85x85_ui_buttons_clicked_4.png")
@onready var attack = preload("res://Art/Ui/85x85_ui_buttons_5.png")
@onready var attack_clicked = preload("res://Art/Ui/85x85_ui_buttons_clicked_5.png")

@onready var basic_atk = preload("res://Art/Ui/85x110_ui_buttons_battle_1.png")
@onready var basic_atk_clicked = preload("res://Art/Ui/85x110_ui_buttons_battle_clicked_1.png")
@onready var area_atk = preload("res://Art/Ui/85x110_ui_buttons_battle_2.png")
@onready var area_atk_clicked = preload("res://Art/Ui/85x110_ui_buttons_battle_clicked_2.png")
@onready var heavy_atk = preload("res://Art/Ui/85x110_ui_buttons_battle_3.png")
@onready var heavy_atk_clicked = preload("res://Art/Ui/85x110_ui_buttons_battle_clicked_3.png")



func _process(_delta):
	var fps: float = Engine.get_frames_per_second()
	FpsCounter.text = "FPS: " + str(fps)


# -------------------------
# MAP TOOLBELT
# -------------------------
func only_one_toggled(button):
	var buttons = [AxeBtn, PickaxeBtn, PumpjackBtn, RocketBtn, AttackBtn]

	for i in buttons:
		var btn = i.get_node("Button")

		if i != button:
			btn.set_pressed_no_signal(false)

			match i:
				AxeBtn: i.texture = axe
				PickaxeBtn: i.texture = pickaxe
				PumpjackBtn: i.texture = pumpjack
				RocketBtn: i.texture = rocket
				AttackBtn: i.texture = attack


func _on_axe_toggled(toggled_on):
	if toggled_on:
		AxeBtn.texture = axe_clicked
		only_one_toggled(AxeBtn)
		main_scene.axe_pressed = true
	else:
		AxeBtn.texture = axe
	emit_signal("axe_changed", toggled_on)
	print("axe changed to ", toggled_on)

func _on_pickaxe_toggled(toggled_on):
	if toggled_on:
		PickaxeBtn.texture = pickaxe_clicked
		only_one_toggled(PickaxeBtn)
	else:
		PickaxeBtn.texture = pickaxe
	emit_signal("pickaxe_changed", toggled_on)

func _on_pumpjack_toggled(toggled_on):
	if toggled_on:
		PumpjackBtn.texture = pumpjack_clicked
		only_one_toggled(PumpjackBtn)
	else:
		PumpjackBtn.texture = pumpjack
	emit_signal("pumpjack_changed", toggled_on)

func _on_rocket_toggled(toggled_on):
	if toggled_on:
		RocketBtn.texture = rocket_clicked
		only_one_toggled(RocketBtn)
	else:
		RocketBtn.texture = rocket
	emit_signal("rocket_changed", toggled_on)

func _on_attack_toggled(toggled_on):
	if toggled_on:
		AttackBtn.texture = attack_clicked
		only_one_toggled(AttackBtn)
	else:
		AttackBtn.texture = attack
	emit_signal("attack_changed", toggled_on)

# -------------------------
# BATTLE TOOLBELT
# -------------------------
func only_one_atk_toggled(button):
	var buttons = [BasicAtkBtn, AreaAtkBtn, HeavyAtkBtn]

	for i in buttons:
		var btn = i.get_node("Button")

		if i != button:
			btn.set_pressed_no_signal(false)

			match i:
				BasicAtkBtn: i.texture = basic_atk
				AreaAtkBtn: i.texture = area_atk
				HeavyAtkBtn: i.texture = heavy_atk


func _on_basic_atk_toggled(toggled_on):
	if toggled_on:
		BasicAtkBtn.texture = basic_atk_clicked
		only_one_atk_toggled(BasicAtkBtn)
	else:
		BasicAtkBtn.texture = basic_atk

func _on_area_atk_toggled(toggled_on):
	if toggled_on:
		AreaAtkBtn.texture = area_atk_clicked
		only_one_atk_toggled(AreaAtkBtn)
	else:
		AreaAtkBtn.texture = area_atk

func _on_heavy_atk_toggled(toggled_on):
	if toggled_on:
		HeavyAtkBtn.texture = heavy_atk_clicked
		only_one_atk_toggled(HeavyAtkBtn)
	else:
		HeavyAtkBtn.texture = heavy_atk
