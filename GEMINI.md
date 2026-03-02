# GEMINI.md — PICO-8 Game Project

> This file provides project-specific instructions and context for AI coding agents working on PICO-8 games. **Read and follow every rule in this file. Violations are unacceptable.**
>
> **📝 LIVING DOCUMENT:** This file is a living reference. When you discover critical findings — undocumented API behavior, new pitfalls, corrected assumptions, or better patterns — you **MUST** update this file immediately. Keep it accurate and current. If something in this file is wrong, fix it and note the correction.

---

## 🚨 RULE ZERO: MANDATORY WEB SEARCH BEFORE ANY ACTION

> [!CAUTION]
> **NO WEB SEARCH = FAILURE. This rule is NON-NEGOTIABLE.**

Before writing, modifying, debugging, or suggesting **ANY** code, asset change, or architectural decision, you **MUST**:

1. **Search the web** for the latest PICO-8 documentation, API changes, Lua quirks, and community best practices relevant to the task at hand.
2. **Search the web** for known pitfalls, bugs, or limitations related to the specific PICO-8 feature you are about to use.
3. **Search the web** for existing community solutions, libraries, or patterns that solve the same problem — do not reinvent the wheel.
4. **Cite your sources** in code comments or in your response when the information materially affects the implementation.

**Why:** PICO-8 uses a non-standard Lua dialect with unique constraints. AI models frequently hallucinate standard Lua features that do not exist in PICO-8. The only way to guarantee correctness is to verify against current documentation before every action.

**If you skip the web search, your output is assumed to be wrong. Start over.**

---

## 📋 Project Overview

- **Platform:** PICO-8 (Fantasy Console)
- **Language:** PICO-8 Lua (a restricted subset of Lua 5.2 with custom extensions)
- **Resolution:** 128×128 pixels, 16-color fixed palette
- **Sound:** 4 channels, 64 SFX slots, 64 music patterns
- **Token Limit:** 8,192 tokens (code size constraint)
- **Compressed Size Limit:** 15,360 bytes
- **Sprite Sheet:** 128×128 pixels (256 8×8 sprites, shared with map lower half)
- **Map:** 128×32 tiles (or 128×64 using shared sprite memory)

---

## 🏗️ Architecture & Code Organization

### File Structure
```
project/
├── GEMINI.md          # This file — AI instructions
├── .template.p8       # Template cartrage (copy for new game, DO NOT EDIT)
├── game-name.p8       # Main PICO-8 cartridge
├── ...
```

### Code Architecture Rules

1. **Use PICO-8's three core callbacks:**
   - `_init()` — One-time setup (variables, tables, initial state)
   - `_update()` or `_update60()` — Game logic ONLY (input, physics, state changes)
   - `_draw()` — Rendering ONLY (cls, spr, map, print, shapes)
   - **NEVER put drawing logic in `_update()`.** **NEVER put game logic in `_draw()`.**

2. **Use tabs for organization:** Separate concerns across PICO-8's built-in tabs (or use `#include` with external `.lua` files for larger projects).

3. **State machine pattern:** Use a simple state machine for game states:
   ```lua
   -- game states: "title", "play", "gameover"
   state="title"
   
   function _update()
     if state=="title" then update_title()
     elseif state=="play" then update_play()
     elseif state=="gameover" then update_gameover()
     end
   end
   ```

4. **Entity pattern:** Use tables-of-tables for game objects:
   ```lua
   enemies={}
   
   function spawn_enemy(x,y,type)
     add(enemies, {x=x, y=y, type=type, hp=3})
   end
   
   function update_enemies()
     for e in all(enemies) do
       -- update logic
       if e.hp<=0 then del(enemies,e) end
     end
   end
   ```

---

## 🎮 PICO-8 Lua Rules (CRITICAL — AI MUST FOLLOW)

> [!WARNING]
> PICO-8 Lua is NOT standard Lua. The following differences will cause silent bugs or crashes if ignored.

