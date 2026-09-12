#include <genesis.h>
#include "resources.h"

#define SCREEN_W        320
#define SCREEN_H        224
#define GROUND_Y        176
#define WORLD_W         2560
#define MAX_PLAYERS     2
#define MAX_ENEMIES     10
#define MAX_BULLETS     12
#define MAX_FX          6
#define MAX_CRATES      4

#define ANIM_IDLE       0
#define ANIM_WALK       1
#define ANIM_JUMP       2
#define ANIM_CROUCH     3
#define ANIM_SHOOT      4
#define ANIM_MELEE      5
#define ANIM_HURT       6
#define ANIM_DEATH      7
#define ANIM_RAGE       8

#define EN_RUNNER       0
#define EN_JUMPER       1
#define EN_ARMORED      2
#define EN_BOSS         3

#define ST_TITLE        0
#define ST_MENU         1
#define ST_OPTIONS      2
#define ST_DIALOG       3
#define ST_PLAY         4
#define ST_PAUSE        5
#define ST_WIN          6
#define ST_GAMEOVER     7

#define T_EMPTY         0
#define T_SKY           1
#define T_GRASS         2
#define T_DIRT          3
#define T_WOOD          4
#define T_BARN          5
#define T_CORN          6
#define T_FENCE         7
#define T_FIRE          8
#define T_METAL         9
#define T_PLAT          10
#define T_MOON          11

#define DIFF_EASY       0
#define DIFF_MED        1
#define DIFF_HARD       2

typedef struct {
    Sprite *spr;
    s16 x, y;
    s16 vx, vy;
    s16 hp, hp_max;
    s16 anim, frame, timer;
    s16 shoot_cd, melee_cd, invuln, rage;
    u16 pad;
    bool alive;
    bool on_ground;
    bool facing_left;
} Player;

typedef struct {
    Sprite *spr;
    s16 x, y;
    s16 vx, vy;
    s16 hp;
    s16 kind;
    s16 anim, frame, timer;
    s16 ai;
    bool alive;
    bool facing_left;
} Enemy;

typedef struct {
    Sprite *spr;
    s16 x, y;
    s16 vx;
    bool alive;
    bool from_p2;
} Bullet;

typedef struct {
    Sprite *spr;
    s16 x, y;
    s16 timer;
    bool alive;
} Fx;

typedef struct {
    Sprite *spr;
    s16 x, y;
    bool alive;
} Crate;

static u8 state;
static u8 menu_sel;
static u8 players_n;
static u8 difficulty;
static u8 lives;
static u8 continues_left;
static u32 score;
static s16 cam_x;
static s16 lock_left, lock_right;
static bool camera_locked;
static bool go_flash;
static u8 go_timer;
static u8 hud_timer;
static u8 sfx_timer;
static u8 dialog_i;
static u8 spawn_flags[16];
static bool boss_spawned;
static bool intro_done;

static Player pl[MAX_PLAYERS];
static Enemy en[MAX_ENEMIES];
static Bullet bu[MAX_BULLETS];
static Fx fx[MAX_FX];
static Crate cr[MAX_CRATES];
static Sprite *hearts[7];

static const char *INTRO[] = {
    "SAMURAI: Kiko, a mutacao",
    "comecou aqui. Limpe a area",
    "e destrua a Matriarca!",
    "KIKO: Horario do banquete.",
    "Vou transformar esses",
    "porcos em bacon!",
    NULL
};

static const char *WIN_LINES[] = {
    "KIKO: Fazenda limpa.",
    "Proxima parada: Amazonia.",
    "SAMURAI: Bom trabalho,",
    "cacador. Siga em frente.",
    NULL
};

static void sfx_beep(u16 tone, u8 frames)
{
    PSG_setTone(0, tone);
    PSG_setEnvelope(0, 4);
    sfx_timer = frames;
}

static void sfx_update(void)
{
    if (sfx_timer) {
        sfx_timer--;
        if (sfx_timer == 0) PSG_setEnvelope(0, PSG_ENVELOPE_MIN);
        else if (sfx_timer < 3) PSG_setEnvelope(0, 10);
    }
}

static void hide_sprite(Sprite *s)
{
    if (s) SPR_setVisibility(s, HIDDEN);
}

static void show_sprite(Sprite *s)
{
    if (s) SPR_setVisibility(s, VISIBLE);
}

static s16 world_to_sx(s16 x)
{
    return x - cam_x;
}

static u16 tile_base(void)
{
    return TILE_USER_INDEX;
}

