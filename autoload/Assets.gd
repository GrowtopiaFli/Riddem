extends Node

var assets:Dictionary = {};
var manifest:PoolStringArray = [];

var assetPath:String = "res://assets/";
var importExt:String = ".import";

func errNotFound():
	print("ERR: Asset Not Found!");

func fetch(path:String):
	path = path.to_lower();
	for i in range(manifest.size()):
		var curFilePath:String = manifest[i];
		var absPath:String = assetPath + curFilePath;
		if (curFilePath.to_lower().ends_with(path)):
			if (!assets.has(curFilePath)):
				assets[curFilePath] = load(absPath);
			if (assets[curFilePath] == null):
				var f:File = File.new();
				var err:bool = f.open(absPath, File.READ) != OK;
				if (!err):
					assets[curFilePath] = f.get_buffer(f.get_len());
					f.close();
			return [assets[curFilePath], absPath];
	return [null, ""];

func extify(a:String = "", b:String = "") -> String:
	return b + "/" + a + "." + b;

func getBytes(path:String = "") -> PoolByteArray:
	path = path.to_lower();
	for i in range(manifest.size()):
		var curFilePath:String = manifest[i];
		if (curFilePath.to_lower().ends_with(path)):
			var absPath:String = assetPath + curFilePath;
			var f:File = File.new();
			var err:bool = f.open(absPath, File.READ) != OK;
			if (!err):
				var byteArray:PoolByteArray = f.get_buffer(f.get_len());
				f.close();
				return byteArray;
			else:
				errNotFound();
	return PoolByteArray([]);

func getText(path:String = "", utf8:bool = false, lf:bool = false) -> String:
	var byteArray:PoolByteArray = getBytes("data/" + path + ".txt");
	var txtData:String = byteArray.get_string_from_ascii();
	if (utf8):
		txtData = byteArray.get_string_from_utf8();
	if (lf):
		return txtData.split("\r").join("");
	return txtData;

func getDat(path:String = "", utf8:bool = false, lf:bool = false) -> String:
	var byteArray:PoolByteArray = getBytes("data/" + path + ".dat");
	var txtData:String = byteArray.get_string_from_ascii();
	if (utf8):
		txtData = byteArray.get_string_from_utf8();
	if (lf):
		return txtData.split("\r").join("");
	return txtData;

func getSpriteFrames(path:String = "") -> SpriteFrames:
	var res = fetch(extify(path, "res"));
	if (res[0] == null || res.size() != 2):
		return null;
	var p:String = res[1];
	if (p.length() < 4):
		return null;
	var pExt:String = p.substr(p.length() - 4);
	if (pExt != ".res"):
		return null;
	return res[0];

func getAudio(path:String = "") -> AudioStreamOGGVorbis:
	var res = fetch(extify(path, "ogg"));
	if (res[0] == null || res.size() != 2): 
		return null;
	var p:String = res[1];
	if (p.length() < 4):
		return null;
	return res[0];

func getPng(path:String = ""):
	var res = fetch(extify(path, "png"));
	if (res[0] == null || res.size() != 2):
		return null;
	var p:String = res[1];
	if (p.length() < 4):
		return null;
	return res[0];

func getBmp(path:String = "") -> ImageTexture:
	var res = fetch(extify(path, "bmp"));
	if (res[0] == null || res.size() != 2):
		return null;
	var p:String = res[1];
	if (p.length() < 4):
		return null;
	return res[0];

func getJpg(path:String = "") -> ImageTexture:
	var res = fetch(extify(path, "jpg"));
	if (res[0] == null || res.size() != 2):
		return null;
	var p:String = res[1];
	if (p.length() < 4):
		return null;
	return res[0];

func getTga(path:String = "") -> ImageTexture:
	var res = fetch(extify(path, "tga"));
	if (res[0] == null || res.size() != 2):
		return null;
	var p:String = res[1];
	if (p.length() < 4):
		return null;
	return res[0];

func getWebp(path:String = "") -> ImageTexture:
	var res = fetch(extify(path, "webp"));
	if (res[0] == null || res.size() != 2):
		return null;
	var p:String = res[1];
	if (p.length() < 4):
		return null;
	if (p[p.length() - 5] != "."):
		return null;
	return res[0];

func getScene(path:String = "") -> Resource:
	return load("res://scenes/" + path + ".tscn");

func getStage(path:String = "") -> Resource:
	return getScene("stages/" + path);

#func _processManifest(folder:String = "") -> Array:
#	var files:Array = [];
#	var dir:Directory = Directory.new();
#	if (dir.open(folder) == OK):
#		if (dir.list_dir_begin(true, false) == OK):
#			var filePath:String = dir.get_next();
#			while (filePath != ""):
#				if (dir.current_is_dir()):
#					files.append_array(_processManifest(folder + filePath + "/"));
#				else:
#					files.append(folder + filePath);
#				filePath = dir.get_next();
#	return files;

func updateManifest():
#	for file in _processManifest(assetPath):
#		var fileName:String = file.substr(assetPath.length());
#		if (fileName.ends_with(importExt)):
#			fileName = fileName.substr(0, fileName.length() - importExt.length());
#		if (!manifest.has(fileName)):
#			manifest.append(fileName);
	var mf:File = File.new();
	if (mf.open("res://manifest/manifest.txt", File.READ) == OK):
		manifest = mf.get_as_text().split("\n");
		mf.close();

func _ready():
	updateManifest();
	pass;
