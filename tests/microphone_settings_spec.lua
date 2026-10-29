local function valid(o) o.IsValid=function() return true end;return o end
local function config(max) return {MinSliderValue=10,MaxSliderValue=max,DefaultSliderValue=100,SliderMultiplier=.02,SliderDelta=10} end
local row={SliderSettings=config(400)}
local ready=false
local actor,lastRawGain
local api=valid({VoiceChatGetMyLocalPlayerVoiceChat=function()return actor end,
 VoiceChatSetRawMicrophoneGain=function(_,gain)lastRawGain=gain end})
local dt=valid({FindRow=function(_,key) assert(key=='MicrophoneVolume');return row end})
local function widget(cvar,path)
 local spin=valid({value=400,max=400,slideMax=400})
 function spin:GetMaxValue() return self.max end
 function spin:GetMaxSliderValue() return self.slideMax end
 function spin:SetMaxValue(value) self.max=value end
 function spin:SetMaxSliderValue(value) self.slideMax=value end
 function spin:SetValue() error('extending a range must not change the selected value') end
 local w=valid({Slider=spin,SliderSettings=config(400),CVarName={ToString=function()return cvar end}})
 function w:GetFullName() return path end
 return w
end
local microphone=widget('GameAudio.VOIPInput','/Engine/Transient.Audio.Microphone')
local music=widget('GameAudio.Music','/Engine/Transient.Audio.Music')
local template=widget('GameAudio.VOIPInput','/Game/Default__StyledSliderSetting')
StaticFindObject=function(path)
 if path=='/Script/UniversalVoiceChatPro.Default__UniversalVoiceChat' then return api end
 assert(path=='/Game/Blueprints/DataTables/Settings/DT_AudioSettings.DT_AudioSettings')
 return ready and dt or nil
end
FindAllOf=function(class) assert(class=='StyledSliderSetting_C');return {microphone,music,template} end
local module=assert(loadfile('Mods/HearYourFriends/Scripts/microphone_settings.lua'),'native microphone range module missing')()
module.refresh()
assert(microphone.Slider.max==1000 and microphone.Slider.slideMax==1000,'both typed and dragged values can reach 1000 percent')
assert(microphone.Slider.value==400,'the selected microphone level is preserved')
assert(music.Slider.max==400 and template.Slider.max==400,'unrelated controls and class templates are untouched')
ready=true;module.refresh()
assert(row.SliderSettings.MaxSliderValue==1000,'future native widgets inherit the extended range')
assert(row.SliderSettings.MinSliderValue==10 and row.SliderSettings.DefaultSliderValue==100 and row.SliderSettings.SliderDelta==10,'native minimum, default and step are preserved')
assert(row.SliderSettings.SliderMultiplier==.02 and 1000*microphone.SliderSettings.SliderMultiplier==20,'1000 percent keeps the native conversion instead of inventing a gain scale')
row.SliderSettings.MaxSliderValue=2000;module.refresh()
assert(row.SliderSettings.MaxSliderValue==2000,'does not reduce a range extended by another mod')
actor=valid({voiceVolume=8});module.refresh()
assert(lastRawGain==1,'the original native microphone range retains neutral capture gain')
actor.voiceVolume=20;module.refresh()
assert(lastRawGain==2.5,'1000 percent adds capture gain above the saturated native 400 percent ceiling')
actor.voiceVolume=4;module.refresh()
assert(lastRawGain==1,'lowering microphone volume removes the extra gain')
actor=nil;module.refresh()
assert(lastRawGain==1,'the main menu does not start or change microphone capture')
print('native microphone range tests passed')
