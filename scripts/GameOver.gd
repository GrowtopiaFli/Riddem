extends Node2D

onready var cursor:Sprite = get_node("Cursor");
onready var options:Array = [
	get_node("GB"),
	get_node("Retry")
];

const NORMAL_COLOR:Color = Color(1, 1, 1, 1);
const HOVER_COLOR:Color = Color(1.25, 1, 1.25, 1);
const HOLD_HOVER_MUL:Color = Color(1.15, 1, 1.15, 1);

var selected:int = -1;

var prevTouchPos:Vector2 = Vector2(-1, -1);
var curTouchPos:Vector2 = Vector2(-1, -1);
var curTouchId:int = -1;
var outOfBounds:bool = false;
var touchBarrier:Vector2 = Vector2(5, 5);

func mouseMove(pos:Vector2):
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
			Audio.play("hit", -5);
		match (selected):
			0:
# warning-ignore:return_value_discarded
				get_tree().change_scene_to(Assets.getScene("Selection"));
			1:
# warning-ignore:return_value_discarded
				get_tree().change_scene_to(Assets.getScene("Play"));
	pass;

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

func _ready():
	Conductor.init();
	Audio.stopAll();
	
	if (Riddem.isAndroid()):
		cursor.position = Vector2(960, 540);
	
	hookSignals();
	
# warning-ignore:return_value_discarded
	Audio.play("hit");
	pass;

func _process(_delta):
	if (!Riddem.isAndroid()):
		cursor.position = Controller.mPos;
	pass;