static u16 tile_id(u8 kind, u16 ox, u16 oy)
{
    /* tiles.png is 192x16: 12 cells of 16x16, stored row-major in 8x8 tiles.
       Row 0 = top 8px of every cell (24 tiles), row 1 = bottom 8px. */
    return tile_base() + (oy * 24) + (kind * 2) + ox;
}

static bool is_barn_col(u16 tx)
{
    static const u16 barns[] = { 24, 70, 122, 188, 250 };
    u16 i;
    for (i = 0; i < 5; i++) {
        if (tx >= barns[i] && tx < barns[i] + 8) return TRUE;
    }
    return FALSE;
}

static bool is_corn_col(u16 tx)
{
    return ((tx >= 40 && tx < 52) || (tx >= 150 && tx < 166) || (tx >= 210 && tx < 220));
}

static bool is_fence_col(u16 tx)
{
    return ((tx >= 55 && tx < 64) || (tx >= 160 && tx < 172));
}

/* Ground is painted in 8x8 tiles. ty here is 8x8 row. */
static u8 tile8_at(u16 tx8, u16 ty8)
{
    u16 tx = tx8 / 2;
    u16 ty16 = ty8; /* we map 8x8 rows directly for sky/ground bands */
    if (ty8 >= 24) return T_DIRT;
    if (ty8 == 22 || ty8 == 23) return T_GRASS;
    if (ty8 >= 16 && ty8 <= 21 && is_barn_col(tx)) {
        if (ty8 <= 17) return T_BARN;
        if ((tx8 & 2) && ty8 == 18) return T_FIRE;
        return T_WOOD;
    }
    if (ty8 >= 19 && ty8 <= 21 && is_corn_col(tx)) return T_CORN;
    if (ty8 == 21 && is_fence_col(tx)) return T_FENCE;
    if (ty8 == 18 && ((tx >= 90 && tx < 98) || (tx >= 200 && tx < 208))) return T_PLAT;
    if (ty8 == 4 && tx == 34) return T_MOON;
    (void)ty16;
    return T_EMPTY;
}

static void draw_column(u16 world_tx8)
{
    u16 plane_x = world_tx8 & 63;
    u16 y;
    for (y = 0; y < 28; y++) {
        u8 kind = tile8_at(world_tx8, y);
        u16 ox = world_tx8 & 1;
        u16 oy = y & 1;
        u16 tid = (kind == T_EMPTY) ? 0 : tile_id(kind, ox, oy);
        u16 plane = (y < 14) ? BG_B : BG_A;
        VDP_setTileMapXY(plane, TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, tid), plane_x, y);
    }
}

static u16 filled_upto = 0;

static void fill_visible_map(s16 cam)
{
    u16 start = (u16)(cam / 8);
    u16 want = start + 42;
    if (filled_upto == 0) {
        u16 i;
        for (i = 0; i < 64; i++) draw_column(i);
        filled_upto = 64;
    }
    while (filled_upto < want) {
        draw_column(filled_upto);
        filled_upto++;
    }
}

static void clear_text(void)
{
    u16 y;
    for (y = 0; y < 28; y++) VDP_clearTextLine(y);
}

static void draw_hud(void)
{
    char buf[24];
    VDP_setTextPalette(PAL3);
    VDP_drawText("KIKO", 2, 0);
    intToStr(score, buf, 6);
    VDP_drawText(buf, 14, 0);
    VDP_drawText("FAZENDA", 31, 0);
    if (camera_locked) VDP_drawText("LOCK", 1, 1);
    else VDP_drawText("    ", 1, 1);
    if (go_flash) VDP_drawText("GO!", 18, 10);
    else VDP_drawText("   ", 18, 10);
}

static void set_player_anim(Player *p, s16 anim)
{
    if (p->anim == anim) return;
    p->anim = anim;
    p->frame = 0;
    p->timer = 0;
    if (p->spr) {
        SPR_setAnim(p->spr, anim);
        SPR_setFrame(p->spr, 0);
    }
}

static void spawn_fx(s16 x, s16 y)
{
    u16 i;
    for (i = 0; i < MAX_FX; i++) {
        if (!fx[i].alive) {
            fx[i].alive = TRUE;
            fx[i].x = x;
            fx[i].y = y;
            fx[i].timer = 16;
            if (!fx[i].spr)
                fx[i].spr = SPR_addSprite(&explosion_sprite, world_to_sx(x), y, TILE_ATTR(PAL2, TRUE, FALSE, FALSE));
            show_sprite(fx[i].spr);
            SPR_setAnim(fx[i].spr, 0);
            return;
        }
    }
}

