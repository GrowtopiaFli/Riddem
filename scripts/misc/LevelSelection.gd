extends Node2D

onready var label:Label = get_node("Label");

var target:int = 0;
var targetScroll:int = 0;
var id:String = "";

func _ready():
	position.x = target * 1920;
	pass;

func _process(_delta):
	position.x = lerp(position.x, (target - (targetScroll)) * 1920, 0.1);
