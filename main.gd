extends Node3D
var player: CharacterBody3D
var pivot: Node3D
var cam: Camera3D
var hud: Control
var move_vec := Vector2.ZERO
var move_id := -1
var look_id := -1
var speed := 5.0
var jump_now := false
var yaw := 0.0

func _ready():
    make_world()
    make_player()
    make_hud()

func make_world():
    var light = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-50,-25,0)
    add_child(light)
    var ground = MeshInstance3D.new()
    var plane = PlaneMesh.new()
    plane.size = Vector2(160,160)
    ground.mesh = plane
    var gm = StandardMaterial3D.new()
    gm.albedo_color = Color(0.18,0.38,0.16)
    ground.material_override = gm
    ground.position.y = -0.12
    add_child(ground)
    var body = StaticBody3D.new()
    var cs = CollisionShape3D.new()
    var bs = BoxShape3D.new()
    bs.size = Vector3(160,0.2,160)
    cs.shape = bs
    body.add_child(cs)
    body.position.y = -0.12
    add_child(body)
    for i in range(28):
        var a = TAU * float(i) / 28.0
        make_tree(Vector3(cos(a)*16,0,sin(a)*16))

func make_tree(p: Vector3):
    var trunk = MeshInstance3D.new()
    var tm = CylinderMesh.new()
    tm.top_radius = 0.2
    tm.bottom_radius = 0.3
    tm.height = 2.0
    trunk.mesh = tm
    trunk.position = p + Vector3(0,1,0)
    var bark = StandardMaterial3D.new()
    bark.albedo_color = Color(0.28,0.15,0.08)
    trunk.material_override = bark
    add_child(trunk)
    var crown = MeshInstance3D.new()
    var sm = SphereMesh.new()
    sm.radius = 1.15
    sm.height = 2.0
    crown.mesh = sm
    crown.position = p + Vector3(0,2.45,0)
    var leaves = StandardMaterial3D.new()
    leaves.albedo_color = Color(0.08,0.3,0.12)
    crown.material_override = leaves
    add_child(crown)

func make_player():
    player = CharacterBody3D.new()
    player.name = "Ram_Player"
    var shape_node = CollisionShape3D.new()
    var capsule = CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    shape_node.shape = capsule
    shape_node.position.y = 0.9
    player.add_child(shape_node)
    var model = MeshInstance3D.new()
    var mesh = CapsuleMesh.new()
    mesh.radius = 0.4
    mesh.height = 1.8
    model.mesh = mesh
    model.position.y = 0.9
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.12,0.35,0.8)
    model.material_override = mat
    player.add_child(model)
    pivot = Node3D.new()
    pivot.position.y = 1.4
    player.add_child(pivot)
    cam = Camera3D.new()
    cam.position = Vector3(0,2,6)
    cam.rotation_degrees.x = -12
    cam.current = true
    pivot.add_child(cam)
    add_child(player)

func make_hud():
    hud = Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(hud)
    hud.draw.connect(draw_hud)

func draw_hud():
    var s = hud.size
    var base = Vector2(110,s.y-115)
    hud.draw_circle(base,62,Color(0,0,0,0.35))
    hud.draw_arc(base,62,0,TAU,48,Color(1,1,1,0.7),3)
    hud.draw_circle(base+move_vec*35,26,Color(0.9,0.9,0.9,0.65))
    var jp = Vector2(s.x-95,s.y-100)
    var rp = Vector2(s.x-195,s.y-75)
    hud.draw_circle(jp,40,Color(0.1,0.4,0.9,0.7))
    hud.draw_circle(rp,32,Color(0.1,0.6,0.2,0.7))
    hud.draw_string(ThemeDB.fallback_font,jp+Vector2(-20,6),"JUMP",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
    hud.draw_string(ThemeDB.fallback_font,rp+Vector2(-15,5),"RUN",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
    hud.draw_string(ThemeDB.fallback_font,Vector2(20,30),"RAMAYANA: THE EPIC WORLD",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)

func _input(e):
    var size = get_viewport().get_visible_rect().size
    if e is InputEventScreenTouch:
        if e.pressed:
            if e.position.x < size.x*0.45 and move_id == -1:
                move_id = e.index
                set_stick(e.position)
            elif e.position.x > size.x*0.55 and look_id == -1:
                look_id = e.index
                if e.position.distance_to(Vector2(size.x-95,size.y-100)) < 55:
                    jump_now = true
                elif e.position.distance_to(Vector2(size.x-195,size.y-75)) < 48:
                    speed = 8.0
        else:
            if e.index == move_id:
                move_id = -1
                move_vec = Vector2.ZERO
                hud.queue_redraw()
            if e.index == look_id:
                look_id = -1
                speed = 5.0
    elif e is InputEventScreenDrag:
        if e.index == move_id:
            set_stick(e.position)
        elif e.index == look_id:
            yaw -= e.relative.x*0.004
            pivot.rotation.y = yaw
            cam.rotation.x = clamp(cam.rotation.x-e.relative.y*0.003,-0.8,0.2)
    elif e is InputEventKey and e.pressed and e.keycode == KEY_SPACE:
        jump_now = true

func set_stick(p):
    var s = get_viewport().get_visible_rect().size
    move_vec = ((p-Vector2(110,s.y-115))/55.0).limit_length(1.0)
    hud.queue_redraw()

func _physics_process(delta):
    if player == null: return
    if not player.is_on_floor():
        player.velocity.y -= 9.8*delta
    elif jump_now:
        player.velocity.y = 5.0
    jump_now = false
    var v = move_vec
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
    v = v.limit_length(1.0)
    var dir = (player.global_transform.basis*Vector3(v.x,0,v.y)).normalized()
    if dir.length()>0.01:
        player.velocity.x = dir.x*speed
        player.velocity.z = dir.z*speed
        player.rotation.y = atan2(-dir.x,-dir.z)
    else:
        player.velocity.x = move_toward(player.velocity.x,0,16*delta)
        player.velocity.z = move_toward(player.velocity.z,0,16*delta)
    player.move_and_slide()
