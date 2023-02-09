extends Node2D

onready var labels:Node2D = get_node("Labels");
onready var songData:Label = get_node("SongData");
onready var cursor:Node2D = get_node("Cursor");
onready var scrollLabel:Label = get_node("ScrollLabel");
onready var speedLabel:Label = get_node("SpeedLabel");
onready var controls:Array = [
	get_node("Left"),
	get_node("Right"),
	get_node("ScrollChange"),
	get_node("PlayBtn"),
	get_node("BackBtn"),
	get_node("SpeedChange")
];

const sizes:Array = [
	Vector2(80, 80), 
	Vector2(80, 80),
	Vector2(80, 80),
	Vector2(202, 74),
	Vector2(151.5, 55.5),
	Vector2(80, 80)
];

const NORMAL_COLOR:Color = Color(1, 1, 1, 1);
const HOVER_COLOR:Color = Color(1.1, 1.1, 1.1, 1);
const HOLD_HOVER_MUL:Color = Color(1.05, 1.05, 1.05, 1);

var selected:int = -1;
var songSelected:int = 0;
var songLabelRes:Resource = Assets.getScene("misc/LevelSelection");

func hookSignals():
# warning-ignore:return_value_discarded
	Controller.connect("mouseMove", self, "mouseMove");
# warning-ignore:return_value_discarded
	Controller.connect("mouseDown", self, "mouseDown");
# warning-ignore:return_value_discarded
	Controller.connect("mouseRelease", self, "mouseRelease");
	
# warning-ignore:return_value_discarded
	Controller.connect("touchDown", self, "touchDown");
# warning-ignore:return_value_discarded
	Controller.connect("touchRelease", self, "touchRelease");
	pass;

# warning-ignore:unused_argument
func touchDown(idx:int, pos:Vector2):
	mouseDown(0, pos);
	pass;

# warning-ignore:unused_argument
func touchRelease(idx:int, pos:Vector2):
	mouseRelease(0, pos);
	pass;

# warning-ignore:unused_argument
func mouseRelease(idx:int, pos:Vector2):
	if (idx == 0):
		for btn in controls:
			btn.modulate = NORMAL_COLOR;
		if (selected >= 0):
# warning-ignore:return_value_discarded
			Audio.play("hit", -6);
		match (selected):
			0:
				var labelMax:int = labels.get_child_count() - 1;
				songSelected -= 1;
				if (songSelected < 0):
					songSelected = labelMax;
				updateSongData();
			1:
				var labelMax:int = labels.get_child_count() - 1;
				songSelected += 1;
				if (songSelected > labelMax):
					songSelected = 0;
				updateSongData();
			2:
				Save.save.scroll += 1;
				if (Save.save.scroll == 0):
					Save.save.scroll += 1;
				if (Save.save.scroll > 1):
					Save.save.scroll = -1;
				Save.save();
				updateScroll();
			3:
				Riddem.curLevel = labels.get_child(songSelected).id;
# warning-ignore:return_value_discarded
				get_tree().change_scene_to(Assets.getScene("Play"));
			4:
# warning-ignore:return_value_discarded
				get_tree().change_scene_to(Assets.getScene("Menu"));
			5:
				Save.save.smidx += 1;
				if (Save.save.smidx > Riddem.speedMulList.size() - 1):
					Save.save.smidx = 0;
				Save.save();
				updateSmidx();
	pass;

func mouseDown(idx:int, pos:Vector2):
	if (idx == 0):
		var smthSelected:bool = false;
		for i in range(controls.size()):
			var btn:Sprite = controls[i];
# warning-ignore:integer_division
# warning-ignore:integer_division
			var posDiff:Vector2 = pos - (btn.position - sizes[i]);
			if (posDiff.x >= 0.0 && posDiff.y >= 0.0 && posDiff.x <= sizes[i].x * 2 && posDiff.y <= sizes[i].y * 2):
				btn.modulate = HOVER_COLOR * HOLD_HOVER_MUL;
				match (i):
					2, 5:
						btn.modulate.r8 = 192;
					3:
						btn.modulate.a8 = 128;
				selected = i;
				smthSelected = true;
			else:
				btn.modulate = NORMAL_COLOR;
		if (!smthSelected):
			selected = -1;
	pass;

func mouseMove(pos:Vector2):
	cursor.position = pos;
	
	var smthSelected:bool = false;
	
	for i in range(controls.size()):
		var btn:Sprite = controls[i];
# warning-ignore:integer_division
# warning-ignore:integer_division
		var posDiff:Vector2 = pos - (btn.position - sizes[i]);
		if (posDiff.x >= 0.0 && posDiff.y >= 0.0 && posDiff.x <= sizes[i].x * 2 && posDiff.y <= sizes[i].y * 2):
			btn.modulate = HOVER_COLOR;
			smthSelected = true;
		else:
			btn.modulate = NORMAL_COLOR;
	
	if (smthSelected):
		cursor.modulate.a8 = 64;
	else:
		cursor.modulate.a8 = 255;
	pass;

func updateSongData():
	var selectedId:String = labels.get_child(songSelected).id;
	if (Save.save.data[selectedId][0]):
		songData.text = "COMPLETED\nMisses: " + str(Save.save.data[selectedId][1]);
	else:
		songData.text = "NOT COMPLETED";
	pass;

func updateSmidx():
	speedLabel.text = "Speed: " + String(Riddem.speedMulList[Save.save.smidx]);
	pass;

func updateScroll():
	match (Save.save.scroll):
		-1:
			scrollLabel.text = "UPSCROLL";
		0:
			scrollLabel.text = "UNKNOWN";
		1:
			scrollLabel.text = "DOWNSCROLL";
	pass;

func _ready():
	Conductor.init();
	
	if (Audio.musPlaying != Riddem.MENU_SONG):
		Audio.stopAll();
# warning-ignore:return_value_discarded
		Audio.playMusic(Riddem.MENU_SONG);
	
	hookSignals();
	
	for i in range(Riddem.levelList.size()):
		var level:String = Riddem.levelList[i];
		var label:Node2D = songLabelRes.instance();
		label.target = i;
		label.id = level;
		labels.add_child(label);
		label.label.text = Riddem.metadataList[level].title;
	
	updateScroll();
	updateSongData();
	updateSmidx();
	pass;

func _process(_delta):
	for label in labels.get_children():
		label.targetScroll = songSelected;
	pass;

func _fixed_process(_delta):
	queue_free();
	pass;
