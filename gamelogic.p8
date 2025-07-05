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