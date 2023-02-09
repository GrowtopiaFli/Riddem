extends Node2D

onready var strum:Sprite = get_node("Strum");
onready var p = get_node("P");

var id:int = -1;
var baseCol:Color = Color8(0, 0, 0, 0);

var useCPU:bool = false;

func _ready():
	if (Riddem.isAndroid() || useCPU):
		var newP:CPUParticles2D = CPUParticles2D.new();
		newP.convert_from_particles(p);
		remove_child(p);
		p.queue_free();
		p.call_deferred("free");
		p = newP;
		add_child(p);
		move_child(p, 0);
	p.emitting = false;

func init():
	strum.self_modulate = baseCol + modulate;
	baseCol += strum.self_modulate;
	modulate = Color8(255, 255, 255, 255);
	p.modulate = baseCol + Color(Riddem.STR_GLOW, Riddem.STR_GLOW, Riddem.STR_GLOW, 0);
	strum.self_modulate.a8 = Riddem.DEFSTR_ALPHA;
	p.modulate.a8 = Riddem.DEFSTR_ALPHA;
	pass;

func glow():
	strum.self_modulate = baseCol + Color(Riddem.STR_GLOW, Riddem.STR_GLOW, Riddem.STR_GLOW, 0);
	p.modulate.a8 = 255;
	p.emitting = true;
	pass;

func press():
	strum.self_modulate = baseCol;
	pass;

func reset():
	strum.self_modulate = baseCol + Color(0, 0, 0, 0);
	strum.self_modulate.a8 = Riddem.DEFSTR_ALPHA;
	p.modulate.a8 = Riddem.DEFSTR_ALPHA;
	pass;
