package.path='Mods/HearYourFriends/Scripts/?.lua;'..package.path
package.preload['UEHelpers.UEHelpers']=function() return {} end
Key={F6=117}
assert(loadfile('Mods/shared/ModMenu/ModMenu.lua'))()
local report=assert(loadfile('Mods/HearYourFriends/Scripts/report.lua'),'report module missing')()
local state=require('state').new({gain=2})
state:sync({{key='76561198000000000',name='Private name'}})
state:setPlayer('76561198000000000',.5)
local data=report.capture(state,{game_build='test',engine='5.4.4',loader='3.0.1',players={{key='76561198000000000',name='Private name',baseline=8,muted=false}}},{})
local json=require('ModMenu.store.json').Encode(data)
assert(not json:find('76561198000000000',1,true) and not json:find('Private name',1,true), 'report omits player names and platform identifiers')
assert(data.players[1].effective==1 and data.players[1].level==.5 and data.master==2, 'report captures exact gain state')
local url=report.issueUrl(data)
assert(url:find('https://github.com/utof/hear-your-friends/issues/new?',1,true)==1, 'opens a reviewable GitHub issue draft')
assert(url:find('body=',1,true) and not url:find('\n',1,true), 'encodes report body safely')
assert(report.encodeUrl('a&b #ю'):find('a%%26b%%20%%23'), 'escapes URL delimiters and UTF-8 bytes')
data=report.capture(state,{players={{key='76561198000000000',baseline=0/0}}},{})
assert(pcall(require('ModMenu.store.json').Encode,data), 'diagnostics still work when an engine value is nonfinite')
print('report tests passed')
-- Opening and buffered close errors must not leak host paths or claim success.
local open=io.open
io.open=function() return nil,'C:/Users/PrivateName/Mods/HearYourFriends-report.json: Permission denied',13 end
local path,failure=report.save(data)
io.open=open
assert(path==nil and not failure:find('PrivateName',1,true), 'open failure omits private absolute paths')
local closed=false
io.open=function() return {write=function(self) return self end,close=function() closed=true;return nil,'disk full',28 end} end
path,failure=report.save(data)
io.open=open
assert(closed and path==nil and failure, 'a buffered close failure is not a successful report save')
print('report save failure tests passed')
local full=io.open('/dev/full','w')
if full then
 full:close()
 io.open=function() return open('/dev/full','w') end
 path,failure=report.save(data)
 io.open=open
 assert(path==nil and failure, 'real filesystem flush failure reaches caller')
end
