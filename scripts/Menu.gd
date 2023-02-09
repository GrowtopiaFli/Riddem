extends Node2D

onready var icon:Sprite = get_node("Icon");
onready var cursor:Sprite = get_node("Cursor");
onready var options:Array = [
	get_node("Play"),
	get_node("Options"),
	get_node("Exit")
];

const GLOW_COL:Color = Color(0.25, 0.25, 0.25, 0);

const minDB:float = 60.0;
const minHZ:int = 80;
const maxHZ:int = 4096;

const NORMAL_COLOR:Color = Color(1, 1, 1, 1);
const HOVER_COLOR:Color = Color(1.2, 1.2, 1.2, 1);
const HOLD_HOVER_MUL:Color = Color(1.15, 1.15, 1.15, 1);

var spectrum:AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(1, 0);
var loudness:float = 0;

var selected:int = -1;

var prevTouchPos:Vector2 = Vector2(-1, -1);
var curTouchPos:Vector2 = Vector2(-1, -1);
var curTouchId:int = -1;
var outOfBounds:bool = false;
var touchBarrier:Vector2 = Vector2(5, 5);

func hookSignals():
# warning-ignore:return_value_discarded
	Controller.connect("mouseMove", self, "mouseMove");
# warning-ignore:return_value_discarded
	Controller.connect("mouseDown", self, "mouseDown");
# warning-ignore:return_value_discarded
	Controller.connect("mouseRelease", self, "mouseRelease");
	
# warning-ignore:return_value_discarded
	Controller.connect("touchPress", self, "touchPress");
# warning-ignore:return_value_discarded
	Controller.connect("touchDown", self, "touchDown");
# warning-ignore:return_value_discarded
	Controller.connect("touchRelease", self, "touchRelease");
	pass;

func touchPress(idx:int, pos:Vector2):
	if (curTouchId < 0):
		curTouchId = idx;
		curTouchPos = pos;
		prevTouchPos = curTouchPos;

func touchDown(idx:int, pos:Vector2):
	if (curTouchId == idx):
		cursor.position += pos - prevTouchPos;
		prevTouchPos = pos;
		var actualPosDiff:Vector2 = (curTouchPos - prevTouchPos).abs();
		if (actualPosDiff > touchBarrier):
			outOfBounds = true;
		if (!outOfBounds):
			mouseDown(0, cursor.position);
		else:
			mouseMove(cursor.position);

# warning-ignore:unused_argument
func touchRelease(idx:int, pos:Vector2):
	if (curTouchId == idx):
		curTouchId = -1;
		outOfBounds = false;
		mouseRelease(0, cursor.position);
		for i in range(options.size()):
			options[i].modulate = NORMAL_COLOR;

func mouseMove(pos:Vector2):
	cursor.position = pos;
	
	var smthSelected:bool = false;
	
	for i in range(options.size()):
		var opt:Label = options[i];
		var posDiff:Vector2 = pos - opt.rect_position;
		if ((posDiff.x >= 0.0 && posDiff.y >= 0.0) && (posDiff.x <= opt.rect_size.x && posDiff.y <= opt.rect_size.y)):
			opt.modulate = HOVER_COLOR;
			smthSelected = true;
		else:
			opt.modulate = NORMAL_COLOR;
	
	if (smthSelected):
		cursor.modulate.a8 = 64;
	else:
		cursor.modulate.a8 = 255;
	pass;

func mouseDown(idx:int, pos:Vector2):
	if (idx == 0):
		var smthSelected:bool = false;
		for i in range(options.size()):
			var opt:Label = options[i];
			var posDiff:Vector2 = pos - opt.rect_position;
			if ((posDiff.x >= 0.0 && posDiff.y >= 0.0) && (posDiff.x <= opt.rect_size.x && posDiff.y <= opt.rect_size.y)):
				opt.modulate = HOVER_COLOR * HOLD_HOVER_MUL;
				selected = i;
				smthSelected = true;
			else:
				opt.modulate = NORMAL_COLOR;
		if (!smthSelected):
			selected = -1;
	pass;

# warning-ignore:unused_argument
func mouseRelease(idx:int, pos:Vector2):
	if (idx == 0):
		if (selected >= 0):
# warning-ignore:return_value_discarded
			Audio.play("hit");
		match (selected):
			0:
# warning-ignore:return_value_discarded
				get_tree().change_scene_to(Assets.getScene("Selection"));
			1:
				if (!Riddem.isAndroid()):
# warning-ignore:return_value_discarded
					get_tree().change_scene_to(Assets.getScene("Options"));

				options[1].text = "Non Yet";
				options[1].rect_position.x = 960 - (options[1].rect_size.x / 2);
			2:
				get_tree().quit();
	pass;

func _ready():
	Conductor.init();
	
	if (Riddem.isAndroid()):
		cursor.position = icon.position;
	
	if (Audio.musPlaying != Riddem.MENU_SONG):
		Audio.stopAll();
# warning-ignore:return_value_discarded
		Audio.playMusic(Riddem.MENU_SONG);
	
	hookSignals();
	pass;

func _process(_delta):
	loudness = clamp((minDB + linear2db(spectrum.get_magnitude_for_frequency_range(minHZ, maxHZ).length())) / minDB, 0, 1);
	icon.scale = Vector2.ONE + (Vector2(loudness, loudness) / 2);
	icon.modulate = Riddem.ColorHSV(360.0 * loudness, 100, 88).rgb + GLOW_COL;
	pass;

func _fixed_process(_delta):
	queue_free();
	pass;
