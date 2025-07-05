## cosmic cascade

a space-themed "Suika Game" clone made in PICO-8! drop planets to merge them into larger celestial bodies, working your way up to creating the sun!

### play the game

**[click here to play cosmic cascade](cosmic_cascade_v1.html)**

### how to play

- **move**: left/right arrow keys to aim
- **drop**: z key to drop planets
- **goal**: merge identical planets to create larger ones
- **win dondition**: dreate the Sun!
- **game over**: Don't let planets overflow the container

## planet progression

mercury → venus → earth → mars → jupiter → saturn → uranus → neptune → pluto → sun

### controls

- **arrow keys**: move drop position left/right
- **z key**: drop planet
- **x key**: restart game (during gameplay)

### features

- **10 unique planets** with detailed pixel art
- **realistic physics** with gravity and collision
- **particle effects** for merging
- **progressive difficulty** as planets get larger
- **high score tracking**
- **space-themed background** with moving stars and cosmic dust

### built With

- **PICO-8** fantasy console
- **Lua** programming language
- custom sprite art for large title text
- physics simulation inspired by Suika Game

## files

- `cosmic_cascade_v1.html` - playable web version
- `cosmic_cascade.p8` - PICO-8 cart file
- source code split across multiple tabs:
  - `main.p8` - core game loop
  - `physics.p8` - planet physics and collisions  
  - `planets.p8` - planet types and rendering
  - `particles.p8` - merge effects
  - `ui.p8` - interface and backgrounds
  - `gamelogic.p8` - game states and menu
