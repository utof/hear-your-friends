local function obj(id)
 return {IsValid=function() return true end,GetAddress=function() return id end,
 GetFName=function() return {ToString=function() return 'PS_'..id end} end,
 GetPlayerName=function() return 'Player '..id end}
end
local localPlayer,other,quiet=obj(1),obj(2),obj(3)
local localActor,otherActor,quietActor=obj(10),obj(20),obj(30)
localActor.ownerPlayerState=localPlayer
otherActor.ownerPlayerState=other
quietActor.ownerPlayerState=quiet
local api={VoiceChatGetMuteAllPlayers=function() return false end,
 VoiceChatLocalIsMutedSomeone=function(_,context,player) assert(context==localActor);return player==quiet end}
local collect=assert(loadfile('Mods/HearYourFriends/Scripts/players.lua'),'player roster missing')()
local roster,muted=collect.collect(api,localActor,{localPlayer,other,quiet},{localActor,otherActor,quietActor})
assert(#roster==3 and not muted, 'lists connected players including local monitor')
assert(roster[1].local_player and roster[2].actor==otherActor, 'binds voice actors by PlayerState, not player-list position')
assert(roster[3].muted and not roster[2].muted, 'retains native mute state')
roster=collect.collect(api,localActor,{other,localPlayer},{otherActor,localActor})
assert(roster[1].key=='PS_2' and roster[1].actor==otherActor, 'row order cannot swap player settings')
print('roster tests passed')
