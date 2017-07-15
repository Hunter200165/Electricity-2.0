--EVENTS.LUA--
Events={}
function Events.messageCreate(message)
	local bet=':'--default
	local content,command,isServer=message.content,'',false
	if message.author.bot==true then return end
	if message.channel.isPrivate then
		--do nothing, it doesn't really matter
	else
		isServer=true
		if filter(message)then
			return
		end
		bet=Database:Get('Settings',message).bet
	end
	local obj=(message.member~=nil and message.member or message.author)
	local rank=getRank(obj,isServer)
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
						end
					else
						sendMessage(message,'Command error:\nYour rank is not high enough to run this command')
					end
				end
			end
		end
	end
end
function Events.ready()
	client:setGameName('Mention me for help!')
	print'ready'
end