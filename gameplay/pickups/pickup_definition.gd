class_name PickupDefinition
extends Resource

enum EffectType {
	DASH_CHARGES,
	WALL_JUMP_CHARGES,
	SPEED_BOOST,
	FORWARD_IMPULSE,
	REPULSION
}

@export_category("identity")
@export var display_name: String = "Pickup"

@export_category("effect")
@export var effect_type: EffectType = (
	EffectType.DASH_CHARGES
)

@export_range(1, 10, 1) var charge_amount: int = 1

@export_range(1.0, 3.0, 0.01) var speed_multiplier: float = 1.25

@export_range(
	0.1,
	60.0,
	0.1,
	"suffix:s"
) var speed_boost_duration_s: float = 5.0

@export_range(
	0.0,
	100.0,
	0.1,
	"suffix:m/s"
) var impulse_minimum_speed_mps: float = 20.0

@export_category("audio")
@export var pickup_streams: Array[AudioStream] = []
@export var hum_stream: AudioStream

@export_category("visual")
@export var visual_material: Material
