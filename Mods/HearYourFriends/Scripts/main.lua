-- Experimental client-side UE4SS mod. See README before using.
local ModMenu = require('ModMenu.ModMenu')
local config = require('config')
local Playback = require('playback')
local MenuReload = require('menu_reload')
local menuPrepared = false
local gain = math.max(0, math.min(4, tonumber(config.gain) or 1))
local warned = false
local soloTest = config.soloTest == true
local localChanged = false
local lastStatus

local function status(message)
    if message == lastStatus then return end
    lastStatus = message
    pcall(function() ModMenu.SetLabel('Voice', 'status', message) end)
    print('[HearYourFriends] ' .. message .. '\n')
end

local function valid(object)
    return object ~= nil and object:IsValid()
end

local function update()
    local ok, failure = pcall(function()
        if not menuPrepared then
            MenuReload.prepare(ModMenu.GetInstanceId())
            menuPrepared = true
        end
        local api = StaticFindObject('/Script/UniversalVoiceChatPro.Default__UniversalVoiceChat')
        if not valid(api) then
            if soloTest then status('Waiting for voice system') end
            return
        end
        local localActor = api:VoiceChatGetMyLocalPlayerVoiceChat()
        if not valid(localActor) then
            if soloTest then status('Waiting for local voice actor') end
            return
        end
        -- Solo testing changes playback on the local voice component only. It never
        -- starts capture or transmits voice; the game controls microphone loopback.
        local localOK, localError = pcall(function()
            local mic, volume = localActor.microphoneSpeakComponent, localActor.voiceVolume
            if not valid(mic) then
                if soloTest then status('Waiting for local microphone component') end
                return
            end
            if not soloTest and not localChanged and not Playback.managed(mic) then return end
            if type(volume) ~= 'number' or volume ~= volume or volume < 0 then
                if soloTest then status('Local voice baseline unavailable') end
                return
            end
            if not valid(mic.VoiceCaptureAudioComponent) then
                if soloTest then status('Waiting for local playback component') end
                return
            end
            local decibels = Playback.apply(mic, volume, soloTest and gain or 1)
            if config.diagnostics then
                print(string.format('[HearYourFriends.Measure] gain=%.6f base=%.6f effect_db=%.6f\n', gain, volume, decibels or 0))
            end
            localChanged = soloTest and gain ~= 1
            if soloTest then
                status(string.format('Applied %.2fx%s', gain, gain == 0 and ' (muted)' or string.format(' (%+.2f dB)', decibels or 0)))
            else
                status('Solo test off; local volume restored')
            end
        end)
        if not localOK then
            status('Solo playback unavailable: ' .. tostring(localError))
        end
        local allMuted = api:VoiceChatGetMuteAllPlayers()
        if type(allMuted) ~= 'boolean' or allMuted then return end
        local localAddress = localActor:GetAddress()
        local actors = FindAllOf('PlayerVoiceChatActor') or {}
        for _, actor in pairs(actors) do
            local actorOK, actorError = pcall(function()
                if not valid(actor) or actor:GetAddress() == localAddress then return end
                local player = actor.ownerPlayerState
                if not valid(player) then return end
                local muted = api:VoiceChatLocalIsMutedSomeone(localActor, player)
                if type(muted) ~= 'boolean' or muted then return end
                local mic = actor.microphoneSpeakComponent
                local volume = actor.voiceVolume
                if not valid(mic) or type(volume) ~= 'number' or volume ~= volume or volume < 0 then return end
                Playback.apply(mic, volume, gain)
            end)
            if not actorOK and not warned then
                warned = true
                print('[HearYourFriends] Voice actor not updated: ' .. tostring(actorError) .. '\n')
            end
        end
    end)
    if not ok then
        if soloTest then
            status('Voice update unavailable: ' .. tostring(failure))
        elseif not warned then
            warned = true
            print('[HearYourFriends] Voice update unavailable: ' .. tostring(failure) .. '\n')
        end
    end
end

ModMenu.Init({ title = 'Hear Your Friends (experimental)', key = Key.F8, keyHint = 'F8', ignoreLook = true })
ModMenu.Register({
    id = 'Voice', title = 'Incoming voice', items = {
        { type = 'number', id = 'gain', label = 'Voice multiplier', default = gain, min = 0, max = 4, debounceMs = 0,
          onChange = function(value)
              if type(value) == 'number' and value == value then gain = math.max(0, math.min(4, value)) end
          end },
        { type = 'checkbox', id = 'solo', label = 'Test local microphone playback', default = soloTest,
          onChange = function(value)
              soloTest = value == true
              if not soloTest and not localChanged then status('Solo test off') end
          end },
        { type = 'label', id = 'status', label = 'Solo test off' },
        { type = 'label', label = 'Solo test needs the game microphone test; use headphones.' },
        { type = 'label', label = '0 = silent; 1 = normal; above 1 boosts.' },
    }
})
LoopAsync(500, function()
    ExecuteInGameThread(update)
    return false
end)
print(string.format('[HearYourFriends] Loaded: gain=%.3f solo=%s; F8 controls.\n', gain, tostring(soloTest)))
