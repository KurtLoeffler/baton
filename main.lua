local baton = require 'baton'

local player = baton.new {
  controls = {
    left = {'key:left', 'axis:leftx-', 'button:dpleft'},
    right = {'key:right', 'axis:leftx+', 'button:dpright'},
    up = {'key:up', 'axis:lefty-', 'button:dpup'},
    down = {'key:down', 'axis:lefty+', 'button:dpdown'},
    action = {'key:x', 'button:a'},
  },
  pairs = {
    move = {'left', 'right', 'up', 'down'}
  },
  joystick = love.joystick.getJoysticks()[1],
}
player.deadzone = .33
player.squareDeadzone = true

local pairDisplayAlpha = 0
local pairDisplayTargetAlpha = 0
local buttonDisplayAlpha = 0
local buttonDisplayTargetAlpha = 0

function love.update(dt)
  player:update()

  pairDisplayTargetAlpha = player:pressed 'move' and 255
                          or player:released 'move' and 255
                          or player:down 'move' and 100
                          or 0
  if pairDisplayAlpha > pairDisplayTargetAlpha then
    pairDisplayAlpha = pairDisplayAlpha - 1000 * dt
  end
  if pairDisplayAlpha < pairDisplayTargetAlpha then
    pairDisplayAlpha = pairDisplayTargetAlpha
  end

  buttonDisplayTargetAlpha = player:pressed 'action' and 255
                          or player:released 'action' and 255
                          or player:down 'action' and 100
                          or 0
  if buttonDisplayAlpha > buttonDisplayTargetAlpha then
    buttonDisplayAlpha = buttonDisplayAlpha - 1000 * dt
  end
  if buttonDisplayAlpha < buttonDisplayTargetAlpha then
    buttonDisplayAlpha = buttonDisplayTargetAlpha
  end
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
  if key == 'tab' then
    player.controls.action[1] = 'key:z'
  end
end

local pairDisplayRadius = 128

function love.draw()
  love.graphics.push()
  love.graphics.translate(400, 300)

  love.graphics.setColor(50, 50, 50, pairDisplayAlpha)
  love.graphics.circle('fill', 0, 0, pairDisplayRadius)

  love.graphics.setColor(255, 255, 255)
  love.graphics.circle('line', 0, 0, pairDisplayRadius)

  local r = pairDisplayRadius * player.deadzone
  if player.squareDeadzone then
    love.graphics.rectangle('line', -r, -r, r*2, r*2)
  else
    love.graphics.circle('line', 0, 0, r)
  end

  love.graphics.setColor(150, 150, 150)
  local x, y = player:getRaw 'move'
  love.graphics.circle('fill', x*pairDisplayRadius,
    y*pairDisplayRadius, 4)
  love.graphics.setColor(255, 255, 255)
  local x, y = player:get 'move'
  love.graphics.circle('fill', x*pairDisplayRadius,
    y*pairDisplayRadius, 4)

  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle('line', -50, 150, 100, 100)
  love.graphics.setColor(255, 255, 255, buttonDisplayAlpha)
  love.graphics.rectangle('fill', -50, 150, 100, 100)

  love.graphics.pop()
end