static void spawn_bullet(s16 x, s16 y, s16 dir, bool p2)
{
    u16 i;
    for (i = 0; i < MAX_BULLETS; i++) {
        if (!bu[i].alive) {
            bu[i].alive = TRUE;
            bu[i].x = x;
            bu[i].y = y;
            bu[i].vx = (dir < 0) ? -5 : 5;
            bu[i].from_p2 = p2;
            if (!bu[i].spr)
                bu[i].spr = SPR_addSprite(&bullet_sprite, world_to_sx(x), y, TILE_ATTR(PAL1, TRUE, FALSE, FALSE));
            SPR_setHFlip(bu[i].spr, dir < 0);
            show_sprite(bu[i].spr);
            sfx_beep(180, 4);
            return;
        }
    }
}

static s16 enemy_hp(s16 kind)
{
    s16 base = 3;
    if (kind == EN_JUMPER) base = 3;
    if (kind == EN_ARMORED) base = 8;
    if (kind == EN_BOSS) base = 70;
    if (difficulty == DIFF_EASY) base = (base * 3) / 4;
    if (difficulty == DIFF_HARD) base = (base * 3) / 2;
    return base;
}

static void spawn_enemy(s16 kind, s16 x, s16 facing)
{
    u16 i;
    for (i = 0; i < MAX_ENEMIES; i++) {
        if (!en[i].alive) {
            Enemy *e = &en[i];
            e->alive = TRUE;
            e->kind = kind;
            e->x = x;
            e->y = (kind == EN_BOSS) ? (GROUND_Y - 32) : (GROUND_Y - 24);
            e->vx = 0;
            e->vy = 0;
            e->hp = enemy_hp(kind);
            e->anim = 0;
            e->frame = 0;
            e->timer = 0;
            e->ai = 0;
            e->facing_left = facing < 0;
            if (!e->spr) {
                const SpriteDefinition *def = (kind == EN_BOSS) ? &boss_sprite : &javali_sprite;
                e->spr = SPR_addSprite(def, world_to_sx(x), e->y, TILE_ATTR(PAL2, TRUE, FALSE, FALSE));
            }
            show_sprite(e->spr);
            SPR_setAnim(e->spr, (kind == EN_ARMORED) ? 4 : 0);
            return;
        }
    }
}

static u16 live_enemies(void)
{
    u16 i, n = 0;
    for (i = 0; i < MAX_ENEMIES; i++) if (en[i].alive) n++;
    return n;
}

static void kill_enemy(Enemy *e)
{
    spawn_fx(e->x, e->y);
    e->alive = FALSE;
    hide_sprite(e->spr);
    if (e->kind == EN_BOSS) score += 5000;
    else if (e->kind == EN_ARMORED) score += 250;
    else if (e->kind == EN_JUMPER) score += 150;
    else score += 100;
    sfx_beep(90, 8);
}

static void hurt_player(Player *p, s16 dmg)
{
    if (!p->alive || p->invuln) return;
    p->hp -= dmg;
    p->invuln = 50;
    set_player_anim(p, ANIM_HURT);
    sfx_beep(320, 8);
    if (p->hp <= 0) {
        p->hp = 0;
        set_player_anim(p, ANIM_DEATH);
    }
}

static void fire_or_melee(Player *p, bool p2)
{
    u16 i;
    bool melee = FALSE;
    for (i = 0; i < MAX_ENEMIES; i++) {
        if (!en[i].alive) continue;
        s16 dx = en[i].x - p->x;
        if (dx < 0) dx = -dx;
        if (dx < 28 && abs(en[i].y - p->y) < 28) {
            melee = TRUE;
            en[i].hp -= (p->rage ? 4 : 2);
            spawn_fx(en[i].x, en[i].y - 4);
            set_player_anim(p, ANIM_MELEE);
            p->melee_cd = 12;
            if (en[i].hp <= 0) kill_enemy(&en[i]);
            sfx_beep(140, 5);
            break;
        }
    }
    if (!melee) {
        s16 dir = p->facing_left ? -1 : 1;
        spawn_bullet(p->x + dir * 18, p->y + 12, dir, p2);
        set_player_anim(p, ANIM_SHOOT);
        p->shoot_cd = 8;
    }
}

