Baton <!-- omit in toc -->
=====
**Baton** is an input library for LÖVE that bridges the gap between keyboard and joystick controls and allows you to easily define and change controls on the fly. You can create multiple independent input managers, which you can use for multiplayer games or other organizational purposes.

```lua
local baton = require 'baton'

local input = baton.new {
  controls = {
    left = {'key:left', 'key:a', 'axis:leftx-', 'button:dpleft'},
    right = {'key:right', 'key:d', 'axis:leftx+', 'button:dpright'},
    up = {'key:up', 'key:w', 'axis:lefty-', 'button:dpup'},
    down = {'key:down', 'key:s', 'axis:lefty+', 'button:dpdown'},
    action = {'key:x', 'button:a'},
  },
  pairs = {
    move = {'left', 'right', 'up', 'down'}
  },
  joystick = love.joystick.getJoysticks()[1],
}

function love.update(dt)
  input:update()

  local x, y = input:get 'move'
  playerShip:move(x*100, y*100)
  if input:pressed 'action' then
    playerShip:shoot()
  end
end
```

Table of contents <!-- omit in toc -->
-----------------
- [Installation](#installation)
- [Usage](#usage)
  - [Defining controls](#defining-controls)
  - [Defining axis pairs](#defining-axis-pairs)
  - [Players](#players)
    - [Creating players](#creating-players)
    - [Updating players](#updating-players)
    - [Getting the value of controls](#getting-the-value-of-controls)
    - [Getting the value of axis pairs](#getting-the-value-of-axis-pairs)
    - [Getting down, pressed, and released states](#getting-down-pressed-and-released-states)
    - [Updating the configuration](#updating-the-configuration)
    - [Getting the active input device](#getting-the-active-input-device)
- [API](#api)
  - [baton](#baton)
    - [Functions](#functions)
      - [`baton.new(config)`](#batonnewconfig)
  - [PlayerConfig](#playerconfig)
    - [Properties](#properties)
      - [`controls` (`table`)](#controls-table)
      - [`pairs` (`table`) (optional)](#pairs-table-optional)
      - [`joystick` (`Joystick`) (optional)](#joystick-joystick-optional)
      - [`deadzone` (`number`) (optional, defaults to `.5`)](#deadzone-number-optional-defaults-to-5)
      - [`squareDeadzone` (`boolean`) (optional)](#squaredeadzone-boolean-optional)
  - [Player](#player)
    - [Properties](#properties-1)
      - [`config` (`PlayerConfig`)](#config-playerconfig)
    - [Functions](#functions-1)
      - [`Player:update()`](#playerupdate)
      - [`Player:getRaw(name)`](#playergetrawname)
      - [`Player:get(name)`](#playergetname)
      - [`Player:down(name)`](#playerdownname)
      - [`Player:pressed(name)`](#playerpressedname)
      - [`Player:released(name)`](#playerreleasedname)
      - [`Player:getActiveDevice()`](#playergetactivedevice)
- [Contributing](#contributing)

Installation
------------
To use Baton, place `baton.lua` in your project, and then add this code to your `main.lua`:
```lua
baton = require 'baton' -- if your baton.lua is in the root directory
baton = require 'path.to.baton' -- if it's in subfolders
```

Usage
-----
### Defining controls
Controls are defined using a table. Each key should be the name of a control, and each value should be another table. This table contains strings defining what sources should be mapped to the control. For example, this table
```lua
controls = {
  left = {'key:left', 'key:a', 'axis:leftx-'}
  shoot = {'key:x', 'button:a'}
}
```
will create a control called "left" that responds to the left arrow key, the A key, and pushing the left analog stick on the controller to the left, and a control called "shoot" that responds to the X key on the keyboard and the A button on the gamepad.

Sources are strings with the following format:
```lua
'[input type]:[input source]'
```
Here are the different input types and the sources that can be associated with them:

| Type     | Description                   | Source                                                                                                                                                                   |
| -------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `key`    | A keyboard key.               | Any LÖVE [KeyConstant](http://love2d.org/wiki/KeyConstant)                                                                                                               |
| `sc`     | A scancode.                   | Any LÖVE [KeyConstant](http://love2d.org/wiki/KeyConstant)                                                                                                               |
| `mouse`  | A mouse button.               | A number representing a mouse button (see [love.mouse.isDown](https://love2d.org/wiki/love.mouse.isDown))                                                                |
| `axis`   | A joystick or gamepad axis.   | Either a number representing a joystick axis or a LÖVE [GamepadAxis](http://love2d.org/wiki/GamepadAxis). Add a '+' or '-' on the end to denote the direction to detect. |
| `button` | A joystick or gamepad button. | Either a number representing a joystick button or a LÖVE [GamepadButton](http://love2d.org/wiki/GamepadButton)                                                           |
| `hat`    | A joystick hat.               | A number representing a joystick hat and a [JoystickHat](https://love2d.org/wiki/JoystickHat). For example '1r' corresponds to the 1st hat pushed right.                 |

### Defining axis pairs
Baton allows you to define **axis pairs**, which group four controls under a single name. This is perfect for analog sticks, arrow keys, etc., as it allows you to get x and y components quickly.  Each pair is defined by a table with the names of the four controls (in the order left, right, up, down).
```lua
pairs = {
  move = {'moveLeft', 'moveRight', 'moveUp', 'moveDown'},
  aim = {'aimLeft', 'aimRight', 'aimUp', 'aimDown'},
}
```

### Players
**Players** are the objects that monitor and manage inputs.

#### Creating players
To create a player, use `baton.new`:
```lua
player = baton.new(config)
```
`config` is a table containing the following values:
- `controls` - a table of controls
- `pairs` - a table of axis pairs (optional)
- `joystick` - a LÖVE joystick (returned from `love.joystick.getJoysticks`). The `joystick` argument is optional; if it's not specified, or if the joystick becomes unavailable later, the player object will just ignore controller inputs.
- `deadzone` - a number from 0-1 representing the minimum value axes have to cross to be detected (optional)
- `squareDeadzone` (bool) - whether to use square deadzones for axis pairs or not (optional)

#### Updating players
You should update each player each frame by calling this function:
```lua
player:update()
```

#### Getting the value of controls
To get the value of a control, use:
```lua
value = player:get(control)
```
For example, for the controls defined above, we could get the value of the "left" control by doing
```lua
left = player:get 'left'
```
`player:get` always returns a number between 0 and 1, and as such, it is most applicable to controls that act as axes, such as movement controls. To get the value of a control without applying the deadzone, use `player:getRaw`.

#### Getting the value of axis pairs
`player.get` can also get the x and y components of an axis pair.
```lua
x, y = player:get(pair)
```
In this case, `x` and `y` are numbers between -1 and 1. The length of the vector x, y is capped to 1. `player.getRaw` will return the value of axis pairs without deadzone applied.

#### Getting down, pressed, and released states
To see whether a control is currently "held down", use:
```lua
down = player:down(control)
```
`player:down` returns `true` if the value of the control is greater than the deadzone, and `false` if not.

```lua
pressed = player:pressed(control)
```
`player:pressed` return `true` if the control was pressed this `frame`, and false if not.

```lua
released = player:released(control)
```
`player:released` return `true` if the control was released this `frame`, and false if not.

These functions are most applicable for controls that act as buttons, such as a shoot button. That being said, they can be used for any control, which is useful if you want to, for example, use a movement control as a discrete button press to operate a menu.

#### Updating the configuration
The `controls` table, `pairs` table, `joystick`, `deadzone`, and `squareDeadzone` can all be accessed via `player.config`. Any of the values can be changed, and the player's behavior will be updated automatically. Note, however, that new controls and pairs cannot be added after the player is created, and controls and pairs should not be removed entirely (if you want to disable a control, you can set it to an empty table, removing all of its sources).

#### Getting the active input device
At any time, only the keyboard/mouse sources or the joystick sources for a player will be active. A device will be considered active if any of the sources for that device exceed the deadzone. The keyboard and mouse will always take precedence over the joystick.

You can call `player:getActiveDevice()` to see which input device is currently active. It will return either `'kbm'` (keyboard/mouse) or `'joy'` (joystick) (or `'none'` if no sources have been used yet). This is useful if you need to change what you display on screen based on the controls the player is using (such as instructions).

API
---
### baton

#### Functions

##### `baton.new(config)`
Creates a new Player object.

Parameters:
- `config` [(`PlayerConfig`)](#playerconfig) - the settings for the player

### PlayerConfig
A table containing control settings for a player.

#### Properties

##### `controls` (`table`)
The controls for the player to use. Each key corresponds to the name of a control, and each value should be a list of the input sources the control should respond to. Input sources are defined as strings with the format `'type:value'`, where `type` is the type of source (like `key` or `axis`), and `value` is the specific control (like `left` or `righty+`).

Here are the valid source types and values:

| Type     | Description                   | Value                                                                                                                                                                    |
| -------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `key`    | A keyboard key.               | Any LÖVE [KeyConstant](http://love2d.org/wiki/KeyConstant)                                                                                                               |
| `sc`     | A scancode.                   | Any LÖVE [KeyConstant](http://love2d.org/wiki/KeyConstant)                                                                                                               |
| `mouse`  | A mouse button.               | A number representing a mouse button (see [love.mouse.isDown](https://love2d.org/wiki/love.mouse.isDown))                                                                |
| `axis`   | A joystick or gamepad axis.   | Either a number representing a joystick axis or a LÖVE [GamepadAxis](http://love2d.org/wiki/GamepadAxis). Add a '+' or '-' on the end to denote the direction to detect. |
| `button` | A joystick or gamepad button. | Either a number representing a joystick button or a LÖVE [GamepadButton](http://love2d.org/wiki/GamepadButton)                                                           |
| `hat`    | A joystick hat.               | A number representing a joystick hat and a [JoystickHat](https://love2d.org/wiki/JoystickHat). For example '1r' corresponds to the 1st hat pushed right.                 |

##### `pairs` (`table`) (optional)
The axis pairs for the player to use. Each key corresponds to the name of a pair, and each value should be a list containing the names of the left, right, up, and down controls in that order.

##### `joystick` (`Joystick`) (optional)
The joystick for the player to use.

##### `deadzone` (`number`) (optional, defaults to `.5`)
The deadzone for the player.

##### `squareDeadzone` (`boolean`) (optional)
Whether to use square deadzones for axis pairs.

### Player

#### Properties

##### `config` [(`PlayerConfig`)](#playerconfig)
The settings for the player.

#### Functions

##### `Player:update()`
Checks the player's controls for changes. Call this every frame.

##### `Player:getRaw(name)`
Gets the value of a control or axis pair without deadzone applied.

Parameters:
- `name` (`string`) - the name of the control or axis pair to get

Returns (if the name of a control is passed):
- `rawValue` (`number`) - the value of the control without deadzone

Returns (if the name of an axis pair is passed):
- `rawX` (`number`) - the x component of the axis pair without deadzone
- `rawY` (`number`) - the y component of the axis pair without deadzone

##### `Player:get(name)`
Gets the value of a control or axis pair.

Parameters:
- `name` (`string`) - the name of the control or axis pair to get

Returns (if the name of a control is passed):
- `value` (`number`) - the value of the control

Returns (if the name of an axis pair is passed):
- `x` (`number`) - the x component of the axis pair
- `y` (`number`) - the y component of the axis pair

##### `Player:down(name)`
Returns whether the control or axis pair with the given name is "held down" (meaning the value is more than the player's deadzone).

Parameters:
- `name` (`string`) - the name of the control or axis pair to get

Returns:
- `down` (`boolean`) - whether the control or axis pair is held down

##### `Player:pressed(name)`
Returns whether the control or axis pair was just pressed this frame.

Parameters:
- `name` (`string`) - the name of the control or axis pair to get

Returns:
- `pressed` (`boolean`) - whether the control or axis pair was just pressed

##### `Player:released(name)`
Returns whether the control or axis pair was just released this frame.

Parameters:
- `name` (`string`) - the name of the control or axis pair to get

Returns:
- `released` (`boolean`) - whether the control or axis pair was just released

##### `Player:getActiveDevice()`
Gets the currently active device.

Returns:
- `device` (`'kbm'` or `'joy'` or `nil`) - the currently active device, or `nil` if no device has been used yet

Contributing
------------
Issues and pull requests are always welcome. To run the test, run `love .` in the baton folder.
