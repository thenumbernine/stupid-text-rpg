require 'ext'

local jobSkills = {
	'hpMax',
	'move',
	'speed',
	'attack',
	'defense',
	'hitChance',
	'evade',
}

local function makeRandomJobName()
	local syllables = table{
		'De',
		'Dur',
		'Derp',
		'Diddly'
	}
	local s = table()
	for i=1,math.random(5)+1 do
		s:insert(syllables[math.random(#syllables)])
	end
	return s:concat()
end

jobs = table()
for i=1,math.random(6) + 4 do
	local job = table()
	jobs:insert(job)
	
	job.name = makeRandomJobName()
	
	job.skills = table()
	
	for _,field in ipairs(jobSkills) do
		job[field] = math.random(20)
	end
end

for _,job in ipairs(jobs) do
	job[job.name] = job
end