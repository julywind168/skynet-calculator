local skynet = require "skynet"
local game_rwlock = require "game".rwlock
local newqueue = require "lualib.queue"

local LOCK_NOTHING = 0
local LOCK_ALL = 1

local function preload_game_static_rwlock()
	local tmp = {}
	for k, v in pairs(game_rwlock) do
		if not v:find("#") then
			if v == '*' then
				game_rwlock[k] = LOCK_ALL
			elseif v == "" then
				game_rwlock[k] = LOCK_NOTHING
			else
				if tmp[v] then
					game_rwlock[k] = tmp[v]
				else
					game_rwlock[k] = v:split(',')
					for i, v in ipairs(game_rwlock[k]) do
						game_rwlock[k][i] = v:trim()
					end
					tmp[v] = game_rwlock[k]
				end
			end
		end
	end
	tmp = nil
end

local function gen_dynamic_rwlock(lock_str, params)
	lock_str = lock_str:gsub("#(%w+)", function(key)
		if params and params[key] then
			return tostring(params[key])
		end
	end)
	local lock = lock_str:split(",")
	for i, l in ipairs(lock) do
		lock[i] = l:trim()
	end

	-- remove `nil` param lock
	for i = #lock, 1, -1 do
		if lock[i]:find('#') then
			table.remove(lock, i)
		end
	end

	return lock
end

local function short_string(s, s2)
	if #s < #s2 then
		return s, s2
	else
		return s2, s
	end
end

local function check_competition(rwlock, rwlock2)
	if rwlock == LOCK_NOTHING or rwlock2 == LOCK_NOTHING then
		return false
	end
	if rwlock == LOCK_ALL or rwlock2 == LOCK_ALL then
		return true
	end
	for _, lock in ipairs(rwlock) do
		for _, lock2 in ipairs(rwlock2) do
			local s, l = short_string(lock, lock2)
			if l:find(s) == 1 then
				return true
			end
		end
	end
	return false
end

local function gen_rwlock(name, params)
	local lock = game_rwlock[name]
	if type(lock) == "string" then
		return gen_dynamic_rwlock(lock, params)
	else
		return lock
	end
end


local Calculator = {
	nworker = 0,
	workers = {},
	workerindex = {},

	slots = {},
	nextone = { empty = true },
	queue = newqueue(),
	result = {}
}

function Calculator:check_slots(rwlock)
	local conflict = false
	for i, s in ipairs(self.slots) do
		if s.working and check_competition(s.lock, rwlock) then
			s.conflict = true
			conflict = true
		end
	end
	return conflict
end

function Calculator:find_conflict()
	for i, s in ipairs(self.slots) do
		if s.working and s.conflict then
			return true
		end
	end
	return false
end

function Calculator:_push(name, params, response, rwlock)
	if self.nextone.empty then
		local conflict = self:check_slots(rwlock)
		local idx = self:find_a_empty_solt()
		if not conflict and idx then
			self:insert2solt(idx, name, params, response, rwlock)
		else
			self.nextone.empty = false
			self.nextone.name = name
			self.nextone.params = params
			self.nextone.response = response
			self.nextone.rwlock = rwlock
		end
	else
		self.queue.put { name = name, params = params, response = response, rwlock = rwlock }
	end
end

function Calculator:nextone_join_solt(idx)
	self.nextone.empty = true
	self:insert2solt(idx, self.nextone.name, self.nextone.params, self.nextone.response, self.nextone.rwlock)

	while self.queue.size() > 0 do
		local item = self.queue.get()
		self:_push(item.name, item.params, item.response, item.rwlock)
		if not self.nextone.empty then
			break
		end
	end
end

function Calculator:insert2solt(idx, name, params, response, rwlock)
	local s = self.slots[idx]
	s.working = true
	s.response = response
	s.lock = rwlock

	skynet.fork(function()
		self:on_worker_done(idx, skynet.call(self.workers[idx], "lua", name, params))
	end)
end

function Calculator:on_worker_done(idx, ...)
	local s = self.slots[idx]
	s.working = false
	s.conflict = false
	if s.response then
		s.response(...)
	end

	if not self.nextone.empty and not self:find_conflict() then
		self:nextone_join_solt(idx)
	end
end

function Calculator:push(name, params, response)
	self:_push(name, params, response, gen_rwlock(name, params))
end

function Calculator:find_a_empty_solt()
	for i, s in ipairs(self.slots) do
		if s.working == false then
			return i
		end
	end
end

-- API
function Calculator:init(nworker)
	preload_game_static_rwlock()
	self.nworker = nworker
	for i = 1, nworker do
		self.workers[i] = skynet.newservice("worker")
	end
	for i, w in ipairs(self.workers) do
		self.workerindex[w] = i
		self.slots[i] = {
			working = false,
			conflict = false,
			response = nil,
			lock = nil
		}
	end
end

function Calculator:call(name, params)
	local token = coroutine.running()

	local function response(...)
		self.result[token] = { ... }
		skynet.wakeup(token)
	end

	self:push(name, params, response)

	skynet.wait(token)

	local result = self.result[token]
	self.result[token] = nil
	return table.unpack(result)
end

function Calculator:send(name, params)
	self:push(name, params)
end

return Calculator
