-- ReArkitekt/gui/systems/playback_manager.lua
-- Utility for computing playback visual states (fade alpha, etc)

local M = {}

function M.compute_fade_alpha(progress, fade_in_ratio, fade_out_ratio)
  fade_in_ratio = fade_in_ratio or 0.1
  fade_out_ratio = fade_out_ratio or 0.2
  
  if progress < fade_in_ratio then
    return progress / fade_in_ratio
  end
  
  if progress > (1.0 - fade_out_ratio) then
    return (1.0 - progress) / fade_out_ratio
  end
  
  return 1.0
end

return M