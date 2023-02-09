extends Node

var savePath:String = "riddem.save";
var save:Dictionary = {
	"version": 1.0,
	"scroll": -1,
	"smidx": 0,
	"data": {},
	"keybind": ["D", "F", "J", "K"],
	"volume": 1.0
};

# warning-ignore:function_conflicts_variable
func save():
	var f:File = File.new();
	var err:bool = f.open_compressed("user://" + savePath, File.WRITE, File.COMPRESSION_ZSTD) != OK;
	if (!err):
		var json:String = JSON.print(save);
		f.store_string(json);
		f.close();

func updateData(level:String, misses:int):
	if (!save.data[level][0]):
		save.data[level][0] = true;
		save.data[level][1] = misses;
		save();
		return;
	
	if (misses < save.data[level][1]):
		save.data[level][1] = misses;
		save();
	pass;

func updateKeys():
	Save.save.keybind = Riddem.KEY_MAP;
	save();
	pass;

func updateVolume():
	Save.save.volume = Riddem.volume;
	save();
	Audio.updateVolume();
	pass;

func loadKeys():
	Riddem.KEY_MAP = Save.save.keybind;
	pass;

func loadVolume():
	Riddem.volume = Save.save.volume;
	Audio.updateVolume();
	pass;

func _ready():
	for level in Riddem.levelList:
		save.data[level] = [false, 0];
	var f:File = File.new();
	var err:bool = f.open_compressed("user://" + savePath, File.READ, File.COMPRESSION_ZSTD) != OK;
	if (!err):
		var res:JSONParseResult = JSON.parse(f.get_as_text());
		f.close();
		if (res.error == OK):
			if (res.result is Dictionary):
				var result:Dictionary = res.result;
				if (result.has("version")):
					if (save.version == result.version):
						for key in save.keys():
							if (result.has(key)):
								match (typeof(save[key])):
									TYPE_INT:
										save[key] = int(result[key]);
									TYPE_STRING:
										save[key] = str(result[key]);
									TYPE_REAL:
										save[key] = float(result[key]);
									_:
										if (typeof(save[key]) == TYPE_DICTIONARY && typeof(result[key]) == TYPE_DICTIONARY):
											for dKey in save[key].keys():
												if (result[key].has(dKey)):
													save[key][dKey] = result[key][dKey];
										else:
											save[key] = result[key];
	loadKeys();
	loadVolume();
	pass;