static void update_player(Player *p, u8 idx)
{
    u16 joy;
    s16 ax = 0;
    bool crouch = FALSE;
    if (!p->alive || !p->spr) return;
    if (p->hp <= 0) {
        p->timer++;
        if (p->timer > 90) {
            if (lives) {
                lives--;
                p->hp = p->hp_max;
                p->invuln = 80;
                p->x = cam_x + 40;
                p->y = GROUND_Y - 32;
                set_player_anim(p, ANIM_IDLE);
            } else {
                p->alive = FALSE;
                hide_sprite(p->spr);
            }
        }
        SPR_setPosition(p->spr, world_to_sx(p->x), p->y);
        return;
    }

    joy = JOY_readJoypad(p->pad);
    if (joy & BUTTON_LEFT) { ax = -1; p->facing_left = TRUE; }
    if (joy & BUTTON_RIGHT) { ax = 1; p->facing_left = FALSE; }
    if ((joy & BUTTON_DOWN) && p->on_ground) crouch = TRUE;

    if (p->rage) p->rage--;
    if (p->invuln) p->invuln--;
    if (p->shoot_cd) p->shoot_cd--;
    if (p->melee_cd) p->melee_cd--;

    if (crouch) {
        p->vx = 0;
        set_player_anim(p, ANIM_CROUCH);
    } else {
        p->vx = ax * (p->rage ? 3 : 2);
        if (p->on_ground) {
            if (p->shoot_cd || p->melee_cd) { /* keep shoot/melee */ }
            else if (ax) set_player_anim(p, ANIM_WALK);
            else if (p->rage) set_player_anim(p, ANIM_RAGE);
            else set_player_anim(p, ANIM_IDLE);
        }
    }

    if ((joy & (BUTTON_B | BUTTON_C)) && p->on_ground && !crouch) {
        /* B jump, C can also jump if used with up - C is special */
    }
    if ((joy & BUTTON_B) && p->on_ground && !crouch) {
        p->vy = -9;
        p->on_ground = FALSE;
        set_player_anim(p, ANIM_JUMP);
        sfx_beep(220, 3);
    }
    if ((joy & BUTTON_C) && !p->rage) {
        p->rage = 90;
        set_player_anim(p, ANIM_RAGE);
        sfx_beep(110, 10);
    }
    if ((joy & BUTTON_A) && p->shoot_cd == 0 && p->melee_cd == 0 && !crouch) {
        fire_or_melee(p, idx == 1);
    }

    p->x += p->vx;
    p->vy += 1;
    if (p->vy > 8) p->vy = 8;
    p->y += p->vy;
    if (p->y >= GROUND_Y - 32) {
        p->y = GROUND_Y - 32;
        p->vy = 0;
        p->on_ground = TRUE;
    } else p->on_ground = FALSE;

    if (p->x < cam_x + 4) p->x = cam_x + 4;
    if (p->x > WORLD_W - 40) p->x = WORLD_W - 40;
    if (camera_locked) {
        if (p->x < lock_left) p->x = lock_left;
        if (p->x > lock_right - 32) p->x = lock_right - 32;
    }

    SPR_setHFlip(p->spr, p->facing_left);
    SPR_setPosition(p->spr, world_to_sx(p->x), p->y);
    if (p->invuln && (p->invuln & 2)) hide_sprite(p->spr);
    else show_sprite(p->spr);

    p->timer++;
    if ((p->anim == ANIM_WALK || p->anim == ANIM_RAGE) && (p->timer & 5) == 0) {
        p->frame++;
        SPR_setFrame(p->spr, p->frame);
    }
    (void)idx;
}

static void update_enemies(void)
{
    u16 i, p;
    s16 target_x = pl[0].x;
    if (players_n > 1 && pl[1].alive) {
        if (pl[1].x > target_x) target_x = pl[1].x;
    }
    for (i = 0; i < MAX_ENEMIES; i++) {
        Enemy *e = &en[i];
        if (!e->alive || !e->spr) continue;
        e->timer++;
        e->facing_left = e->x > target_x;
        if (e->kind == EN_BOSS) {
            e->ai++;
            if ((e->ai % 180) < 70) e->vx = e->facing_left ? -3 : 3;
            else if ((e->ai % 180) < 90) {
                if (e->y >= GROUND_Y - 32) e->vy = -10;
                e->vx = 0;
                SPR_setAnim(e->spr, 2);
            } else {
                e->vx = 0;
                SPR_setAnim(e->spr, 0);
            }
        } else if (e->kind == EN_JUMPER) {
            e->vx = e->facing_left ? -2 : 2;
            if ((e->timer % 70) == 0) e->vy = -8;
            SPR_setAnim(e->spr, 2);
        } else if (e->kind == EN_ARMORED) {
            e->vx = e->facing_left ? -1 : 1;
            SPR_setAnim(e->spr, 4);
        } else {
            e->vx = e->facing_left ? -2 : 2;
            if ((e->timer & 6) == 0) SPR_nextFrame(e->spr);
        }
        e->x += e->vx;
        e->vy += 1;
        if (e->vy > 7) e->vy = 7;
        e->y += e->vy;
        if (e->y >= ((e->kind == EN_BOSS) ? GROUND_Y - 32 : GROUND_Y - 24)) {
            e->y = (e->kind == EN_BOSS) ? GROUND_Y - 32 : GROUND_Y - 24;
            e->vy = 0;
        }
        SPR_setHFlip(e->spr, !e->facing_left);
        SPR_setPosition(e->spr, world_to_sx(e->x), e->y);

        for (p = 0; p < players_n; p++) {
            if (!pl[p].alive || pl[p].hp <= 0) continue;
            s16 dx = pl[p].x - e->x;
            s16 dy = pl[p].y - e->y;
            if (dx < 0) dx = -dx;
            if (dy < 0) dy = -dy;
            if (dx < 22 && dy < 22) hurt_player(&pl[p], (e->kind == EN_BOSS) ? 2 : 1);
        }
    }
}

