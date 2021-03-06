--EVENTS.LUA--
--[[
	TODO:
		Add deleted message log.
]]
local fmt=string.format
Cooldowns={}
Events={}
function Events.messageCreate(message)
	local settings,ignore={},{}
	local bet=Database.Default.Settings.bet--default
	local content,command,isServer,private=message.content,'',false,false
	if message.author.bot==true then return end
	if not message.guild then
		private=true
	else
		settings=Database:Get(message).Settings
		ignore=Database:Get(message).Ignore
		isServer=true
		local filt,reason=filter(message)
		if filt then
			local reply=message:reply(fmt("Your message has been filtered. Reason: %s | This message will self destruct in T-10 seconds.",reason))
			message:delete()
			coroutine.wrap(function()
				timer.setTimeout(10*1000,coroutine.wrap(function()
					reply:delete()
				end))
			end)()
			return
		end
		bet=settings.bet or bet
		if ignore[message.channel.id]==true then
			if message.content:sub(1,#bet+#'unignored'):lower()==bet..'unignore'then
				--don't return
			else
				return'Ignored'
			end
		end
	end
	local obj=(private and message.author or message.member or message.guild:getMember(message.author))
	local rank=getRank(obj,isServer)
	if content:find(client.user.mentionString)then
		sendMessage(message,("To see info about the bot | %sabout\nTo see commands | %scmds\nTo see settings | %ssettings /l"):format(bet,bet,bet))
	end
	if content:sub(1,#bet)==bet then
		local n
		if content:find' 'then
			n=content:find' '
			command=content:sub(#bet+1,n-1)
			n=n+1
		else
			command=content:sub(#bet+1)
			n=9999
		end
		for name,tab in pairs(Commands)do
			for ind,cmd in pairs(tab.Commands)do
				if command:lower()==cmd:lower()then
					if Cooldowns[obj.id]then sendTempMessage({message,embed(nil,"You're on cooldown!",colors.bright_blue),true},2)message:delete()return end
					if tab.serverOnly then
						if not isServer then
							sendMessage(message,'Command error:\nThis command does not work in DMs.')
							return
						end
					end
					if rank>=tab.Rank then
						local switches,args
						if tab.Multi then
							args=string.split(content:sub(n),' ')
						else
							args={content:sub(n)}
						end
						if tab.Switches then
							switches=getSwitches(args[1])
						else
							switches={}
						end
						local a,b=pcall(tab.Function,message,args,switches)
						if not a then
							sendMessage(message,'Command error:\n'..b)
							sendLog(hooks[FFB('Errors')],"**COMMAND ERROR**",fmt("Error message: %s\n\nCommand: %s\n\nGuild id: %s\n\nChannel id: %s\n\nUser id: %s",b,tab.Name,(isServer and message.guild.id or"PRIVATE CHANNEL"),message.channel.id,message.author.id))
						end
						local g=message.guild
						if g then
							local m=message.member
							local c=message.channel
							sendAudit(g,embed('Audit Log',nil,colors.blue,{
								{name='Name',value=m.username,inline=true},
								{name='Descriminator',value=m.discriminator,inline=true},
								{name='Id',value=m.id,inline=true},
								{name='Shard',value=g.shardId,inline=true},
								{name='Channel',value=c.name,inline=true},
								{name='Chan ID',value=c.id,inline=true},
								{name='Message',value=tostring(message.content)},
							},{timestamp=getTimestamp()}),true)
						end
					else
						sendMessage(message,'Command error:\nYour rank is not high enough to run this command')
					end
				end
			end
		end
	end
end
function Events.messageUpdate(message)
	if message.author.bot==true then return end
	if message.channel.isPrivate then return end
	local settings=Database:Get(message).Settings
	local filt,reason=filter(message)
	if filt then
		local reply=message:reply(fmt("Your message has been filtered. Reason: %s | This message will self destruct in T-10 seconds.",reason))
		message:delete()
		coroutine.wrap(function()
			timer.setTimeout(10*1000,coroutine.wrap(function()
				reply:delete()
			end))
		end)()
		return
	end
end
function Events.messageDelete(message)
	if message.channel.isPrivate then return end
	local settings=Database:Get(message).Settings
	if convertToBool(settings.log_deleted)==true then
		local chan=resolveChannel(message.guild,settings.other_logs)
		if chan then
			local m=message.member
			sendMessage(chan,embed('Delete Log',nil,colors.blue,{
				{name='Name',value=m.username,inline=true},
				{name='Descriminator',value=m.discriminator,inline=true},
				{name='Id',value=m.id,inline=true},
				{name='Channel',value=chan.name,inline=true},
				{name='Channel ID',value=chan.id,inline=true},
				{name='Inline fix',value='.',inline=true},
				{name='Message',value=tostring(message.content)},
			},{timestamp=getTimestamp()}),true)
		end
	end
end
function Events.memberCreate(member)
	local guild=member.guild
	local settings=Database:Get(guild).Settings
	if convertToBool(settings.auto_role)==true then
		if member.bot then
			for i,v in pairs(settings.auto_bot_roles)do
				local role=resolveRole(guild,v)
				if role then
					member:addRole(role)
				else
					client:warning(string.format('Role not found. Role id: %s | Guild id: %s',v,guild.id))
				end
			end
		else
			for i,v in pairs(settings.auto_roles)do
				local role=resolveRole(guild,v)
				if role then
					member:addRole(role)
				end
			end
		end
	end
end
function Events.guildCreate(guild)
	for g in client.guilds:iter()do
		local chan=g.textChannels:get('370801361220141057')
		if chan then
			local tx=fmt('Guild name: %s\nGuild ID: %s\nGuild member count: %s',guild.name,guild.id,tostring(guild.totalMemberCount))
			local owner=guild:getMember(guild.ownerId)
			if owner then
				tx=tx..fmt('\n\nOwner name: %s\nOwner ID: %s',owner.name,owner.id)
				local thetx=''
				local bet=Database:Get(guild).Settings.bet
				function append(ntx,fin)
					fin=fin or false
					thetx=thetx..ntx..(fin==false and'\n\n'or'')
				end
				append('Thank you for using Electricity! Here are some example commands.')
				append('For example, to set your prefix to `!` you would do `%ssettings /s bet /v !`')
				append('Or to see the commands, you would do `%scmds`')
				append('To see a list of settings, say `%ssettings /l`',true)
				sendMessage(owner,embed(nil,fmt(thetx,bet,bet,bet),colors.blue),true)
			end
			sendMessage(chan,embed('New guild!',tx,colors.blue),true)
		end
	end
	if not _G.beta and API.Data.Stats.NG==true then
		API.Stats:Post()
	end
end
function Events.guildDelete(guild)
	for g in client.guilds:iter()do
		local chan=g.textChannels:get('370801361220141057')
		if chan then
			local tx=fmt('Guild name: %s\nGuild ID: %s',guild.name,guild.id)
			local owner=guild:getMember(guild.ownerId)
			if owner then
				tx=tx..fmt('\n\nOwner name: %s\nOwner ID: %s',owner.name,owner.id)
			end
			sendMessage(chan,embed('Left guild! :(',tx,colors.blue),true)
		end
	end
	if not _G.beta and API.Data.Stats.NG==true then
		API.Stats:Post()
	end
end
function Events.Timing(data)--todo: bypass time mutes with global mute
	local args=string.split(data,'||')
	if args[1]=='UNMUTE'then
		local g=client:getGuild(args[2])
		if g then
			if args[3]=='all'then
				for c in guild.textChannels:iter()do
					local u=client:getUser(args[4])
					if u then
						local m=g:getMember(u.id)
						unmute(m,c)
					end
				end
			else
				local c=client:getChannel(args[3])
				if c then
					local u=client:getUser(args[4])
					if u then
						local m=g:getMember(u.id)
					end
				end
			end
		end
	elseif args[1]=='REMINDER'then
		local g=client:getGuild(args[2])
		if g then
			local c=g:getChannel(args[3])
			local m=g:getMember(args[4])
			if not m then return end
			local time=timeBetween(toSeconds(parseTime(args[5])))
			local obj=c or m
			if obj then
				local txt=fmt('You asked to be reminded of `%s` after %s.',args[6],time)
				if args[7]then
					txt=txt..fmt('\nTimer ended %s.',(tonumber(args[7])>0 and timeBetween(tonumber(args[7]))..' ago'or'now'))
				end
				sendMessage(obj,{
					content=m.mentionString,
					embed=embed('Reminder',txt,colors.blue)
				})
			end
		end
	end
end
function Events.ready()
	Timing:on(Events.Timing)
	client:setGame('Mention me for help!')
	for guild in client.guilds:iter()do
		Database:Get(guild)
		Timing:load(guild)
		local chan=guild.textChannels:get('370801361220141057')
		if chan then
			_G.infoChannel=chan
		end
	end
	if not _G.beta then
		timer.setInterval(360000,function()
			coroutine.wrap(function()
				if not _G.beta and API.Data.Stats.Time==true then
					API.Stats:post()
				end
			end)()
		end)
	end
	client:info'Bot is ready.'
	_G.ready=true
end