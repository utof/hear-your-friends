package.preload['ModMenu.core.umg']=function() return {} end
package.preload['slider']=function() return {} end
local ui=assert(loadfile('Mods/HearYourFriends/Scripts/native_ui.lua'),'native UI missing')()
local function row(path,valid)
 return {GetFullName=function() return path end,IsValid=function() return true end,
 PlayerState={IsValid=function() return valid end}}
end
assert(ui.isPlayerRow(row('/Engine/Transient.W_PlayerMenu.WidgetTree.W_PlayerList_1.Row',true)), 'targets current Players list')
assert(not ui.isPlayerRow(row('/Game/Templates.W_PlayerMenu.W_PlayerList_1.Row',true)), 'does not edit class templates')
assert(not ui.isPlayerRow(row('/Engine/Transient.W_PlayerMenu.W_PlayerList_MutedPlayers.Row',true)), 'does not alter muted or blocked lists')
assert(not ui.isPlayerRow(row('/Engine/Transient.W_ServerAdminMenu.W_PlayerList.Row',true)), 'does not alter administration rows')
assert(not ui.isPlayerRow(row('/Engine/Transient.W_PlayerMenu.W_PlayerList_1.Row',false)), 'ignores rows with no bound player')
print('native UI scope tests passed')
