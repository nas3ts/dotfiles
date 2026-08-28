-- Scales mpv's fixed-size OSD text and subtitles to the display's HiDPI scale
-- so they aren't tiny on high-resolution screens. mpv's ModernX control bar is
-- already window-height adaptive (modernx vid_scale=false uses mp.get_osd_size
-- height), so only the fixed-pixel OSD/subtitles need scaling here.
--
-- Reads mpv's display-hidpi-scale property (2 on a 4K @ scale-2 monitor, 1 on
-- a standard one) and applies it as a multiplier to osd-scale and sub-scale.
-- osd-scale multiplies the fixed osd-font-size and sub-scale multiplies the
-- fixed sub-font-size from mpv.conf. Re-runs when the window moves to a
-- different monitor.
local BASE = 1.0      -- overall multiplier (tune if 2x feels too big/small)
local MIN, MAX = 1.0, 4.0

local function apply()
  local hidpi = mp.get_property_number("display-hidpi-scale", 1) or 1
  local f = math.min(MAX, math.max(MIN, hidpi * BASE))

  mp.set_property_number("osd-scale", f) -- multiplies osd-font-size
  mp.set_property_number("sub-scale", f) -- multiplies sub-font-size
end

mp.observe_property("display-hidpi-scale", "number", function() apply() end)
mp.register_event("file-loaded", apply)
apply()
