local event = require('event'):new();

ashita.events.register('packet_in', 'zoneChange_packet_in', function(e)
    if (e.id == 0x00A) then
        event:trigger(e);
    end
end);

return event;