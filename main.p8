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