### What PICO-8 Lua Does NOT Have
- ❌ No standard Lua library (`string.format`, `table.insert`, `io`, `os`, `math.floor`, etc.)
- ❌ No `require()` or `module()` — use `#include` for external files
- ❌ No floating-point numbers — PICO-8 uses **16:16 fixed-point** arithmetic
- ❌ No `math.*` functions — use PICO-8 equivalents: `flr()`, `ceil()`, `abs()`, `sqrt()`, `sin()`, `cos()`, `atan2()`, `rnd()`, `srand()`, `min()`, `max()`, `mid()`, `sgn()`
- ❌ No `table.insert` / `table.remove` — use `add(tbl, val, [idx])` and `del(tbl, val)` or `deli(tbl, idx)`
- ❌ No `table.concat`, `string.format`, `string.rep` — no PICO-8 equivalents
- ❌ No `string.byte`, `string.char` — use PICO-8 equivalents: `ord(str, [idx])` and `chr(val)`
- ❌ No `string.sub` — use `sub(str, from, to)`
- ❌ No `tostring()` — use `tostr(val, [format_flags])`
- ❌ No `tonumber()` — use `tonum(str, [format_flags])`
- ❌ No `pcall()`, `xpcall()`, `error()`, `loadstring()`, `dofile()`, `collectgarbage()`, `_G`
- ❌ No `coroutine.*` library — use PICO-8 equivalents: `cocreate()`, `coresume()`, `costatus()`, `yield()`

### What PICO-8 Lua DOES Have (Standard Lua Features That Work)
- ✅ `pairs(tbl)` — iterate all key-value pairs (order not guaranteed)
- ✅ `ipairs(tbl)` — iterate sequential integer-keyed entries in order
- ✅ `#tbl` — length operator for 1-based sequential tables
- ✅ `unpack(tbl, [i], [j])` — unpack table values into multiple returns
- ✅ `select(idx, ...)` — select from variadic arguments (`select("#",...)` for count)
- ✅ `type(val)` — returns type as string ("number", "string", "table", "boolean", "function", "nil")
- ✅ `setmetatable(tbl, mt)` / `getmetatable(tbl)` — full metatable support (including `__index`, `__newindex`, `__add`, `__sub`, `__mul`, `__div`, `__len`, `__eq`, `__lt`, `__le`, `__tostring`, `__call`)
- ✅ `rawset()`, `rawget()`, `rawequal()`, `rawlen()` — bypass metamethods
- ✅ Variadic functions with `...` syntax
- ✅ `goto` / `::label::` — unconditional jumps (used for custom main loops: `::_:: ... goto _`)
- ✅ `table.sort(tbl, [comp])` — in-place sort with optional comparison function (works as in standard Lua)

