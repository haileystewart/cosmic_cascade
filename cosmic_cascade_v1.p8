pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cosmic cascade
-- by hailey stewart

-- tab 0: main
-- core game loop and initialization

function _init()
  -- initialize menu state first
  game_state = "menu"
  setup_menu()
  
  -- drop position and properties
  drop_x = 45        -- where we're aiming (centered in container)
  drop_y = 5         -- drop height (very top)
  
  -- game area (minimal 1px walls, ground 2px from bottom)
  ground_y = 126     -- ground starts 2 pixels from bottom
  container_left = 1    -- 1 pixel left wall
  container_right = 90  -- leaves 1px for right wall + space for ui
  
  -- drop system
  holding_planet = true  -- true = holding, false = can drop next
  
  -- planet type system
  current_planet_type = 1  -- start with mercury
  next_planet_type = random_small_planet()
  
  -- all planets on screen
  planets = {}
  
  -- particle system for merge effects
  particles = {}
  
  -- game scoring
  score = 0
  
  -- initialize game state variables
  high_score = 0
  restart_hold_time = 0
  restart_required_time = 1  -- 1 second
  hasdropped = false  -- track if player has dropped a planet yet
  failcounter = 0     -- fail counter for game over detection
end

function _update60()
  if game_state == "menu" then
    update_menu()
  elseif game_state == "playing" then
    -- update game state logic first
    update_game_state()
    
    if holding_planet then
      -- when holding: allow left/right movement for aiming
      if btn(0) then drop_x = drop_x - 2 end  -- left (faster for bigger container)
      if btn(1) then drop_x = drop_x + 2 end  -- right
      
      -- keep drop position within bounds (much larger container)
      local planet_radius = planet_types[current_planet_type][1]
      if drop_x - planet_radius < container_left then
        drop_x = container_left + planet_radius
      end
      if drop_x + planet_radius > container_right then
        drop_x = container_right - planet_radius
      end
      
      -- drop the planet when z is pressed
      if btnp(4) then
        -- create new planet and add to planets table
        local planet_radius = planet_types[current_planet_type][1]
        local new_planet = {
          x = drop_x,
          y = drop_y,
          vx = 0,
          vy = 0,
          planet_type = current_planet_type,
          weight = planet_radius,
          hitcount = 0,      -- initialize for game over detection
          failcounter = 0    -- initialize for game over detection
        }
        add(planets, new_planet)
        
        -- mark that we've dropped our first planet
        hasdropped = true
        
        -- prepare next planet
        current_planet_type = next_planet_type
        next_planet_type = random_small_planet()
      end
    end
    
    -- update physics
    update_physics()
    
    -- update particles
    update_particles()

    -- manual restart (x button) - only during gameplay
    if btnp(5) then
      restart_game()
    end
  elseif game_state == "gameover" then
    -- restart logic handled in update_game_state()
    update_game_state()
  end
end

function _draw()
  if game_state == "menu" then
    draw_menu()
  else
    -- clear screen with deep space background
    cls(0)  -- black background
    
    -- draw space background
    draw_space_background()
    
    -- draw container
    draw_container()
    
    -- draw all planets that have been dropped
    for planet in all(planets) do
      draw_planet(planet.x, planet.y, planet.planet_type)
      
      -- draw warning indicator for planets above danger zone
      if planet.failcounter and planet.failcounter > 3 then
        local planet_radius = planet_types[planet.planet_type][1]
        -- flashing red circle around failing planet
        local flash_color = 8 + flr(time() * 8) % 2  -- alternates between 8 and 9 (red/orange)
        circ(planet.x, planet.y, planet_radius + 1, flash_color)
      end
    end
    
    -- draw merge particle effects
    draw_particles()
    
    -- draw drop cursor and preview when holding (only during gameplay)
    if holding_planet and game_state == "playing" then
      draw_drop_preview()
    end
    
    -- draw ui
    draw_ui()
    
    -- draw game over screen if needed (no more victory state)
    if game_state == "gameover" then
      draw_game_over_screen()
    end
  end
end
-->8
-- tab 1: physics
-- planet movement, collisions, and merging

function update_physics()
  -- reset hitcount for all planets at start of frame
  for planet in all(planets) do
    planet.hitcount = planet.hitcount or 0
    planet.failcounter = planet.failcounter or 0
  end
  
  -- update all planets on screen
  for planet in all(planets) do
    local planet_radius = planet_types[planet.planet_type][1]
    
    -- reset collision impulses
    planet.ix = 0
    planet.iy = 0
    
    -- apply lighter gravity
    planet.vy = planet.vy + 0.05
    
    -- move planet
    planet.x = planet.x + planet.vx
    planet.y = planet.y + planet.vy
    
    -- bounce off ground
    if planet.y + planet_radius > ground_y then
      planet.y = ground_y - planet_radius
      planet.vy = abs(planet.vy) * -0.5
    end
    
    -- bounce off walls (updated for much larger container)
    if planet.x < container_left + planet_radius then
      planet.x = container_left + planet_radius
      planet.vx = abs(planet.vx) * 0.5
    end
    if planet.x > container_right - planet_radius then
      planet.x = container_right - planet_radius
      planet.vx = abs(planet.vx) * -0.5
    end
  end

  -- collision detection and merging
  local merges = {}
  
  for i = 1, #planets do
    for j = i + 1, #planets do
      local planet1 = planets[i]
      local planet2 = planets[j]
      local radius1 = planet_types[planet1.planet_type][1]
      local radius2 = planet_types[planet2.planet_type][1]
      
      -- calculate distance between planets
      local dx = planet1.x - planet2.x
      local dy = planet1.y - planet2.y
      local distance = sqrt(dx * dx + dy * dy)
      local min_distance = radius1 + radius2
      
      -- if planets are overlapping
      if distance < min_distance and distance > 0 then
        -- mark both planets as having been hit (for game over detection)
        planet1.hitcount = planet1.hitcount + 1
        planet2.hitcount = planet2.hitcount + 1
        
        -- calculate push amount
        local push = min_distance - distance
        
        -- use planet weight
        local weight1 = planet1.weight
        local weight2 = planet2.weight
        local total_weight = weight1 + weight2
        local strength1 = weight2 / total_weight
        local strength2 = weight1 / total_weight
        
        -- normalize direction
        dx = dx / distance
        dy = dy / distance
        
        -- accumulate impulses
        planet1.ix = planet1.ix + dx * push * strength1
        planet1.iy = planet1.iy + dy * push * strength1
        planet2.ix = planet2.ix - dx * push * strength2
        planet2.iy = planet2.iy - dy * push * strength2
        
        -- check for merge
        if planet1.planet_type == planet2.planet_type then
          add(merges, {planet1, planet2})
        end
      end
    end
  end
  
  -- apply accumulated impulses
  for planet in all(planets) do
    planet.x = planet.x + planet.ix * 0.7
    planet.y = planet.y + planet.iy * 0.7
    planet.vx = planet.vx + planet.ix * 0.35
    planet.vy = planet.vy + planet.iy * 0.35
  end
  
  -- process merges
  process_merges(merges)
