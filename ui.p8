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