### What PICO-8 Lua DOES Have (Unique Extensions)
- ✅ `+=`, `-=`, `*=`, `/=`, `%=`, `..=` and bitwise (`&=`, `|=`, etc.) compound assignment operators
- ✅ `!=` as an alias for `~=` (not-equal)
- ✅ `\` integer division operator — `9\2` → `4` (equivalent to `flr(9/2)`)
- ✅ `?` as shorthand for `print` — `?"hello"` instead of `print("hello")`
- ✅ Single-line `if` shorthand — `if (cond) stmt1 stmt2` (parentheses required, no `then`/`end`)
- ✅ Single-line `while` shorthand — `while (cond) stmt` (parentheses required, no `do`/`end`)
- ✅ `print(str, x, y, col)` — built-in text rendering with P8SCII control codes
- ✅ `add(tbl, val, [idx])` / `del(tbl, val)` / `deli(tbl, [idx])` — table manipulation
- ✅ `all(tbl)` — iterator for sequential tables
- ✅ `foreach(tbl, func)` — apply function to each element
- ✅ `count(tbl, [val])` — count elements (or occurrences of a specific value)
- ✅ `split(str, [sep], [convert_numbers])` — split string into table (number sep = char groups)
- ✅ `btn(i, [p])` / `btnp(i, [p])` — button state (0-5: ⬅️➡️⬆️⬇️🅾️❎, players 0-7). `btnp` repeats after 15 frames, then every 4 frames. Custom delays: `poke(0x5f5c, initial_delay)` `poke(0x5f5d, repeat_delay)` (255 = never repeat, 0 = default).
- ✅ `spr(n, x, y, [w, h], [flip_x], [flip_y])` / `sspr(sx, sy, sw, sh, dx, dy, [dw, dh], [flip_x], [flip_y])` — sprite drawing
- ✅ `map(tile_x, tile_y, [sx, sy], [tile_w, tile_h], [layers])` / `mget(x, y)` / `mset(x, y, val)` / `fget(n, [f])` / `fset(n, [f], val)` — map/flags
- ✅ `tline(x0, y0, x1, y1, mx, my, [mdx, mdy], [layers])` — textured line from map data (for pseudo-3D / Mode 7 effects). Call `tline(N)` with a single arg to set the number of fractional bits for map coordinates: `tline(16)` = pixel precision (default=3, i.e. tile precision where 0.125 = 1 pixel). Higher values = more precision for close-up textured surfaces.
- ✅ `oval(x0, y0, x1, y1, [col])`, `ovalfill(x0, y0, x1, y1, [col])` — draw ellipses
- ✅ `rrect(x, y, w, h, [r], [col])`, `rrectfill(x, y, w, h, [r], [col])` — rounded rectangles. **NOTE:** unlike `rect()` which uses corner-to-corner coords, `rrect()` uses position + width/height + radius. `r` defaults to 0. (v0.2.7+)
- ✅ `circ(x, y, r, [col])`, `circfill(x, y, r, [col])` — circles
- ✅ `rect(x0, y0, x1, y1, [col])`, `rectfill(x0, y0, x1, y1, [col])` — rectangles (corner-to-corner)
- ✅ `line(x0, y0, [x1, y1, [col]])` — line drawing. Omit x1,y1 to continue from end of last line. Call `line()` with no args to reset continuation.
- ✅ `pset(x, y, [col])` — set pixel
- ✅ `pget()`, `sget()`, `sset()` — read/write individual pixels on screen/spritesheet
- ✅ `fillp(pattern)` — 4×4 fill pattern for dithering effects. Fill patterns can also be embedded in any COL parameter via high bits (see "Inline Fill Patterns" below).
- ✅ `cursor(x, y, [col])` / `color([col])` — set cursor position / default draw color. **Note:** `color()` with no args defaults to **6** (light gray), not 0.
- ✅ `sfx(n, [channel], [offset], [length])` — play sound effect. Returns channel index used (v0.2.7+). `music(n, [fade_len], [channel_mask])` — play music patterns.
- ✅ `camera([x, y])` / `clip(x, y, w, h, [clip_previous])` — display control. When `clip_previous` is true, the new clip rect is intersected with the old one.
- ✅ `pal(c0, c1, [p])` — swap color c0 for c1 in palette p (0=draw, 1=display, 2=secondary). Also accepts table form: `pal(tbl, [p])` to set multiple entries at once, e.g. `pal({[12]=9, [14]=8})`.
- ✅ `palt(c, [t])` — set transparency for color c. `palt()` resets to default (only color 0 transparent).
- ✅ `peek(addr, [n])`, `poke(addr, val1, [val2, ...])`, `peek2()`, `poke2()`, `peek4()`, `poke4()` — 8/16/32-bit memory access. `peek` can return multiple values (up to 8192). `poke` can write multiple sequential bytes.
- ✅ `@addr`, `%addr`, `$addr` — shorthand peek operators (8/16/32-bit, slightly faster)
- ✅ `memcpy()`, `memset()`, `reload()`, `cstore()` — memory operations
- ✅ `stat(n)` — system info (see stat reference below)
- ✅ `t()` / `time()` — seconds elapsed since cart started
- ✅ `cartdata(id)`, `dget(idx)`, `dset(idx, val)` — persistent save data (64 numbers)
- ✅ `cocreate()`, `coresume()`, `costatus()`, `yield()` — coroutines. **IMPORTANT:** Errors inside coroutines are silently swallowed! Always wrap: `assert(coresume(c))` to surface errors.
- ✅ `printh(str, [filename], [overwrite], [save_to_desktop])` — debug print to host terminal or file. Use `"@clip"` as filename to write to clipboard.
- ✅ `tostr(val, [format_flags])` / `tonum(val, [format_flags])` — with hex and integer modes
- ✅ `chr(val)` / `ord(str, [idx])` / `sub(str, from, [to])` — string/character operations
- ✅ `menuitem(idx, [label], [callback])` — custom pause menu items (up to 5)
- ✅ `extcmd(cmd, [p1, p2])` — system commands (screenshots, GIFs, audio recording, label, etc.). For `"video"`/`"screen"`: p1=scale factor, p2>0 saves to folder instead of desktop. For `"audio_end"`: p1>0 saves to folder.
- ✅ `flip()` — manual frame flip (needed for custom `goto`-based main loops)
- ✅ `assert(cond, [msg])` — stop with error if condition is false
- ✅ `load(filename, [breadcrumb], [param_str])` — load cart; `breadcrumb` adds a menu item to return. `run([param_str])` — restart cart. `stop([msg])` — halt with optional message. `ls([dir])` — list .p8 files (returns table at runtime).
- ✅ Uppercase is auto-converted to lowercase in `.p8` files
- ✅ Bitwise operators: `&` `|` `^^` `~` `<<` `>>` `>>>` `<<>` `>><`
- ✅ Bitwise functions: `band()` `bor()` `bxor()` `bnot()` `shl()` `shr()` `lshr()` `rotl()` `rotr()`

### Trig Convention
- PICO-8 `sin()` and `cos()` use a **0.0–1.0 range** (NOT 0–2π)
- PICO-8 `sin()` is **inverted** compared to standard math (`sin(0.25)` returns `-1`, not `1`)
- `atan2(dx, dy)` returns values in the **0.0–1.0 range**

### Fixed-Point Math
- Numbers are **16.16 fixed-point** (range: -32768 aka `-0x8000` to ≈32767.99999 aka `0x7fff.ffff`)
- Integer part: 16 bits, fractional part: 16 bits
- Minimum step between numbers: ~0.00002 (0x0.0001)
- Be careful with large multiplications — overflow is possible
- **If you add 1 to a counter each frame, it overflows after ~18 minutes!**
- Division by zero returns `0x7fff.ffff` (max positive) or `-0x7fff.ffff` (max negative)

### Critical Quirks
- `sgn(0)` returns **1**, not 0 — this is intentional PICO-8 behavior
- **Sprite 0 is "empty"** — `map()` and `tline()` skip it by default (disable with `poke(0x5f36, 0x8)`)
- **Sprite sheet / map sharing** — bottom half of sprite sheet (sprites 128-255) and bottom half of map (rows 32-63) occupy the **same memory** at 0x1000–0x1FFF
- `rnd(tbl)` returns a random element from a table (not just numbers)
- Lua arrays are **1-based** — `foreach`, `all`, `#` all start at index 1

