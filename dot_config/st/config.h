/* See LICENSE file for copyright and license details. */

/*
 * st is configured at compile time. Copy or symlink this file as config.h in
 * the st source tree before running make.
 */

static char *font = "Hack Nerd Font:size=12:antialias=true:autohint=true";
static int borderpx = 10;

/*
 * Program launch precedence:
 * 1: program passed with -e
 * 2: scroll and/or utmp
 * 3: SHELL environment variable
 * 4: user's shell from /etc/passwd
 * 5: value of shell below
 */
static char *shell = "/bin/sh";
char *utmp = NULL;
char *scroll = NULL;
char *stty_args = "stty raw pass8 nl -echo -iexten -cstopb 38400";
char *vtiden = "\033[?6c";

float cwscale = 1.0;
float chscale = 1.0;

wchar_t *worddelimiters = L" `'\"()[]{}<>,";

int allowaltscreen = 1;
int allowwindowops = 0;
static int bellvolume = 0;

char *termname = "st-256color";
unsigned int tabspaces = 8;

static const char *colorname[] = {
	/* Dracula normal colors */
	[0] = "#21222c",
	[1] = "#ff5555",
	[2] = "#50fa7b",
	[3] = "#f1fa8c",
	[4] = "#bd93f9",
	[5] = "#ff79c6",
	[6] = "#8be9fd",
	[7] = "#f8f8f2",

	/* Dracula bright colors */
	[8]  = "#6272a4",
	[9]  = "#ff6e6e",
	[10] = "#69ff94",
	[11] = "#ffffa5",
	[12] = "#d6acff",
	[13] = "#ff92df",
	[14] = "#a4ffff",
	[15] = "#ffffff",

	[255] = 0,

	/* Extra colors used by defaults below */
	[256] = "#f8f8f2",
	[257] = "#282a36",
	[258] = "#44475a",
	[259] = "#f1fa8c",
};

/*
 * Default colors (colorname index):
 * foreground, background, cursor, reverse cursor
 */
unsigned int defaultfg = 256;
unsigned int defaultbg = 257;
unsigned int defaultcs = 256;
static unsigned int defaultrcs = 257;

/*
 * Default cursor shape:
 * 2: block, 4: underline, 6: bar
 */
static unsigned int cursorshape = 6;

static unsigned int cols = 120;
static unsigned int rows = 34;

static unsigned int mouseshape = XC_xterm;
static unsigned int mousefg = 256;
static unsigned int mousebg = 257;

static unsigned int defaultattr = 11;
static uint forcemousemod = ShiftMask;

static MouseShortcut mshortcuts[] = {
	/* mask                 button   function        argument        release */
	{ XK_ANY_MOD,           Button2, selpaste,       {.i = 0},       1 },
	{ ShiftMask,            Button4, ttysend,        {.s = "\033[5;2~"}, 0 },
	{ XK_ANY_MOD,           Button4, ttysend,        {.s = "\031"},      0 },
	{ ShiftMask,            Button5, ttysend,        {.s = "\033[6;2~"}, 0 },
	{ XK_ANY_MOD,           Button5, ttysend,        {.s = "\005"},      0 },
};

#define MODKEY Mod1Mask
#define TERMMOD (ControlMask|ShiftMask)

static Shortcut shortcuts[] = {
	/* mask                 keysym          function        argument */
	{ TERMMOD,              XK_C,           clipcopy,       {.i = 0} },
	{ TERMMOD,              XK_V,           clippaste,      {.i = 0} },
	{ TERMMOD,              XK_Y,           selpaste,       {.i = 0} },
	{ ShiftMask,            XK_Insert,      selpaste,       {.i = 0} },
	{ TERMMOD,              XK_Prior,       zoom,           {.f = +1} },
	{ TERMMOD,              XK_Next,        zoom,           {.f = -1} },
	{ TERMMOD,              XK_Home,        zoomreset,      {.f = 0} },
	{ ControlMask,          XK_plus,        zoom,           {.f = +1} },
	{ ControlMask,          XK_equal,       zoom,           {.f = +1} },
	{ ControlMask,          XK_KP_Add,      zoom,           {.f = +1} },
	{ ControlMask,          XK_minus,       zoom,           {.f = -1} },
	{ ControlMask,          XK_KP_Subtract, zoom,           {.f = -1} },
	{ ControlMask,          XK_0,           zoomreset,      {.f = 0} },
	{ ControlMask,          XK_KP_0,        zoomreset,      {.f = 0} },
	{ TERMMOD,              XK_Num_Lock,    numlock,        {.i = 0} },
};

