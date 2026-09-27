class_name RetinalHudState
extends RefCounted

var look_delta: Vector2 = Vector2.ZERO
var look_speed: float = 0.0

var world_velocity: Vector3 = Vector3.ZERO
var local_velocity: Vector3 = Vector3.ZERO
var speed_mps: float = 0.0
var acceleration_mps2: float = 0.0

var is_gliding: bool = false
var reverse_stamina_ratio: float = 1.0

var is_grapple_ready: bool = false
var is_grapple_active: bool = false

var fall_progress: float = 0.0
var is_fall_critical: bool = false

var fall_risk_ratio: float = 0.0
var is_fall_lethal: bool = false