### `stat()` Reference
| stat(n) | Returns |
|---------|--------------------------------------|
| 0 | Memory usage (0–2048) |
| 1 | CPU used since last flip (1.0 = 100%) |
| 4 | Clipboard contents (after CTRL-V) |
| 6 | Parameter string |
| 7 | Current framerate |
| 46–49 | Currently playing SFX on channels 0–3 |
| 50–53 | Note number (0–31) on channels 0–3 |
| 54 | Currently playing pattern index |
| 55 | Total patterns played |
| 56 | Ticks on current pattern |
| 57 | TRUE when music is playing |
| 80–85 | UTC time: year, month, day, hour, min, sec |
| 90–95 | Local time |
| 100 | Current breadcrumb label, or nil |
| 110 | TRUE when in frame-by-frame mode |
| 30 | TRUE when keypress available |
| 31 | Character from keyboard |
| 32–33 | Mouse X, Y |
| 34 | Mouse buttons (bitfield) |
| 36 | Mouse wheel event |
| 38–39 | Relative mouse X, Y movement (requires pointer lock flag 0x4) |

### Mouse and Keyboard Input
Mouse/keyboard is **opt-in** (not available by default):
```lua
poke(0x5f2d, flags) -- flags bitfield:
-- 0x1 = enable devkit input
-- 0x2 = mouse buttons trigger btn(4)..btn(6)
-- 0x4 = pointer lock (use stat(38),stat(39) for relative movement)
poke(0x5f2d, 1) -- most common: just enable devkit input
-- then read via stat():
x = stat(32)  -- mouse x
y = stat(33)  -- mouse y
b = stat(34)  -- mouse buttons
if stat(30) then key = stat(31) end -- keyboard
```

### Memory Map
```
0x0000  GFX (sprite sheet)
0x1000  GFX2/MAP2 (shared memory)
0x2000  MAP
0x3000  GFX FLAGS
0x3100  SONG
0x3200  SFX
0x4300  USER DATA
0x5600  CUSTOM FONT
0x5E00  PERSISTENT CART DATA (256 bytes)
0x5F00  DRAW STATE
0x5F40  HARDWARE STATE
0x5F80  GPIO PINS (128 bytes)
0x6000  SCREEN (8K)
0x8000  USER DATA (upper)
```