static void update_bullets(void)
{
    u16 i, j;
    for (i = 0; i < MAX_BULLETS; i++) {
        if (!bu[i].alive) continue;
        bu[i].x += bu[i].vx;
        if (bu[i].x < cam_x - 16 || bu[i].x > cam_x + SCREEN_W + 16) {
            bu[i].alive = FALSE;
            hide_sprite(bu[i].spr);
            continue;
        }
        SPR_setPosition(bu[i].spr, world_to_sx(bu[i].x), bu[i].y);
        for (j = 0; j < MAX_ENEMIES; j++) {
            if (!en[j].alive) continue;
            s16 dx = bu[i].x - en[j].x;
            s16 dy = bu[i].y - (en[j].y + 8);
            if (dx < 0) dx = -dx;
            if (dy < 0) dy = -dy;
            if (dx < 22 && dy < 18) {
                s16 dmg = 1;
                if (en[j].kind == EN_ARMORED) dmg = 1;
                if (pl[bu[i].from_p2 ? 1 : 0].rage) dmg = 2;
                en[j].hp -= dmg;
                bu[i].alive = FALSE;
                hide_sprite(bu[i].spr);
                spawn_fx(bu[i].x, bu[i].y - 8);
                if (en[j].hp <= 0) kill_enemy(&en[j]);
                break;
            }
        }
    }
}

static void update_fx(void)
{
    u16 i;
    for (i = 0; i < MAX_FX; i++) {
        if (!fx[i].alive) continue;
        fx[i].timer--;
        SPR_setPosition(fx[i].spr, world_to_sx(fx[i].x), fx[i].y);
        if (fx[i].timer <= 0) {
            fx[i].alive = FALSE;
            hide_sprite(fx[i].spr);
        }
    }
}

static void spawn_wave_flag(u8 id)
{
    if (spawn_flags[id]) return;
    spawn_flags[id] = 1;
    switch (id) {
    case 1:
        spawn_enemy(EN_RUNNER, 420, -1);
        spawn_enemy(EN_RUNNER, 480, -1);
        spawn_enemy(EN_RUNNER, 540, -1);
        break;
    case 2:
        camera_locked = TRUE;
        lock_left = 700;
        lock_right = 1080;
        spawn_enemy(EN_RUNNER, 1000, -1);
        spawn_enemy(EN_RUNNER, 740, 1);
        spawn_enemy(EN_JUMPER, 940, -1);
        break;
    case 3:
        spawn_enemy(EN_ARMORED, 1280, -1);
        spawn_enemy(EN_RUNNER, 1360, -1);
        break;
    case 4:
        camera_locked = TRUE;
        lock_left = 1500;
        lock_right = 1880;
        spawn_enemy(EN_JUMPER, 1800, -1);
        spawn_enemy(EN_RUNNER, 1540, 1);
        spawn_enemy(EN_RUNNER, 1840, -1);
        spawn_enemy(EN_ARMORED, 1700, -1);
        break;
    case 5:
        spawn_enemy(EN_RUNNER, 2100, -1);
        spawn_enemy(EN_JUMPER, 2180, -1);
        break;
    case 6:
        camera_locked = TRUE;
        lock_left = 2280;
        lock_right = 2540;
        spawn_enemy(EN_BOSS, 2460, -1);
        boss_spawned = TRUE;
        VDP_drawText("MAE JAVALI", 14, 2);
        break;
    }
}

