
-- ! The whole premise is fundamentally wrong.
-- ! We have to track what step we're on to know the duration
local skillchains = T{
    [288] = 'Light',
    [289] = 'Darkness',
    [290] = 'Gravitation',
    [291] = 'Fragmentation',
    [292] = 'Distortion'
};


ashita.events.register('packet_in', 'burst_message_cb', function(e)
    if (e.id == 0x29) then
        local message = struct.unpack('i2', e.data, 0x18 + 1);
        if (message >= 288 and message <= 301) then
            
        end
    end
end);
