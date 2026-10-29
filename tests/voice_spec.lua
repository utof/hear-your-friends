package.path='Mods/HearYourFriends/Scripts/?.lua;'..package.path
local menu,playerMenu,tick,status_text
local values={}
local function object(address)
 return {IsValid=function() return true end,GetAddress=function() return address end,
 GetFName=function() return {ToString=function() return 'PS_'..address end} end,
 GetPlayerName=function() return 'Player '..address end}
end
local local_actor,remote,muted,no_owner=object(1),object(2),object(3),object(4)
local function component()
 local mic=object(99);mic.calls={};mic.VoiceCaptureAudioComponent=object(101)
 mic.VoiceCaptureAudioComponent.Sound=object(102)
 function mic:SetVoiceVolume(volume) self.calls[#self.calls+1]=volume end
 return mic
end
local_actor.ownerPlayerState=object(11)
remote.ownerPlayerState,muted.ownerPlayerState=object(12),object(13)
local_actor.microphoneSpeakComponent,local_actor.voiceVolume=component(),.3
remote.microphoneSpeakComponent,remote.voiceVolume=component(),.4
muted.microphoneSpeakComponent,muted.voiceVolume=component(),.8
no_owner.microphoneSpeakComponent,no_owner.voiceVolume=component(),.5
local game=object(200);game.PlayerArray={local_actor.ownerPlayerState,remote.ownerPlayerState,muted.ownerPlayerState}
local voice=object(20)
function voice:VoiceChatGetMyLocalPlayerVoiceChat() return local_actor end
function voice:VoiceChatGetMuteAllPlayers() return false end
function voice:VoiceChatLocalIsMutedSomeone(context,player) assert(context==local_actor);return player:GetAddress()==13 end
StaticFindObject=function() return voice end
FindAllOf=function() return {local_actor,remote,muted,no_owner} end
LoopAsync=function(_,fn) tick=fn end
LoopInGameThreadWithDelay=function() end
ExecuteInGameThread=function(fn) fn() end
Key={F8=119}
package.preload['config']=function() return {gain=1,soloTest=false} end
package.preload['ModMenu.ModMenu']=function() return {
 Init=function() end,GetInstanceId=function() return 'test' end,
 Register=function(section) if section.id=='Voice' then menu=section else playerMenu=section end end,
 SetLabel=function(_,_,text) status_text=text end,Set=function(section,key,value) values[section..'.'..key]=value end,
} end
package.preload['UEHelpers.UEHelpers']=function() return {GetGameStateBase=function() return game end,GetWorld=function() return game end} end
package.preload['ModMenu.core.util']=function() return {PinFn=function(fn) return fn end} end
package.preload['menu_reload']=function() return {prepare=function() end} end
package.preload['native_ui']=function() return {new=function() return {refresh=function() end,poll=function() end} end} end
package.preload['slider']=function() return {install=function() end} end
package.preload['report']=function() return {} end
package.preload['playback']=function() return {managed=function(mic) return mic.changed end,apply=function(mic,base,gain)
 if gain~=1 or mic.changed then mic:SetVoiceVolume(base*gain);mic.changed=gain~=1 end
 return gain>0 and 20*math.log(gain,10) or 0
end} end
dofile('Mods/HearYourFriends/Scripts/main.lua')
assert(menu.items[1].type=='slider', 'uses a slider instead of a numeric field')
tick()
assert(#local_actor.microphoneSpeakComponent.calls==0, 'does not change local playback by default')
assert(playerMenu and #playerMenu.items==2, 'lists connected remote players, including muted players')
local gain=menu.items[1].onChange
local resetLevels=playerMenu.items[1].onChange
resetLevels(0)
local savedPlayers=game.PlayerArray
game.PlayerArray={local_actor.ownerPlayerState};tick()
game.PlayerArray=savedPlayers;tick()
assert(values['Players.PS_12']==1, 'F8 value resets with state when a player leaves and rejoins')
remote.microphoneSpeakComponent.calls={}
gain(2);tick()
assert(remote.microphoneSpeakComponent.calls[1]==.8, 'master controls remote voice')
assert(#muted.microphoneSpeakComponent.calls==0 and #no_owner.microphoneSpeakComponent.calls==0, 'honors mute and unknown ownership')
playerMenu.items[1].onChange(.5)
assert(remote.microphoneSpeakComponent.calls[#remote.microphoneSpeakComponent.calls]==.4, 'player slider multiplies master for the correct identity')
assert(#muted.microphoneSpeakComponent.calls==0, 'another player control does not bypass mute')
voice.VoiceChatGetMuteAllPlayers=function() return true end
tick();local calls=#remote.microphoneSpeakComponent.calls
gain(3)
assert(#remote.microphoneSpeakComponent.calls==calls, 'honors mute all')
voice.VoiceChatGetMuteAllPlayers=function() return false end
playerMenu.items[1].onChange(1);gain(1);tick()
assert(remote.microphoneSpeakComponent.calls[#remote.microphoneSpeakComponent.calls]==.4, 'restores baseline')
local solo=menu.items[2].onChange
solo(true);gain(2)
assert(local_actor.microphoneSpeakComponent.calls[#local_actor.microphoneSpeakComponent.calls]==.6, 'local monitor uses the same gain stage')
solo(false)
assert(local_actor.microphoneSpeakComponent.calls[#local_actor.microphoneSpeakComponent.calls]==.3, 'turning monitor off restores local playback')
solo(true)
local_actor.microphoneSpeakComponent.VoiceCaptureAudioComponent.Sound=nil
tick()
assert(status_text:find('loopback',1,true), 'explains missing microphone playback instead of claiming gain is active')
local_actor.microphoneSpeakComponent.VoiceCaptureAudioComponent.Sound=object(102)
local saved=voice.VoiceChatGetMyLocalPlayerVoiceChat
voice.VoiceChatGetMyLocalPlayerVoiceChat=function() return nil end
tick()
assert(status_text:find('Load a world',1,true), 'reports unavailable world')
voice.VoiceChatGetMyLocalPlayerVoiceChat=saved
print('voice control tests passed')
