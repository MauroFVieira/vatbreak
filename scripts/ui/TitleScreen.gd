extends Control

# ──────────────────────────────────────────────
#  TitleScreen.gd
# ──────────────────────────────────────────────

@onready var start_button: Button = $VBoxContainer/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	start_button.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()
