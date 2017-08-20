local Iterable = require('iterables/Iterable')

local Cache = require('class')('Cache', Iterable)

function Cache:__init(array, constructor, parent)
	local objects = {}
	for _, data in ipairs(array) do
		local obj = constructor(data, parent)
		objects[obj:__hash()] = obj
	end
	self._count = #array
	self._objects = objects
	self._constructor = constructor
	self._parent = parent
end

function Cache:__len()
	return self._count
end

local function insert(self, k, obj)
	self._objects[k] = obj
	self._count = self._count + 1
	return obj
end

local function remove(self, k, obj)
	self._objects[k] = nil
	self._count = self._count - 1
	return obj
end

local function hash(data)
	local meta = getmetatable(data)
	if not meta or meta.__jsontype ~= 'object' then
		return nil, 'data must be a json object'
	end
	if data.id then -- snowflakes
		return data.id
	elseif data.user then -- members
		return data.user.id
	elseif data.emoji then -- reactions
		return data.emoji.id or data.emoji.name
	elseif data.code then -- invites
		return data.code
	else
		return nil, 'json data could not be hashed'
	end
end

function Cache:_insert(data)
	local k = assert(hash(data))
	local old = self._objects[k]
	if old then
		old:_load(data)
		return old
	else
		local obj = self._constructor(data, self._parent)
		return insert(self, k, obj)
	end
end

function Cache:_remove(data)
	local k = assert(hash(data))
	local old = self._objects[k]
	if old then
		old:_load(data)
		return remove(self, k, old)
	else
		return self._constructor(data, self._parent)
	end
end

function Cache:_delete(k)
	local old = self._objects[k]
	if old then
		return remove(self, k, old)
	else
		return nil
	end
end

function Cache:_load(array, update)
	if update then
		local updated = {}
		for _, data in ipairs(array) do
			local obj = self:_insert(data)
			updated[obj:__hash()] = true
		end
		for obj in self:iter() do
			local k = obj:__hash()
			if not updated[k] then
				self:_delete(k)
			end
		end
	else
		for _, data in ipairs(array) do
			self:_insert(data)
		end
	end
end

function Cache:get(k)
	return self._objects[k]
end

function Cache:iter()
	local objects, k, obj = self._objects
	return function()
		k, obj = next(objects, k)
		return obj
	end
end

return Cache
