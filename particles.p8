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