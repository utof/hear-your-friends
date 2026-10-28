-- Experimental client-side UE4SS mod. See README before using.
local ModMenu = require('ModMenu.ModMenu')
local gain = 1
local changed = {}
local warned = false

local function valid(object)
    return object ~= nil and object:IsValid()
end

local function update()
    local ok, failure = pcall(function()
        local api = StaticFindObject('/Script/UniversalVoiceChatPro.Default__UniversalVoiceChat')
        if not valid(api) then return end
        local localActor = api:VoiceChatGetMyLocalPlayerVoiceChat()
        if not valid(localActor) then return end
        local allMuted = api:VoiceChatGetMuteAllPlayers()
        if type(allMuted) ~= 'boolean' or allMuted then return end
        local localAddress = localActor:GetAddress()
        local actors = FindAllOf('PlayerVoiceChatActor') or {}
        for _, actor in pairs(actors) do
            local actorOK, actorError = pcall(function()
                if not valid(actor) or actor:GetAddress() == localAddress then return end
                local address = actor:GetAddress()
                if gain == 1 and not changed[address] then return end
                local player = actor.ownerPlayerState
                if not valid(player) then return end
                local muted = api:VoiceChatLocalIsMutedSomeone(player, localActor)
                if type(muted) ~= 'boolean' or muted then return end
                local mic = actor.microphoneSpeakComponent
                local volume = actor.voiceVolume
                if not valid(mic) or type(volume) ~= 'number' or volume ~= volume or volume < 0 then return end
                mic:SetVoiceVolume(volume * gain)
                changed[address] = gain ~= 1 or nil
            end)
            if not actorOK and not warned then
                warned = true
                print('[HearYourFriends] Voice actor not updated: ' .. tostring(actorError) .. '\n')
            end
        end
    end)
    if not ok and not warned then
        warned = true
        print('[HearYourFriends] Voice update unavailable: ' .. tostring(failure) .. '\n')
    end
end

ModMenu.Init({ title = 'Hear Your Friends (experimental)', instanceId = 'HearYourFriends', key = Key.F8, keyHint = 'F8', ignoreLook = true })
ModMenu.Register({
    id = 'Voice', title = 'Incoming voice', items = {
        { type = 'number', id = 'gain', label = 'Voice multiplier', default = 1, min = 1, max = 4,
          onChange = function(value)
              if type(value) == 'number' and value == value then gain = math.max(1, math.min(4, value)) end
          end },
        { type = 'label', label = '1 = normal; values above 1 are experimental.' },
    }
})
LoopAsync(500, function()
    ExecuteInGameThread(update)
    return false
end)
print('[HearYourFriends] Experimental controls: F8; multiplier starts at 1.\n')
