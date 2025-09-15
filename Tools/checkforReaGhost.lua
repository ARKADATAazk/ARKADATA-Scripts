-- Function to find an FX by name and return its index
function findFXByName(track, fx_name)
    local fx_count = reaper.TrackFX_GetCount(track)
    for i = 0, fx_count - 1 do
        local retval, fx_name_out = reaper.TrackFX_GetFXName(track, i, "")
        if fx_name_out:find(fx_name) then
            return i
        end
    end
    return -1 -- FX not found
end

-- Function to activate and make an envelope visible for a parameter
function activateAndShowEnvelope(track, fx_index, param_index)
    -- Get or create the envelope for the parameter
    local envelope = reaper.GetFXEnvelope(track, fx_index, param_index, true)
    if envelope then
        -- Get the current state chunk
        local retval, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
        
        if retval then
            -- Modify the chunk to make the envelope visible and armed
            -- Find and replace visibility and activation flags
            chunk = chunk:gsub("VIS %d+", "VIS 1")
            chunk = chunk:gsub("ARM %d+", "ARM 1")
            
            -- Apply the modified chunk back to the envelope
            reaper.SetEnvelopeStateChunk(envelope, chunk, false)
        end
    end
end


-- Main function to check and activate corresponding envelopes
function activateCorrespondingTrueEnvelopes(track)
    local ghost_fx_index = findFXByName(track, "ReaGhostMIDI")
    local true_fx_index = findFXByName(track, "ReaTrueMIDI")

    if ghost_fx_index == -1 then
        reaper.ShowConsoleMsg("ReaGhostMIDI not found on the selected track!\n")
        return
    end

    if true_fx_index == -1 then
        reaper.ShowConsoleMsg("ReaTrueMIDI not found on the selected track!\n")
        return
    end

    -- Loop through parameters of the ReaGhostMIDI FX
    for paramIndex = 0, reaper.TrackFX_GetNumParams(track, ghost_fx_index) - 1 do
        -- Get the parameter name
        local retval, paramName = reaper.TrackFX_GetParamName(track, ghost_fx_index, paramIndex, "")
        
        -- Check if there is an active envelope associated with the parameter
        local envelope = reaper.GetFXEnvelope(track, ghost_fx_index, paramIndex, false)
        if envelope then
            reaper.ShowConsoleMsg("Active envelope found in ReaGhostMIDI for parameter: " .. paramName .. "\n")
            
            -- Activate and show the corresponding envelope in ReaTrueMIDI
            activateAndShowEnvelope(track, true_fx_index, paramIndex)
            reaper.ShowConsoleMsg("Activated and made visible the corresponding envelope in ReaTrueMIDI for parameter: " .. paramName .. "\n")
        end
    end
end

-- Get the selected track
track = reaper.GetSelectedTrack(0, 0) -- Assuming the track is selected

if track then
    activateCorrespondingTrueEnvelopes(track)
else
    reaper.ShowConsoleMsg("No track selected.\n")
end
