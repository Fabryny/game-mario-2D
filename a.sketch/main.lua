require 'src/Dependencies'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 256
VIRTUAL_HEIGHT = 144

TILE_SIZE = 16

-- number of tiles in each tile set
TILE_SET_WIDTH = 5
TILE_SET_HEIGHT = 4
-- number of tile sets in sheet
TILE_SETS_WIDE = 6
TILE_SETS_TALL = 10
-- number of topper sets in sheet
TOPPER_SETS_WIDE = 6
TOPPER_SETS_TALL = 18

CHARACTER_WIDTH = 16
CHARACTER_HEIGHT = 20

CHARACTER_MOVE_SPEED = 40
CAMERA_SCROLL_SPEED = 40

JUMP_VELOCITY = -200
GRAVITY = 7
-- tile ID
SKY = 5
GROUND = 3

function love.load()
    messageSpeed = 50
    math.randomseed(os.time())
    
    tilesheet = gTextures['tiles']
    quads = GenerateQuads(tilesheet, TILE_SIZE, TILE_SIZE)
    
    topperSheet = gTextures['toppers']
    topperQuads = GenerateQuads(topperSheet, TILE_SIZE, TILE_SIZE)

    -- divide quad tables into tile sets
    tilesets = GenerateTileSets(quads, TILE_SETS_WIDE, TILE_SETS_TALL, TILE_SET_WIDTH, TILE_SET_HEIGHT)
    toppersets = GenerateTileSets(topperQuads, TOPPER_SETS_WIDE, TOPPER_SETS_TALL, TILE_SET_WIDTH, TILE_SET_HEIGHT)

    -- random tile set and topper set for the level
    tileset = math.random(#tilesets)
    topperset = math.random(#toppersets)

    characterSheet = gTextures['character']
    characterQuads = GenerateQuads(characterSheet, CHARACTER_WIDTH, CHARACTER_HEIGHT)

    -- two animations depending on whether we're moving
    idleAnimation = Animation {
        frames = {1},
        interval = 1
    }
    movingAnimation = Animation {
        frames = {10, 11},
        interval = 0.2
    }
    jumpAnimation = Animation {
        frames = {3},
        interval = 1
    }

    
    characterDY = 0
    currentAnimation = idleAnimation


    characterX = VIRTUAL_WIDTH / 2 - (CHARACTER_WIDTH / 2)
    characterY = ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT

    direction = 'right'

    mapWidth = 20
    mapHeight = 20

    cameraScroll = 0

    backgroundR = math.random(255) / 255 
    backgroundG = math.random(255) / 255 
    backgroundB = math.random(255) / 255 

    tiles = generateLevel()
--[[     for y = 1, mapHeight do
        table.insert(tiles, {})
        
        for x = 1, mapWidth do
            -- sky and bricks; this ID directly maps to whatever quad we want to render
            table.insert(tiles[y], {
                id = y < 7 and SKY or GROUND
            })
        end
    end
 ]]
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Mario')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    if key == 'space' and characterDY == 0 then
        characterDY = JUMP_VELOCITY
        currentAnimation = jumpAnimation
    end
    
    -- allow us to regenerate the level at will
    if key == 'r' then
        tileset = math.random(#tilesets)
        topperset = math.random(#toppersets)
    end
end

function love.update(dt)

    characterDY = characterDY + GRAVITY
    characterY = characterY + characterDY * dt
    
    -- if we've gone below the map limit, set DY to 0
    if characterY > ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT then
        characterY = ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT
        characterDY = 0
    end  

    currentAnimation:update(dt)

    if love.keyboard.isDown('left') then
        messageSpeed = messageSpeed - CHARACTER_MOVE_SPEED * dt
        characterX = characterX - CHARACTER_MOVE_SPEED * dt
        if characterDY == 0 then
            currentAnimation = movingAnimation
        end
        direction = 'left'
        
    elseif love.keyboard.isDown('right') then
        messageSpeed = messageSpeed + CHARACTER_MOVE_SPEED * dt
        characterX = characterX + CHARACTER_MOVE_SPEED * dt

        if characterDY == 0 then
            currentAnimation = movingAnimation
        end
        direction = 'right'
    else
        currentAnimation = idleAnimation
    end
    
    -- set the camera's left edge to half the screen to the left of the player's center
    cameraScroll = characterX - (VIRTUAL_WIDTH / 2) + (CHARACTER_WIDTH / 2)
end

function love.draw()
    push:start()
        -- translate scene by camera scroll amount; negative shifts have the effect of making it seem
        -- like we're actually moving right and vice-versa; note the use of math.floor, as rendering
        -- fractional camera offsets with a virtual resolution will result in weird pixelation and artifacting
        -- as things are attempted to be drawn fractionally and then forced onto a small virtual canvas
        love.graphics.translate(-math.floor(cameraScroll), 0)
        love.graphics.clear(backgroundR, backgroundG, backgroundB, 1)

        for y = 1, mapHeight do
            for x = 1, mapWidth do
                local tile = tiles[y][x]
                love.graphics.draw(tilesheet, tilesets[tileset][tile.id], 
                    (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)

                -- draw a topper on top of the tile if it contains the flag for it
                if tile.topper then
                    love.graphics.draw(topperSheet, toppersets[topperset][tile.id], 
                        (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
                end
            end
        end
        
--[[         love.graphics.draw(characterSheet, characterQuads[1], math.floor(characterX), math.floor(characterY)) ]]


        -- draw character, this time getting the current frame from the animation
        -- we also check for our direction and scale by -1 on the X axis if we're facing left
        -- when we scale by -1, we have to set the origin to the center of the sprite as well for proper flipping
        love.graphics.draw(characterSheet, characterQuads[currentAnimation:getCurrentFrame()], 
        
            -- X and Y we draw at need to be shifted by half our width and height because we're setting the origin
            -- to that amount for proper scaling, which reverse-shifts rendering
            math.floor(characterX) + CHARACTER_WIDTH / 2, math.floor(characterY) + CHARACTER_HEIGHT / 2, 

            -- 0 rotation, then the X and Y scales
            0, direction == 'left' and -1 or 1, 1,

            -- lastly, the origin offsets relative to 0,0 on the sprite (set here to the sprite's center)
            CHARACTER_WIDTH / 2, CHARACTER_HEIGHT / 2)
            love.graphics.printf('Press R to change THEME', messageSpeed, 10, VIRTUAL_WIDTH )
    push:finish()
end

function generateLevel()
    local tiles = {}

    for y = 1, mapHeight do
        table.insert(tiles, {})
        
        for x = 1, mapWidth do
            table.insert(tiles[y], {
                id = SKY,
                topper = false
            })
        end
    end
 -- iterate over X at the top level to generate the level in columns instead of rows
 for x = 1, mapWidth do
    if math.random(7) == 1 then
        goto continue -- Make a chasms
    end

    -- random chance for a pillar
    local spawnPillar = math.random(5) == 1
    
    if spawnPillar then
        for pillar = 4, 6 do
            tiles[pillar][x] = {
                id = GROUND,
                topper = pillar == 4 and true or false
            }
        end
    end

    -- always generate ground
    for ground = 7, mapHeight do
        tiles[ground][x] = {
            id = GROUND,
            topper = (not spawnPillar and ground == 7) and true or false 
        }
    end

    ::continue::
end

    return tiles
end