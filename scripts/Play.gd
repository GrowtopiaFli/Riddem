extends Node

onready var wrapper:Node2D = get_node("Wrapper");
onready var strums:Node2D = wrapper.get_node("Strums");
onready var orbs:Node2D = wrapper.get_node("Orbs");
onready var mirrorOrbs:Node2D = wrapper.get_node("MirrorOrbs");
onready var borders:Node2D = get_node("Borders");
onready var pb:ColorRect = get_node("Prog/Bar");
onready var bar:ColorRect = get_node("HB/Bar");
onready var icon:Sprite = get_node("Icon");
onready var missCounter:Label = get_node("MissCounter");
onready var metaWrapper:Node2D = get_node("MetaWrapper");
onready var title:Label = metaWrapper.get_node("Title");
onready var artist:Label = metaWrapper.get_node("Artist");

onready var timer:Timer = get_node("Timer");
onready var tween:Tween = get_node("Tween");

var spectrum:AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(1, 0);
var loudness:float = 0;

var misses:int = 0;

const GLOW_COL:Color = Color(0.25, 0.25, 0.25, 0);

const minDB:float = 60.0;
const minHZ:int = 80;
const maxHZ:int = 4096;

var strumRes:Resource = Assets.getScene("misc/Strum");
var orbRes:Resource = Assets.getScene("misc/Orb");

var strumList:Array = [];
var stepList:Array = [];
var orbList:Array = [];
var inputOrbs:Array = [];

var levelName:String = "";
var genStep:int = 0;
var bpm:int = 130;
var speed:float = 1;
var health:float = 1;
var barDefPos:int = 10;
var barMaxSize:int = 610;

var levelData:Dictionary = {};

var song:AudioStreamPlayer;
var songMetadata:Dictionary = {};

var curSteps:float = 0;
var songPos:float = 0;

var androidPressed:Array = [false, false, false, false];
var androidTouches:Array = [[], [], [], []];

# warning-ignore:unused_argument
func hit(id:int = -1):
	health += 0.025;
	if (health > 1.0):
		health = 1.0;
	Audio.play("hit", -2);
	pass;

# warning-ignore:unused_argument
func missed(id:int = -1):
	health -= 0.05;
	if (health < 0.0):
		health = 0.0;
	misses += 1;
	pass;

func keyPress(key):
	var idx:int = Riddem.KEY_MAP.find(key);
	if (idx != -1):
		var exemptNext:bool = false;
		for strum in strumList:
			if (strum.id == idx):
				strum.press();
				for orb in inputOrbs:
					if (weakref(orb).get_ref()):
						var orbPos:float = orb.steps - curSteps;
						if  (orbPos >= -Riddem.STEP_THRES && orbPos <= Riddem.STEP_THRES):
							if (orb.id == idx):
								strum.glow();
								hit(orb.id);
								inputOrbs.remove(inputOrbs.find(orb));
								if (stepList.has(orb.steps)):
									stepList.remove(stepList.find(orb.steps));
								orbs.remove_child(orb);
								orb.queue_free();
								orb.call_deferred("free");
								exemptNext = true;
							else:
								var exemption:bool = false;
								for curOrb in inputOrbs:
									if (weakref(curOrb).get_ref()):
										var stepDiff:float = orb.steps - curOrb.steps;
										if (curOrb.id == idx && stepDiff >= 0 && stepDiff <= Riddem.ORB_ACCEPT_THRES):
											exemption = true;
											break;
								if (!exemption && !exemptNext):
									missed(orb.id);
								if (exemptNext):
									exemptNext = false;
	pass;

func keyRelease(key):
	var idx:int = Riddem.KEY_MAP.find(key);
	if (idx != -1):
		for strum in strumList:
			if (strum.id == idx):
				strum.reset();
	pass;

func startSong():
	Conductor.songPos = 0;
# warning-ignore:return_value_discarded
	tween.interpolate_property(title, "modulate", title.modulate, Color8(0, 0, 0, 0), 0.5);
# warning-ignore:return_value_discarded
	tween.interpolate_property(artist, "modulate", artist.modulate, Color8(0, 0, 0, 0), 0.5);
	if (Riddem.isAndroid()):
