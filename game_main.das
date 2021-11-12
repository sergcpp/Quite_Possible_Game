require daslib/media
// options debugger            // uncomment for debug in VS Code
// require daslib/debug        // uncomment for debug in VS Code

let
    TIME_STEP           = (1.0/120.0) // quite low value as collision detection is not continous
    UNIT_SIZE           = 40.0
    PLAYER_OUTER_COLOR  = 0x00691401
    PLAYER_INNER_COLOR  = 0x00d25500
    OUTER_BORDER_SIZE   = 3.0
    GROUND_HEIGHT       = 0.0
    OUTER_BLOCK_COLOR   = 0x00FFFFFF
    INNER_BLOCK_COLOR   = 0x00000000
    GRAVITY             = 10000.0
    SCROLL_SPEED        = 710.0

    map = [[string[16]
        "                                                                                                                                                                                                                                           ****************************************************************************************************************************************************************************************************************************************************************************************************                                                                                                                                               ***";
        "                                                                                                                                                                                                                                           ******************************************************************************************************************************************bbbb****************************************************bbbbbbbbbbbbbbbbbbbbbb****************************************************************************                                                                                                                                               ***";
        "                                                                                                                                                                                                                                               *************************************************                                      r                      rr                     *    *             rr           r          r            *                      *     rr                                            rrr                                                                                                                                                                    ***";
        "                                                                                                                                                                                                                                                   *****************************************                                                                                                                                                      *           *                            *                                                                                                                                                                                                  ***";
        "                                                                                                                                                                                                                                                                                                                                                                                                                                                       *                                   r                                                                                                                                                                                                  ***";
        "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    **       **          **  **        **                                     ***";
        "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    **       **          **  **        **                                     ***";
        "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    **   *   **  *****   **  **        **  ******  *******   *****            ***";
        "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    **  ***  ** **   **  **  **    ****** **    **  **   ** **   **           ***";
        "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ** ** ** ** *******  **  **   **   ** **    **  **   ** *******           ***";
        "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ****   **** **       **  **   **   ** **    **  **   ** **                ***";
        "                                                                                                                                                       *                                   t                                                       *****************************************                                                                                                                                                                                                                                                                                                                        **       **  ****** *** ***    ******  ******  ***   **  ******           ***";
        "                                                                                                                                                  *           *                            *                                                   *************************************************                                                                                                                                                                                                                                                                                                                                                                                              ***";
        "                                      t                      tt                     *    *             tt           t          tt            *                      *     tt                                            ttt                *********************************************************                                                                                                                                                                                                                                                                                                                                                                                          ***";
        "                                                                                     bbbb                                                     bbbbbbbbbbbbbbbbbbbbbbb                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ***";
        "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    ]]

    BLOCK_OFFSET        = float2(0.5 * UNIT_SIZE, -14.0 * UNIT_SIZE)

struct Player
    pos: float2
    vel: float2
    rot: float
    rot_vel: float
    is_alive: bool
    is_onground: bool
    is_underground: bool

var
    camera_pos: float2
    player: Player
    time_accum = 0.0
    attempt = 0
    reset_timer = 0.0
    sound: SoundHandle
    playing_sound: PlayingSoundHandle
    death_sound: SoundHandle
    text_up = true

def reset_player(var p: Player)
    p.is_alive = true
    p.pos = float2(0.0, -0.5 * UNIT_SIZE)
    p.vel = float2(0.0)
    p.rot = 0.0
    p.rot_vel = 0.0
    p.is_onground = false
    p.is_underground = false
    return

def render_player(var p: Player)
    let x = p.pos.x - camera_pos.x
    let y = p.pos.y - camera_pos.y

    let x_axis = float2(cos(p.rot), sin(p.rot))
    let y_axis = float2(-x_axis.y, x_axis.x);

    if p.is_alive
        var points: array<float2>
        points |> push(float2(-0.5 * UNIT_SIZE, -0.5 * UNIT_SIZE))
        points |> push(float2(+0.5 * UNIT_SIZE, -0.5 * UNIT_SIZE))
        points |> push(float2(+0.5 * UNIT_SIZE, +0.5 * UNIT_SIZE))
        points |> push(float2(-0.5 * UNIT_SIZE, +0.5 * UNIT_SIZE))

        points[0] = float2(x, y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_OUTER_COLOR)

        points[0] = float2(-0.5 * UNIT_SIZE + OUTER_BORDER_SIZE, -0.5 * UNIT_SIZE + OUTER_BORDER_SIZE)
        points[1] = float2(+0.5 * UNIT_SIZE - OUTER_BORDER_SIZE, -0.5 * UNIT_SIZE + OUTER_BORDER_SIZE)
        points[2] = float2(+0.5 * UNIT_SIZE - OUTER_BORDER_SIZE, +0.5 * UNIT_SIZE - OUTER_BORDER_SIZE)
        points[3] = float2(-0.5 * UNIT_SIZE + OUTER_BORDER_SIZE, +0.5 * UNIT_SIZE - OUTER_BORDER_SIZE)

        points[0] = float2(x, y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_INNER_COLOR)
    else
        let t = 75.0 * pow(1.0 - reset_timer, 0.3)
        let alpha = min(max(uint(reset_timer * reset_timer * reset_timer * reset_timer * 255.0), 0u), 255u) << 24u

        enable_alpha_blend()

        var points: array<float2>
        points |> push(float2(0.0, 0.0))
        points |> push(float2(+0.5 * UNIT_SIZE, 0.0))
        points |> push(float2(+0.5 * UNIT_SIZE, +0.5 * UNIT_SIZE))
        points |> push(float2(0.0, +0.5 * UNIT_SIZE))

        points[0] = float2(x, y) + t * float2(x_axis.x, y_axis.y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + t * float2(x_axis.x, y_axis.y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + t * float2(x_axis.x, y_axis.y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + t * float2(x_axis.x, y_axis.y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_OUTER_COLOR | alpha)

        points[0] = float2(0.0, 0.0)
        points[1] = float2(+0.5 * UNIT_SIZE - OUTER_BORDER_SIZE, 0.0)
        points[2] = float2(+0.5 * UNIT_SIZE - OUTER_BORDER_SIZE, +0.5 * UNIT_SIZE - OUTER_BORDER_SIZE)
        points[3] = float2(0.0, +0.5 * UNIT_SIZE - OUTER_BORDER_SIZE)

        points[0] = float2(x, y) + t * float2(x_axis.x, y_axis.y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + t * float2(x_axis.x, y_axis.y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + t * float2(x_axis.x, y_axis.y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + t * float2(x_axis.x, y_axis.y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_INNER_COLOR | alpha)

        //
        points[0] = float2(-0.5 * UNIT_SIZE, -0.5 * UNIT_SIZE)
        points[1] = float2(0.0, -0.5 * UNIT_SIZE)
        points[2] = float2(0.0, 0.0)
        points[3] = float2(-0.5 * UNIT_SIZE, 0.0)

        points[0] = float2(x, y) + t * float2(-x_axis.x, -y_axis.y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + t * float2(-x_axis.x, -y_axis.y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + t * float2(-x_axis.x, -y_axis.y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + t * float2(-x_axis.x, -y_axis.y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_OUTER_COLOR | alpha)

        points[0] = float2(-0.5 * UNIT_SIZE + OUTER_BORDER_SIZE, -0.5 * UNIT_SIZE + OUTER_BORDER_SIZE)
        points[1] = float2(0.0, -0.5 * UNIT_SIZE + OUTER_BORDER_SIZE)
        points[2] = float2(0.0, 0.0)
        points[3] = float2(-0.5 * UNIT_SIZE + OUTER_BORDER_SIZE, 0.0)

        points[0] = float2(x, y) + t * float2(-x_axis.x, -y_axis.y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + t * float2(-x_axis.x, -y_axis.y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + t * float2(-x_axis.x, -y_axis.y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + t * float2(-x_axis.x, -y_axis.y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_INNER_COLOR | alpha)

        //
        points[0] = float2(-0.5 * UNIT_SIZE, 0.0)
        points[1] = float2(0.0, 0.0)
        points[2] = float2(0.0, +0.5 * UNIT_SIZE)
        points[3] = float2(-0.5 * UNIT_SIZE, +0.5 * UNIT_SIZE)

        points[0] = float2(x, y) + t * float2(-x_axis.x, y_axis.y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + t * float2(-x_axis.x, y_axis.y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + t * float2(-x_axis.x, y_axis.y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + t * float2(-x_axis.x, y_axis.y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_OUTER_COLOR | alpha)

        points[0] = float2(-0.5 * UNIT_SIZE + OUTER_BORDER_SIZE, 0.0)
        points[1] = float2(0.0, 0.0)
        points[2] = float2(0.0, +0.5 * UNIT_SIZE - OUTER_BORDER_SIZE)
        points[3] = float2(-0.5 * UNIT_SIZE + OUTER_BORDER_SIZE, +0.5 * UNIT_SIZE - OUTER_BORDER_SIZE)

        points[0] = float2(x, y) + t * float2(-x_axis.x, y_axis.y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + t * float2(-x_axis.x, y_axis.y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + t * float2(-x_axis.x, y_axis.y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + t * float2(-x_axis.x, y_axis.y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_INNER_COLOR | alpha)

        //
        points[0] = float2(0.0, -0.5 * UNIT_SIZE)
        points[1] = float2(+0.5 * UNIT_SIZE, -0.5 * UNIT_SIZE)
        points[2] = float2(+0.5 * UNIT_SIZE, 0.0)
        points[3] = float2(0.0, 0.0)

        points[0] = float2(x, y) + t * float2(x_axis.x, -y_axis.y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + t * float2(x_axis.x, -y_axis.y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + t * float2(x_axis.x, -y_axis.y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + t * float2(x_axis.x, -y_axis.y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_OUTER_COLOR | alpha)

        points[0] = float2(0.0, -0.5 * UNIT_SIZE + OUTER_BORDER_SIZE)
        points[1] = float2(+0.5 * UNIT_SIZE - OUTER_BORDER_SIZE, -0.5 * UNIT_SIZE + OUTER_BORDER_SIZE)
        points[2] = float2(+0.5 * UNIT_SIZE - OUTER_BORDER_SIZE, 0.0)
        points[3] = float2(0.0, 0.0)

        points[0] = float2(x, y) + t * float2(x_axis.x, -y_axis.y) + points[0].x * x_axis + points[0].y * y_axis
        points[1] = float2(x, y) + t * float2(x_axis.x, -y_axis.y) + points[1].x * x_axis + points[1].y * y_axis
        points[2] = float2(x, y) + t * float2(x_axis.x, -y_axis.y) + points[2].x * x_axis + points[2].y * y_axis
        points[3] = float2(x, y) + t * float2(x_axis.x, -y_axis.y) + points[3].x * x_axis + points[3].y * y_axis

        fill_convex_polygon(points, PLAYER_INNER_COLOR | alpha)

        disable_alpha_blend()


def get_strip_alpha(i: uint)
    let alpha1 = min(0xFF * (i + uint(UNIT_SIZE)) / 200u, 0xFF)
    let alpha2 = min(0xFF * (1280u - i) / 200u, 0xFF)
    return min(alpha1, alpha2)

def render_world()
    let player_ix = int(player.pos.x / UNIT_SIZE)
    if player_ix >= length(map[0])
        reset_game()

    let gravity_sign = character_at(map[15], player_ix)

    //
    // Fill background with gradient
    //
    var goal_r = 0x41
    var goal_g = 0xea
    var goal_b = 0xff

    if gravity_sign == '-'
        goal_g = 0x00
        goal_b = 0x00

    var i = 0u
    while i < 720u
        let r = ((720u - i) * 0x0e + i * goal_r) / 720u
        let g = ((720u - i) * 0x23 + i * goal_g) / 720u
        let b = ((720u - i) * 0x24 + i * goal_b) / 720u
        fill_rect(0, int(i), 1280, 5, (r << 16u) | (g << 8u) | b)
        i += 5u

    //
    // Draw ground line
    //
    enable_alpha_blend()
    i = 0u
    while i < 1280u
        let alpha = get_strip_alpha(i)
        fill_rect(int(i), int(GROUND_HEIGHT - camera_pos.y), int(UNIT_SIZE), 3, 0x00E0E0E0 | (alpha << 24u))
        i += uint(UNIT_SIZE)
    disable_alpha_blend()
    
    //
    // Draw blocks
    //
    var temp_points: array<float2>
    temp_points |> push(float2(0.0))
    temp_points |> push(float2(0.0))
    temp_points |> push(float2(0.0))

    enable_alpha_blend()
    for iy in range(0, 16)
        let fy = BLOCK_OFFSET.y + float(iy) * UNIT_SIZE
        for ix in range(max(player_ix - 6, 0), min(player_ix + 26, length(map[iy])))
            let c = character_at(map[iy], ix)

            let fx = BLOCK_OFFSET.x + float(ix) * UNIT_SIZE
            let alpha = get_strip_alpha(uint(fx - camera_pos.x))
            if c == '*'
                fill_rect(int(fx - camera_pos.x), int(fy - camera_pos.y), int(UNIT_SIZE), int(UNIT_SIZE), OUTER_BLOCK_COLOR | (alpha << 24u))
                fill_rect(int(fx - camera_pos.x + OUTER_BORDER_SIZE), int(fy - camera_pos.y + OUTER_BORDER_SIZE), int(UNIT_SIZE - 2.0 * OUTER_BORDER_SIZE), int(UNIT_SIZE - 2.0 * OUTER_BORDER_SIZE), INNER_BLOCK_COLOR | (alpha << 24u))
            elif c == 't' || c == 'r'
                temp_points[0] = float2(fx - camera_pos.x + 0.5 * UNIT_SIZE, fy - camera_pos.y)
                temp_points[1] = float2(fx - camera_pos.x + UNIT_SIZE, fy - camera_pos.y + UNIT_SIZE)
                temp_points[2] = float2(fx - camera_pos.x, fy - camera_pos.y + UNIT_SIZE)
                
                if c == 'r'
                    swap(temp_points[0].y, temp_points[1].y)
                    temp_points[2].y = temp_points[1].y

                fill_convex_polygon(temp_points, OUTER_BLOCK_COLOR | (alpha << 24u))

                let center = float2(fx - camera_pos.x + 0.5 * UNIT_SIZE, fy - camera_pos.y + 0.5 * UNIT_SIZE)

                temp_points[0] = 0.6 * temp_points[0] + 0.4 * center
                temp_points[1].x = 0.8 * temp_points[1].x + 0.2 * center.x
                temp_points[2].x = 0.8 * temp_points[2].x + 0.2 * center.x

                fill_convex_polygon(temp_points, INNER_BLOCK_COLOR | (alpha << 24u))
            elif c == 'b'
                fill_rect(int(fx - camera_pos.x), int(fy - camera_pos.y), int(UNIT_SIZE), int(0.4 * UNIT_SIZE), INNER_BLOCK_COLOR | (alpha << 24u))

    disable_alpha_blend()


def reset_game()
    time_accum = 0.0
    camera_pos = float2(-250.0, -500.0)
    reset_player(player)

[export]
def initialize
    set_window_title("Quite Possible Game")
    sound = create_managed_sound("sound.mp3")
    playing_sound = sound |> play_sound_loop(1.0, 1.0)
    set_sound_play_pos(playing_sound, 19.5)
    death_sound = create_managed_sound("death.wav")
    reset_game()
    return

[export]
def act(delta: float)
    let space = get_key(VK_SPACE)

    let player_ix = int(player.pos.x / UNIT_SIZE)
    if player_ix >= length(map[0])
        reset_game()

    let gravity_sign = character_at(map[15], player_ix)
    if gravity_sign == '-'
        text_up = false
    else
        text_up = true

    if get_key(VK_ESCAPE)
        schedule_quit_game()
    if get_key(VK_R) && player.is_alive
        player.is_alive = false
    if space && player.is_alive
        if player.is_onground && gravity_sign == '+'
            player.vel.y -= 1600.0
            player.rot = -PI
            player.rot_vel = 10.0
        elif player.is_underground && gravity_sign == '-'
            player.vel.y += 1600.0
            player.rot = PI
            player.rot_vel = -10.0

    time_accum += delta
    time_accum = min(time_accum, 1.0) // avoid runaway accumulation

    let was_alive = player.is_alive
    let was_onground = player.is_onground
    let was_underground = player.is_underground
    player.is_onground = false
    player.is_underground = false

    while time_accum > TIME_STEP
        let dt = TIME_STEP

        if gravity_sign == '+'
            player.vel += float2(0.0, GRAVITY) * dt
        else
            player.vel += float2(0.0, -GRAVITY) * dt
        
        player.pos += player.vel * dt
        
        player.rot += player.rot_vel * dt
        if player.rot > 0.0
            player.rot = 0.0

        for iy in range(0, 16)
            let fy = BLOCK_OFFSET.y + float(iy) * UNIT_SIZE
            for ix in range(max(player_ix - 1, 0), min(player_ix + 1, length(map[iy])))
                let c = character_at(map[iy], ix)
                let fx = BLOCK_OFFSET.x + float(ix) * UNIT_SIZE
                if c == '*'
                    if (player.pos.x - 0.5 * UNIT_SIZE < fx + UNIT_SIZE && player.pos.x + 0.5 * UNIT_SIZE > fx &&
                        player.pos.y - 0.5 * UNIT_SIZE < fy + UNIT_SIZE && player.pos.y + 0.5 * UNIT_SIZE > fy)
                        if (fy + 0.5 * UNIT_SIZE - player.pos.y > 0.7 * 0.5 * UNIT_SIZE)
                            player.is_onground = true
                            player.pos.y = fy - 0.5 * UNIT_SIZE
                            player.vel.y = 0.0
                            player.rot = 0.0
                            player.rot_vel = 0.0
                        elif (player.pos.y - fy - 0.5 * UNIT_SIZE > 0.7 * 0.5 * UNIT_SIZE)
                            player.is_underground = true
                            player.pos.y = fy + 1.5 * UNIT_SIZE
                            player.vel.y = 0.0
                            player.rot = 0.0
                            player.rot_vel = 0.0
                        else
                            player.is_alive = false
                elif c == 't' || c == 'r'
                    if (player.pos.x - 0.5 * UNIT_SIZE < fx + 0.75 * UNIT_SIZE && player.pos.x + 0.5 * UNIT_SIZE > fx + 0.25 * UNIT_SIZE &&
                        player.pos.y - 0.5 * UNIT_SIZE < fy + 0.75 * UNIT_SIZE && player.pos.y + 0.5 * UNIT_SIZE > fy + 0.25 * UNIT_SIZE)
                        player.is_alive = false
                elif c == 'b'
                    if (player.pos.x - 0.5 * UNIT_SIZE < fx && player.pos.x + 0.5 * UNIT_SIZE > fx &&
                        player.pos.y - 0.5 * UNIT_SIZE < fy && player.pos.y + 0.5 * UNIT_SIZE > fy)
                        player.is_alive = false
        
        if (player.pos.y + 0.5 * UNIT_SIZE >= GROUND_HEIGHT)
            player.is_onground = true
            player.pos.y = GROUND_HEIGHT - 0.5 * UNIT_SIZE
            if player.vel.y > 0.0
                player.vel.y = 0.0

        if (player.is_alive)
            player.pos.x += SCROLL_SPEED * dt

        time_accum -= TIME_STEP

    if was_onground && !player.is_onground && !player.is_underground && player.rot_vel == 0.0
        player.rot = -0.5f * PI
        player.rot_vel = 16.0
    elif was_underground && !player.is_underground && !player.is_onground && player.rot_vel == 0.0
        player.rot = 0.5f * PI
        player.rot_vel = -16.0

    camera_pos.x = player.pos.x - 250.0
    var cam_goal = (gravity_sign == '+') ? (player.pos.y - 500.0) : (player.pos.y - 220.0)

    if abs(camera_pos.y - cam_goal) > 150.0
        camera_pos.y = 0.99 * camera_pos.y + 0.01 * cam_goal

    if was_alive && !player.is_alive
        player.rot = -PI
        player.rot_vel = -1.0
        play_sound(death_sound)
        reset_timer = 1.0

    reset_timer -= delta

    if !player.is_alive && reset_timer <= 0.0
        ++attempt
        reset_game()

    return

[export]
def draw
    render_world()
    render_player(player)

    set_font_name("VeraMono-Bold.ttf")
    set_font_size(36)
    if text_up
        text_out(540, 120, "Attempt {attempt}", 0xF0F0F0)
    else
        text_out(540, 720 - 240, "Attempt {attempt}", 0xF0F0F0)

    return