static void pump_events(void)
{
    if (cam_x > 280) spawn_wave_flag(1);
    if (cam_x > 680) spawn_wave_flag(2);
    if (cam_x > 1180) spawn_wave_flag(3);
    if (cam_x > 1480) spawn_wave_flag(4);
    if (cam_x > 2000) spawn_wave_flag(5);
    if (cam_x > 2240) spawn_wave_flag(6);

    if (camera_locked && live_enemies() == 0) {
        camera_locked = FALSE;
        go_flash = TRUE;
        go_timer = 50;
        VDP_clearTextLine(2);
        if (boss_spawned) {
            state = ST_WIN;
            dialog_i = 0;
            clear_text();
        }
    }
}

static void update_camera(void)
{
    s16 lead = pl[0].x;
    u8 i;
    for (i = 1; i < players_n; i++) {
        if (pl[i].alive && pl[i].x > lead) lead = pl[i].x;
    }
    s16 want = lead - 80;
    if (want < 0) want = 0;
    if (want > WORLD_W - SCREEN_W) want = WORLD_W - SCREEN_W;
    if (want < cam_x) want = cam_x; /* never scroll back */
    if (camera_locked) {
        if (want < lock_left) want = lock_left;
        if (want > lock_right - SCREEN_W) want = lock_right - SCREEN_W;
        if (want < cam_x) want = cam_x;
    }
    cam_x = want;
    VDP_setHorizontalScroll(BG_A, -cam_x);
    VDP_setHorizontalScroll(BG_B, -(cam_x / 3));
    fill_visible_map(cam_x);
}

static void reset_entities(void)
{
    u16 i;
    for (i = 0; i < MAX_ENEMIES; i++) { en[i].alive = FALSE; en[i].spr = NULL; }
    for (i = 0; i < MAX_BULLETS; i++) { bu[i].alive = FALSE; bu[i].spr = NULL; }
    for (i = 0; i < MAX_FX; i++) { fx[i].alive = FALSE; fx[i].spr = NULL; }
    for (i = 0; i < MAX_CRATES; i++) { cr[i].alive = FALSE; cr[i].spr = NULL; }
    for (i = 0; i < 16; i++) spawn_flags[i] = 0;
    for (i = 0; i < 7; i++) hearts[i] = NULL;
    boss_spawned = FALSE;
    camera_locked = FALSE;
    go_flash = FALSE;
    filled_upto = 0;
    cam_x = 0;
}

static void start_stage(void)
{
    u8 i;
    SPR_end();
    VDP_clearPlane(BG_A, TRUE);
    VDP_clearPlane(BG_B, TRUE);
    clear_text();
    VDP_setBackgroundColor(0);
    PAL_setPalette(PAL0, pal_stage.data, CPU);
    PAL_setPalette(PAL1, kiko_sprite.palette->data, CPU);
    PAL_setPalette(PAL2, javali_sprite.palette->data, CPU);
    PAL_setPalette(PAL3, pal_stage.data, CPU);

    VDP_loadTileSet(&tileset_stage, TILE_USER_INDEX, DMA);
    VDP_setScrollingMode(HSCROLL_PLANE, VSCROLL_PLANE);
    SPR_init();
    reset_entities();
    fill_visible_map(0);
    {
        u16 x, y;
        for (y = 22; y < 28; y++) {
            for (x = 0; x < 64; x++) {
                u8 kind = (y <= 23) ? T_GRASS : T_DIRT;
                u16 tid = tile_id(kind, x & 1, y & 1);
                VDP_setTileMapXY(BG_A, TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, tid), x, y);
            }
        }
    }

    lives = (difficulty == DIFF_HARD) ? 3 : (difficulty == DIFF_EASY) ? 6 : 4;
    score = 0;
    intro_done = FALSE;

    for (i = 0; i < players_n; i++) {
        Player *p = &pl[i];
        p->alive = TRUE;
        p->x = 48 + i * 36;
        p->y = GROUND_Y - 32;
        p->vx = 0;
        p->vy = 0;
        p->hp_max = (difficulty == DIFF_HARD) ? 6 : 8;
        p->hp = p->hp_max;
        p->anim = ANIM_IDLE;
        p->frame = 0;
        p->timer = 0;
        p->shoot_cd = 0;
        p->melee_cd = 0;
        p->invuln = 40;
        p->rage = 0;
        p->on_ground = TRUE;
        p->facing_left = FALSE;
        p->pad = (i == 0) ? JOY_1 : JOY_2;
        p->spr = SPR_addSprite(&kiko_sprite, p->x, p->y, TILE_ATTR(PAL1, TRUE, FALSE, FALSE));
        SPR_setAnim(p->spr, ANIM_IDLE);
    }

    cr[0].alive = TRUE; cr[0].x = 520; cr[0].y = GROUND_Y - 32;
    cr[1].alive = TRUE; cr[1].x = 1240; cr[1].y = GROUND_Y - 32;
    cr[2].alive = TRUE; cr[2].x = 2100; cr[2].y = GROUND_Y - 32;
    for (i = 0; i < 3; i++) {
        cr[i].spr = SPR_addSprite(&crate_sprite, world_to_sx(cr[i].x), cr[i].y, TILE_ATTR(PAL2, TRUE, FALSE, FALSE));
    }

    dialog_i = 0;
    state = ST_DIALOG;
}

