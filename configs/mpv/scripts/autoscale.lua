-- Scales mpv's fixed-size OSD text and subtitles to the display's HiDPI scale
-- so they aren't tiny on high-resolution screens. mpv's ModernX control bar is
-- already window-height adaptive (modernx vid_scale=false uses mp.get_osd_size
-- height), so only the fixed-pixel OSD/subtitles need scaling here.
--
-- Reads mpv's display-hidpi-scale property (2 on a 4K @ scale-2 monitor, 1 on
-- a standard one) and applies it as a multiplier to osd-scale and sub-scale.
-- osd-scale multiplies the fixed osd-font-size and sub-scale multiplies the
-- fixed sub-font-size from mpv.conf.
--
-- display-hidpi-scale is not available at script load (the window hasn't mapped
-- yet and it reads -1), so we skip until it holds a real value and re-apply
-- whenever the window maps (osd-dimensions) or the scale changes (monitor move).
local BASE = 1.0      -- overall multiplier on top of display scale (2x on a 4K @ scale-2 monitor)
local MIN, MAX = 1.0, 6.0

local function current_scale()
  local hidpi = mp.get_property_number("display-hidpi-scale", 1) or 1
  if not (hidpi and hidpi > 0) then
    return nil
  end
  return math.min(MAX, math.max(MIN, hidpi * BASE))
end

local function apply()
  local f = current_scale()
  if not f then
    mp.msg.verbose("autoscale: display scale not ready yet, skipping")
    return
  end
  mp.set_property_number("osd-scale", f) -- multiplies osd-font-size
  mp.set_property_number("sub-scale", f) -- multiplies sub-font-size
  mp.msg.verbose("autoscale: applied osd/sub-scale = " .. f)
end

mp.observe_property("display-hidpi-scale", "number", function() apply() end)
mp.observe_property("osd-dimensions", "native", function() apply() end)
-- The window takes a moment to map; re-check shortly after start.
mp.add_timeout(0.3, function() apply() end)
mp.add_timeout(1.0, function() apply() end)
apply()
