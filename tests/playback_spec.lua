-- Test the gain stage independently of voice actor selection. Engine access is
-- mocked; the real output sweep remains the acoustic acceptance test.
local serial, constructed = 0, 0
local objects = {}
local function object(name)
    serial = serial + 1
    local o = { name = name, address = serial }
    function o:IsValid() return true end
    function o:GetFName() return { ToString = function() return self.name end } end
    function o:GetAddress() return self.address end
    return o
end
FName = function(name) return name end
StaticFindObject = function(path) return object(path) end
StaticConstructObject = function(class, outer, name)
    constructed = constructed + 1
    local o = object(name or ('auto_' .. constructed))
    o.outer, o.Chain, o.Settings = outer, {}, {}
    function o:SetSettings(settings)
        self.Settings = {}
        for k,v in pairs(settings) do self.Settings[k] = v end
    end
    table.insert(objects, o)
    return o
end
FindObject = function(_, outer, name)
    for _, o in ipairs(objects) do if o.outer == outer and o.name == name then return o end end
end
local audio = object('voice')
audio.stops, audio.plays, audio.playing = 0, 0, true
function audio:IsPlaying() return self.playing end
function audio:Stop() self.stops = self.stops + 1; self.playing = false end
function audio:Play() self.plays = self.plays + 1; self.playing = true end
local mic = object('microphone')
mic.VoiceCaptureAudioComponent = audio
audio.Sound = object('proceduralVoice')
function mic:SetVoiceVolume(volume) self.volume = volume end
local loader = assert(loadfile('Mods/HearYourFriends/Scripts/playback.lua'), 'playback gain module is missing')
local playback = loader()
playback.apply(mic, 8, 1)
assert(constructed == 0 and mic.volume == nil, 'normal startup leaves playback alone')
playback.apply(mic, 8, 2)
assert(mic.volume == 8, 'gain must not be multiplied into the saturated component volume')
local chain = audio.Sound.SourceEffectChain
assert(chain and #chain.Chain == 1, 'preset is referenced by the Unreal chain for GC')
local preset = chain.Chain[1].Preset
assert(math.abs(preset.Settings.OutputGainDb - 20*math.log(2,10)) < 1e-6, 'twofold gain uses six decibels')
assert(preset.Settings.Ratio == 1 and preset.Settings.LookAheadMsec == 0, 'adds gain without compression or look-ahead')
assert(audio.stops == 1 and audio.plays == 1, 'attaches once to active playback')
playback.apply(mic, 8, .1)
assert(math.abs(preset.Settings.OutputGainDb + 20) < 1e-6, 'attenuation uses the same gain stage')
assert(audio.stops == 1, 'changing a value does not restart playback')
playback.apply(mic, 8, 0)
assert(mic.volume == 0 and preset.Settings.OutputGainDb == 0, 'zero mutes without log of zero')
playback.apply(mic, 3, 4)
assert(mic.volume == 3, 'restores the current replicated baseline after mute')
assert(math.abs(preset.Settings.OutputGainDb - 20*math.log(4,10)) < 1e-6, 'fourfold gain')
local reloaded = loader()
assert(reloaded.managed(mic), 'finds its own effect after a Lua reload')
reloaded.apply(mic, 3, 1)
assert(preset.Settings.OutputGainDb == 0 and mic.volume == 3, 'reload can restore normal playback')
assert(constructed == 2, 'reload does not accumulate gain effects')
local other = object('originalChain')
local original = object('radioEffect')
other.Chain = {{Preset = original, bBypass = false}}
audio.Sound.SourceEffectChain = other
reloaded.apply(mic, 3, 2)
assert(#audio.Sound.SourceEffectChain.Chain == 2, 'preserves existing source effects')
assert(audio.Sound.SourceEffectChain.Chain[1].Preset == original, 'original effects stay first')
assert(#other.Chain == 1, 'never changes a shared game effect asset')
local radio = object('radioChain')
radio.Chain = {{ Preset = original, bBypass = true }}
mic.soundEffectChainAsset, audio.SourceEffectChain = radio, radio
reloaded.apply(mic, 3, 4)
assert(mic.soundEffectChainAsset ~= radio, 'radio uses a private copy')
assert(audio.SourceEffectChain == mic.soundEffectChainAsset, 'active radio override follows its gain chain')
local radioPreset = mic.soundEffectChainAsset.Chain[2].Preset
assert(math.abs(radioPreset.Settings.OutputGainDb - 20*math.log(4,10)) < 1e-6, 'radio gain matches proximity gain')
local stops = audio.stops
-- The real plugin clears the component override when proximity playback starts.
audio.SourceEffectChain = nil
reloaded.apply(mic, 3, .5)
assert(audio.stops == stops, 'mode switches do not require reattaching the base gain')
assert(math.abs(radioPreset.Settings.OutputGainDb - 20*math.log(.5,10)) < 1e-6, 'updates inactive radio preset too')
assert(audio.Sound.SourceEffectChain.Chain[2].Preset.Settings.OutputGainDb == radioPreset.Settings.OutputGainDb, 'both playback modes use the same gain')
assert(radio.Chain[1].bBypass == true and #radio.Chain == 1, 'radio asset remains intact')
local foreign = object('otherModChain')
foreign.Chain = {{Preset = original, bBypass = false}}
audio.SourceEffectChain = foreign
reloaded.apply(mic, 3, 2)
local foreignCopy = audio.SourceEffectChain
reloaded.apply(mic, 3, 4)
assert(audio.SourceEffectChain == foreignCopy, 'repeated updates retain a private copy of another mod override')
assert(audio.SourceEffectChain.Chain[1].Preset == original, 'keeps override effects on repeated updates')
print('playback gain tests passed')