### Memory Remapping Registers
GFX, SCREEN, and MAP memory regions can be reassigned for advanced effects:
```lua
poke(0x5f54, addr) -- GFX source: 0x00 (default) or 0x60 (use screen as spritesheet)
poke(0x5f55, addr) -- SCREEN dest: 0x60 (default) or 0x00 (render to spritesheet)
poke(0x5f56, addr) -- MAP source: 0x20 (default), 0x10-0x2f, or 0x80+
poke(0x5f57, w)    -- MAP width: 0=256, default=128
```
Addresses are in 256-byte increments (e.g., `0x20` means `0x2000`). GFX/SCREEN can also map to upper memory (`0x80`, `0xA0`, `0xC0`, `0xE0`).

### Out-of-Bounds Return Values
`pget()`, `sget()`, `mget()` return 0 when coordinates are out of bounds. Custom defaults:
```lua
poke(0x5f36, 0x10) -- enable custom OOB return values
poke(0x5f5b, val)  -- pget() OOB return value
poke(0x5f59, val)  -- sget() OOB return value
poke(0x5f5a, val)  -- mget() OOB return value
```

### Inverted Draw Operations (v0.2.6+)
Filled shapes can be drawn *inverted* — filling everything EXCEPT the shape:
```lua
poke(0x5f34, 0x2)  -- enable inversion mode
-- use high bits in COL: set bit 0x0800.0000 to invert
rrectfill(40, 40, 48, 48, 4, 0x0800.0007) -- inverted white rounded rect
```
Works with `circfill`, `ovalfill`, `rectfill`, `rrectfill`. Great for spotlight / fog-of-war effects.

### Inline Fill Patterns via Color Parameter
Fill patterns can be embedded directly in any COL parameter without separate `fillp()` calls:
```lua
poke(0x5f34, 0x1) -- enable fill pattern via color high bits
circfill(64,64,20, 0x114E.ABCD) -- pattern=0xABCD, colors=0x4E (brown+pink)
-- bit 0x1000.0000 = observe high bits
-- bit 0x0100.0000 = transparency
-- bit 0x0200.0000 = apply to sprites
-- bit 0x0400.0000 = apply secondary palette globally
-- bit 0x0800.0000 = invert draw operation
```

---

## 🎯 Token Optimization Guidelines

> [!IMPORTANT]
> Every token counts. The 8,192 token limit is a hard wall. Follow these patterns.

### What Costs Tokens
- Each variable name, literal value, operator, or opening bracket = **1 token**
- `end`, `local`, commas, semicolons, periods, colons, closing brackets = **0 tokens (free)**

### Token-Saving Patterns

```lua
-- ✅ Multi-assignment (saves 1 token per extra var)
a,b,c=1,2,3

-- ✅ Omit trailing nils
mynum,myobj=3   -- myobj is nil automatically

-- ✅ Omit parentheses for single string/table args
print"hello"
add_particle{x=10,y=20}

-- ✅ Short-circuit ternary
result=condition and val_true or val_false

-- ✅ Use split() for data tables
data=split"1,2,3,4,5"  -- cheaper than {1,2,3,4,5} for large lists

-- ✅ Cache repeated table accesses
local px,py=player.x,player.y

-- ✅ Assign frequently-used functions to short names
local s=sin
local c=cos

-- ❌ AVOID: Separate assignments when multi works
-- ❌ AVOID: Unnecessary local variables for single-use values
-- ❌ AVOID: Verbose function names when short ones suffice (in tight code)
```

### When NOT to Optimize
- **Readability first** during development — optimize later when approaching the limit
- **Don't pre-optimize** — use the `info` command in the PICO-8 console to check token count. (`stat(1)` is CPU usage, NOT token count.)
- Use `#include` with external files to keep source readable; the token count applies to the final compiled cart

---

## 🕹️ Game Development Best Practices

### Game Feel ("Juice")
- **Screen shake** on impacts: offset camera by small random amounts, decay quickly
- **Hit flash**: swap palette to all-white for 1-2 frames using `pal()`
- **Particles**: spawn small particle effects for hits, explosions, footsteps
- **Squash and stretch**: scale sprites slightly on jump/land
- **Sound feedback**: every meaningful action should have a sound effect
- **Freeze frames**: pause gameplay for 1-3 frames on big hits for dramatic impact