static Key keys[] = {
	/* keysym           mask            string      appkey appcursor */
	{ XK_KP_Home,       ShiftMask,      "\033[2J",       0,   -1},
	{ XK_KP_Home,       ShiftMask,      "\033[1;2H",     0,   +1},
	{ XK_KP_Home,       XK_ANY_MOD,     "\033[H",        0,   -1},
	{ XK_KP_Home,       XK_ANY_MOD,     "\033[1~",       0,   +1},
	{ XK_KP_Up,         XK_ANY_MOD,     "\033Ox",       +1,    0},
	{ XK_KP_Up,         XK_ANY_MOD,     "\033[A",        0,   -1},
	{ XK_KP_Up,         XK_ANY_MOD,     "\033OA",        0,   +1},
	{ XK_KP_Down,       XK_ANY_MOD,     "\033Or",       +1,    0},
	{ XK_KP_Down,       XK_ANY_MOD,     "\033[B",        0,   -1},
	{ XK_KP_Down,       XK_ANY_MOD,     "\033OB",        0,   +1},
	{ XK_KP_Left,       XK_ANY_MOD,     "\033Ot",       +1,    0},
	{ XK_KP_Left,       XK_ANY_MOD,     "\033[D",        0,   -1},
	{ XK_KP_Left,       XK_ANY_MOD,     "\033OD",        0,   +1},
	{ XK_KP_Right,      XK_ANY_MOD,     "\033Ov",       +1,    0},
	{ XK_KP_Right,      XK_ANY_MOD,     "\033[C",        0,   -1},
	{ XK_KP_Right,      XK_ANY_MOD,     "\033OC",        0,   +1},
	{ XK_KP_Prior,      ShiftMask,      "\033[5;2~",     0,    0},
	{ XK_KP_Prior,      XK_ANY_MOD,     "\033[5~",       0,    0},
	{ XK_KP_Begin,      XK_ANY_MOD,     "\033[E",        0,    0},
	{ XK_KP_End,        ControlMask,    "\033[J",       -1,    0},
	{ XK_KP_End,        ControlMask,    "\033[1;5F",    +1,    0},
	{ XK_KP_End,        ShiftMask,      "\033[K",       -1,    0},
	{ XK_KP_End,        ShiftMask,      "\033[1;2F",    +1,    0},
	{ XK_KP_End,        XK_ANY_MOD,     "\033[4~",       0,    0},
	{ XK_KP_Next,       ShiftMask,      "\033[6;2~",     0,    0},
	{ XK_KP_Next,       XK_ANY_MOD,     "\033[6~",       0,    0},
	{ XK_KP_Insert,     ShiftMask,      "\033[2;2~",    +1,    0},
	{ XK_KP_Insert,     ShiftMask,      "\033[4l",      -1,    0},
	{ XK_KP_Insert,     ControlMask,    "\033[L",       -1,    0},
	{ XK_KP_Insert,     ControlMask,    "\033[2;5~",    +1,    0},
	{ XK_KP_Insert,     XK_ANY_MOD,     "\033[4h",      -1,    0},
	{ XK_KP_Insert,     XK_ANY_MOD,     "\033[2~",      +1,    0},
	{ XK_KP_Delete,     ControlMask,    "\033[M",       -1,    0},
	{ XK_KP_Delete,     ControlMask,    "\033[3;5~",    +1,    0},
	{ XK_KP_Delete,     ShiftMask,      "\033[2K",      -1,    0},
	{ XK_KP_Delete,     ShiftMask,      "\033[3;2~",    +1,    0},
	{ XK_KP_Delete,     XK_ANY_MOD,     "\033[P",       -1,    0},
	{ XK_KP_Delete,     XK_ANY_MOD,     "\033[3~",      +1,    0},
	{ XK_KP_Multiply,   XK_ANY_MOD,     "\033Oj",       +2,    0},
	{ XK_KP_Add,        XK_ANY_MOD,     "\033Ok",       +2,    0},
	{ XK_KP_Enter,      XK_ANY_MOD,     "\033OM",       +2,    0},
	{ XK_KP_Enter,      XK_ANY_MOD,     "\r",           -1,    0},
	{ XK_KP_Subtract,   XK_ANY_MOD,     "\033Om",       +2,    0},
	{ XK_KP_Decimal,    XK_ANY_MOD,     "\033On",       +2,    0},
	{ XK_KP_Divide,     XK_ANY_MOD,     "\033Oo",       +2,    0},
	{ XK_KP_0,          XK_ANY_MOD,     "\033Op",       +2,    0},
	{ XK_KP_1,          XK_ANY_MOD,     "\033Oq",       +2,    0},
	{ XK_KP_2,          XK_ANY_MOD,     "\033Or",       +2,    0},
	{ XK_KP_3,          XK_ANY_MOD,     "\033Os",       +2,    0},
	{ XK_KP_4,          XK_ANY_MOD,     "\033Ot",       +2,    0},
	{ XK_KP_5,          XK_ANY_MOD,     "\033Ou",       +2,    0},
	{ XK_KP_6,          XK_ANY_MOD,     "\033Ov",       +2,    0},
	{ XK_KP_7,          XK_ANY_MOD,     "\033Ow",       +2,    0},
	{ XK_KP_8,          XK_ANY_MOD,     "\033Ox",       +2,    0},
	{ XK_KP_9,          XK_ANY_MOD,     "\033Oy",       +2,    0},
	{ XK_Up,            ShiftMask,      "\033[1;2A",    0,    0},
	{ XK_Up,            Mod1Mask,       "\033[1;3A",    0,    0},
	{ XK_Up,            ShiftMask|Mod1Mask, "\033[1;4A", 0,   0},
	{ XK_Up,            ControlMask,    "\033[1;5A",    0,    0},
	{ XK_Up,            ShiftMask|ControlMask, "\033[1;6A", 0, 0},
	{ XK_Up,            ControlMask|Mod1Mask, "\033[1;7A", 0, 0},
	{ XK_Up,            ShiftMask|ControlMask|Mod1Mask, "\033[1;8A", 0, 0},
	{ XK_Up,            XK_ANY_MOD,     "\033[A",        0,   -1},
	{ XK_Up,            XK_ANY_MOD,     "\033OA",        0,   +1},
	{ XK_Down,          ShiftMask,      "\033[1;2B",    0,    0},
	{ XK_Down,          Mod1Mask,       "\033[1;3B",    0,    0},
	{ XK_Down,          ShiftMask|Mod1Mask, "\033[1;4B", 0,   0},
	{ XK_Down,          ControlMask,    "\033[1;5B",    0,    0},
	{ XK_Down,          ShiftMask|ControlMask, "\033[1;6B", 0, 0},
	{ XK_Down,          ControlMask|Mod1Mask, "\033[1;7B", 0, 0},
	{ XK_Down,          ShiftMask|ControlMask|Mod1Mask, "\033[1;8B", 0, 0},
	{ XK_Down,          XK_ANY_MOD,     "\033[B",        0,   -1},
	{ XK_Down,          XK_ANY_MOD,     "\033OB",        0,   +1},
	{ XK_Left,          ShiftMask,      "\033[1;2D",    0,    0},
	{ XK_Left,          Mod1Mask,       "\033[1;3D",    0,    0},
	{ XK_Left,          ShiftMask|Mod1Mask, "\033[1;4D", 0,   0},
	{ XK_Left,          ControlMask,    "\033[1;5D",    0,    0},
	{ XK_Left,          ShiftMask|ControlMask, "\033[1;6D", 0, 0},
	{ XK_Left,          ControlMask|Mod1Mask, "\033[1;7D", 0, 0},
	{ XK_Left,          ShiftMask|ControlMask|Mod1Mask, "\033[1;8D", 0, 0},
	{ XK_Left,          XK_ANY_MOD,     "\033[D",        0,   -1},
	{ XK_Left,          XK_ANY_MOD,     "\033OD",        0,   +1},
	{ XK_Right,         ShiftMask,      "\033[1;2C",    0,    0},
	{ XK_Right,         Mod1Mask,       "\033[1;3C",    0,    0},
	{ XK_Right,         ShiftMask|Mod1Mask, "\033[1;4C", 0,   0},
	{ XK_Right,         ControlMask,    "\033[1;5C",    0,    0},
	{ XK_Right,         ShiftMask|ControlMask, "\033[1;6C", 0, 0},
	{ XK_Right,         ControlMask|Mod1Mask, "\033[1;7C", 0, 0},
	{ XK_Right,         ShiftMask|ControlMask|Mod1Mask, "\033[1;8C", 0, 0},
	{ XK_Right,         XK_ANY_MOD,     "\033[C",        0,   -1},
	{ XK_Right,         XK_ANY_MOD,     "\033OC",        0,   +1},
	{ XK_Escape,        XK_ANY_MOD,     "\033",          0,    0},
	{ XK_Insert,        ShiftMask,      "\033[4l",      -1,    0},
	{ XK_Insert,        ShiftMask,      "\033[2;2~",    +1,    0},
	{ XK_Insert,        ControlMask,    "\033[L",       -1,    0},
	{ XK_Insert,        ControlMask,    "\033[2;5~",    +1,    0},
	{ XK_Insert,        XK_ANY_MOD,     "\033[4h",      -1,    0},
	{ XK_Insert,        XK_ANY_MOD,     "\033[2~",      +1,    0},
	{ XK_Delete,        ControlMask,    "\033[M",       -1,    0},
	{ XK_Delete,        ControlMask,    "\033[3;5~",    +1,    0},
	{ XK_Delete,        ShiftMask,      "\033[2K",      -1,    0},
	{ XK_Delete,        ShiftMask,      "\033[3;2~",    +1,    0},
	{ XK_Delete,        XK_ANY_MOD,     "\033[P",       -1,    0},
	{ XK_Delete,        XK_ANY_MOD,     "\033[3~",      +1,    0},
	{ XK_BackSpace,     XK_NO_MOD,      "\177",          0,    0},
	{ XK_BackSpace,     Mod1Mask,       "\033\177",      0,    0},
	{ XK_Home,          ShiftMask,      "\033[2J",       0,   -1},
	{ XK_Home,          ShiftMask,      "\033[1;2H",     0,   +1},
	{ XK_Home,          XK_ANY_MOD,     "\033[H",        0,   -1},
	{ XK_Home,          XK_ANY_MOD,     "\033[1~",       0,   +1},
	{ XK_End,           ControlMask,    "\033[J",       -1,    0},
	{ XK_End,           ControlMask,    "\033[1;5F",    +1,    0},
	{ XK_End,           ShiftMask,      "\033[K",       -1,    0},
	{ XK_End,           ShiftMask,      "\033[1;2F",    +1,    0},
	{ XK_End,           XK_ANY_MOD,     "\033[4~",       0,    0},
	{ XK_Prior,         ControlMask,    "\033[5;5~",     0,    0},
	{ XK_Prior,         ShiftMask,      "\033[5;2~",     0,    0},
	{ XK_Prior,         XK_ANY_MOD,     "\033[5~",       0,    0},
	{ XK_Next,          ControlMask,    "\033[6;5~",     0,    0},
	{ XK_Next,          ShiftMask,      "\033[6;2~",     0,    0},
	{ XK_Next,          XK_ANY_MOD,     "\033[6~",       0,    0},
	{ XK_F1,            XK_ANY_MOD,     "\033OP",        0,    0},
	{ XK_F2,            XK_ANY_MOD,     "\033OQ",        0,    0},
	{ XK_F3,            XK_ANY_MOD,     "\033OR",        0,    0},
	{ XK_F4,            XK_ANY_MOD,     "\033OS",        0,    0},
	{ XK_F5,            XK_ANY_MOD,     "\033[15~",      0,    0},
	{ XK_F6,            XK_ANY_MOD,     "\033[17~",      0,    0},
	{ XK_F7,            XK_ANY_MOD,     "\033[18~",      0,    0},
	{ XK_F8,            XK_ANY_MOD,     "\033[19~",      0,    0},
	{ XK_F9,            XK_ANY_MOD,     "\033[20~",      0,    0},
	{ XK_F10,           XK_ANY_MOD,     "\033[21~",      0,    0},
	{ XK_F11,           XK_ANY_MOD,     "\033[23~",      0,    0},
	{ XK_F12,           XK_ANY_MOD,     "\033[24~",      0,    0},
};

static MouseKey mkeys[] = {
	/* button               mask            string */
	{ Button4,              XK_NO_MOD,      "\031" },
	{ Button5,              XK_NO_MOD,      "\005" },
};
