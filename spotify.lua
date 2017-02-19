local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")
local dbus = dbus

local spotify = {}

spotify.player_status = {}
spotify.widget = wibox.widget.textbox("")
spotify.widget:set_font('Play 7')

spotify.init = function ()
  local controlActions = {
    "play",
    "pause",
    "prev",
    "next",
  }

  for i, action in ipairs(controlActions) do
    spotify[action] = function () return spotify.action(action) end
  end

  dbus.add_match("session", "path='/org/mpris/MediaPlayer2',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'")
  dbus.connect_signal(
    "org.freedesktop.DBus.Properties",
    spotify.update
  )
end

local get_current = function (cb)
  local noisy = [[bash -c '
    sp current-oneline
    ']]
  awful.spawn.with_line_callback(noisy, {
                                   stdout = cb,
                                   stderr = function(line)
                                     naughty.notify { text = "ERR:"..line}
                                   end,
  })
end

spotify.update = function (path, bus_path, payload, ...)
  -- payload.PlaybackStatus
  -- payload.Metadata
  -- 
  local json = require('json')
  local args = {...}
  naughty.notify { text = json.encode(payload) }
  get_current (function (current)
   spotify.widget:set_text(current)
  end)
end

spotify.action = function (action)
  os.execute('sp ' .. action)
end

function spotify.post_update(result_string, parse_status_callback)
  spotify.player_status = {}
  local state = nil
  if result_string:match("Playing") then
    state = 'play'
  elseif result_string:match("Paused") then
    state = 'pause'
  end
  spotify.player_status.state = state
  if state == 'play' or state == 'pause' then
    awful.spawn.easy_async(
      dbus_cmd .. "Metadata",
      function(str) spotify.parse_metadata(str, parse_status_callback) end
    )
  else
    parse_status_callback(spotify.player_status)
  end
end

function spotify.parse_metadata(result_string, parse_status_callback)
  h_table.merge(spotify.player_status, parse.find_values_in_string(
    result_string,
    "([%w]+): (.*)$",
    { artist='artist',
      title='title',
      album='album',
      date='contentCreated',
      cover_url='artUrl'
    }
  ))
  spotify.player_status.date = h_string.max_length(spotify.player_status.date, 4)
  spotify.player_status.file = 'spotify stream'
  parse_status_callback(spotify.player_status)
end

return spotify