end

function process_merges(merges)
  for merge in all(merges) do
    local planet1 = merge[1]
    local planet2 = merge[2]
    
    if planet1.deleted != true and planet2.deleted != true then
      -- calculate merge position
      local merge_x = (planet1.x + planet2.x) / 2
      local merge_y = (planet1.y + planet2.y) / 2
      
      -- create star particle effect at merge location
      create_merge_particles(merge_x, merge_y, planet1.planet_type)
      
      -- add score based on planet type (bigger bonus for later planets)
      score = score + planet1.planet_type * planet1.planet_type * 5
      
      -- special case: if both planets are suns, they disappear instead of merging
      if planet_types[planet1.planet_type][4] == "sun" and planet_types[planet2.planet_type][4] == "sun" then
        -- create extra spectacular particle effect for sun collision
        create_sun_collision_effect(merge_x, merge_y)
        -- add bonus score for sun collision
        score = score + 1000
        
        -- both suns disappear - no new planet created
        planet1.deleted = true
        planet2.deleted = true
        del(planets, planet1)
        del(planets, planet2)
        
      else
        -- normal merge: create new bigger planet
        local new_type = planet1.planet_type + 1
        if new_type <= #planet_types then
          local new_radius = planet_types[new_type][1]
          local new_planet = {
            x = merge_x,
            y = merge_y,
            vx = (planet1.vx + planet2.vx) / 2,
            vy = (planet1.vy + planet2.vy) / 2,
            planet_type = new_type,
            weight = new_radius,
            hitcount = 0,      -- initialize hitcount
            failcounter = 0    -- initialize failcounter
          }
          add(planets, new_planet)
          
          -- special celebration for creating the sun!
          if planet_types[new_type][4] == "sun" then
            create_sun_celebration(merge_x, merge_y)
          end
        end
        
        -- remove old planets
        planet1.deleted = true
        planet2.deleted = true
        del(planets, planet1)
        del(planets, planet2)
      end
    end
  end
end

function create_sun_collision_effect(x, y)
  -- massive particle explosion when two suns collide
  for i = 1, 150 do
    local angle = rnd(1)
    local speed = rnd(12) + 5  -- faster and more spread out
    local particle = {
      x = x,
      y = y,
      vx = cos(angle) * speed,
      vy = sin(angle) * speed,
      life = 100 + rnd(50),  -- longer lasting
      max_life = 100 + rnd(50),
      color = rnd() > 0.3 and 7 or (rnd() > 0.5 and 9 or 10),  -- white, orange, yellow
      size = rnd(4) + 3  -- bigger particles
    }
    particle.max_life = particle.life
    add(particles, particle)
  end
end

function create_sun_celebration(x, y)
  -- extra spectacular particle effect for the sun
  for i = 1, 100 do
    local angle = rnd(1)
    local speed = rnd(8) + 3
    local particle = {
      x = x,
      y = y,
      vx = cos(angle) * speed,
      vy = sin(angle) * speed,
      life = 80 + rnd(40),
      max_life = 80 + rnd(40),
      color = rnd() > 0.5 and 9 or 10,  -- orange and yellow
      size = rnd(3) + 2
    }
    particle.max_life = particle.life
    add(particles, particle)
  end
end
-->8
-- tab 2: planets
-- planet configurations and drawing functions

-- planet configurations: radius, main_color, accent_color, name
planet_types = {
  {4, 5, 13, "mercury"},     -- tiny
  {6, 9, 4, "venus"},        -- small  
  {8, 12, 7, "earth"},       -- medium
  {10, 8, 2, "mars"},        -- large
  {12, 11, 3, "jupiter"},    -- bigger gas giant with rings
  {14, 10, 9, "saturn"},     -- big with prominent rings
  {17, 13, 5, "uranus"},     -- ice giant
  {19, 1, 12, "neptune"},    -- ice giant
  {22, 6, 5, "pluto"},       -- dwarf planet
  {24, 9, 10, "sun"},        -- the ultimate goal!
}

function random_small_planet()
  -- only spawn the 4 smallest planets for now
  return flr(rnd(4)) + 1
end

