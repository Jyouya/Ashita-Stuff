addon.name    = 'wizardui';
addon.author  = 'Jyouya';
addon.version = '1.0';
addon.desc    = 'Helpful wizard buttons';

require('common');
local settings = require('settings');

local GUI = require('J-GUI');

local elemental = require('elemental');
local enfeebling = require('enfeebling');
local enhancing = require('enhancing');
local selfBuffs = require('enhancing.selfBuffs');
local selfTrackedBuffs = require('enhancing.selfTrackedBuffs')
local healing = require('healing');
local ninjutsu = require('ninjutsu');
local divine = require('divine');
local targetbar = require('targetbar');
local jobability = require('jobability');
local config = require('config');


local default_settings = T {
    default = T {
        elemental = T {
            visible = true,
            x = 1000,
            y = 350
        },
        enfeebling = T {
            visible = true,
            x = 500,
            y = 350
        },
        ninjutsu = T {
            elemental = T {
                visible = true,
                x = 600,
                y = 300
            }
        },
        divine = T {
            visible = true,
            x = 400,
            y = 400
        },
        enhancing = T {
            Haste = T {
                visible = true,
                x = 400,
                y = 400,
            },
            Refresh = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Protect = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Shell = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Regen = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Adloquium = T {
                visible = true,
                x = 300,
                y = 400,
            },
            ['Animus Augeo'] = T {
                visible = true,
                x = 300,
                y = 400,
            },
            ['Animus Minuo'] = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Sneak = T {
                visible = false,
                x = 300,
                y = 400,
            },
            Invisible = T {
                visible = false,
                x = 300,
                y = 400,
            },
            Deodorize = T {
                visible = false,
                x = 300,
                y = 400,
            },
            Embrava = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Phalanx = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Firestorm = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Rainstorm = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Thunderstorm = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Sandstorm = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Windstorm = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Hailstorm = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Aurorastorm = T {
                visible = true,
                x = 300,
                y = 400,
            },
            Voidstorm = T {
                visible = true,
                x = 300,
                y = 400,
            }
        },
        selfEnhancing = T {
            ['Misc'] = true, -- Pro/shell, Adlo, Auspice, Blink, Crusade, Phalanx, Reprisal, Stoneskin, Temnper,
            ['Enspell'] = true,
            ['Enspell II'] = true,
            ['Barstatus'] = true,
            ['Barstatusra'] = true,
            ['Barelement'] = true,
            ['Barelementra'] = true,
            ['Spikes'] = true,
            ['Boost'] = true,
            ['Gain'] = true,
            visible = true,
            x = 400,
            y = 400
        },
        selfEnhancing2 = T {
            trackedBuffs = T {},
            visible = true,
            x = 400,
            y = 400,
        },
        jobAbility = T {
            visible = true,
            x = 100,
            y = 100
        },
        healing = T {
            partyFrame = T {},
            visible = true,
            x = 400,
            y = 400,
            cure = T {
                visible = true,
                potency = T {
                    [1] = 30,
                    [2] = 90,
                    [3] = 192,
                    [4] = 396,
                    [5] = 800,
                    [6] = 1600
                },
                curagaPotency = T {
                    [1] = 60,
                    [2] = 180,
                    [3] = 400,
                    [4] = 800,
                    [5] = 1500,
                }
            },
            status = T {
                visible = true,
                x = 400,
                y = 400,
                trackedStatus = T {
                    ['bio'] = true,
                    ['dia'] = true,
                    ['paralysis'] = true,
                    ['slow'] = true,
                    ['weight'] = true,
                    ['blindness'] = true,
                    ['silence'] = true,
                    ['sleep'] = true,
                    ['bind'] = true,
                    ['poison'] = true,
                    ['shock'] = true,
                    ['rasp'] = true,
                    ['choke'] = true,
                    ['frost'] = true,
                    ['burn'] = true,
                    ['drown'] = true,
                    ['elegy'] = true,
                    ['requiem'] = true,
                    ['threnody'] = true,
                    ['doom'] = true,
                    ['curse'] = true,
                    ['petrification'] = true,
                    ['addle'] = true,
                    ['plague'] = true,
                    ['disease'] = true,
                    ['str down'] = true,
                    ['dex down'] = true,
                    ['vit down'] = true,
                    ['agi down'] = true,
                    ['int down'] = true,
                    ['mnd down'] = true,
                    ['chr down'] = true,
                    ['max hp down'] = true,
                    ['max mp down'] = true,
                    ['accuracy down'] = true,
                    ['attack down'] = true,
                    ['evasion down'] = true,
                    ['flash'] = true,
                    ['magic acc down'] = true,
                    ['magic atk down'] = true,
                    ['helix'] = true,
                    ['max tp down'] = true,
                    ['lullaby'] = true,
                }
            }
        }
    }
};
local settingsTable;
local setup;

local function updateSettings()
    settings.save();
end

function setup(jobSettings)
    GUI.ctx.forceReload();

    elemental.setup(jobSettings);
    enfeebling.setup(jobSettings);
    enhancing.setup(jobSettings);
    selfBuffs.setup(jobSettings);
    healing.setup(jobSettings);
    ninjutsu.setup(jobSettings);
    divine.setup(jobSettings);
    targetbar.setup(jobSettings);
    jobability.setup(jobSettings);
    selfTrackedBuffs.setup(jobSettings);

    config.setup(jobSettings, updateSettings);
end

do
    local prevJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
    local prevSub = AshitaCore:GetMemoryManager():GetPlayer():GetSubJob();
    local prevLvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    ashita.events.register('packet_in', 'job_level_change', function(e)
        -- ? Track 0x00A for load in?
        if (e.id == 0x01B) then
            local job = struct.unpack('B', e.data, 0x08 + 1);
            local subJob = struct.unpack('B', e.data, 0x0B + 1);
            local lvl = struct.unpack('B', e.data, 0x09 + 1);
            -- print(lvl);
            if (job ~= prevJob or subJob ~= prevSub) then
                (function()
                    prevJob = job;
                    prevSub = subJob;
                    local mainJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", job);

                    -- print(mainJob);
                    if (not settingsTable[mainJob]) then
                        settingsTable[mainJob] = settingsTable.default:copy(true);
                    end

                    local jobSettings = settingsTable[mainJob];

                    GUI.ctx.forceReload();

                    setup(jobSettings);
                end):once(1); -- Wait 1 second so the job can change in client memory
            end
        end
    end);
end


ashita.events.register('load', 'load_cb', function()
    settingsTable = settings.load(default_settings);

    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local mainJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", player:GetMainJob());
    -- local subJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", player:GetSubJob());

    if (not settingsTable[mainJob]) then
        settingsTable[mainJob] = settingsTable.default:copy(true);
        settings.save();
    end

    local jobSettings = settingsTable[mainJob];

    GUI.ctx.forceReload();

    setup(jobSettings);


    settings.register('settings', 'settings_update', function()
        local job = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
        local mainJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", job);

        -- print(mainJob);
        if (not settingsTable[mainJob]) then
            settingsTable[mainJob] = settingsTable.default:copy(true);
        end

        local jobSettings = settingsTable[mainJob];

        GUI.ctx.forceReload();

        setup(jobSettings);
    end)
end);
