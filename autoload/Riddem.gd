extends Node

const COLORS:Array = [
	Color8(255, 255, 192, 255),
	Color8(192, 255, 255, 255),
	Color8(255, 192, 192, 255),
	Color8(192, 255, 192, 255)
];

const STRUM_MARGIN:int = 100;
const STRUM_MAPPING:Array = [
	Vector2(-3, 0),
	Vector2(-1, 0),
	Vector2(1, 0),
	Vector2(3, 0)
];
const STRUM_DEGS:Array = [
	270,
	90,
	270,
	90
]

const DEFSTR_ALPHA:int = 100;
const STR_GLOW:float = 0.175;

const MUS_DEL_THRES:float = 0.1;

const STRUM_SIZE:float = 160.0;
const ORB_SIZE:float = 128.0;
const OFF_ORB_SIZE:float = (ORB_SIZE / 2) + (STRUM_SIZE / 2);

const STEP_MISS_OFFSET:float = 0.6;
const ORB_ACCEPT_THRES:float = 0.1;

const MENU_SONG:String = "byte (lowpass)";

const levelList:Array = [
#	"groundzero",
	"storm",
	"bb2016",
	"failure",
	"out",
#	"sunrise",
	"echo",
	"byte",
	"smile",
	"emo",
	"impulse",
	"headache",
	"glass",
	"dotv"
];

const metadataList:Dictionary = {
#	"groundzero": {"artist": "GWeb & Duckstuffed", "title": "Ground Zero", "speed": 1.25},
	"storm": {"artist": "GWeb", "title": "Storm", "speed": 1.5},
	"bb2016": {"artist": "GWeb", "title": "Bring Back 2016", "speed": 1.8},
	"failure": {"artist": "GWeb", "title": "Failure", "speed": 1.5},
#	"sunrise": {"artist": "GWeb", "title": "Sunrise", "speed": 1.25},
	"echo": {"artist": "GWeb", "title": "Echo", "speed": 1.5},
	"out": {"artist": "GWeb", "title": "Out", "speed": 1.5},
	"byte": {"artist": "GWeb", "title": "Byte", "speed": 1.75},
	"smile": {"artist": "GWeb", "title": "Smile", "speed": 2},
	"emo": {"artist": "GWeb", "title": "Emo", "speed": 1.5},
	"impulse": {"artist": "GWeb", "title": "Impulse", "speed": 1.5},
	"headache": {"artist": "GWeb", "title": "Headache", "speed": 1.75},
	"glass": {"artist": "GWeb", "title": "Glass", "speed": 1.5},
	"dotv": {"artist": "GWeb", "title": "F-777 - Dance Of The Violins (GWeb Remix)", "speed": 1.75}
};

const speedMulList:Array =[
	1.0,
	0.9,
	0.8,
	0.75,
	0.6,
	0.5,
	1.1,
	1.25
];

const STEP_THRES:float = 0.75;

const KEYS_ALLOWED:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789;',.\"/][{}]|\\`~-_=+";

var KEY_MAP:Array = [];
var volume:float = 0;
var curLevel:String = "";

func ColorHSV(h:float = 360, s:float = 0, v:float = 100, a:float = 1) -> Dictionary:
	# stol-
	# i mean borrowed and modified from https://www.reddit.com/r/godot/comments/ajll6t/create_color_from_hsv_values/
	
	# original comments:
	# based on code at
	# http://stackoverflow.com/questions/51203917/math-behind-hsv-to-rgb-conversion-of-colors
	
	if (h > 360):
		h = 360;
	if (h < -360):
		h = -360;
	if (s > 100):
		s = 100;
	if (v > 100):
		v = 100;
	if (s < 0):
		s = 0;
	if (v < 0):
		v = 0;
	if (a > 1):
		a = 1;
	if (a < 0):
		a = 0;
	
	var hsv:Array = [0 + h, 0 + s, 0 + v];
	
	h /= 360;
	s /= 100;
	v /= 100;
	
	var r:float = 0;
	var g:float = 0;
	var b:float = 0;

	var i:float = floor(h * 6);
	var f:float = h * 6 - i;
	var p:float = v * (1 - s);
	var q:float = v * (1 - f * s);
	var t:float = v * (1 - (1 - f) * s);

	match (int(i) % 6):
		0:
			r = v;
			g = t;
			b = p;
		1:
			r = q;
			g = v;
			b = p;
		2:
			r = p;
			g = v;
			b = t;
		3:
			r = p;
			g = q;
			b = v;
		4:
			r = t;
			g = p;
			b = v;
		5:
			r = v;
			g = p;
			b = q;
	
	var dict:Dictionary = {
		"rgb": Color(r, g, b, a),
		"hsv": hsv
	};
	
	return dict;

## Reference: https://gist.github.com/andrew-wilkes/cdca96f8f148da13694983476a703cc1
#func getOGGMetadata(path:String) -> Dictionary:
#	var data:PoolByteArray = Assets.getBytes(Assets.extify("music/" + path, "ogg"));
#	var info:Dictionary = { "artist": "", "title": "" };
#	# Locate the comments header, it is where the second "vorbis" octet stream occurs
#	var hex:String = data.subarray(0, 0x100).hex_encode();
#	var idx:int = hex.find("766f72626973");
#	if (idx > 0):
## warning-ignore:integer_division
#		idx = hex.find("766f72626973", idx + 6) / 2 + 6;
#		# Let's just use the 1st byte of the 32-bit length values for the length
#		# Skip over vendor_string
#		idx += data[idx] + 4;
#		var num_comments:int = data[idx];
#		idx += 4;
#		for n in num_comments:
#			var commentLength = data[idx];
#			idx += 4;
#			var comment:String = data.subarray(idx, idx + commentLength - 1).get_string_from_utf8();
#			var tagVal:Array = comment.split("=");
#			if (tagVal.size() == 2):
#				var tag:String = tagVal[0].to_lower();
#				match (tag):
#					"artist":
#						info["artist"] = tagVal[1];
#					"title":
#						info["title"] = tagVal[1];
#			idx += commentLength;
#	return info;

func isAndroid():
	return OS.get_name() == "Android";

var android:Dictionary = {
	"songPlaying": "",
	"menuSongPos": 0.0
};

func _ready():
#	for levelName in levelList:
#		metadataList[levelName] = getOGGMetadata(levelName);
	pass;