# warning-ignore:return_value_discarded
		tween.interpolate_property(get_node("Pause/Sprite"), "self_modulate", Color8(0, 0, 0, 0), Color8(255, 255, 255, 255), 0.5);
# warning-ignore:return_value_discarded
	tween.start();
	song.play();
	pass;

# warning-ignore:unused_argument
func touchDown(idx:int, pos:Vector2):
# warning-ignore:narrowing_conversion
	var partTouched:int = clamp(floor(pos.x / 480.0), 0, 3);
	if (!androidPressed[partTouched]):
		androidPressed[partTouched] = true;
		for i in range(androidTouches.size()):
			var touch:Array = androidTouches[i];
			if (i == partTouched):
				if (!touch.has(idx)):
					touch.append(idx);
			else:
				if (touch.has(idx)):
					touch.remove(touch.find(idx));
					androidPressed[i] = false;
					keyRelease(Riddem.KEY_MAP[i]);
		keyPress(Riddem.KEY_MAP[partTouched]);
	pass;

# warning-ignore:unused_argument
func touchRelease(idx:int, pos:Vector2):
# warning-ignore:narrowing_conversion
	var partTouched:int = clamp(floor(pos.x / 480.0), 0, 3);
	androidPressed[partTouched] = false;
	keyRelease(Riddem.KEY_MAP[clamp(floor(pos.x / 480.0), 0, 3)]);
	pass;

func hookSignals():
# warning-ignore:return_value_discarded
	Controller.connect("keyPress", self, "keyPress");
#	Controller.connect("keyDown", self, "keyDown");
# warning-ignore:return_value_discarded
	Controller.connect("keyRelease", self, "keyRelease");
	
## warning-ignore:return_value_discarded
#	Controller.connect("touchPress", self, "touchPress");
# warning-ignore:return_value_discarded
	Controller.connect("touchDown", self, "touchDown");
# warning-ignore:return_value_discarded
	Controller.connect("touchRelease", self, "touchRelease");

# warning-ignore:return_value_discarded
	timer.connect("timeout", self, "startSong");
# warning-ignore:return_value_discarded
	Conductor.connect("finished", self, "endSong");
	pass;

func endSong():
	Save.updateData(levelName, misses);
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(Assets.getScene("Selection"));
	pass;

func loadLevel():
	var levelStr:String = Assets.getDat("levels/" + levelName + "/level", false, true).replace("\n", "");
	bpm = int(levelStr.split("-")[1]);
	levelStr = levelStr.split("-")[0];
	
	for i in levelStr:
		match (i):
			"/":
				genStep += 4;
			"=":
				genStep += 1;
			_:
				if (!levelData.has(genStep)):
					levelData[genStep] = [];
				levelData[genStep].append(int(i));
	
	songMetadata = Riddem.metadataList[levelName];
	speed = songMetadata.speed;
	title.text = songMetadata.title;
	artist.text = "by\n" + songMetadata.artist;
	
# warning-ignore:return_value_discarded
	tween.interpolate_property(metaWrapper, "position", metaWrapper.position, Vector2.ZERO, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.25);
# warning-ignore:return_value_discarded
	tween.start();
	
	song = Audio.loadMusic(levelName, 0, false);
	Conductor.init(song, bpm);
	
	stepList = levelData.keys();
	stepList.sort();
	
	for orbSteps in stepList:
		for orbId in levelData[orbSteps]:
			var orbTime:float = orbSteps * Conductor.stepSecs;
			orbList.append({
				"id": orbId,
				"steps": orbSteps,
				"time": orbTime,
				"targetPos": Riddem.STRUM_MAPPING[orbId] * Riddem.STRUM_MARGIN
			});
	pass;

func fixWrapper():
	wrapper.position.y += 412 * Save.save.scroll;
	match (Save.save.scroll):
		-1:
			mirrorOrbs.modulate.a8 = 50;
		1:
			orbs.modulate.a8 = 50;
	pass;

