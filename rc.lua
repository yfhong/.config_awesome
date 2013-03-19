-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Vicious widget library
require("vicious")
-- Revelation library
--require("revelation")
-- Eminent library
package.path = package.path .. ';' .. awful.util.getdir("config") .. "/eminent/?.lua"
require("eminent")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
-- Use zenburn theme
beautiful.init(awful.util.getdir("config") .. "/themes/zenburn.lua")

-- This is used later as the default terminal and editor to run.
-- Hard code urxvt as term
terminal = "urxvtcd"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

-- }}}

-- {{{ Wibox
-- Create a CPU widget
cpuwidget = awful.widget.graph({ layout = awful.widget.layout.horizontal.rightleft })
cpuwidget:set_width(40)
cpuwidget:set_background_color(theme.bg_normal)
cpuwidget:set_color('#FFFFFF')
--cpuwidget:set_gradient_colors({ '#FF5656', '#88A175', '#AECF96' })
vicious.register(cpuwidget, vicious.widgets.cpu, '$1', 5)

-- Create a memory widget
memwidget = widget({ type = "textbox" })
--vicious.cache(vicious.widgets.mem)
vicious.register(memwidget, vicious.widgets.mem, "$2/$9M ", 13)

-- Create a battery widget
batwidget = widget({ type = "textbox" })
vicious.register(batwidget, vicious.widgets.bat,
    function (widget, args)
        if (args[3] == "N/A") then
            return string.format("%s%s%% ", args[1], args[2])
        else
            return string.format("%s%s%% %s ", args[1], args[2], args[3])
        end
    end, 61, "BAT0")

-- Create a temperature widget
thmwidget = widget({ type = "textbox" })
vicious.register(thmwidget, vicious.widgets.thermal, "$1° ", 19, {"coretemp.0", "core"})

-- Create a wifi widget
function has_wifi ()
    local f = io.open("/proc/net/dev")
    s = f:read("*all")
    f:close()
    return string.match(s, "wlan") ~= nil
end
if has_wifi() then
    wifiwidget = widget({ type = "textbox" })
    vicious.register(wifiwidget, vicious.widgets.wifi, "${ssid} ", 63, "wlan0")
else
    wifiwidget = nil
end

-- Create a net widget
netwidget = widget({ type = "textbox" })
--vicious.register(netwidget, vicious.widgets.net, "${eth0 down_kb}/${eth0 up_kb}KB ", 7)
vicious.register(netwidget, vicious.widgets.net,
    function (widget, args)
        local down_kb = args["{eth0 down_kb}"]
        local up_kb = args["{eth0 up_kb}"]
        if (args["{wlan0 down_kb}"] ~= nil) then
            down_kb = down_kb + args["{wlan0 down_kb}"]
            up_kb = up_kb + args["{wlan0 up_kb}"]
        end
        return down_kb .. "/" .. up_kb .. "KB "
    end, 7)

-- Create a textclock widget
-- Make clock at left
mytextclock = awful.widget.textclock({ align = "left" }, " %a %m/%d <b>%H:%M</b> ")

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mytextclock,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        s == 1 and mysystray or nil,
        s == 1 and cpuwidget or nil,
        s == 1 and memwidget or nil,
        s == 1 and thmwidget or nil,
        s == 1 and batwidget or nil,
        s == 1 and wifiwidget or nil,
        s == 1 and netwidget or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
function lock_screen ()
    awful.util.spawn_with_shell("xset q | grep -q 'prefer blanking:  yes' && xautolock -locknow || (xautolock -enable; sleep 1; xautolock -locknow)")
end

function toggle_blank ()
    local f = io.popen("xset q")
    local xset = f:read("*all")
    f:close()
    if string.find(xset, "prefer blanking:  yes") then
        awful.util.spawn_with_shell("xset -dpms s noblank s off; xautolock -disable")
        naughty.notify({text = "Disable screensaver"})
    else
        awful.util.spawn_with_shell("xset +dpms s default; xautolock -enable")
        naughty.notify({text = "Enable screensaver"})
    end
end

globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Revelation
    --awful.key({modkey}, "e", revelation),

    -- Window info
    awful.key({ modkey, "Control" }, "i",
        function ()
            local c = client.focus
            local crole = "N/A"
            local cgeom = c:geometry()
            if c.role then crole = c.role end
            if c then naughty.notify({
                text = "Class:    " .. c.class .. "\n"
                .. "Instance: " .. c.instance .. "\n"
                .. "Role:     " .. crole .. "\n"
                .. "Type:     " .. c.type .. "\n"
                .. "Geometry: "
                .. cgeom.x .. " " .. cgeom.y .. " " .. cgeom.width .. " " .. cgeom.height
            })
            else naughty.notify({ text = "No focused window" })
            end
        end),

    -- Center window
    awful.key({ modkey, }, "c",
        function ()
            local c = client.focus
            if c then
                awful.placement.centered(c, c.transient_for)
            end
        end),

    -- Make window ontop
    awful.key({ modkey, }, "t",
        function ()
            local c = client.focus
            if c then
                c.ontop = not c.ontop
            end
        end),

    -- Misc
    awful.key({ }, "XF86Eject", lock_screen),
    awful.key({ }, "Pause", lock_screen),
    awful.key({ modkey }, "XF86Eject", toggle_blank),
    awful.key({ modkey }, "Pause", toggle_blank),
    awful.key({ }, "XF86Display", function () awful.util.spawn("my-extern-monitor right") end),

    -- Volume
    awful.key({ modkey }, ".", function () awful.util.spawn("my-volume up") end),
    awful.key({ modkey }, ",", function () awful.util.spawn("my-volume down") end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey, "Shift" }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "x",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            -- Check if horizontally and vertically maxed first
            if c.maximized_horizontal and c.maximized_vertical then
                c.maximized_horizontal = false
                c.maximized_vertical = false
            else
                c.maximized_horizontal = true
                c.maximized_vertical = true
            end
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = 0,
                     border_color = beautiful.border_normal,
                     size_hints_honor = false,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true, border_width = 0 } },
    { rule = { class = "mplayer2" },
      properties = { floating = true,
                     border_width = 0 } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "feh" },
      properties = { floating = true } },
    { rule = { class = "Cview" },
      properties = { floating = true } },
    { rule = { class = "URxvt" },
      properties = { opacity = 0.97, border_width = beautiful.border_width } },
    { rule = { class = "Gvim" },
      properties = { opacity = 0.97 } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    { rule = { class = "Firefox", instance = "Navigator" },
      properties = { tag = tags[1][2], border_width = 0 } },
    { rule = { class = "Iceweasel", instance = "Navigator" },
      properties = { tag = tags[1][2], border_width = 0 } },
    { rule = { class = "Aurora", instance = "Navigator" },
      properties = { tag = tags[1][2] } },
    { rule = { class = "Chromium-browser" },
      properties = { tag = tags[1][2] } },
    -- screen 3
    { rule = { class = "Icedove-bin" },
      properties = { tag = tags[1][3] } },
    -- screen 4
    { rule = { class = "Pidgin" },
      properties = { tag = tags[1][4] } },
    { rule = { class = "emesene" },
      properties = { tag = tags[1][4] } },
    { rule = { class = "Empathy" },
      properties = { tag = tags[1][4] } },
    -- screen 5
    { rule = { class = "VirtualBox" },
      properties = { tag = tags[1][5] } },
    { rule = { class = "VBoxSDL" },
      properties = { tag = tags[1][5] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
            -- Place new floating client center
            if awful.client.floating.get(c) and not c.maximized_horizontal
                    and not c.maximized_vertical and c.class ~= "Iceweasel"
                    and c.class ~= "Firefox" then
                    awful.placement.centered(c, c.transient_for)
            end
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- For a rest
mytimer = timer { timeout = 3600 }
mytimer:add_signal("timeout", function()
    naughty.notify({ text = "Time for a REST" })
end)
mytimer:start()

-- http://awesome.naquadah.org/wiki/Autostart
function run_once(prg,arg_string,pname,screen)
    if not prg then
        do return nil end
    end
    if not pname then
       pname = prg
    end
    if not arg_string then
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. "' || (" .. prg .. ")",screen)
    else
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. "' || (" .. prg .. " " .. arg_string .. ")",screen)
    end
end
--run_once("unagi")
run_once("compton")
run_once("parcellite")
run_once("xcalib .color/icc/Apple_Macbook_Pro_5,2_LCD.icc")
run_once("xautolock -time 15 -locker 'i3lock --color=000000'")
-- run_once("xsetroot -cursor_name left_ptr")
-- }}}
