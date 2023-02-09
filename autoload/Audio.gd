extends Node

var musPlaying:String = "";

func _ready():
# warning-ignore:return_value_discarded
	$GCTimer.connect("timeout", self, "_gc");
	pass;

func updateVolume():
	var db:float = -32.0 - (Riddem.volume * -32.0);
	if (db >= 32):
		db = -80;
	AudioServer.set_bus_volume_db(0, db);
	pass;

func loadSound(sound:String = "", gain:float = 0, bus:String = "Sounds") -> AudioStreamPlayer:
	sound = "sounds/" + sound;
	var target:AudioStreamOGGVorbis = Assets.getAudio(sound);
	if (target == null):
		target = Assets.getAudio(sound);
	if (target == null):
		print("ERROR: Could not play sound: ", sound);
		return null;
	target.loop = false;
		
	var snd:AudioStreamPlayer = AudioStreamPlayer.new();
	snd.bus = bus;
	snd.stream = target;
	snd.volume_db = gain;
	$Sounds.add_child(snd);
	return snd;

func play(sound:String = "", gain:float = 0, bus:String = "Sounds") -> AudioStreamPlayer:
	var snd:AudioStreamPlayer = loadSound(sound, gain, bus);
	snd.play();
	return snd;

func loadMusic(music:String = "", gain:float = 0, loop:bool = true, bus:String = "Music") -> AudioStreamPlayer:
	musPlaying = music;
	music = "music/" + music;
	var target:AudioStreamOGGVorbis = Assets.getAudio(music);
	if (target == null):
		target = Assets.getAudio(music);
	if (target == null):
		print("ERROR: Could not play music: ", music);
		return null;
	target.loop = loop;
	
	var mus:AudioStreamPlayer = AudioStreamPlayer.new();
	mus.bus = bus;
	mus.stream = target;
	mus.volume_db = gain;
	$Songs.add_child(mus);
	return mus;

func playMusic(music:String = "", gain:float = 0, loop:bool = true, bus:String = "Music") -> AudioStreamPlayer:
	var mus:AudioStreamPlayer = loadMusic(music, gain, loop, bus);
	mus.play();
	return mus;
	
func stopMusic(stream:AudioStream):
	for i in $Songs.get_children():
		if (i):
			if (i.name.begins_with("@")):
				if (i.stream == stream):
					i.stop();
	pass;

func stopSound(stream:AudioStream):
	for i in $Sounds.get_children():
		if (i):
			if (i.name.begins_with("@")):
				if (i.stream == stream):
					i.stop();
	pass;

func stopAll():
	for i in $Sounds.get_children():
		if (i):
			if (i.name.begins_with("@")):
				if (weakref(i).get_ref()):
					i.queue_free();
	
	for i in $Songs.get_children():
		if (i):
			if (i.name.begins_with("@")):
				if (weakref(i).get_ref()):
					i.queue_free();
	musPlaying = "";
	pass;

func _gc():
	for i in $Sounds.get_children():
		if (i):
			if (i.name.begins_with("@")):
				if (i.playing != true):
					i.queue_free();
	pass;

func findSound(stream):
	for i in $Sounds.get_children():
		if (i):
			if (i.name.begins_with("@")):
				if (i.stream == stream):
					return i;

func findSong(stream:AudioStreamOGGVorbis):
	for i in $Songs.get_children():
		if (i):
			print(i.name);
			if (i.name.begins_with("@")):
				if (i.stream == stream):
					return i;
