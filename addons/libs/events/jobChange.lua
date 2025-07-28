local event = require('event');

local onSubJobChange = event:new();
local onMainJobChange = event:new();
local onJobChange = event:new();

local lastMainJob, lastSubJob;

lastMainJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
lastSubJob = AshitaCore:GetMemoryManager():GetPlayer():GetSubJob();
ashita.events.register('packet_in', 'subjob_packet_in', function(e)
    if (e.id == 0x061) then
        local mainJob = struct.unpack('B', e.data, 0x0C + 0x01);
        local subJob = struct.unpack('B', e.data, 0x0E + 0x01);

        if (mainJob == 0) then return; end

        if (mainJob and mainJob ~= lastMainJob) then
            local job = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", mainJob);

            onMainJobChange:trigger(job);
            lastMainJob = mainJob;
        end

        if (subJob and subJob ~= lastSubJob) then
            -- print('job change from ' .. tostring(lastSubJob) .. ' to ' .. subJob)
            local job = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", subJob);
            onSubJobChange:trigger(job);
            lastSubJob = subJob;
        end

        if (mainJob and mainJob ~= lastMainJob and subJob and subJob ~= lastSubJob) then
            local main = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", mainJob);
            local sub = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", subJob);

            onJobChange:trigger(main, sub)
        end
    end
end);

return {
    onMainJobChange = onMainJobChange,
    onSubJobChange = onSubJobChange,
    onJobChange = onJobChange,
};
