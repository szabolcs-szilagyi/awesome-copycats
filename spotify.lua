local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")
local dbus = dbus

local spotify = {}

spotify.widget = wibox.widget.textbox("")
spotify.widget:set_font('Play 7')

spotify.init = function ()
  dbus.add_match("session", "path='/org/mpris/MediaPlayer2',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'")
  dbus.connect_signal(
    "org.freedesktop.DBus.Properties",
    spotify.update
  )
end

spotify.play = function () return spotify.action("play") end
spotify.pause = function () return spotify.action("pause") end
spotify.prev = function () return spotify.action("prev") end
spotify.next = function () return spotify.action("next") end

spotify.action = function (action)
  os.execute('sp ' .. action)
end

spotify.update = function (path, bus_path, payload)
  local meta = payload.Metadata
  spotify.widget:set_text(meta['xesam:artist'][1] .. ' | ' .. meta['xesam:title'])
end

return spotify
