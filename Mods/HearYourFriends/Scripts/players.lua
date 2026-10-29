local M={}
local function valid(object) return object~=nil and object:IsValid() end
function M.key(player) return player:GetFName():ToString() end
local function text(value)
    if type(value)=='string' then return value end
    return value:ToString()
end
function M.collect(api,localActor,playerArray,actors)
    local localPlayer=localActor.ownerPlayerState
    local localAddress=valid(localPlayer) and localPlayer:GetAddress() or nil
    local voices={}
    for _,actor in pairs(actors) do
        if valid(actor) and valid(actor.ownerPlayerState) then voices[actor.ownerPlayerState:GetAddress()]=actor end
    end
    local allMuted=api:VoiceChatGetMuteAllPlayers()
    local result={}
    for i=1,#playerArray do
        local player=playerArray[i]
        if valid(player) then
            local isLocal=player:GetAddress()==localAddress
            local muted=not isLocal and (allMuted~=false or api:VoiceChatLocalIsMutedSomeone(localActor,player)~=false)
            result[#result+1]={key=M.key(player),name=text(player:GetPlayerName()),player=player,
                actor=voices[player:GetAddress()],local_player=isLocal,muted=muted,slot=#result+1}
        end
    end
    return result,allMuted
end
function M.diagnostics(roster,localActor)
    local result={}
    for _,player in ipairs(roster) do
        local row={key=player.key,local_player=player.local_player,muted=player.muted,voice_ready=false}
        pcall(function()
            local actor=player.actor
            if not valid(actor) then return end
            row.baseline=actor.voiceVolume
            local mic=actor.microphoneSpeakComponent
            local audio=valid(mic) and mic.VoiceCaptureAudioComponent or nil
            row.voice_ready=valid(audio) and valid(audio.Sound)
            if not row.voice_ready then return end
            row.component_volume=audio.VolumeMultiplier
            local function decibels(chain)
                if not valid(chain) then return nil end
                local preset=FindObject(StaticFindObject('/Script/Synthesis.SourceEffectDynamicsProcessorPreset'),chain,'HearYourFriendsGain',true)
                return valid(preset) and preset.Settings.OutputGainDb or nil
            end
            row.base_effect_db=decibels(audio.Sound.SourceEffectChain)
            row.radio_effect_db=decibels(mic.soundEffectChainAsset)
            local position,origin=actor:K2_GetActorLocation(),localActor:K2_GetActorLocation()
            row.distance_m=math.sqrt((position.X-origin.X)^2+(position.Y-origin.Y)^2+(position.Z-origin.Z)^2)/100
        end)
        pcall(function() row.radio=player.actor.isUsingRadio end)
        result[#result+1]=row
    end
    return result
end
return M
