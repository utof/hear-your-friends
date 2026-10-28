-- Gain uses Unreal's source DSP: the component-volume path saturates audibly.
local M = {}
local PRESET_CLASS = '/Script/Synthesis.SourceEffectDynamicsProcessorPreset'
local PRESET_NAME = 'HearYourFriendsGain'

local function valid(object)
    return object ~= nil and object:IsValid()
end

local function same(a, b)
    return valid(a) and valid(b) and a:GetAddress() == b:GetAddress()
end

local function ownedPreset(chain)
    if not valid(chain) then return nil end
    local preset = FindObject(StaticFindObject(PRESET_CLASS), chain, PRESET_NAME, true)
    return valid(preset) and preset or nil
end

function M.managed(mic)
    if not valid(mic) then return false end
    local audio = mic.VoiceCaptureAudioComponent
    if not valid(audio) or not valid(audio.Sound) then return false end
    return ownedPreset(audio.Sound.SourceEffectChain) ~= nil
        or ownedPreset(audio.SourceEffectChain) ~= nil
        or ownedPreset(mic.soundEffectChainAsset) ~= nil
end

local function gainChain(original, outer)
    local preset = ownedPreset(original)
    if preset then return original, preset, false end
    local entries = {}
    if valid(original) then
        for i = 1, #original.Chain do
            local entry = original.Chain[i]
            entries[#entries + 1] = { Preset = entry.Preset, bBypass = entry.bBypass }
        end
    end
    local chainClass = StaticFindObject('/Script/Engine.SoundEffectSourcePresetChain')
    local presetClass = StaticFindObject(PRESET_CLASS)
    assert(valid(chainClass) and valid(presetClass), 'Unreal source gain classes unavailable')
    local chain = StaticConstructObject(chainClass, outer) -- Unreal gives it a unique name.
    preset = StaticConstructObject(presetClass, chain, FName(PRESET_NAME))
    assert(valid(chain) and valid(preset), 'Cannot create voice gain effect')
    entries[#entries + 1] = { Preset = preset, bBypass = false }
    chain.Chain = entries -- Engine references keep presets alive across GC and Lua reloads.
    local settings = preset.Settings
    settings.Ratio, settings.InputGainDb, settings.OutputGainDb, settings.LookAheadMsec = 1, 0, 0, 0
    preset:SetSettings(settings)
    return chain, preset, true
end

local function setGain(preset, decibels)
    if math.abs(preset.Settings.OutputGainDb - decibels) > 0.00001 then
        local settings = preset.Settings
        settings.OutputGainDb = decibels
        preset:SetSettings(settings)
    end
end

function M.apply(mic, baseline, gain)
    assert(valid(mic) and valid(mic.VoiceCaptureAudioComponent), 'Voice playback component unavailable')
    assert(type(baseline) == 'number' and baseline == baseline and baseline >= 0 and baseline < math.huge, 'Invalid voice baseline')
    assert(type(gain) == 'number' and gain == gain and gain >= 0 and gain <= 4, 'Invalid voice gain')
    local audio = mic.VoiceCaptureAudioComponent
    assert(valid(audio.Sound), 'Voice procedural sound unavailable')
    if gain == 1 and not M.managed(mic) then return end
    local decibels = gain > 0 and 20 * math.log(gain, 10) or 0
    local override, radio = audio.SourceEffectChain, mic.soundEffectChainAsset
    local baseChain, basePreset, fresh = gainChain(audio.Sound.SourceEffectChain, audio)
    setGain(basePreset, decibels)
    audio.Sound.SourceEffectChain = baseChain
    local radioChain
    if valid(radio) then
        local preset, created
        radioChain, preset, created = gainChain(radio, audio)
        fresh = fresh or created
        setGain(preset, decibels)
        mic.soundEffectChainAsset = radioChain
    end
    if valid(override) then
        if same(override, radio) then
            audio.SourceEffectChain = radioChain
        elseif ownedPreset(override) then
            setGain(ownedPreset(override), decibels)
        else
            local chain, preset, created = gainChain(override, audio)
            setGain(preset, decibels)
            audio.SourceEffectChain = chain
            fresh = fresh or created
        end
    end
    if fresh then
        -- UE 5.4 has no reflected live chain setter. Attach once per component;
        -- subsequent edits update the preset without stopping playback.
        local wasPlaying = audio:IsPlaying()
        audio:Stop()
        if wasPlaying then audio:Play(0) end
    end
    -- UpdateRadioState selects its radio chain or clears the override to use the
    -- procedural sound's chain. Both private chains retain gain through that reset.
    mic:SetVoiceVolume(gain == 0 and 0 or baseline)
    return decibels
end

return M
