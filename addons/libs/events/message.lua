local event = require('event');

local onMessage = event:new();
local message_in_handle = tostring {};

ashita.events.register('packet_in', message_in_handle, function(e)
    if (e.id ~= 0x029) then return; end

    onMessage:trigger({
        actorId = struct.unpack('I4', e.data, 0x04 + 1),
        targetId = struct.unpack('I4', e.data, 0x08 + 1),
        param1 = struct.unpack('I4', e.data, 0x0C + 1),
        param2 = struct.unpack('I4', e.data, 0x10 + 1),
        actorIdx = struct.unpack('I2', e.data, 0x14 + 1),
        targetIdx = struct.unpack('I2', e.data, 0x16 + 1),
        message = struct.unpack('I2', e.data, 0x18 + 1),
    });
end);

return onMessage;