static void enter_title(void)
{
    u16 i;
    if (SPR_isInitialized()) SPR_end();
    VDP_setScrollingMode(HSCROLL_PLANE, VSCROLL_PLANE);
    VDP_setHorizontalScroll(BG_A, 0);
    VDP_setHorizontalScroll(BG_B, 0);
    VDP_clearPlane(BG_A, TRUE);
    VDP_clearPlane(BG_B, TRUE);
    clear_text();
    VDP_setBackgroundColor(0);
    PAL_setPalette(PAL0, img_title.palette->data, CPU);
    VDP_drawImageEx(BG_A, &img_title, TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, TILE_USER_INDEX), 5, 3, FALSE, TRUE);
    VDP_setTextPalette(PAL0);
    VDP_drawText("A FAZENDA TOMADA", 12, 16);
    VDP_drawText("MEGA DRIVE / GENESIS", 10, 18);
    state = ST_TITLE;
    menu_sel = 0;
    hud_timer = 0;
    for (i = 0; i < MAX_PLAYERS; i++) pl[i].spr = NULL;
}

static void enter_menu(void)
{
    VDP_clearPlane(BG_A, TRUE);
    VDP_clearPlane(BG_B, TRUE);
    clear_text();
    PAL_setPalette(PAL0, pal_stage.data, CPU);
    VDP_setBackgroundColor(0);
    VDP_setTextPalette(PAL0);
    VDP_drawText("KIKO WILD FURY - MATAJAVA", 7, 4);
    VDP_drawText("1 PLAYER", 14, 10);
    VDP_drawText("2 PLAYERS", 14, 12);
    VDP_drawText("OPTIONS", 14, 14);
    VDP_drawText("A / START confirma", 10, 22);
    state = ST_MENU;
}

static void draw_menu_cursor(void)
{
    VDP_drawText("  ", 11, 10);
    VDP_drawText("  ", 11, 12);
    VDP_drawText("  ", 11, 14);
    VDP_drawText(">", 11, 10 + menu_sel * 2);
}

static void enter_options(void)
{
    clear_text();
    VDP_drawText("OPTIONS", 16, 4);
    VDP_drawText("DIFICULDADE", 8, 8);
    VDP_drawText("ESQ/DIR muda   B/START volta", 5, 22);
    state = ST_OPTIONS;
}

static void draw_options(void)
{
    VDP_drawText("FACIL   ", 22, 8);
    VDP_drawText("NORMAL  ", 22, 8);
    VDP_drawText("DIFICIL ", 22, 8);
    if (difficulty == DIFF_EASY) VDP_drawText("FACIL   ", 22, 8);
    else if (difficulty == DIFF_HARD) VDP_drawText("DIFICIL ", 22, 8);
    else VDP_drawText("NORMAL  ", 22, 8);
    VDP_drawText("A atira  B pula  C especial", 6, 14);
    VDP_drawText("Nunca role a camera para tras", 5, 16);
}

static void draw_dialog(void)
{
    const char **lines = (state == ST_WIN) ? WIN_LINES : INTRO;
    u8 i;
    VDP_setTextPalette(PAL0);
    VDP_drawText("+------------------------------+", 4, 18);
    for (i = 0; i < 3; i++) {
        const char *s = lines[dialog_i + i];
        VDP_clearText(5, 19 + i, 30);
        if (s) VDP_drawText(s, 5, 19 + i);
    }
    VDP_drawText("+------------------------------+", 4, 22);
    VDP_drawText("A / START", 15, 23);
}

static bool any_player_alive(void)
{
    u8 i;
    for (i = 0; i < players_n; i++) if (pl[i].alive && pl[i].hp > 0) return TRUE;
    for (i = 0; i < players_n; i++) if (pl[i].alive) return TRUE;
    return FALSE;
}

