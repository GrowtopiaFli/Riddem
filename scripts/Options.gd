extends Node2D

onready var strumWrapper:Node2D = get_node("Strums");
onready var box:ColorRect = strumWrapper.get_node("BoxWrapper/Box");
onready var vbNode:Node2D = get_node("VB");
onready var vb:ColorRect = vbNode.get_node("Bar");
onready var vbLabel:Label = vb.get_node("Label");
onready var strums:Array = [
	strumWrapper.get_node("1"),
	strumWrapper.get_node("2"),
	strumWrapper.get_node("3"),
	strumWrapper.get_node("4")
];
onready var strumLabels:Array = [
	strums[0].get_node("Label"),
	strums[1].get_node("Label"),
	strums[2].get_node("Label"),
	strums[3].get_node("Label")
];

const GLOW_COL:Color = Color(0.15, 0.15, 0.15, 0);

const minDB:float = 60.0;
const minHZ:int = 80;
const maxHZ:int = 4096;

const keybinds:Dictionary = {
	"Left": -1,
	"Right": 1
}

var spectrum:AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(1, 0);
var loudness:float = 0;

var selected:int = 0;
var boxSelected:int = 0;
var editMode:bool = false;

func _ready():
	Conductor.init();
	if (Audio.musPlaying != Riddem.MENU_SONG):
		Audio.stopAll();
# warning-ignore:return_value_discarded
		Audio.playMusic(Riddem.MENU_SONG);
	
	updateText();
	updateVText();
	pass;

func keyPress(key:String):
	match (key):
		"Escape":
# warning-ignore:return_value_discarded
			Audio.play("hit");
# warning-ignore:return_value_discarded
			get_tree().change_scene_to(Assets.getScene("Menu"));
		"Up":
# warning-ignore:return_value_discarded
			Audio.play("hit", -9);
			selected -= 1;
		"Down":
# warning-ignore:return_value_discarded
			Audio.play("hit", -9);
			selected += 1;
	if (selected > 1):
		selected = 0;
	if (selected < 0):
		selected = 1;
	if (selected > 0):
		editMode = false;
		box.modulate.r8 = 255;
		box.modulate.g8 = 255;
		box.modulate.a8 = 80;
	if (!editMode):
		if (keybinds.has(key)):
			match (selected):
				0:
# warning-ignore:return_value_discarded
					Audio.play("hit", -12);
					boxSelected += keybinds[key];
					if (boxSelected > 3):
						boxSelected = 0;
					if (boxSelected < 0):
						boxSelected = 3;
				1:
# warning-ignore:return_value_discarded
					Audio.play("hit", -6);
					Riddem.volume += keybinds[key] * 0.05;
					if (Riddem.volume > 1):
						Riddem.volume = 1;
					if (Riddem.volume < 0):
						Riddem.volume = 0;
					Save.updateVolume();
					updateVText();
		if (key == "Enter"):
# warning-ignore:return_value_discarded
			Audio.play("hit", -10);
			editMode = true;
			box.modulate.r8 = 255;
			box.modulate.g8 = 160;
			box.modulate.a8 = 128;
	else:
		if (Riddem.KEYS_ALLOWED.find(key) != -1):
			if (Riddem.KEY_MAP.has(key)):
				var swapIdx:int = Riddem.KEY_MAP.find(key);
				var swapKey:String = Riddem.KEY_MAP[boxSelected];
				Riddem.KEY_MAP[boxSelected] = key;
				Riddem.KEY_MAP[swapIdx] = swapKey;
			else:
				Riddem.KEY_MAP[boxSelected] = key;
			Save.updateKeys();
			updateText();
		editMode = false;
		box.modulate.r8 = 255;
		box.modulate.g8 = 255;
		box.modulate.a8 = 80;
	pass;

func _input(evt):
	if (evt is InputEventKey):
		var key:String = OS.get_scancode_string(evt.scancode);
		if (evt.pressed):
			keyPress(key);
	pass;

func updateText():
	for i in range(strumLabels.size()):
		strumLabels[i].text = Riddem.KEY_MAP[i];
	pass;

func updateVText():
	vbLabel.text = "Volume: " + String(Riddem.volume * 100) + "%";
	pass;

func _process(_delta):
	loudness = clamp((minDB + linear2db(spectrum.get_magnitude_for_frequency_range(minHZ, maxHZ).length())) / minDB, 0, 1);
	var daScale:Vector2 = Vector2(0.75, 0.75) + (Vector2(loudness, loudness) * 0.25);
	var daColor:Color = Riddem.ColorHSV(360.0 * loudness, 100, 88).rgb + GLOW_COL;
	for strum in strums:
		strum.scale = daScale;
		strum.self_modulate = daColor;
	box.visible = selected == 0;
	if (box.visible):
		box.rect_position.x = lerp(box.rect_position.x, boxSelected * 200, 0.15);
	vb.rect_size.x = lerp(vb.rect_size.x, Riddem.volume * 606.0, 0.1);
	vbNode.modulate.a8 = lerp(vbNode.modulate.a8, 50 + (selected * 205), 0.2);
	pass;
