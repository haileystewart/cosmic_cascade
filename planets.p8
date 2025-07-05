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