static void tick_title(u16 joy, u16 changed)
{
    hud_timer++;
    if ((hud_timer / 24) & 1) VDP_drawText("PRESS START", 14, 20);
    else VDP_drawText("           ", 14, 20);
    if (changed & (BUTTON_START | BUTTON_A | BUTTON_C)) enter_menu();
    (void)joy;
}

static void tick_menu(u16 joy, u16 changed)
{
    if (changed & BUTTON_UP) { if (menu_sel) menu_sel--; }
    if (changed & BUTTON_DOWN) { if (menu_sel < 2) menu_sel++; }
    draw_menu_cursor();
    if (changed & (BUTTON_START | BUTTON_A)) {
        if (menu_sel == 2) enter_options();
        else {
            players_n = (menu_sel == 1) ? 2 : 1;
            start_stage();
        }
    }
    (void)joy;
}

static void tick_options(u16 joy, u16 changed)
{
    if (changed & BUTTON_LEFT) { if (difficulty) difficulty--; }
    if (changed & BUTTON_RIGHT) { if (difficulty < 2) difficulty++; }
    draw_options();
    if (changed & (BUTTON_B | BUTTON_START)) enter_menu();
    (void)joy;
}

static void tick_dialog(u16 changed)
{
    const char **lines = (state == ST_WIN) ? WIN_LINES : INTRO;
    SPR_update();
    draw_dialog();
    if (changed & (BUTTON_A | BUTTON_START | BUTTON_C)) {
        dialog_i += 3;
        if (lines[dialog_i] == NULL) {
            if (state == ST_WIN) enter_title();
            else {
                clear_text();
                state = ST_PLAY;
                intro_done = TRUE;
            }
        }
    }
}

static void tick_play(u16 joy, u16 changed)
{
    u8 i;
    if (changed & BUTTON_START) {
        state = ST_PAUSE;
        VDP_drawText("PAUSE", 17, 12);
        return;
    }
    for (i = 0; i < players_n; i++) update_player(&pl[i], i);
    update_enemies();
    update_bullets();
    update_fx();
    pump_events();
    update_camera();

    for (i = 0; i < 3; i++) {
        if (!cr[i].alive || !cr[i].spr) continue;
        SPR_setPosition(cr[i].spr, world_to_sx(cr[i].x), cr[i].y);
        u8 p;
        for (p = 0; p < players_n; p++) {
            if (!pl[p].alive) continue;
            if (abs(pl[p].x - cr[i].x) < 20 && abs(pl[p].y - cr[i].y) < 20) {
                cr[i].alive = FALSE;
                hide_sprite(cr[i].spr);
                score += 200;
                pl[p].hp = pl[p].hp_max;
                sfx_beep(160, 6);
            }
        }
    }

    if (go_timer) {
        go_timer--;
        if (go_timer == 0) go_flash = FALSE;
    }
    hud_timer++;
    if ((hud_timer & 7) == 0) draw_hud();

    if (!any_player_alive()) {
        if (continues_left) {
            state = ST_GAMEOVER;
            VDP_drawText("CONTINUE? START", 12, 12);
        } else {
            state = ST_GAMEOVER;
            VDP_drawText("GAME OVER - START", 11, 12);
        }
    }
    SPR_update();
    (void)joy;
}

static u16 prev_joy;

int main(bool hardReset)
{
    u16 joy, changed;

    VDP_setScreenWidth320();
    VDP_setPlaneSize(64, 32, TRUE);
    PSG_reset();
    JOY_init();
    players_n = 1;
    difficulty = DIFF_MED;
    continues_left = 3;
    enter_title();
    prev_joy = 0;
    (void)hardReset;

    while (TRUE) {
        joy = JOY_readJoypad(JOY_1);
        changed = (joy ^ prev_joy) & joy;
        prev_joy = joy;
        sfx_update();

        switch (state) {
        case ST_TITLE:    tick_title(joy, changed); break;
        case ST_MENU:     tick_menu(joy, changed); break;
        case ST_OPTIONS:  tick_options(joy, changed); break;
        case ST_DIALOG:
        case ST_WIN:      tick_dialog(changed); break;
        case ST_PAUSE:
            SPR_update();
            if (changed & BUTTON_START) {
                VDP_drawText("     ", 17, 12);
                state = ST_PLAY;
            }
            break;
        case ST_PLAY:     tick_play(joy, changed); break;
        case ST_GAMEOVER:
            if (changed & BUTTON_START) {
                if (continues_left && !any_player_alive()) {
                    continues_left--;
                    start_stage();
                } else enter_title();
            }
            if (changed & BUTTON_B) enter_title();
            break;
        default: break;
        }
        SYS_doVBlankProcess();
    }
    return 0;
}
