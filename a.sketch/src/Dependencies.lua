Class = require 'lib/class'
push = require 'lib/push'

require 'src/Util'
require 'src/Animation'

gTextures = {
    ['tiles'] = love.graphics.newImage('graphics/tiles.png'),
    ['character'] = love.graphics.newImage('graphics/character.png'),
    ['toppers'] = love.graphics.newImage('graphics/tile_tops.png'),
}