func _ready():
	Conductor.init();
	Audio.stopAll();
	
	if (Riddem.isAndroid()):
		borders.visible = true;

	hookSignals();
	
	levelName += Riddem.curLevel;

	for i in range(4):
		var strum:Node2D = strumRes.instance();
		strums.add_child(strum);
		strum.strum.rotation_degrees = Riddem.STRUM_DEGS[i];
		strum.modulate = Riddem.COLORS[i];
		strum.init();
		strum.id = i;
		strum.position = Riddem.STRUM_MAPPING[i] * Riddem.STRUM_MARGIN;
		strumList.append(strum);
	
	loadLevel();
	
	Conductor.songPos = -3;
	Conductor.startPlaying();
	timer.start(3);
	
	fixWrapper();
	if (Save.save.scroll == 0):
		speed /= 1.5;
	speed *= Riddem.speedMulList[Save.save.smidx];
	pass;

func updateOrbs():
	curSteps = Conductor.getSteps();
	songPos = Conductor.getPosition();
	
	if (orbList.size() > 0):
		var orbData:Dictionary = orbList[0];
		var diff:float = (orbData.time - songPos) - ((16.0 / speed) * Conductor.stepSecs);
		if (diff <= 0.0):
			var orb:Node2D = orbRes.instance();
			orb.id = orbData.id;
			orb.steps = orbData.steps;
			orb.time = orbData.time;
			orb.targetPos = orbData.targetPos;
			orb.position = Vector2(2048, 2048);
			orb.init();
			orbs.add_child(orb);
			
			var mirrorOrb:Node2D = orbRes.instance();
			mirrorOrb.id = orbData.id;
			mirrorOrb.steps = orbData.steps;
			mirrorOrb.time = orbData.time;
			mirrorOrb.targetPos = orbData.targetPos;
			mirrorOrb.position = Vector2(2048, 2048);
			mirrorOrb.init();
			mirrorOrbs.add_child(mirrorOrb);
			
			orbList.pop_front();
	
	for orb in orbs.get_children():
		curSteps = Conductor.getSteps();
		var posOffset:float = (orb.steps - curSteps) * (Riddem.STRUM_SIZE * speed);
		orb.position.x = orb.targetPos.x;
#		if ([0, 1].has(orb.id)):
#			orb.position.y = orb.targetPos.y - posOffset;
#		else:
		orb.position.y = orb.targetPos.y + posOffset;
		if (!inputOrbs.has(orb)):
			inputOrbs.append(orb);
		if (orb.position.y + Riddem.STRUM_SIZE <= 0.0):
			missed(orb.id);
			if (stepList.has(orb.steps)):
				stepList.remove(stepList.find(orb.steps));
			orbs.remove_child(orb);
			orb.queue_free();
			orb.call_deferred("free");
	
	for orb in mirrorOrbs.get_children():
		curSteps = Conductor.getSteps();
		var posOffset:float = (orb.steps - curSteps) * (Riddem.STRUM_SIZE * speed);
		orb.position.x = orb.targetPos.x;
		orb.position.y = orb.targetPos.y - posOffset;
		if (!stepList.has(orb.steps)):
			mirrorOrbs.remove_child(orb);
			orb.queue_free();
			orb.call_deferred("free");
	pass;

func updateHealth():
	bar.rect_size.y = barMaxSize * health;
	bar.rect_position.y = barDefPos + (barMaxSize - bar.rect_size.y);
	if (health <= 0.0):
# warning-ignore:return_value_discarded
		get_tree().change_scene_to(Assets.getScene("GameOver"));
	pass;

func updatePos():
	pb.rect_size.x = 278 * (Conductor.getPosition() / Conductor.getLength());
	pass;

func updateMisses():
	missCounter.text = "Misses: " + String(misses);
	pass;

func _process(_delta):
	loudness = clamp((minDB + linear2db(spectrum.get_magnitude_for_frequency_range(minHZ, maxHZ).length())) / minDB, 0, 1);
	icon.scale = Vector2.ONE + (Vector2(loudness, loudness) / 2);
	icon.modulate = Riddem.ColorHSV(360.0 * loudness, 100, 88).rgb + GLOW_COL;
	
	updateHealth();
	updateMisses();
	updateOrbs();
	
	if (!Conductor.songInvalid()):
		updatePos();
	pass;

func _fixed_process(_delta):
	queue_free();
	pass;
