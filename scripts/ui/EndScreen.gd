extends Control

# ──────────────────────────────────────────────
#  EndScreen.gd
#  Shown on win. Displays elapsed time.
# ──────────────────────────────────────────────

@onready var time_label:    Label  = $VBoxContainer/TimeLabel
@onready var again_button:  Button = $VBoxContainer/PlayAgainButton
@onready var title_button:  Button = $VBoxContainer/TitleButton


func _ready() -> void:
	time_label.text = "Containment restored in %s" % GameState.get_elapsed_formatted()
	again_button.pressed.connect(_on_play_again)
	title_button.pressed.connect(_on_go_title)
	again_button.grab_focus()


func _on_play_again() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_go_title() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
