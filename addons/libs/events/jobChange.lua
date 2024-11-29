local event = require('event');
local encoding = require('encoding');

local onSubJobChange = event:new();
local onMainJobChange = event:new();


local lastMainJob, lastSubJob;
ashita.events.register('packet_in', 'subjob_packet_in', function(e)
    if (e.id == 0x061) then
        local mainJob = struct.unpack('B', e.data, 0x0C + 0x01);
        local subJob = struct.unpack('B', e.data, 0x0E + 0x01);

        if (mainJob and mainJob ~= lastMainJob) then
            local job = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", mainJob);
            if (type(job) == 'string') then
                job = encoding:ShiftJIS_To_UTF8(job:trimend('\x00'));
            end
            onMainJobChange:trigger(job);
        end

        if (subJob and subJob ~= lastSubJob) then
            local job = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", subJob);
            if (type(job) == 'string') then
                job = encoding:ShiftJIS_To_UTF8(job:trimend('\x00'));
            end
            onMainJobChange:trigger(job);
        end
    end
end);

return {
    onMainJobChange = onMainJobChange,
    onSubJobChange = onSubJobChange
};
