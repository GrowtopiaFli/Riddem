extends Node

signal keyPress(key);
signal keyDown(key);
signal keyRelease(key);

signal mouseMove(pos);
signal mouseScroll(idx, pos);
signal mousePress(idx, pos);
signal mouseDown(idx, pos);
signal mouseRelease(idx, pos);

signal touchPress(pos);
signal touchDown(pos);
signal touchRelease(pos);

const keys:Array = [];
const mouse:Array = [false, false, false];

var mPos:Vector2 = Vector2(-1, -1);
var tPos:Dictionary = {};

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN);
	pass;

func _process(_delta):
	for key in keys:
		emit_signal("keyDown", key);
	for i in range(mouse.size()):
		if (mouse[i]):
			emit_signal("mouseDown", i, mPos);
	for tId in tPos.keys():
		emit_signal("touchDown", tId, tPos[tId]);
	pass;

func _input(evt):
	if (evt is InputEventKey):
		var key:String = OS.get_scancode_string(evt.scancode);
		if (evt.pressed):
			if (!keys.has(key)):
				keys.append(key);
				emit_signal("keyPress", key);
		else:
			if (keys.has(key)):
				keys.remove(keys.find(key));
			emit_signal("keyRelease", key);
	if (evt is InputEventMouseMotion):
		mPos = evt.position;
		emit_signal("mouseMove", mPos);
	if (evt is InputEventMouseButton):
		mPos = evt.position;
		var idx:int = evt.button_index - 1;
		if (idx in range(3)):
			if (evt.pressed):
				if (!mouse[idx]):
					mouse[idx] = true;
					emit_signal("mousePress", idx, mPos);
			else:
				mouse[idx] = false;
				emit_signal("mouseRelease", idx, mPos);
		elif (idx < 5):
			idx -= 3;
			emit_signal("mouseScroll", idx, mPos);
	if (evt is InputEventScreenTouch):
		if (evt.pressed):
			if (!tPos.has(evt.index)):
				tPos[evt.index] = evt.position;
				emit_signal("touchPress", evt.index, evt.position);
		else:
			if (tPos.has(evt.index)):
# warning-ignore:return_value_discarded
				tPos.erase(evt.index);
			emit_signal("touchRelease", evt.index, evt.position);
	if (evt is InputEventScreenDrag):
		tPos[evt.index] = evt.position;
	pass;
