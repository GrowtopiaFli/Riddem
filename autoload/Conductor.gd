extends Node

signal finished();
signal sectionHit(sec);
signal beatHit(b);
signal stepHit(s);

var bpm:int = 130;

var sections:int = 0;
var beats:int = 0;
var steps:int = 0;

var prevSections:int = -1;
var prevBeats:int = -1;
var prevSteps:int = -1;

var song:AudioStreamPlayer = null;
var songFinished:bool = false;

var playing:bool = false;

var sectionSecs:float = 0;
var beatSecs:float = 0;
var stepSecs:float = 0;

var songPos:float = 0;
var startedPlaying:bool = false;

func setBPM(BPM:int = 130):
	bpm = BPM;
	sectionSecs = (60.0 / bpm) * 4.0;
	beatSecs = sectionSecs / 4.0;
	stepSecs = beatSecs / 4.0;

func init(SONG:AudioStreamPlayer = null, BPM:int = 130):
	startedPlaying = false;
	beats = 0;
	steps = 0;
	prevBeats = 0;
	prevSteps = 0;
	songFinished = false;
	song = SONG;
	if (song != null):
		if (song.is_connected("finished", self, "finished")):
			song.disconnect("finished", self, "finished");
# warning-ignore:return_value_discarded
		song.connect("finished", self, "finished");
	songFinished = false;
	setBPM(BPM);

func songInvalid() -> bool:
	if (song == null):
		return true;
	if (song.stream == null):
		return true;
	return !song.playing;

func getSteps() -> float:
	return getPosition() / stepSecs;

func getBeats() -> float:
	return getPosition() / stepSecs;

func getPosition() -> float:
	return songPos;

func getLength() -> float:
	if (songInvalid()):
		return 0.0;
	return song.stream.get_length();

func startPlaying():
	startedPlaying = true;
	pass;

func stopPlaying():
	startedPlaying = false;
	pass;

func finished():
	song = null;
	songFinished = true;
	emit_signal("finished");
	pass;

func _process(delta):
	if (startedPlaying):
		songPos += delta;
	if (!songInvalid()):
		var actualPos:float = song.get_playback_position();
		if (abs(actualPos - songPos) >= Riddem.MUS_DEL_THRES):
			songPos = actualPos;
# warning-ignore:unused_variable
		var songLen:float = getLength();
	
		var songMins:float = songPos / 60;

# warning-ignore:narrowing_conversion
		steps = bpm * songMins * 4;
# warning-ignore:narrowing_conversion
		beats = bpm * songMins;
# warning-ignore:narrowing_conversion
		sections = (bpm * songMins) / 4;
		
		if (steps != prevSteps):
			emit_signal("stepHit", steps);
		if (beats != prevBeats):
			emit_signal("beatHit", beats);
		if (sections != prevSections):
			emit_signal("sectionHit", sections);
		
		prevSteps = steps;
		prevBeats = beats;
		prevSections = sections;
	pass;