### Collision Detection
- Use **bounding box (AABB)** for most collisions:
  ```lua
  function collides(a,b)
    return a.x<b.x+b.w and b.x<a.x+a.w
       and a.y<b.y+b.h and b.y<a.y+a.h
  end
  ```
- Use **sprite flags** (`fget`/`fset`) to mark solid tiles for map collision
- Check collision BEFORE moving, not after

### Map-Based Collision
```lua
function solid(x,y)
  return fget(mget(x\8, y\8), 0)  -- flag 0 = solid
end

function move_player(p)
  local nx=p.x+p.dx
  local ny=p.y+p.dy
  if not solid(nx, p.y) and not solid(nx+7, p.y) 
     and not solid(nx, p.y+7) and not solid(nx+7, p.y+7) then
    p.x=nx
  end
  -- repeat for y...
end
```

### Drawing Order
1. `cls()` — clear screen
2. `map()` — background/terrain
3. Sprites (sorted by y-position for depth, if applicable)
4. Particles / effects
5. HUD / UI (drawn last, on top of everything)

### Performance
- **CPU budget:** Use `stat(1)` to monitor CPU usage (1.0 = 100%)
- **Minimize `for` loops** over large tables each frame
- **Avoid `sqrt()`** when you can compare squared distances instead
- **Use `map()`** for backgrounds — it's much faster than drawing individual sprites
- **Coroutines** are great for sequencing events without blocking the game loop

---

## 🤖 Vibe Coding / AI Agent Workflow Rules

### How to Work on This Project

1. **Plan before coding.** Before generating any code:
   - Describe the approach and get approval
   - Break the task into small, testable steps
   - Consider token budget impact

2. **Work in small increments.** Each change should be:
   - One logical feature or fix
   - Testable independently
   - Small enough to review easily

3. **Test after every change.** After modifying code:
   - Verify the game still runs without errors
   - Check that existing functionality isn't broken
   - Report the token count using `info` in the PICO-8 console if applicable

4. **Use version control.** Commit early and commit often — every logical change gets its own commit with a descriptive message. **Always `git push` immediately after committing.** Do not accumulate unpushed commits.

5. **Document decisions.** If you make a non-obvious design choice, explain WHY in a comment.

### AI-Specific Anti-Patterns (DO NOT DO THESE)

> [!CAUTION]
> These are the most common ways AI agents break PICO-8 code.

- ❌ **Do NOT use standard Lua functions** (`math.floor`, `table.insert`, `string.format`, etc.)
- ❌ **Do NOT use `require()`** — PICO-8 doesn't have a module system
- ❌ **Do NOT assume floating-point precision** — it's 16:16 fixed-point
- ❌ **Do NOT generate large amounts of code at once** — work incrementally
- ❌ **Do NOT ignore the token limit** — always consider token cost
- ❌ **Do NOT use uppercase variable names in `.p8` files** — they get auto-lowercased
- ❌ **Do NOT put draw calls in `_update()`** or logic in `_draw()`
- ❌ **Do NOT rewrite existing working code** unless specifically asked to
- ⚠️ **Be careful when generating pixel art / sprite data** — use the `.p8` file format reference below and document your design intent clearly in comments. For complex art, describe what each sprite should look like before writing hex data.
- ❌ **Do NOT hallucinate PICO-8 API functions** — if you're unsure a function exists, SEARCH THE WEB FIRST

### AI-Specific Best Practices (DO THESE)

- ✅ **Always verify API calls exist** by searching PICO-8 docs before using them
- ✅ **Use `printh()` for debugging** — it prints to the host terminal, not the game screen
- ✅ **Prefer simple, readable code** over clever tricks (optimize only when needed)
- ✅ **Show token impact** when suggesting changes near the limit
- ✅ **Ask before refactoring** — don't restructure working code without permission
- ✅ **Explain PICO-8-specific decisions** — the developer may not know every quirk
- ✅ **Use `#include`** for external source files when the project grows beyond a single tab
- ✅ **Respect sprite flags convention** — flag 0 = solid/collidable (or whatever the project defines)
- ✅ **Disclose AI assistance** if contributing to the PICO-8 community (BBS, itch.io)
- ✅ **Generate complete assets** — write sprite, map, SFX, and music data using the `.p8` file format documented below
- ✅ **Comment sprite designs** — before each `__gfx__` block, describe what each sprite is in comments
- ✅ **Wrap `coresume()` in `assert()`** — coroutine errors are silently swallowed otherwise

---

