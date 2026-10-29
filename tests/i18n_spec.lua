package.path='Mods/HearYourFriends/Scripts/?.lua;'..package.path
local i18n=require('i18n')
assert(i18n.resolve('en-US')=='en')
assert(i18n.resolve('pt-BR')=='pt' and i18n.resolve('es-419')=='es')
assert(i18n.resolve('zh-Hant-TW')=='zh-Hant' and i18n.resolve('zh-CN')=='zh-Hans')
assert(i18n.resolve('zh-HK')=='zh-Hant' and i18n.resolve('zh-Hans-SG')=='zh-Hans')
assert(i18n.resolve('unknown')=='en', 'unknown languages fall back to English')
local tag='en-US'
local locale=i18n.new(function() return tag end)
locale:refresh()
assert(locale:t('master')=='Master voice volume')
tag='fr-FR';assert(locale:refresh(), 'detects a game language change without restart')
assert(locale:t('master')~='Master voice volume')
assert(not locale:refresh(), 'unchanged game language does not rebuild the UI')
for _,language in ipairs({'en','fr','de','pt-BR','ru','ja','zh-Hans','zh-Hant','es-419'}) do
 tag=language;locale:refresh()
 for _,key in ipairs({'master','report','support','native_voice','native_local','monitor_pending'}) do
  assert(type(locale:t(key))=='string' and #locale:t(key)>0, 'required controls have localized labels')
 end
 assert(locale:t('monitor_active',2):find('2.00',1,true), 'translated status retains numeric gain')
end
print('game language tests passed')
