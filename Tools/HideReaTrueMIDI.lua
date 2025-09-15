-- Define the filter for envelope names
local filterName = "ReaTrueMIDI"  -- Replace with your specific filter criteria

-- Get the current toggle state from the project extstate
local extStateKey = "CustomEnvelopeVisibilityToggle"
local toggleState = reaper.GetProjExtState(0, "EnvelopeVisibility", extStateKey)
toggleState = tonumber(toggleState)

-- If the state is nil or 0, set it to 1 (show), otherwise toggle to 0 (hide)
if toggleState == nil or toggleState == 0 then
    toggleState = 1  -- Show envelopes
else
    toggleState = 0  -- Hide envelopes
end

-- Save the new toggle state back to the project extstate
reaper.SetProjExtState(0, "EnvelopeVisibility", extStateKey, tostring(toggleState))

-- Loop through all tracks
for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    
    -- Loop through all FX on the track
    for fx = 0, reaper.TrackFX_GetCount(track) - 1 do
        
        -- Loop through all parameters of the FX
        for param = 0, reaper.TrackFX_GetNumParams(track, fx) - 1 do
            local envelope = reaper.GetFXEnvelope(track, fx, param, false)  -- false to not create if it doesn't exist
            
            if envelope then  -- Check if the envelope exists
                local retval, envName = reaper.GetEnvelopeName(envelope, "")
                
                -- Apply the filter criteria
                if string.match(envName, filterName) then  -- Envelope name matches filter
                    local _, stateChunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
                    
                    -- Show or hide based on toggle state
                    if toggleState == 1 then
                        stateChunk = stateChunk:gsub("\nVIS %d", "\nVIS 1")  -- Show envelope
                    else
                        stateChunk = stateChunk:gsub("\nVIS %d", "\nVIS 0")  -- Hide envelope
                    end
                    
                    reaper.SetEnvelopeStateChunk(envelope, stateChunk, true)
                end
            end
        end
    end
end

reaper.UpdateArrange()
