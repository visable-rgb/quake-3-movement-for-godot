extends CharacterBody3D


var MouseSensitivityX: float = 1.0
var MouseSensitivityY: float = 1.0

#movement stuff

var MoveSpeed: float = 7.0
var RunAcceleration: float = 14.0
var RunDeacceleration: float = 10.0
var AirAcceleration: float = 2.0
var AirDeacceleration: float = 2.0
var AirControl: float = 0.3
var SideStrafeAcceleration: float = 50.0
var SideStrafeSpeed: float = 1.0
var Gravity: float = 20.0
var GroundFriction: float = 6.0
var JumpSpeed: float = 8.0
var HoldJumpToBhop : bool = false

var RotX: float = 0.0
var RotY: float = 0.0

var MoveDirection : Vector3 = Vector3.ZERO;
var MoveDirectionNorm : Vector3 = Vector3.ZERO;
var PlayerVelocity : Vector3 = Vector3.ZERO;
var PlayerTopVelocity : float = 0.0;

@onready var Head: Node3D = $head

var Grounded: bool = false
# players can queue the next jump just before he hits the ground
var WishJump: bool = false

var PlayerFriction : float = 0.0

var ForwardMove: float = 0.0
var StrafeMove: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		RotX -= event.relative.y * MouseSensitivityX * 0.01
		RotY -= event.relative.x * MouseSensitivityY * 0.01
	
	RotX = clampf(RotX, deg_to_rad(-90), deg_to_rad(90))
	rotation = Vector3(0.0,RotY,0.0)
	Head.rotation = Vector3(RotX,0.0,0.0)

func _physics_process(delta) -> void:
	
	QueueJump()
	if is_on_floor():
		GroundMove(delta)
	else:
		AirMove(delta)
		
	move_and_slide()

func SetMovementDir() -> void:
	ForwardMove = Input.get_action_strength("action_backward") - Input.get_action_strength("action_forward")
	StrafeMove = Input.get_action_strength("action_right") - Input.get_action_strength("action_left")


func QueueJump() -> void:
	
	if HoldJumpToBhop:
		WishJump = Input.is_action_just_pressed("action_jump")
		return
	
	if Input.is_action_pressed("action_jump") && !WishJump:
		WishJump = true
	if Input.is_action_just_released("action_jump"):
		WishJump = false

func AirMove(delta: float) -> void:
	var WishDir : Vector3
	var Wishvel : float = AirAcceleration
	
	SetMovementDir()
	
	if ForwardMove == 0 && StrafeMove != 0:
		Wishvel = AirAcceleration
	
	WishDir = Vector3(StrafeMove,0.0,ForwardMove).rotated(Vector3.UP,rotation.y)
	WishDir.normalized()
	MoveDirectionNorm = WishDir
	
	var WishSpeed = WishDir.length()
	WishSpeed *= MoveSpeed
	
	acceleration(WishDir, WishSpeed, Wishvel, delta)
	
	velocity.y -= Gravity * delta
	
	
func AirController(Wishdir: Vector3, WishSpeed: float, delta: float) -> void:
	var ZSpeed: float
	var Speed: float
	var Dot : float
	var k: float
	var i : int
	
	if ForwardMove == 0 || WishSpeed == 0:
		return
	
	ZSpeed = velocity.y
	velocity.y = 0
	Speed = velocity.length()
	velocity.normalized()
	
	Dot = Wishdir.dot(velocity)
	k = 32
	k *= AirControl * Dot * Dot * delta
	
	if Dot > 0:
		velocity.x = velocity.x * Speed + Wishdir.x * k
		velocity.y = velocity.y * Speed + Wishdir.y * k
		velocity.z = velocity.z * Speed + Wishdir.z * k
		
		velocity.normalized()
		MoveDirectionNorm = velocity
	
	velocity.x *= Speed
	velocity.y = ZSpeed
	velocity.z *= Speed

func GroundMove(delta: float) -> void:
	
	var WishDir: Vector3
	var Wishvel: Vector3
	
	# Do not apply friction if the player is queueing up the next jump
	if !WishJump:
		ApplyFriction(1.0, delta)
	else:
		ApplyFriction(0, delta)
	
	SetMovementDir()
	
	
	WishDir = Vector3(StrafeMove,0.0,ForwardMove).rotated(Vector3.UP, rotation.y)
	WishDir.normalized()
	MoveDirectionNorm = WishDir
	
	var WishSpeed = WishDir.length()
	WishSpeed *= MoveSpeed
	
	acceleration(WishDir, WishSpeed, RunAcceleration, delta)
	
	velocity.y = 0
	
	if WishJump:
		velocity.y = JumpSpeed
		WishJump = false

func ApplyFriction(t : float, delta: float) -> void:
	var Vec: Vector3 = velocity
	var Vel: float
	var Speed: float
	var NewSpeed: float
	var Controller: float
	var Drop: float
	
	Vec.y = 0.0
	Speed = Vec.length()
	Drop = 0.0
	
	if is_on_floor():
		Controller = Speed if Speed < RunDeacceleration else Speed
		Drop = Controller * GroundFriction * delta * t
	
	NewSpeed = Speed - Drop
	PlayerFriction = NewSpeed
	if NewSpeed < 0:
		NewSpeed = 0
	elif Speed > 0:
		NewSpeed /= Speed
	
	velocity.x *= NewSpeed
	velocity.z *= NewSpeed


func acceleration(wishdir: Vector3, wishspeed: float, accel: float, delta) -> void:
	
	var AddSpeed: float
	var AccelSpeed: float
	var CurrentSpeed: float
	
	CurrentSpeed = wishdir.dot(velocity)
	AddSpeed = wishspeed - CurrentSpeed
	if AddSpeed <= 0:
		return
	AccelSpeed = accel * delta * wishspeed
	if AccelSpeed > AddSpeed:
		AccelSpeed = AddSpeed
	
	velocity.x += AccelSpeed * wishdir.x
	velocity.z += AccelSpeed * wishdir.z