## 🎨 Art & Asset Guidelines

### Color Palette
- **Fixed 16 colors** (0-15) — use hex digit directly in `__gfx__`:
  - `0`: Black, `1`: Dark Blue, `2`: Dark Purple, `3`: Dark Green
  - `4`: Brown, `5`: Dark Gray, `6`: Light Gray, `7`: White
  - `8`: Red, `9`: Orange, `a`: Yellow, `b`: Green
  - `c`: Blue, `d`: Indigo, `e`: Pink, `f`: Peach
- **Extended palette** (colors 128-143): Available via `pal()` for screen display

---

## 📦 `.p8` File Format Reference (AI Asset Generation)

> [!IMPORTANT]
> AI agents CAN and SHOULD generate all asset data directly. The `.p8` file is plain text with hex-encoded sections. Use these formats to create complete games.

### File Structure
```
pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- game code here
__gfx__
-- sprite sheet (128 lines × 128 hex chars)
__gff__
-- sprite flags (2 lines × 256 hex chars)
__map__
-- map upper half (32 lines × 256 hex chars)
__sfx__
-- sound effects (64 lines × 168 hex chars)
__music__
-- music patterns (64 lines)
```

Empty/unused sections can be omitted entirely. PICO-8 fills missing data with zeros.

### `__gfx__` — Sprite Sheet (128×128 pixels)

- **128 lines**, each **128 hex characters**
- Each hex digit = 1 pixel color (0-f)
- Lines are pixel rows, top-to-bottom
- Sprite N occupies: column `(N%16)*8` to `(N%16)*8+7`, row `(N\16)*8` to `(N\16)*8+7`

```
-- Example: sprite 0 = small heart (8×8, using color 8=red, 0=black)
Row 0: 00000000  →  ........
Row 1: 08808800  →  .♥.♥♥...
Row 2: 08888800  →  .♥♥♥♥...
Row 3: 08888800  →  .♥♥♥♥...
Row 4: 00888000  →  ..♥♥♥...
Row 5: 00080000  →  ...♥....
Row 6: 00000000  →  ........
Row 7: 00000000  →  ........
```

Each line in `__gfx__` is a full 128-pixel row of the sheet. The first 8 chars of rows 0-7 = sprite 0, chars 8-15 = sprite 1, etc.

### `__gff__` — Sprite Flags

- **2 lines**, each **256 hex chars** (128 bytes per line)
- Each hex pair = 8 flags for one sprite (bit 0 = flag 0, etc.)
- Line 1: sprites 0-127, Line 2: sprites 128-255
- Example: sprite 0 as solid (flag 0 set) = `01`, no flags = `00`

### `__map__` — Map Data (upper 32 rows)

- **32 lines**, each **256 hex chars**
- Each hex pair = sprite ID (00-ff) for one tile
- 128 tiles per row, read left-to-right
- Bottom 32 rows (32-63) share memory with sprites 128-255 in `__gfx__`

### `__sfx__` — Sound Effects

> [!WARNING]
> The `.p8` file note format (5 nibbles) differs from the RAM format (2 bytes at `0x3200`). Use the format matching your approach.

- **64 lines**, each **168 hex chars** (84 bytes)

**Per-SFX line layout:**

| Chars | Bytes | Meaning |
|-------|-------|---------|
| 0-1 | 1 | Editor mode (00=pitch, 01=tracker) |
| 2-3 | 1 | Speed (note duration, 1/128s multiples) |
| 4-5 | 1 | Loop start (note index 0-31) |
| 6-7 | 1 | Loop end (note index 0-31) |
| 8-167 | 80 | 32 notes, 5 nibbles (2.5 bytes) each |

**Note encoding in `.p8` file (5 hex digits per note):**

