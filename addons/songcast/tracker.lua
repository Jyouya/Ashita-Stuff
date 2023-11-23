local songs = require('songs');

local casts = T {};

local function handleActionPacket(e)
    local type = ashita.bits.unpack_be(e.data_raw, 0, 82, 4);

    if (type ~= 8 and type ~= 4) then
        return;
    end

    local spellGroup = ashita.bits.unpack_be(e.data_raw, 0, 102, 16);

    
    local actorId = ashita.bits.unpack_be(e.data_raw, 0, 40, 32);
    
    -- print(AshitaCore:GetMemoryManager():GetEntity():GetLookBody(actorId));
    
    -- Finishes Casting
    if (type == 4) then
        casts[actorId] = nil;
        return;
    end

    -- Test if the spell is a song
    if (spellGroup ~= 28531) then
        return;
    end
    
    -- Begins Casting
    if (type == 8) then
        local targetCount = ashita.bits.unpack_be(e.data_raw, 0, 72, 6);
        if (targetCount < 1) then
            return;
        end

        local actionCount = ashita.bits.unpack_be(e.data_raw, 0, 182, 4);
        if (actionCount < 1) then
            return;
        end

        local spellId = ashita.bits.unpack_be(e.data_raw, 0, 213, 17);

        local spell = AshitaCore:GetResourceManager():GetSpellById(spellId);
        
        if (not spell) then return; end
        local spellName = spell.Name[1];


        casts[actorId] = T {
            song = songs[spellName],
            time = os.clock()
        };
    end
end


ashita.events.register('packet_in', 'action_tracker_cb', function(e)
    if (e.id == 0x0028) then
        handleActionPacket(e);
        -- elseif (e.id == 0x0029) then
        --     handleMessagePacket(e.data);
    end
end);

return casts;
