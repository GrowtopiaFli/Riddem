extends Sprite

var id:int = -1;
var steps:int = 0;
var time:float = 0;
var speed:float = 1;
var targetPos:Vector2 = Vector2.ZERO;

func init():
	if (id >= 0):
		modulate = Riddem.COLORS[id];
	pass;