| Digit(s) | Meaning | Values |
|----------|---------|--------|
| 0-1 | Pitch | 00-3f (c-0 to d#-5) |
| 2 | Waveform | 0-7 built-in, 8-f = custom SFX 0-7 as instrument |
| 3 | Volume | 0-7 |
| 4 | Effect | 0=none, 1=slide, 2=vibrato, 3=drop, 4=fade_in, 5=fade_out, 6=arp_fast, 7=arp_slow |

**Waveforms:** 0=sine, 1=triangle, 2=sawtooth, 3=long_square, 4=short_square, 5=ringing, 6=noise, 7=ringing_sine

**Pitch reference (common notes):**
```
c-0=00  c#0=01  d-0=02  ...  b-0=0b
c-1=0c  c#1=0d  ...           b-1=17
c-2=18  c#2=19  ...           b-2=23
c-3=24  c#3=25  ...           b-3=2f
c-4=30  c#4=31  ...           b-4=3b
c-5=3c  c#5=3d  d-5=3e  d#5=3f
```

**Example SFX** — a simple rising "pickup" sound (4 notes, triangle wave, volume 5):
```
001000000c15000e15001015001215000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
          ↑↑↑↑↑
          0c=pitch(c-1) 1=triangle 5=vol 0=no_effect
```

**SFX in RAM (for `poke()` at `0x3200 + n*68`):**

Each note = 2 bytes at `0x3200 + sfx_id*68 + note_idx*2`:
```
Byte 0 (low):  [w1 w0 p5 p4 p3 p2 p1 p0]  -- low 2 waveform bits + 6 pitch bits
Byte 1 (high): [c  e2 e1 e0 v2 v1 v0 w2]  -- custom flag, 3 effect, 3 volume, high waveform bit
```
After 64 note bytes: byte 64=editor_mode, byte 65=speed, byte 66=loop_start, byte 67=loop_end.

### `__music__` — Music Patterns

- **64 lines**, each formatted as: `FF AABBCCDD`
  - `FF` = flags byte (hex)
  - `AA`,`BB`,`CC`,`DD` = SFX IDs for channels 0-3

**Flags:** bit 0 (`01`)=loop start, bit 1 (`02`)=loop end, bit 2 (`04`)=stop

**Channel values:** `00`-`3f` = play SFX 0-63. Add `40` to mute that channel (e.g., `41` = SFX 1 muted).

**Example** — 2-pattern loop playing SFX 0-3 then 4-7:
```
01 00010203
02 04050607
```

### Runtime Asset Generation (Alternative to File Hex)

Generate assets with code in `_init()`. Uses tokens but enables procedural content:

```lua
-- write pixel to sprite sheet: sset(x, y, color)
-- sprite n starts at pixel ( (n%16)*8, (n\16)*8 )
function write_spr(n, data)
 local sx,sy=(n%16)*8,(n\16)*8
 for y=0,7 do for x=0,7 do
  sset(sx+x, sy+y, data[y*8+x+1])
 end end
end

-- set map tiles
mset(0, 0, 1)  -- place sprite 1 at map tile (0,0)

-- write SFX via poke (see RAM format above)
local addr=0x3200  -- sfx 0
poke(addr+64, 0)   -- editor mode
poke(addr+65, 16)  -- speed
poke(addr+66, 0)   -- loop start
poke(addr+67, 0)   -- loop end
-- poke note bytes at addr+0..63
```

---

## 📐 Coding Style

- **Indentation:** 1 space (saves characters, standard PICO-8 convention)
- **Naming:** `snake_case` for everything (functions, variables, tables)
- **Comments:** Use `--` for inline comments; explain WHY, not WHAT
- **Line length:** Keep lines short — PICO-8's built-in editor wraps at ~32 chars (external editors can be wider)
- **Globals vs Locals:** Use `local` where possible to avoid namespace pollution; globals are fine for game state accessed across tabs
- **Function style:** Keep functions short and focused (one responsibility)

---

## 🔄 Workflow Commands

### Development
```bash
# Run PICO-8 and load the cartridge
pico8 -run game.p8

# Export as HTML for web distribution
# (run inside PICO-8 console)
export game.html

# Export as PNG cartridge
export game.p8.png
```

### Useful PICO-8 Console Commands
```
load game.p8       -- load cartridge
run                -- run the cartridge
save game.p8       -- save cartridge
info               -- show token/size stats
folder             -- open cartridge folder in OS file manager
```

---

## 📚 Reference Links (Search These First!)

- [PICO-8 API Reference (Wiki)](https://pico-8.fandom.com/wiki/APIReference)
- [PICO-8 User Manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html)
- [PICO-8 Cheat Sheet](https://www.lexaloffle.com/bbs/?tid=28207)
- [Token Optimization Guide](https://github.com/seleb/PICO-8-Token-Optimizations)
- [Nerdy Teachers PICO-8 Tutorials](https://nerdyteachers.com/PICO-8/)
- [PICO-8 BBS (Community)](https://www.lexaloffle.com/bbs/?cat=7)
