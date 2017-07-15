API={
	Data={},
	Endpoints={
		['DBots_Stats']='https://bots.discord.pw/api/bots/%s/stats',
		['Meow']='http://random.cat/meow',
		['Urban']='https://api.urbandictionary.com/v0/define?term=%s',
	},
}
pcall(function()
	API.Data=require('./apidata.lua')
end)
function API:Post(End,Fmt,...)
	local point
	local p=API.Endpoints[End]
	if p then
		if Fmt then
			point=p:format(table.unpack(Fmt))
		else
			point=p
		end
	end
	print(point,...)
	return http.request('POST',point,...)
end
function API:Get(End,Fmt)
	local point
	local p=API.Endpoints[End]
	if p then
		if Fmt then
			point=p:format(table.unpack(Fmt))
		else
			point=p
		end
	end
	return http.request('GET',point)
end
API.DBots={}
function API.DBots:Stats_Update(info)
	return API:Post('DBots_Stats',{client.user.id},{{"Content-Type","application/json"},{"Authorization",API.Data.DBots_Auth}},json.encode(info))
end
API.Misc={}
function API.Misc:Cats()
	local requestdata,request=API:Get('Meow')
	if not json.decode(request)then
		return'ERROR: Unable to decode JSON [API.Misc:Cats]'
	end
	return json.decode(request).file
end
function API.Misc:Urban(input,d)
	if d then
		input=input:sub(1,input:find'/d'-1)
	else
		d=2
	end
	local fmt=string.format
	local request=query.urlencode(input)
	if request then
		local technical,data=API:Get('Urban',{request})
		local jdata=json.decode(data)
		if jdata then
			local t=fmt('Results for: %s\n',input)
			if jdata.list[1]then
				if d then
					local def=0
					for i=1,d do
						if jdata.list[i]then
							t=t..fmt('**Definition %d:** %s\n',i,jdata.list[i].definition)
							def=i
						end
					end
					t=t..fmt('**Definitions found: %s**',def)
				end
			else
				t=t..'No definitions found.'
			end
			return t
		else
			return"ERROR: unable to json decode"
		end
	else
		return"ERROR: unable to urlencode"
	end
end