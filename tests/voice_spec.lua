local menu, tick
Key = { F8 = 119 }
package.preload['ModMenu.ModMenu'] = function()
    return { Init = function() end, Register = function(section) menu = section end }
end
LoopAsync = function(_, callback) tick = callback end
ExecuteInGameThread = function(callback) callback() end
local function object(address)
    return { IsValid = function() return true end, GetAddress = function() return address end }
end
local local_actor, remote, muted, no_owner = object(1), object(2), object(3), object(4)
local function component()
    return { IsValid = function() return true end, calls = {}, SetVoiceVolume = function(self, volume) table.insert(self.calls, volume) end }
end
remote.microphoneSpeakComponent, muted.microphoneSpeakComponent, no_owner.microphoneSpeakComponent = component(), component(), component()
remote.voiceVolume, muted.voiceVolume, no_owner.voiceVolume = 0.4, 0.8, 0.5
remote.ownerPlayerState, muted.ownerPlayerState = object(12), object(13)
local voice = object(20)
function voice:VoiceChatGetMyLocalPlayerVoiceChat() return local_actor end
function voice:VoiceChatGetMuteAllPlayers() return false end
function voice:VoiceChatLocalIsMutedSomeone(player, context) assert(context == local_actor); return player:GetAddress() == 13 end
StaticFindObject = function() return voice end
FindAllOf = function() return {local_actor, remote, muted, no_owner} end

assert(loadfile('Mods/shared/ModMenu/ModMenu.lua'))
dofile('Mods/HearYourFriends/Scripts/main.lua')
assert(menu and tick, 'registers UI and timer')
local change = menu.items[1].onChange
change(2)
tick(); tick()
assert(#remote.microphoneSpeakComponent.calls == 2, 'updates remote actor')
assert(remote.microphoneSpeakComponent.calls[1] == 0.8 and remote.microphoneSpeakComponent.calls[2] == 0.8, 'does not compound gain')
assert(#muted.microphoneSpeakComponent.calls == 0, 'skips muted player')
assert(#no_owner.microphoneSpeakComponent.calls == 0, 'skips unknown owner')
change(1)
tick()
assert(remote.microphoneSpeakComponent.calls[3] == 0.4, 'restores original volume')
voice.VoiceChatGetMyLocalPlayerVoiceChat = function() return nil end
change(3)
tick()
assert(#remote.microphoneSpeakComponent.calls == 3, 'fails closed without a local player')
voice.VoiceChatGetMyLocalPlayerVoiceChat = function() return local_actor end
voice.VoiceChatGetMuteAllPlayers = function() return true end
tick()
assert(#remote.microphoneSpeakComponent.calls == 3, 'honors mute all')
voice.VoiceChatGetMuteAllPlayers = function() return false end
remote.voiceVolume = 0.2
change(100)
tick()
assert(remote.microphoneSpeakComponent.calls[4] == 0.8, 'uses current baseline and clamps gain')
print('voice control tests passed')
