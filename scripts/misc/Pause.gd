extends Node2D

onready var overlay:Node2D = get_node("Overlay");
onready var btn:Sprite = get_node("Sprite");
onready var menuBtn:Sprite = overlay.get_node("Btn");

# warning-ignore:unused_argument
func touchDown(idx:int, pos:Vector2):
	var posDiff:Vector2 = pos - btn.position;
	if (posDiff.x >= 0 && posDiff.x <= 128 && posDiff.y >= 0 && posDiff.y <= 128):
		btn.modulate.a8 = 128;
	else:
		btn.modulate.a8 = 255;
	if (get_tree().paused):
		var secPosDiff:Vector2 = pos - (menuBtn.position - Vector2(202, 74));
		if (secPosDiff.x >= 0 && secPosDiff.x <= 404 && secPosDiff.y >= 0 && secPosDiff.y <= 148):
			menuBtn.modulate.a8 = 128;
		else:
			menuBtn.modulate.a8 = 255;
	pass;

# warning-ignore:unused_argument
func touchRelease(idx:int, pos:Vector2):
	var posDiff:Vector2 = pos - btn.position;
	if (posDiff.x >= 0 && posDiff.x <= 128 && posDiff.y >= 0 && posDiff.y <= 128):
		btn.modulate.a8 = 255;
		togglePause();
	if (get_tree().paused):
		var secPosDiff:Vector2 = pos - (menuBtn.position - Vector2(202, 74));
		if (secPosDiff.x >= 0 && secPosDiff.x <= 404 && secPosDiff.y >= 0 && secPosDiff.y <= 148):
			menuBtn.modulate.a8 = 255;
			menu();
	pass;

func menu():
	togglePause();
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(Assets.getScene("Selection"));
	pass;

func togglePause():
	get_tree().paused = !get_tree().paused;
	overlay.visible = get_tree().paused;
	pass;

func keyPress(key:String):
	match (key):
		"Enter":
			togglePause();
		"Escape":
			if (get_tree().paused):
				menu();
	pass;

func hookSignals():
# warning-ignore:return_value_discarded
	Controller.connect("keyPress", self, "keyPress");
	
# warning-ignore:return_value_discarded
	Controller.connect("touchDown", self, "touchDown");
# warning-ignore:return_value_discarded
	Controller.connect("touchRelease", self, "touchRelease");
	pass;

func _ready():
	if (Riddem.isAndroid()):
		btn.visible = true;
	else:
		overlay.get_node("PCLabel").visible = true;
	hookSignals();
	pass;
