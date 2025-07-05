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