function draw_planet(x, y, planet_type)
  local config = planet_types[planet_type]
  local radius = config[1]
  local main_color = config[2]
  local accent_color = config[3]
  local name = config[4]
  
  if name == "mercury" then
    -- mercury: cratered surface
    circfill(x, y, radius, 5)      -- gray base
    circfill(x, y, radius - 1, 13) -- lighter center
    -- multiple craters
    circfill(x - 2, y - 1, 1, 5)
    circfill(x + 1, y + 1, 1, 5)
    pset(x, y - 2, 6)
    
  elseif name == "venus" then
    -- venus: thick atmosphere
    circfill(x, y, radius, 4)      -- brown base
    circfill(x, y, radius - 1, 9)  -- orange atmosphere
    circfill(x, y, radius - 2, 10) -- yellow center
    -- atmospheric swirls (adjusted for smaller size)
    for i = 1, 2 do
      local angle = time() * 0.5 + i
      local sx = x + cos(angle) * (radius - 2)
      local sy = y + sin(angle) * 1
      pset(sx, sy, 4)
    end
    
  elseif name == "earth" then
    -- earth: blue with continents and extended atmosphere/clouds
    circfill(x, y, radius, 1)      -- dark blue base
    circfill(x, y, radius - 1, 12) -- blue oceans
    
    -- continents (green/brown) - extended 1 radius outward
    circfill(x - 3, y - 2, 2, 3)   -- continent 1 (larger)
    circfill(x + 2, y + 2, 2, 11)  -- continent 2 (larger)
    circfill(x - 1, y + 4, 1, 3)   -- small island (extended)
    pset(x + 4, y - 1, 3)          -- additional land (extended)
    pset(x - 4, y + 1, 11)         -- additional land (extended)
    
    -- white clouds extending 1 radius beyond surface
    pset(x - 5, y, 7)              -- extended cloud
    pset(x + 5, y - 1, 7)          -- extended cloud
    pset(x + 2, y + 5, 7)          -- extended cloud
    pset(x, y - 5, 7)              -- extended cloud
    pset(x - 3, y - 4, 7)          -- extended cloud
    pset(x + 4, y + 3, 7)          -- extended cloud
    -- original closer clouds
    pset(x - 3, y, 7)
    pset(x + 2, y - 1, 7)
    pset(x + 1, y + 3, 7)
    pset(x, y - 3, 7)
    
  elseif name == "mars" then
    -- mars: red planet with polar caps
    circfill(x, y, radius, 2)      -- dark red base
    circfill(x, y, radius - 1, 8)  -- red surface
    circfill(x, y, radius - 2, 14) -- light red center
    -- polar ice caps (adjusted for smaller size)
    circfill(x, y - radius + 2, 1, 7) -- north pole
    circfill(x, y + radius - 2, 1, 7) -- south pole
    -- dust storms
    pset(x - 2, y, 4)
    pset(x + 2, y - 1, 4)
    pset(x - 1, y + 2, 4)
    
  elseif name == "jupiter" then
    -- jupiter: gas giant with subtle rings and great red spot
    -- draw subtle rings first (jupiter has faint rings)
    for r = 10, 11 do
      for angle = 0, 1, 0.1 do
        local ring_x = x + cos(angle) * r
        local ring_y = y + sin(angle) * r
        if rnd() > 0.7 then  -- sparse, faint rings
          pset(ring_x, ring_y, 5)
        end
      end
    end
    
    -- draw planet body (adjusted for radius 12)
    circfill(x, y, radius - 2, 3)      -- dark green base
    circfill(x, y, radius - 3, 11)     -- light green
    circfill(x, y, radius - 4, 10)     -- yellow center
    
    -- horizontal bands
    for i = -2, 2 do
      line(x - radius + 3, y + i * 2, x + radius - 3, y + i * 2, 3)
    end
    -- great red spot
    circfill(x - 2, y + 1, 2, 8)
    circfill(x - 2, y + 1, 1, 2)
    
  elseif name == "saturn" then
    -- saturn: pale yellow with prominent rings inside the radius
    -- draw rings first (behind the planet) - adjusted for radius 14
    for r = 10, 12 do
      circ(x, y, r, 6)  -- outer ring system
    end
    for r = 7, 8 do
      circ(x, y, r, 5)  -- inner ring system
    end

    -- draw planet body (smaller than full radius to fit rings)
    circfill(x, y, 8, 4)      -- brown base
    circfill(x, y, 7, 10)     -- yellow
    circfill(x, y, 6, 9)      -- orange center

    -- draw rings in front (partial overlap)
    for r = 10, 12 do
      -- draw only parts of rings that would be in front
      for angle = 0.3, 0.7, 0.05 do
        local ring_x = x + cos(angle) * r
        local ring_y = y + sin(angle) * r
        pset(ring_x, ring_y, 6)
      end
    end
    
  elseif name == "uranus" then
    -- uranus: distinctive cyan ice giant (adjusted for radius 17)
    circfill(x, y, radius, 1)      -- dark base
    circfill(x, y, radius - 1, 12) -- light blue main color
    circfill(x, y, radius - 2, 7)  -- white icy center
    
    -- uranus is tilted on its side - draw tilted bands
    for i = -4, 4 do
      local band_x1 = x - radius + 4 + i * 2
      local band_y1 = y - radius + 8
      local band_x2 = x + radius - 4 + i * 2  
      local band_y2 = y + radius - 8
      line(band_x1, band_y1, band_x2, band_y2, 13)
    end
    
    -- ice crystals in distinctive pattern (more for larger size)
    for i = 1, 10 do
      local angle = i * 0.1
      local ix = x + cos(angle) * (radius - 5)
      local iy = y + sin(angle) * (radius - 5)
      pset(ix, iy, 7)
    end
    
  elseif name == "neptune" then
    -- neptune: distinctive deep blue with pink storm features (adjusted for radius 19)
    circfill(x, y, radius, 0)      -- black base
    circfill(x, y, radius - 1, 1)  -- dark blue
    circfill(x, y, radius - 2, 12) -- light blue middle
    
    -- distinctive pink storm systems (using color 14) - larger for bigger planet
    circfill(x - 6, y - 5, 5, 14)   -- large pink storm
    circfill(x - 6, y - 5, 4, 2)    -- dark red center
    circfill(x + 5, y + 4, 3, 14)   -- smaller pink storm
    
    -- unique wind pattern with pink highlights (more for larger size)
    for i = 1, 8 do
      local angle = time() * 0.4 + i * 0.25
      local wx = x + cos(angle) * (radius - 4)
      local wy = y + sin(angle) * 4
      local color = (i % 2 == 0) and 14 or 7  -- alternate pink and white
      pset(wx, wy, color)
    end
    
    -- additional pink atmospheric features
    pset(x - 3, y + 7, 14)
    pset(x + 7, y - 2, 14)
    pset(x - 7, y + 3, 14)
    pset(x + 2, y - 8, 14)
    
  elseif name == "pluto" then
    -- pluto: small, icy dwarf planet (standalone, no charon)
    circfill(x, y, radius, 5)      -- gray base
    circfill(x, y, radius - 1, 6)  -- lighter gray
    circfill(x, y, radius - 2, 7)  -- white center
    -- surface features (heart-shaped region like real pluto)
    circfill(x - 4, y - 4, 3, 4)   -- dark region (like real pluto's heart)
    circfill(x + 2, y + 3, 4, 5)   -- another surface feature
    circfill(x - 2, y + 5, 2, 13)  -- bright icy region
    -- surface details
    pset(x + 6, y - 2, 4)          -- surface marking
    pset(x - 6, y + 1, 7)          -- ice patch
    
  elseif name == "sun" then
    -- sun: massive, brilliant star with solar flares (adjusted for radius 24)
    -- solar corona (outermost layer)
    for r = radius - 2, radius do
      circ(x, y, r, 9)  -- orange corona
    end
    
    -- main solar body
    circfill(x, y, radius - 3, 10)  -- yellow base
    circfill(x, y, radius - 5, 9)   -- orange middle
    circfill(x, y, radius - 7, 8)   -- red core
    
    -- solar flares and prominences (adjusted for smaller size)
    for i = 1, 8 do
      local angle = time() + i * 0.25
      local flare_x = x + cos(angle) * (radius - 2)
      local flare_y = y + sin(angle) * (radius - 2)
      local flare_length = sin(time() * 2 + i) * 2 + 3  -- shorter flares
      local end_x = flare_x + cos(angle) * flare_length
      local end_y = flare_y + sin(angle) * flare_length
      line(flare_x, flare_y, end_x, end_y, 9)
    end
    
    -- sunspots (adjusted positions)
    circfill(x - 4, y - 3, 1, 2)
    circfill(x + 3, y + 2, 1, 0)
    circfill(x - 1, y + 4, 1, 4)
  end
end
-->8
-- tab 3: particles
-- particle system for merge effects

function create_merge_particles(x, y, planet_type)
  -- create bigger, more spectacular white star particles
  local particle_count = 30 + planet_type * 5  -- more particles for bigger planets
  
  for i = 1, particle_count do
    local angle = rnd(1)  -- random direction
    local speed = rnd(5) + 2  -- faster, more dramatic spread
    local particle = {
      x = x,
      y = y,
      vx = cos(angle) * speed,
      vy = sin(angle) * speed,
      life = 40 + rnd(30),  -- longer lasting particles
      max_life = 40 + rnd(30),
      color = 7,  -- bright white
      size = rnd(2) + 1  -- varying particle sizes
    }
    particle.max_life = particle.life
    add(particles, particle)
  end
  
  -- add some special golden particles for bigger planets
  if planet_type >= 5 then  -- jupiter and above
    for i = 1, 10 do
      local angle = rnd(1)
      local speed = rnd(3) + 1
      local particle = {
        x = x,
        y = y,
        vx = cos(angle) * speed,
        vy = sin(angle) * speed,
        life = 50 + rnd(20),
        max_life = 50 + rnd(20),
        color = 10,  -- golden yellow
        size = 2
      }
      particle.max_life = particle.life
      add(particles, particle)
    end
  end
end

function update_particles()
  for p in all(particles) do
    -- move particle
    p.x = p.x + p.vx
    p.y = p.y + p.vy
    
    -- apply gravity and friction
    p.vy = p.vy + 0.1  -- slight gravity
    p.vx = p.vx * 0.98  -- air resistance
    p.vy = p.vy * 0.98
    
    -- fade out over time
    p.life = p.life - 1
    
    -- remove dead particles
    if p.life <= 0 then
      del(particles, p)
    end
  end
end

function draw_particles()
  for p in all(particles) do
    -- draw star shape that fades out with varying sizes
    local fade = p.life / p.max_life
    if fade > 0.3 then
      -- draw larger plus sign for star effect
      local size = p.size or 1
      pset(p.x, p.y, p.color)
      for s = 1, size do
        pset(p.x - s, p.y, p.color)
        pset(p.x + s, p.y, p.color)
        pset(p.x, p.y - s, p.color)
        pset(p.x, p.y + s, p.color)
      end
    else
      -- just single pixel when fading
      pset(p.x, p.y, p.color)
    end
  end
end
-->8
-- tab 4: ui
-- user interface and drawing functions

function draw_space_background()
  -- clear to black space
  cls(0)
  
  -- draw scrolling galaxy background
  draw_moving_galaxy()
end

function draw_moving_galaxy()
  -- multiple layers for parallax effect
  draw_galaxy_layer(0.3, 1, 19)   -- slow moving distant stars
  draw_galaxy_layer(0.7, 6, 15)   -- medium speed gray stars  
  draw_galaxy_layer(1.2, 7, 13)   -- faster white stars
  draw_cosmic_dust()              -- moving cosmic dust clouds
  draw_shooting_stars()           -- angled shooting stars
end

function draw_galaxy_layer(speed, color, star_count)
  local scroll_offset = time() * speed * 10
  
  for star_id = 1, star_count do
    -- create deterministic star positions that repeat seamlessly
    local base_x = (star_id * 47) % 256  -- use 256 for seamless wrapping
    local star_y = (star_id * 31) % 128
    
    -- apply scrolling with wrapping
    local star_x = (base_x + scroll_offset) % 256
    
    -- only draw if star is on screen (with extra margin for wrapping)
    if star_x < 140 then
      -- handle screen wrapping
      local screen_x = star_x % 128
      
      -- different star types based on star_id
      local star_type = star_id % 4
      
      if star_type == 0 then
        -- single pixel
        pset(screen_x, star_y, color)
        
      elseif star_type == 1 then
        -- small cross
        pset(screen_x, star_y, color)
        if screen_x > 0 then pset(screen_x-1, star_y, color) end
        if screen_x < 127 then pset(screen_x+1, star_y, color) end
        if star_y > 0 then pset(screen_x, star_y-1, color) end
        if star_y < 127 then pset(screen_x, star_y+1, color) end
        
      elseif star_type == 2 then
        -- double pixel
        pset(screen_x, star_y, color)
        if screen_x < 127 then pset(screen_x+1, star_y, color) end
        
      else
        -- single bright pixel
        pset(screen_x, star_y, color)
      end
    end
  end
end

function draw_cosmic_dust()
  -- slow moving cosmic dust clouds
  local dust_scroll = time() * 0.5 * 10
  
  for dust_id = 1, 6 do
    local base_x = (dust_id * 67) % 256
    local dust_y = (dust_id * 41) % 128
    local dust_x = (base_x + dust_scroll) % 256
    
    if dust_x < 140 then
      local screen_x = dust_x % 128
      
      -- create small dust cloud clusters
      for i = 0, 3 do
        for j = 0, 2 do
          local cloud_x = screen_x + i
          local cloud_y = dust_y + j
          
          if cloud_x < 128 and cloud_y < 128 then
            -- very subtle dark blue dust
            if (cloud_x + cloud_y + dust_id) % 3 == 0 then
              pset(cloud_x, cloud_y, 1)  -- dark blue
            end
          end
        end
      end
    end
  end
end

function draw_shooting_stars()
  -- shooting stars with angled trajectories
  for star_id = 1, 4 do
    -- each shooting star has a different cycle time
    local cycle_time = 3 + star_id * 0.7  -- different speeds
    local star_progress = (time() + star_id * 2) % cycle_time / cycle_time
    
    -- only show shooting star for part of its cycle
    if star_progress > 0.1 and star_progress < 0.4 then
      -- deterministic starting position and angle for each star
      local start_x = 140 + (star_id * 43) % 50  -- start off-screen right
      local start_y = (star_id * 37) % 100       -- random y position
      local angle = 0.15 + (star_id * 0.1)      -- different angles
      
      -- calculate current position based on progress
      local distance = star_progress * 200  -- how far it's traveled
      local current_x = start_x - cos(angle) * distance
      local current_y = start_y + sin(angle) * distance
      
      -- draw the shooting star trail
      local trail_length = 8 + star_id * 2
      for i = 0, trail_length do
        local trail_x = current_x + cos(angle) * i * 2
        local trail_y = current_y - sin(angle) * i * 2
        
        if trail_x >= 0 and trail_x < 128 and trail_y >= 0 and trail_y < 128 then
          -- fade the trail from bright white to dark
          local brightness = 7 - flr(i / 3)  -- fade from white to darker
          if brightness > 0 then
            pset(trail_x, trail_y, max(brightness, 1))
          end
        end
      end
      
      -- bright head of shooting star
      if current_x >= 0 and current_x < 128 and current_y >= 0 and current_y < 128 then
        pset(current_x, current_y, 7)      -- bright white head
        pset(current_x-1, current_y, 7)    -- make head slightly wider
        pset(current_x, current_y-1, 7)
      end
    end
  end
end

function draw_container()
  -- draw two-layer container: outer purple, inner black
  
  -- outer purple layer (thicker walls)
  -- outer ground (2 pixels thick)
  line(container_left - 1, ground_y, container_right + 1, ground_y, 13)      -- purple ground line
  line(container_left - 1, ground_y + 1, container_right + 1, ground_y + 1, 5) -- second ground line
  
  -- outer left wall (2 pixels thick)  
  line(container_left - 1, 0, container_left - 1, ground_y + 1, 5)          -- outer purple left wall
  line(container_left, 0, container_left, ground_y, 13)                      -- inner purple left wall
  
  -- outer right wall (2 pixels thick)
  line(container_right, 0, container_right, ground_y, 13)                    -- inner purple right wall  
  line(container_right + 1, 0, container_right + 1, ground_y + 1, 5)        -- outer purple right wall
  
  -- inner black layer (1 pixel inside the purple)
  -- inner ground
  line(container_left + 1, ground_y - 1, container_right - 1, ground_y - 1, 0) -- black ground line
  
  -- inner left wall
  line(container_left + 1, 0, container_left + 1, ground_y - 1, 0)          -- black left wall
  
  -- inner right wall
  line(container_right - 1, 0, container_right - 1, ground_y - 1, 0)        -- black right wall
  
  -- danger indicator when failcounter > 3
  if failcounter > 3 then
    local container_width = container_right - container_left
    local fail_width = container_width * 0.5 * (failcounter / 120)
    -- red warning bars from left and right (shrunk by 1 pixel each side)
    rectfill(container_left + 1, 7, container_left + fail_width, 9, 8)  -- left red bar (moved 1 pixel right)
    rectfill(container_right - fail_width, 7, container_right - 1, 9, 8) -- right red bar (moved 1 pixel left)
  end
end

function draw_drop_preview()
  local planet_radius = planet_types[current_planet_type][1]
  
  -- draw a glowing drop path (adjusted for new container)
  for y = drop_y + 10, ground_y, 3 do
    local glow = sin(time() * 2 + y * 0.1) * 0.5 + 0.5
    local color = glow > 0.5 and 8 or 2
    pset(drop_x, y, color)
  end
  
  -- draw the planet we're about to drop
  draw_planet(drop_x, drop_y, current_planet_type)
  
  -- draw orbital indicator around planet
  for i = 1, 12 do
    local angle = i / 12 + time() * 0.5
    local orbit_x = drop_x + cos(angle) * (planet_radius + 4)
    local orbit_y = drop_y + sin(angle) * (planet_radius + 4)
    pset(orbit_x, orbit_y, 7)
  end
end

function draw_ui()
  -- right side ui - clean format
  local ui_x = 96
  
  -- large "score" header with light grey text and dark grey outline
  sprint("score", ui_x, 5, 6, 5)  -- light grey with dark grey outline
  
  -- score value in pink with peach outline
  sprint(score, ui_x, 15, 8, 14)  -- red text with pink outline
  if score > high_score then
    sprint("★", ui_x + 23, 15, 10, 9)  -- yellow star with orange outline (new best!)
  end
  
  -- large "next" header in light grey text and dark grey outline
  sprint("next", ui_x, 35, 6, 5)  -- light grey with dark grey outline
  
  -- next planet preview with planet name
  draw_planet(ui_x + 13, 54, next_planet_type)
  
  -- draw planet name under the preview
  local planet_name = planet_types[next_planet_type][4]
  sprint(planet_name, ui_x, 70, 6, 5)  -- light grey with dark grey outline
  
  -- best section with light grey text and dark grey outline
  sprint("best", ui_x, 80, 6, 5)  -- light grey with dark grey outline
  sprint(high_score, ui_x, 90, 8, 9)  -- red with orange outline
  
  -- progress section (show highest planet achieved) with light grey text and dark grey outline
  local max_planet = 1
  local sun_count = 0
  for planet in all(planets) do
    max_planet = max(max_planet, planet.planet_type)
    if planet_types[planet.planet_type][4] == "sun" then
      sun_count = sun_count + 1
    end
  end
  
  if sun_count > 0 then
    sprint("sun ★", ui_x, 100, 10, 9)  -- orange with yellow outline
    sprint("achieved!", ui_x, 110, 10, 9)  -- orange with yellow outline
  else
    sprint(max_planet .. "/" .. #planet_types, ui_x, 100, 6, 5)  -- light grey with dark grey outline
  end
end

-- outlined text function
function sprint(text, x, y, col1, col2)
  print(text, x, y+1, col2)   -- shadow down
  print(text, x, y-1, col2)   -- shadow up  
  print(text, x+1, y, col2)   -- shadow right
  print(text, x-1, y, col2)   -- shadow left
  print(text, x, y, col1)     -- main text on top
end
-->8
-- tab 5: gamelogic
-- game states, scoring, and additional features

-- game state management (menu, playing, and gameover)
game_state = "menu"

-- high score system
high_score = 0

-- play again system
restart_hold_time = 0
restart_required_time = 1  -- 1 second

-- fail counter system
failcounter = 0

-- menu system
menu_planets = {}

-- sprite-based text drawing
function draw_sprite_text_cosmic(x, y)
  -- draw top half of cosmic (sprites 000-005)
  for i = 0, 5 do
    spr(i, x + i * 8, y)
  end
  
  -- draw bottom half of cosmic (sprites 016-021)  
  for i = 0, 5 do
    spr(16 + i, x + i * 8, y + 8)
  end
end

function draw_sprite_text_cascade(x, y)
  -- draw top half of cascade (sprites 006-012)
  for i = 0, 6 do
    spr(6 + i, x + i * 8, y)
  end
  
  -- draw bottom half of cascade (sprites 022-028)  
  for i = 0, 6 do
    spr(22 + i, x + i * 8, y + 8)
  end
end

-- menu setup function
function setup_menu()
  menu_planets = {}
  for i = 1, 20 do
    local planet_type = flr(rnd(#planet_types)) + 1  -- all planet types for menu
    local planet_radius = planet_types[planet_type][1]
    local y = rnd(128)
    menu_planets[i] = {
      x = rnd(128),
      y = y,
      vy = y / 50,
      planet_type = planet_type,
      radius = planet_radius
    }
  end
end

-- menu update function
function update_menu()
  for i, planet in pairs(menu_planets) do
    planet.y = planet.y + planet.vy
    planet.vy = planet.vy + 0.02
    if planet.y > 128 + planet.radius then
      planet.x = rnd(128)
      planet.vy = 0
      planet.planet_type = flr(rnd(#planet_types)) + 1  -- all planet types
      planet.radius = planet_types[planet.planet_type][1]
      planet.y = -planet.radius - 10
    end
  end
  
  if btnp(4) then
    start_game()
  end
end

-- menu drawing function
function draw_menu()
  -- draw space background
  draw_space_background()
  
  -- draw falling planets
  for i, planet in pairs(menu_planets) do
    draw_planet(planet.x, planet.y, planet.planet_type)
  end
  
  -- draw custom sprite-based title (properly centered)
  draw_sprite_text_cosmic(40, 25)    -- cosmic: 48px wide, centered at (128-48)/2 = 40
  draw_sprite_text_cascade(36, 45)   -- cascade: 56px wide, centered at (128-56)/2 = 36
  
  -- draw subtitle and instructions
  local subtitles = {
    "a \"suika game\" clone",
    "in space!",
    "",
    "press 🅾️ to start "
  }
  
  for i = 1, #subtitles do
    local text = subtitles[i]
    local col, outline_col
    if i > 3 then
      col = 8        -- red for start instruction
      outline_col = 14  -- pink outline
    else
      col = 6        -- light grey for subtitles
      outline_col = 5   -- dark grey outline
    end
    sprint(text, 65 - #text * 2, 84 + i * 7, col, outline_col)
  end
  
  -- draw high score if we have one
  if high_score > 0 then
    sprint("best: " .. high_score, 64 - (#("best: " .. high_score) * 2), 64, 6, 5)
  end
end

-- start game function
function start_game()
  game_state = "playing"
  planets = {}
  particles = {}
  drop_x = 45
  holding_planet = true
  current_planet_type = 1
  next_planet_type = random_small_planet()
  score = 0
  restart_hold_time = 0
  hasdropped = false
  failcounter = 0
end

-- game over detection
function check_game_over()
  local maxfailcount = 0
  
  for planet in all(planets) do
    local planet_radius = planet_types[planet.planet_type][1]
    local ymin = planet.y - planet_radius
    
    if ymin < 8 and planet.hitcount and planet.hitcount > 0 then
      planet.failcounter = (planet.failcounter or 0) + 1
      maxfailcount = max(maxfailcount, planet.failcounter)
    else
      planet.failcounter = 0
    end
    
    planet.hitcount = 0
  end
  
  if maxfailcount > 0 then
    failcounter = failcounter + 1
    if failcounter > 120 then
      return true
    end
  else
    failcounter = 0
  end
  
  return false
end

-- container overflow detection
function check_container_overflow()
  local planets_in_upper_half = 0
  for planet in all(planets) do
    if planet.y < ground_y / 2 then
      planets_in_upper_half = planets_in_upper_half + 1
    end
  end
  return planets_in_upper_half > 8
end

-- main game state update function
function update_game_state()
  if game_state == "playing" then
    if hasdropped then
      if check_game_over() then
        game_state = "gameover"
        if score > high_score then
          high_score = score
        end
      end
    end
  elseif game_state == "gameover" then
    if btn(4) then
      restart_hold_time = restart_hold_time + 1/60
      if restart_hold_time >= restart_required_time then
        restart_game()
      end
    else
      restart_hold_time = 0
    end
  end
end

-- restart function (returns to menu instead of directly restarting)
function restart_game()
  game_state = "menu"
  setup_menu()
  restart_hold_time = 0
end

-- game over screen drawing
function draw_game_over_screen()
  -- overlay
  for y = 30, 85 do
    for x = 20, 108 do
      if (x + y) % 2 == 0 then
        pset(x, y, 0)
      end
    end
  end
  
  -- game over box
  rectfill(25, 35, 103, 80, 1)
  rect(25, 35, 103, 80, 0)
  
  -- text with outlines
  sprint("game over", 46, 40, 8, 2)
  sprint("final score:", 42, 50, 6, 5)
  
  local score_str = tostr(score)
  local score_x = 64 - (#score_str * 2)
  sprint(score_str, score_x, 60, 8, 2)
  
  sprint("hold z to menu", 34, 70, 6, 5)
  
  -- progress circle when holding z
  if btn(4) then
    -- circle position
    local x = 63.5
    local y = 90.5
    
    -- draw circle background and outline
    circfill(x, y, 7, 9)
    circ(x, y, 7, 0)
    
    -- progress calculation
    local progress = restart_hold_time / restart_required_time
    
    -- draw progress arc
    for a = 0.001, progress, 0.003 do
      local x2 = cos(0.25 - a) * 6 + x
      local y2 = sin(0.25 - a) * 6 + y
      line(x, y, x2, y2, 8)
    end
  end
end
__gfx__
00888880008888800088888000888008880088008888800000888880008888000888880008888800088880088888800888880000000000000000000000000000
08999998089999980899999808999889998899889999980008999998089999808999998089999980899998899999888999998000000000000000000000000000
89999999899999998999999989999999999899899999998089999999899999989999999899999998999999899999988999998000000000000000000000000000
89988899899888998998889989988998899899899888998089988899899889989988899899888998998899899889998998880000000000000000000000000000
89980088899808998999988889988998899899899800880089980088899889989999888899800888998899899808998998800000000000000000000000000000
89980088899808998888999989980880899899899800880089980088899999988889999899800888999999899808998999980000000000000000000000000000
89988899899888998998889989980000899899899888998089988899899889989988899899888998998899899889998998880000000000000000000000000000
89999999899999998999999989980000899899899999998089999999899889989999999899999998998899899999988999998000000000000000000000000000
08999998089999980899999889980000899899889999980008999998899889988999998089999988998899899999888999998000000000000000000000000000
00888880008888800088888008800000088088008888800000888880088008800888880008888800880088088888800888880000000000000000000000000000
__label__
000000000000000000000000000000000000000111111111000000000000000000567777999999999777777777777777777776589989aaaa9999888888888888
0000000000000000000000000000000000000111ccccccc111000000000000000055677777977777777777777777777777776558899998aaa999998888888889
0000000000000000000000000000000000011ccc7777777ccc1100000000000000956677777777777777777777777777777665888898999aaaa9999999999999
00000000000000000000000000000000011cc7777777777777cc110000000000000056677777777777777777777777777766588888899999aaaaaa999999999a
0000000000000000000000000000000011c77777777777777777c11000000000000095667777777777777777777777777665888888888999999aaaaaaaaaaaaa
00000000000000000000000000000001cc7777777777777777777cc100000000000099556777777777777777777777776558888888888899999999aa9aaaaaa9
0000000000000000000000000000001cc777777777777777777777cc100000000000999556677777777777777777776655888888888888999999999999999999
0000000000000000000000000000011c77777777777777777777777c110000000000999aa556677777777777777766550888888888888899a999999999999999
0000000000000000000000d0d0d0d1d7d7d7d7d77777777777777777c10000000000999aa955566677777777766655508888888888888899aa99909999999990
00000000000000000000000dddddddddddddddddd7777777777777777c1000000000999aa998855566666666655548888888888888888899aa99900900000000
0000000000000000000000000d0d1d7d777d7d7d7d777777777777777c10000000000999aa9988885500000000048888888888888888899aa999000000000000
00000000000000000000000000dddddddddddddddddd77777777777777c1000000000999aa9988800011111111100088888888888888899aa999000000000000
0000000000000000000000000001d7d7d7d7d7d7d7d7d7777777777777c1000000000999aa99900111ccccccccc11100888888888888999aa999000000000000
0000000000000000000000000011cd7d7d7d7d7d7d7d7d777777777777c11000000009909aa90111ccccccccccccc11108888888888899aa9099000000000000
000000000000000000000000001c77dddddddddddddddddd77777777777c101000003333333011ccccccccccccccccc110088888888999aa9990000000000000
000000000000000000000000001c7777d7d7d7d7d7d7d7d7d7777777777c111100333bbbbb333cccccccccccccccccccc100888888899aa09990000000000000
000000000000000000000000001c77777d000000000dddddddd77777777c1010033bbaaaaabb33cccccccccccccccccccc1008888899aaa99900000000000000
000000000000000000000000001c7770001111111110007d7d7d7777777c10003bbaaaaaaaaabb3cccccccccccccccccccc100888999aa909900000000000000
001000000000000000000000001c700111ccccccccc11100dddddd77777c1003bbaaaaaaaaaaabb3cccccccccccccccccccc1088999aa0999000000000000000
011100000000000000000000001c0111ccccccccccccc11107d7d7d7777c1033baaaaaaaaaaaaab33eecccccccccccccccccc10999aaa9990000000000000000
001000000000000000000000000011ccccccccccccccccc1100dddddd77c1033333333333333333332eeccccccccccccccccc1109aaa99090000000000000000
0000000000000000000000000001ccccccccccccccccccccc1007d7d7dc1133baaaaaaaaaaaaaaab3322eccceccccccccccccc10aaa909900000000000000000
000000000000000000000000001ccccccccccccccccccccccc1007d7d7d1033333333333333333333322eecccccccccccccccc11009999000000000000000000
00000000000000000000000001ccccccccccccccccccccccccc100ddddddd3baaaaa888aaaaaaaaab3222eccccccccccccccccc1099090000000000000000000
0000000000000000000000001ccccccccccccccccccccccccccc107d7d1d0333333882883333333333222eccccccccccccccccc1099900000000000000000000
000000000000000000000001cccccceeeeeccccccc88888ccc88888ddd88888aaa88822888aa88aa88888ecccccecccccccccccc100000000000000000000000
000000000010000000000011cccccee222eeccccc8999998c8999998d89999983899988999889988999998cccccccccccccccccc100000000000000000000000
00000000011100000000001ccccce2222222eccc89999999899999998999999989999999999899899999998ccccccecccccccccc100000000000000011111111
00000000001000000000011ccccee2222222eecc89988899899888998998889989988998899899899888998ccccccccccccccccc10000000000000111ccccccc
0000000000000000000001ccccce222222222ecc8998cc888998c89989999888899889988998998998ec88cccccccccccccccccc10000000000011ccc7777777
0000000000000000000001ccccce222222222ecc8998cc888998c899888899998998a88a8998998998cc88cccceeeccccccc7ccc100000000011cc7777777777
000000000000000000001cccccce222222222ecc8998889989988899899888998998aaaa899899899888998cceeeeecccccccccc10000000011c777777777777
000000000000000000001ccccccee2222222eecc8999999989999999899999998998baaa899899899999998ceeeeeeeccccccccc100000001cc7777777777777
000000000000000000001ccccccce2222222ecccc8999998c89999981899999889983bbb89989988999998cceeeeeeeccccccccc10000001cc77777777777777
000000000000000000001ccc7ccccee222eecccccc88888ccc88888c1088888008803333388c88cc88888ccceeeeeeecccccccc100000011c777777777777777
000000000000000000001ccccccccceeeeeccccccccccccccccccccc10000000000501ccccccccccccccccccceeeeecccccccccd0d0d0d1d7d7d7d7d77777777
000000000000000000001ccccccccccccccccccccceeeccccccccccc100000000000011ccccccccccccecccccceeeccccccccc11dddddddddddddddddd777777
000000000000000000001cccccccccccccccccccceeeeecccccc7ccc100000000000001ccccccccccccccccccccccccccccccc1000d0d1d7d7d7d7d7d7d77777
000000000000000000001ccccccccccecccccccceeeeeeeccccccccc1000000000000011ccccccccccccccccccccccccccccc110000dddddddddddddddddd777
000000000000000000001ccccc555555555ccccceeeeeeeccccccccc1000000000000001ccccccccccccccccccccccccccccc10000001d7d7d7d7d7d7d7d7d77
0000500000000000000001c555666666666555cceeeeeeecccccccc100000000000000001ccccccccccccccccccccccccccc100000011cd7d7d7d7d7d7d7d7d7
00003333333000000000555666777777777666555eeeeeccccccccc1000000000000000001ccccccccccccccccccccccccc100000001c77ddddddddddddddddd
00333bbbbb33300000055667777777777777776655eeeccccccccc110000000000000000001ccccccccccccccccccccccc1000000001c7777d7d7d7d7d7d7d7d
033bbaaaaabb33000556677777777777777777776655cccccccccc1000000000000000000001ccccccccccccccccccccc10000000001c77777dddddddddddddd
3bbaaaaaaaaabb3055677777777777777777777777655cccccccc1100000000000000000000011ccccccccccccccccc1100000000001c7777777d7d7d7d7d7d7
bbaaaaaaaaaaabb56677777777777777777777888886658888ccc8888800088888000888800888888cc88888ccccc111000000000001c77777777ddddddddddd
baaaaaaaaaaaaa5667777777777777777777789999986899998c8999998089999980899998899999888999998cc11100000000000001c7777777777d7d7d7d7d
333333333333356677777777777777777777899999998999999899999998999999989999998999999889999981100000000000000001c77777777777dddddddd
aaaaaaaaaaaa5567777777777777777777778998889989988998998889989988899899889989988999899888000000000000000000011c777777777777d7d7d7
3333333333335677777777777777777777778998778889988998999988889980088899889989980899899880000000000000000000041c7777777777777d7d7d
aaaa888aaaa56777777777777777777777778998778889999998888999989980088899999989980899899998000000000000000000491c77777777777777dddd
333882883355677777777777777777777777899888998998899899888998998889989988998998899989988800000000000000000049a1c777777777777777d7
aaa82228aa56777777777777777777777777899999998998899899999998999999989988998999999889999980000000000000000049a1c7777777777777777d
333882883356777777777777777777777777789999988998899889999980899999889988998999998889999980000000000000000049aa1c7777777777777777
aaaa888aa5677777777777777444777777777788888778877885088888000888888888828808888880088888000000000000000000499a11c777777777777777
333333333567777777777777444447777777777777777777776500000000002288e777e88220000000000000000000000000000000049aa1cc77777777777777
baaaaaaaa5677777777777744444447777777777777777777765000000000288eeee7eeee88200000000000000000000000000000000499a1cc7777777777777
bbaaaaaa5677777777777774444444777777777777777777777650000000288eeeeeeeeeee88200000000000000000000000000000000499911c777777777777
3bbaaaaa567777777777777444444477777777777777777777765000011228eeeeeeeeeeeee82200000000000000000000066000000000444411cc7777777777
033bbaaa56777777777777774444477777774777777777777776500000028eeeeeeeeeeeeeee820000000000000000000000000000000000000011ccc7777777
00333bbb56777777777777777444777555777777777777777776500000228eeeeeeeeeeeeeee822000000000000000000000000000000000000000111ccccccc
000033335677777777777777777775555555777777777777777650000028eeeeeeeeeeeeeeeee820000000000000000000000000000000000000000011111111
000000005677777777777777777775555555777777777777777650000028eeeeeeeeee4eeeeee820000000000000000000000000000000000000000000000110
000000005677777777777777777755555555577777777777777650000028eeeeee4eeeeeeeeee820000000000000000000000000000000000000000000000000
000000005677777777777777777ddd555555577777777777777650000028eeeeeeeeeeeeeeeee820000000000000000000000000000000000000000000000000
00000000567777777777777777ddddd55555577777777777777650000028eeeeeee4eeeeeeeee820000000000000000000000000000000000000000000000000
00000000056777777777777777ddddd555557777777777777765000000228eeeeeeeeeeeeeee8220000000000000000000000000000000000000000000000000
00000000056777777777777777ddddd555557777777777777765000000028eeeeeeeeeeeeeee8200000000000000000000000000000000000000000000000000
000000000567777777777777777ddd75557777777777777777650000000228eeeeeeeeeeeee82200000000000000000000000000000000000000000000000000
000000000056777777777777777777777777777777777777765000000000288eeeeeeeeeee882000000000000000000000000000000000000000000000000000
0000000000567777777777777777777777777777777777777650000000000288eeee7eeee8820000000000000000000000000000000000000000000000000000
000000000055677777777777777777777777777777777777655000000000002288e777e882200000000000000000000000000000000000000000000000000000
00000000000567777777777777777777777777777777777765000000000000022288788222000000000000000000000000000000000000000000000000000000
00000000000056777777777777777777777777777777777650000000000000000222222200000000000000000000000000000000000000000000000000000000
00000000000055677777777777777777777777777777776550000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005667777777777777777777777777777766500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000566777777777777777777777777777665000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000056677777777777777777777777776650000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005567777777777777777777777765500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000556677777777777777777776655000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005566777777777777777665500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006000000000555666777777777666555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000555666666666555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000010000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000
00000000000000000000000005550000050500550505055505050555000000550555055505550505000000550500005505500555000000000000000000000000
00000000000000000000000056665000565655665656566656565666500005665666566656665656500005665650056656655666500000000000000000000000
00000000000000000000000056565000565656555656556556565656500056555656566656555656500056555650565656565655000000000000000000000000
00000000007000000000000056665000050556665656556556655666500056555666565656650505000056505650565656565665000000000000000000000000
00000000000000000000000056565000000005565656556556565656500056565656565656550000000056555655565656565655000000000000000000000000
00000000000000000000000056565000000056650566566656565656500056665656565656665000000005665666566556565666500000000000000000000000
00000000000000000000000005050000000005500055055505050505000005550505050505550000000000550555055005050555000000000000000000000000
00000000000000000000000000000000000000000000000555055000000055055505550055055500500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005666566500000566566656665566566655650000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000565565650005655565656565655565505650000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000565565650005666566656665650566505650000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000565565650000556565556565655565500500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005666565650005665565056565566566655650000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000555050500000550050005050055055500500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000eee0eee0eee00ee00ee000000eeeee000000eee00ee000000ee0eee0eee0eee0eee000000000000000000000000000000
000000000000000100000000000000e888e888e888ee88ee88e0000e88888e0000e888ee88e0000e88e888e888e888e888e00000000000000000000000000000
000000000000000000000000000000e8e8e8e8e8eee8eee8ee0000e88eee88e0000e8ee8e8e000e8ee0e8ee8e8e8e8ee8e000000000000000000000000000000
000000000000000000000000000000e888e88ee88ee888e888e000e88e8e88e0000e8ee8e8e000e888ee8ee888e88e0e8e000000000000000000000000000000
000000000000000000000000000000e8eee8e8e8ee0ee8eee8e000e88eee88e0000e8ee8e8e0000ee8ee8ee8e8e8e8ee8e000000000000000000000000000000
000000000000000000000000000000e8e0e8e8e888e88ee88e00000e88888e00000e8ee88e0000e88e0e8ee8e8e8e8ee8e000000000000000000000000000600
0000000000000000000000000000000e000e0e0eee0ee00ee0000000eeeee0000000e00ee000000ee000e00e0e0e0e00e0000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000600000000000000000555555555000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000555666666666555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000555666777777777666555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005566777777777777777665500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000027000270001d0001d0001f0002200024000240002500026000270002c0002800028000290002a00029000290002a0002a00026000290003000029000280002700027000240000e000120001500000000
