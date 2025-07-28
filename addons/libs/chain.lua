--[[
* Chains displays current skillchains for the active target.
* It is based on the skillchains addon by Ivaar for Ashita v3.
*
* Several functions are leveraged from LuAshitacast by Thorny
* ParseActionPacket function is leveraged from timers by The Mystic
*
* Chains is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Chains is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
--]]

-- created from chains, by Sippius, Ivaar, and NerfOnline

require('common');
local ffi = require('ffi');
local chat = require('chat');

local skills = {};

skills[3] = { -- Weaponskills
    [1] = { en = 'Combo', skillchain = { 'Impaction' } },
    [2] = { en = 'Shoulder Tackle', skillchain = { 'Reverberation', 'Impaction' } },
    [3] = { en = 'One Inch Punch', skillchain = { 'Compression' } },
    [4] = { en = 'Backhand Blow', skillchain = { 'Detonation' } },
    [5] = { en = 'Raging Fists', skillchain = { 'Impaction' } },
    [6] = { en = 'Spinning Attack', skillchain = { 'Liquefaction', 'Impaction' } },
    [7] = { en = 'Howling Fist', skillchain = { 'Transfixion', 'Impaction' } },
    [8] = { en = 'Dragon Kick', skillchain = { 'Fragmentation' } },
    [9] = { en = 'Asuran Fists', skillchain = { 'Gravitation', 'Liquefaction' } },
    [10] = { en = 'Final Heaven', skillchain = { 'Light', 'Fusion' } },
    [11] = { en = 'Ascetic\'s Fury', skillchain = { 'Fusion', 'Transfixion' } },
    [12] = { en = 'Stringing Pummel', skillchain = { 'Gravitation', 'Liquefaction' } },
    [13] = { en = 'Tornado Kick', skillchain = { 'Induration', 'Detonation', 'Impaction' } },
    [14] = { en = 'Victory Smite', skillchain = { 'Light', 'Fragmentation' } },
    [15] = { en = 'Shijin Spiral', skillchain = { 'Fusion', 'Reverberation' }, aeonic = 'Light', weapon = 'Godhand' },
    [16] = { en = 'Wasp Sting', skillchain = { 'Scission' } },
    [17] = { en = 'Viper Bite', skillchain = { 'Scission' } },
    [18] = { en = 'Shadowstitch', skillchain = { 'Reverberation' } },
    [19] = { en = 'Gust Slash', skillchain = { 'Detonation' } },
    [20] = { en = 'Cyclone', skillchain = { 'Detonation', 'Impaction' } },
    [23] = { en = 'Dancing Edge', skillchain = { 'Scission', 'Detonation' } },
    [24] = { en = 'Shark Bite', skillchain = { 'Fragmentation' } },
    [25] = { en = 'Evisceration', skillchain = { 'Gravitation', 'Transfixion' } },
    [26] = { en = 'Mercy Stroke', skillchain = { 'Darkness', 'Gravitation' } },
    [27] = { en = 'Mandalic Stab', skillchain = { 'Fusion', 'Compression' } },
    [28] = { en = 'Mordant Rime', skillchain = { 'Fragmentation', 'Distortion' } },
    [29] = { en = 'Pyrrhic Kleos', skillchain = { 'Distortion', 'Scission' } },
    [30] = { en = 'Aeolian Edge', skillchain = { 'Scission', 'Detonation', 'Impaction' } },
    [31] = { en = 'Rudra\'s Storm', skillchain = { 'Darkness', 'Distortion' } },
    [32] = { en = 'Fast Blade', skillchain = { 'Scission' } },
    [33] = { en = 'Burning Blade', skillchain = { 'Liquefaction' } },
    [34] = { en = 'Red Lotus Blade', skillchain = { 'Liquefaction', 'Detonation' } },
    [35] = { en = 'Flat Blade', skillchain = { 'Impaction' } },
    [36] = { en = 'Shining Blade', skillchain = { 'Scission' } },
    [37] = { en = 'Seraph Blade', skillchain = { 'Scission' } },
    [38] = { en = 'Circle Blade', skillchain = { 'Reverberation', 'Impaction' } },
    [40] = { en = 'Vorpal Blade', skillchain = { 'Scission', 'Impaction' } },
    [41] = { en = 'Swift Blade', skillchain = { 'Gravitation' } },
    [42] = { en = 'Savage Blade', skillchain = { 'Fragmentation', 'Scission' } },
    [43] = { en = 'Knights of Round', skillchain = { 'Light', 'Fusion' } },
    [44] = { en = 'Death Blossom', skillchain = { 'Fragmentation', 'Distortion' } },
    [45] = { en = 'Atonement', skillchain = { 'Fusion', 'Reverberation' } },
    [46] = { en = 'Expiacion', skillchain = { 'Distortion', 'Scission' } },
    [48] = { en = 'Hard Slash', skillchain = { 'Scission' } },
    [49] = { en = 'Power Slash', skillchain = { 'Transfixion' } },
    [50] = { en = 'Frostbite', skillchain = { 'Induration' } },
    [51] = { en = 'Freezebite', skillchain = { 'Induration', 'Detonation' } },
    [52] = { en = 'Shockwave', skillchain = { 'Reverberation' } },
    [53] = { en = 'Crescent Moon', skillchain = { 'Scission' } },
    [54] = { en = 'Sickle Moon', skillchain = { 'Scission', 'Impaction' } },
    [55] = { en = 'Spinning Slash', skillchain = { 'Fragmentation' } },
    [56] = { en = 'Ground Strike', skillchain = { 'Fragmentation', 'Distortion' } },
    [57] = { en = 'Scourge', skillchain = { 'Light', 'Fusion' } },
    [58] = { en = 'Herculean Slash', skillchain = { 'Induration', 'Detonation', 'Impaction' } },
    [59] = { en = 'Torcleaver', skillchain = { 'Light', 'Distortion' } },
    [60] = { en = 'Resolution', skillchain = { 'Fragmentation', 'Scission' }, aeonic = 'Light', weapon = 'Lionheart' },
    [61] = { en = 'Dimidiation', skillchain = { 'Light', 'Fragmentation' } },
    [64] = { en = 'Raging Axe', skillchain = { 'Detonation', 'Impaction' } },
    [65] = { en = 'Smash Axe', skillchain = { 'Induration', 'Reverberation' } },
    [66] = { en = 'Gale Axe', skillchain = { 'Detonation' } },
    [67] = { en = 'Avalanche Axe', skillchain = { 'Scission', 'Impaction' } },
    [68] = { en = 'Spinning Axe', skillchain = { 'Liquefaction', 'Scission', 'Impaction' } },
    [69] = { en = 'Rampage', skillchain = { 'Scission' } },
    [70] = { en = 'Calamity', skillchain = { 'Scission', 'Impaction' } },
    [71] = { en = 'Mistral Axe', skillchain = { 'Fusion' } },
    [72] = { en = 'Decimation', skillchain = { 'Fusion', 'Reverberation' } },
    [73] = { en = 'Onslaught', skillchain = { 'Darkness', 'Gravitation' } },
    [74] = { en = 'Primal Rend', skillchain = { 'Gravitation', 'Reverberation' } },
    [75] = { en = 'Bora Axe', skillchain = { 'Scission', 'Detonation' } },
    [76] = { en = 'Cloudsplitter', skillchain = { 'Darkness', 'Fragmentation' } },
    [77] = { en = 'Ruinator', skillchain = { 'Distortion', 'Detonation' }, aeonic = 'Darkness', weapon = 'Tri-Edge' },
    [80] = { en = 'Shield Break', skillchain = { 'Impaction' } },
    [81] = { en = 'Iron Tempest', skillchain = { 'Scission' } },
    [82] = { en = 'Sturmwind', skillchain = { 'Reverberation', 'Scission' } },
    [83] = { en = 'Armor Break', skillchain = { 'Impaction' } },
    [84] = { en = 'Keen Edge', skillchain = { 'Compression' } },
    [85] = { en = 'Weapon Break', skillchain = { 'Impaction' } },
    [86] = { en = 'Raging Rush', skillchain = { 'Induration', 'Reverberation' } },
    [87] = { en = 'Full Break', skillchain = { 'Distortion' } },
    [88] = { en = 'Steel Cyclone', skillchain = { 'Distortion', 'Detonation' } },
    [89] = { en = 'Metatron Torment', skillchain = { 'Light', 'Fusion' } },
    [90] = { en = 'King\'s Justice', skillchain = { 'Fragmentation', 'Scission' } },
    [91] = { en = 'Fell Cleave', skillchain = { 'Scission', 'Detonation', 'Impaction' } },
    [92] = { en = 'Ukko\'s Fury', skillchain = { 'Light', 'Fragmentation' } },
    [93] = { en = 'Upheaval', skillchain = { 'Fusion', 'Compression' }, aeonic = 'Light', weapon = 'Chango' },
    [96] = { en = 'Slice', skillchain = { 'Scission' } },
    [97] = { en = 'Dark Harvest', skillchain = { 'Reverberation' } },
    [98] = { en = 'Shadow of Death', skillchain = { 'Induration', 'Reverberation' } },
    [99] = { en = 'Nightmare Scythe', skillchain = { 'Compression', 'Scission' } },
    [100] = { en = 'Spinning Scythe', skillchain = { 'Reverberation', 'Scission' } },
    [101] = { en = 'Vorpal Scythe', skillchain = { 'Transfixion', 'Scission' } },
    [102] = { en = 'Guillotine', skillchain = { 'Induration' } },
    [103] = { en = 'Cross Reaper', skillchain = { 'Distortion' } },
    [104] = { en = 'Spiral Hell', skillchain = { 'Distortion', 'Scission' } },
    [105] = { en = 'Catastrophe', skillchain = { 'Darkness', 'Gravitation' } },
    [106] = { en = 'Insurgency', skillchain = { 'Fusion', 'Compression' } },
    [107] = { en = 'Infernal Scythe', skillchain = { 'Compression', 'Reverberation' } },
    [108] = { en = 'Quietus', skillchain = { 'Darkness', 'Distortion' } },
    [109] = { en = 'Entropy', skillchain = { 'Gravitation', 'Reverberation' }, aeonic = 'Darkness', weapon = 'Anguta' },
    [112] = { en = 'Double Thrust', skillchain = { 'Transfixion' } },
    [113] = { en = 'Thunder Thrust', skillchain = { 'Transfixion', 'Impaction' } },
    [114] = { en = 'Raiden Thrust', skillchain = { 'Transfixion', 'Impaction' } },
    [115] = { en = 'Leg Sweep', skillchain = { 'Impaction' } },
    [116] = { en = 'Penta Thrust', skillchain = { 'Compression' } },
    [117] = { en = 'Vorpal Thrust', skillchain = { 'Reverberation', 'Transfixion' } },
    [118] = { en = 'Skewer', skillchain = { 'Transfixion', 'Impaction' } },
    [119] = { en = 'Wheeling Thrust', skillchain = { 'Fusion' } },
    [120] = { en = 'Impulse Drive', skillchain = { 'Gravitation', 'Induration' } },
    [121] = { en = 'Geirskogul', skillchain = { 'Light', 'Distortion' } },
    [122] = { en = 'Drakesbane', skillchain = { 'Fusion', 'Transfixion' } },
    [123] = { en = 'Sonic Thrust', skillchain = { 'Transfixion', 'Scission' } },
    [124] = { en = 'Camlann\'s Torment', skillchain = { 'Light', 'Fragmentation' } },
    [125] = { en = 'Stardiver', skillchain = { 'Gravitation', 'Transfixion' }, aeonic = 'Darkness', weapon = 'Trishula' },
    [128] = { en = 'Blade: Rin', skillchain = { 'Transfixion' } },
    [129] = { en = 'Blade: Retsu', skillchain = { 'Scission' } },
    [130] = { en = 'Blade: Teki', skillchain = { 'Reverberation' } },
    [131] = { en = 'Blade: To', skillchain = { 'Induration', 'Detonation' } },
    [132] = { en = 'Blade: Chi', skillchain = { 'Transfixion', 'Impaction' } },
    [133] = { en = 'Blade: Ei', skillchain = { 'Compression' } },
    [134] = { en = 'Blade: Jin', skillchain = { 'Detonation', 'Impaction' } },
    [135] = { en = 'Blade: Ten', skillchain = { 'Gravitation' } },
    [136] = { en = 'Blade: Ku', skillchain = { 'Gravitation', 'Transfixion' } },
    [137] = { en = 'Blade: Metsu', skillchain = { 'Darkness', 'Fragmentation' } },
    [138] = { en = 'Blade: Kamu', skillchain = { 'Fragmentation', 'Compression' } },
    [139] = { en = 'Blade: Yu', skillchain = { 'Reverberation', 'Scission' } },
    [140] = { en = 'Blade: Hi', skillchain = { 'Darkness', 'Gravitation' } },
    [141] = { en = 'Blade: Shun', skillchain = { 'Fusion', 'Impaction' }, aeonic = 'Light', weapon = 'Heishi Shorinken' },
    [144] = { en = 'Tachi: Enpi', skillchain = { 'Transfixion', 'Scission' } },
    [145] = { en = 'Tachi: Hobaku', skillchain = { 'Induration' } },
    [146] = { en = 'Tachi: Goten', skillchain = { 'Transfixion', 'Impaction' } },
    [147] = { en = 'Tachi: Kagero', skillchain = { 'Liquefaction' } },
    [148] = { en = 'Tachi: Jinpu', skillchain = { 'Scission', 'Detonation' } },
    [149] = { en = 'Tachi: Koki', skillchain = { 'Reverberation', 'Impaction' } },
    [150] = { en = 'Tachi: Yukikaze', skillchain = { 'Induration', 'Detonation' } },
    [151] = { en = 'Tachi: Gekko', skillchain = { 'Distortion', 'Reverberation' } },
    [152] = { en = 'Tachi: Kasha', skillchain = { 'Fusion', 'Compression' } },
    [153] = { en = 'Tachi: Kaiten', skillchain = { 'Light', 'Fragmentation' } },
    [154] = { en = 'Tachi: Rana', skillchain = { 'Gravitation', 'Induration' } },
    [155] = { en = 'Tachi: Ageha', skillchain = { 'Compression', 'Scission' } },
    [156] = { en = 'Tachi: Fudo', skillchain = { 'Light', 'Distortion' } },
    [157] = { en = 'Tachi: Shoha', skillchain = { 'Fragmentation', 'Compression' }, aeonic = 'Light', weapon = 'Dojikiri Yasutsuna' },
    [158] = { en = 'Tachi: Suikawari', skillchain = { 'Fusion' } },
    [160] = { en = 'Shining Strike', skillchain = { 'Impaction' } },
    [161] = { en = 'Seraph Strike', skillchain = { 'Impaction' } },
    [162] = { en = 'Brainshaker', skillchain = { 'Reverberation' } },
    [165] = { en = 'Skullbreaker', skillchain = { 'Induration', 'Reverberation' } },
    [166] = { en = 'True Strike', skillchain = { 'Detonation', 'Impaction' } },
    [167] = { en = 'Judgment', skillchain = { 'Impaction' } },
    [168] = { en = 'Hexa Strike', skillchain = { 'Fusion' } },
    [169] = { en = 'Black Halo', skillchain = { 'Fragmentation', 'Compression' } },
    [170] = { en = 'Randgrith', skillchain = { 'Light', 'Fragmentation' } },
    [172] = { en = 'Flash Nova', skillchain = { 'Induration', 'Reverberation' } },
    [174] = { en = 'Realmrazer', skillchain = { 'Fusion', 'Impaction' }, aeonic = 'Light', weapon = 'Tishtrya' },
    [175] = { en = 'Exudation', skillchain = { 'Darkness', 'Fragmentation' } },
    [176] = { en = 'Heavy Swing', skillchain = { 'Impaction' } },
    [177] = { en = 'Rock Crusher', skillchain = { 'Impaction' } },
    [178] = { en = 'Earth Crusher', skillchain = { 'Detonation', 'Impaction' } },
    [179] = { en = 'Starburst', skillchain = { 'Compression', 'Reverberation' } },
    [180] = { en = 'Sunburst', skillchain = { 'Compression', 'Reverberation' } },
    [181] = { en = 'Shell Crusher', skillchain = { 'Detonation' } },
    [182] = { en = 'Full Swing', skillchain = { 'Liquefaction', 'Impaction' } },
    [184] = { en = 'Retribution', skillchain = { 'Gravitation', 'Reverberation' } },
    [185] = { en = 'Gate of Tartarus', skillchain = { 'Darkness', 'Distortion' } },
    [186] = { en = 'Vidohunir', skillchain = { 'Fragmentation', 'Distortion' } },
    [187] = { en = 'Garland of Bliss', skillchain = { 'Fusion', 'Reverberation' } },
    [188] = { en = 'Omniscience', skillchain = { 'Gravitation', 'Transfixion' } },
    [189] = { en = 'Cataclysm', skillchain = { 'Compression', 'Reverberation' } },
    [191] = { en = 'Shattersoul', skillchain = { 'Gravitation', 'Induration' }, aeonic = 'Darkness', weapon = 'Khatvanga' },
    [192] = { en = 'Flaming Arrow', skillchain = { 'Liquefaction', 'Transfixion' } },
    [193] = { en = 'Piercing Arrow', skillchain = { 'Reverberation', 'Transfixion' } },
    [194] = { en = 'Dulling Arrow', skillchain = { 'Liquefaction', 'Transfixion' } },
    [196] = { en = 'Sidewinder', skillchain = { 'Reverberation', 'Transfixion', 'Detonation' } },
    [197] = { en = 'Blast Arrow', skillchain = { 'Induration', 'Transfixion' } },
    [198] = { en = 'Arching Arrow', skillchain = { 'Fusion' } },
    [199] = { en = 'Empyreal Arrow', skillchain = { 'Fusion', 'Transfixion' } },
    [200] = { en = 'Namas Arrow', skillchain = { 'Light', 'Distortion' } },
    [201] = { en = 'Refulgent Arrow', skillchain = { 'Reverberation', 'Transfixion' } },
    [202] = { en = 'Jishnu\'s Radiance', skillchain = { 'Light', 'Fusion' } },
    [203] = { en = 'Apex Arrow', skillchain = { 'Fragmentation', 'Transfixion' }, aeonic = 'Light', weapon = 'Fail-Not' },
    [208] = { en = 'Hot Shot', skillchain = { 'Liquefaction', 'Transfixion' } },
    [209] = { en = 'Split Shot', skillchain = { 'Reverberation', 'Transfixion' } },
    [210] = { en = 'Sniper Shot', skillchain = { 'Liquefaction', 'Transfixion' } },
    [212] = { en = 'Slug Shot', skillchain = { 'Reverberation', 'Transfixion', 'Detonation' } },
    [213] = { en = 'Blast Shot', skillchain = { 'Induration', 'Transfixion' } },
    [214] = { en = 'Heavy Shot', skillchain = { 'Fusion' } },
    [215] = { en = 'Detonator', skillchain = { 'Fusion', 'Transfixion' } },
    [216] = { en = 'Coronach', skillchain = { 'Darkness', 'Fragmentation' } },
    [217] = { en = 'Trueflight', skillchain = { 'Fragmentation', 'Scission' } },
    [218] = { en = 'Leaden Salute', skillchain = { 'Gravitation', 'Transfixion' } },
    [219] = { en = 'Numbing Shot', skillchain = { 'Induration', 'Detonation', 'Impaction' } },
    [220] = { en = 'Wildfire', skillchain = { 'Darkness', 'Gravitation' } },
    [221] = { en = 'Last Stand', skillchain = { 'Fusion', 'Reverberation' }, aeonic = 'Light', weapon = 'Fomalhaut' },
    [224] = { en = 'Exenterator', skillchain = { 'Fragmentation', 'Scission' }, aeonic = 'Light', weapon = 'Aeneas' },
    [225] = { en = 'Chant du Cygne', skillchain = { 'Light', 'Distortion' } },
    [226] = { en = 'Requiescat', skillchain = { 'Gravitation', 'Scission' }, aeonic = 'Darkness', weapon = 'Sequence' },
    [227] = { en = 'Knights of Rotund', skillchain = { 'Light' } },
    [228] = { en = 'Final Paradise', skillchain = { 'Light' } },
    [238] = { en = 'Uriel Blade', skillchain = { 'Light', 'Fragmentation' } },
    [239] = { en = 'Glory Slash', skillchain = { 'Light', 'Fusion' } },
};

skills[4] = { -- BLU/SCH Spells
    [144] = { en = 'Fire', skillchain = { 'Liquefaction' } },
    [145] = { en = 'Fire II', skillchain = { 'Liquefaction' } },
    [146] = { en = 'Fire III', skillchain = { 'Liquefaction' } },
    [147] = { en = 'Fire IV', skillchain = { 'Liquefaction' } },
    [148] = { en = 'Fire V', skillchain = { 'Liquefaction' } },
    [149] = { en = 'Blizzard', skillchain = { 'Induration' } },
    [150] = { en = 'Blizzard II', skillchain = { 'Induration' } },
    [151] = { en = 'Blizzard III', skillchain = { 'Induration' } },
    [152] = { en = 'Blizzard IV', skillchain = { 'Induration' } },
    [153] = { en = 'Blizzard V', skillchain = { 'Induration' } },
    [154] = { en = 'Aero', skillchain = { 'Detonation' } },
    [155] = { en = 'Aero II', skillchain = { 'Detonation' } },
    [156] = { en = 'Aero III', skillchain = { 'Detonation' } },
    [157] = { en = 'Aero IV', skillchain = { 'Detonation' } },
    [158] = { en = 'Aero V', skillchain = { 'Detonation' } },
    [159] = { en = 'Stone', skillchain = { 'Scission' } },
    [160] = { en = 'Stone II', skillchain = { 'Scission' } },
    [161] = { en = 'Stone III', skillchain = { 'Scission' } },
    [162] = { en = 'Stone IV', skillchain = { 'Scission' } },
    [163] = { en = 'Stone V', skillchain = { 'Scission' } },
    [164] = { en = 'Thunder', skillchain = { 'Impaction' } },
    [165] = { en = 'Thunder II', skillchain = { 'Impaction' } },
    [166] = { en = 'Thunder III', skillchain = { 'Impaction' } },
    [167] = { en = 'Thunder IV', skillchain = { 'Impaction' } },
    [168] = { en = 'Thunder V', skillchain = { 'Impaction' } },
    [169] = { en = 'Water', skillchain = { 'Reverberation' } },
    [170] = { en = 'Water II', skillchain = { 'Reverberation' } },
    [171] = { en = 'Water III', skillchain = { 'Reverberation' } },
    [172] = { en = 'Water IV', skillchain = { 'Reverberation' } },
    [173] = { en = 'Water V', skillchain = { 'Reverberation' } },
    [278] = { en = 'Geohelix', skillchain = { 'Scission' }, delay = 5 },
    [279] = { en = 'Hydrohelix', skillchain = { 'Reverberation' }, delay = 5 },
    [280] = { en = 'Anemohelix', skillchain = { 'Detonation' }, delay = 5 },
    [281] = { en = 'Pyrohelix', skillchain = { 'Liquefaction' }, delay = 5 },
    [282] = { en = 'Cryohelix', skillchain = { 'Induration' }, delay = 5 },
    [283] = { en = 'Ionohelix', skillchain = { 'Impaction' }, delay = 5 },
    [284] = { en = 'Noctohelix', skillchain = { 'Compression' }, delay = 5 },
    [285] = { en = 'Luminohelix', skillchain = { 'Transfixion' }, delay = 5 },
    [503] = { en = 'Impact', skillchain = { 'Compression' } },
    [519] = { en = 'Screwdriver', skillchain = { 'Transfixion', 'Scission' } },
    [527] = { en = 'Smite of Rage', skillchain = { 'Detonation' } },
    [529] = { en = 'Bludgeon', skillchain = { 'Liquefaction' } },
    [539] = { en = 'Terror Touch', skillchain = { 'Compression', 'Reverberation' } },
    [540] = { en = 'Spinal Cleave', skillchain = { 'Scission', 'Detonation' } },
    [543] = { en = 'Mandibular Bite', skillchain = { 'Induration' } },
    [545] = { en = 'Sickle Slash', skillchain = { 'Compression' } },
    [551] = { en = 'Power Attack', skillchain = { 'Reverberation' } },
    [554] = { en = 'Death Scissors', skillchain = { 'Compression', 'Reverberation' } },
    [560] = { en = 'Frenetic Rip', skillchain = { 'Induration' } },
    [564] = { en = 'Body Slam', skillchain = { 'Impaction' } },
    [567] = { en = 'Helldive', skillchain = { 'Transfixion' } },
    [569] = { en = 'Jet Stream', skillchain = { 'Impaction' } },
    [577] = { en = 'Foot Kick', skillchain = { 'Detonation' } },
    [585] = { en = 'Ram Charge', skillchain = { 'Fragmentation' } },
    [587] = { en = 'Claw Cyclone', skillchain = { 'Scission' } },
    [589] = { en = 'Dimensional Death', skillchain = { 'Transfixion', 'Impaction' } },
    [594] = { en = 'Uppercut', skillchain = { 'Liquefaction', 'Impaction' } },
    [596] = { en = 'Pinecone Bomb', skillchain = { 'Liquefaction' } },
    [597] = { en = 'Sprout Smack', skillchain = { 'Reverberation' } },
    [599] = { en = 'Queasyshroom', skillchain = { 'Compression' } },
    [603] = { en = 'Wild Oats', skillchain = { 'Transfixion' } },
    [611] = { en = 'Disseverment', skillchain = { 'Distortion' } },
    [617] = { en = 'Vertical Cleave', skillchain = { 'Gravitation' } },
    [620] = { en = 'Battle Dance', skillchain = { 'Impaction' } },
    [622] = { en = 'Grand Slam', skillchain = { 'Induration' } },
    [623] = { en = 'Head Butt', skillchain = { 'Impaction' } },
    [628] = { en = 'Frypan', skillchain = { 'Impaction' } },
    [631] = { en = 'Hydro Shot', skillchain = { 'Reverberation' } },
    [638] = { en = 'Feather Storm', skillchain = { 'Transfixion' } },
    [640] = { en = 'Tail Slap', skillchain = { 'Reverberation' } },
    [641] = { en = 'Hysteric Barrage', skillchain = { 'Detonation' } },
    [643] = { en = 'Cannonball', skillchain = { 'Fusion' } },
    [650] = { en = 'Seedspray', skillchain = { 'Induration', 'Detonation' } },
    [652] = { en = 'Spiral Spin', skillchain = { 'Transfixion' } },
    [653] = { en = 'Asuran Claws', skillchain = { 'Liquefaction', 'Impaction' } },
    [654] = { en = 'Sub-zero Smash', skillchain = { 'Fragmentation' } },
    [665] = { en = 'Final Sting', skillchain = { 'Fusion' } },
    [666] = { en = 'Goblin Rush', skillchain = { 'Fusion', 'Impaction' } },
    [667] = { en = 'Vanity Dive', skillchain = { 'Transfixion', 'Scission' } },
    [669] = { en = 'Whirl of Rage', skillchain = { 'Scission', 'Detonation' } },
    [670] = { en = 'Benthic Typhoon', skillchain = { 'Gravitation', 'Transfixion' } },
    [673] = { en = 'Quad. Continuum', skillchain = { 'Distortion', 'Scission' } },
    [677] = { en = 'Empty Thrash', skillchain = { 'Compression', 'Scission' } },
    [682] = { en = 'Delta Thrust', skillchain = { 'Liquefaction', 'Detonation' } },
    [688] = { en = 'Heavy Strike', skillchain = { 'Fragmentation', 'Transfixion' } },
    [692] = { en = 'Sudden Lunge', skillchain = { 'Detonation' } },
    [693] = { en = 'Quadrastrike', skillchain = { 'Liquefaction', 'Scission', 'Impaction' } },
    [697] = { en = 'Amorphic Spikes', skillchain = { 'Gravitation' } },
    [699] = { en = 'Barbed Crescent', skillchain = { 'Distortion', 'Scission' } },
    [704] = { en = 'Paralyzing Triad', skillchain = { 'Gravitation' } },
    [706] = { en = 'Glutinous Dart', skillchain = { 'Fragmentation' } },
    [709] = { en = 'Thrashing Assault', skillchain = { 'Fusion' } },
    [714] = { en = 'Sinker Drill', skillchain = { 'Gravitation', 'Reverberation' } },
    [723] = { en = 'Saurian Slide', skillchain = { 'Fragmentation', 'Distortion' } },
    [740] = { en = 'Tourbillion', skillchain = { 'Light', 'Fragmentation' } },
    [742] = { en = 'Bilgestorm', skillchain = { 'Darkness', 'Gravitation' } },
    [743] = { en = 'Bloodrake', skillchain = { 'Darkness', 'Distortion' } },
    [885] = { en = 'Geohelix II', skillchain = { 'Scission' }, delay = 5 },
    [886] = { en = 'Hydrohelix II', skillchain = { 'Reverberation' }, delay = 5 },
    [887] = { en = 'Anemohelix II', skillchain = { 'Detonation' }, delay = 5 },
    [888] = { en = 'Pyrohelix II', skillchain = { 'Liquefaction' }, delay = 5 },
    [889] = { en = 'Cryohelix II', skillchain = { 'Induration' }, delay = 5 },
    [890] = { en = 'Ionohelix II', skillchain = { 'Impaction' }, delay = 5 },
    [891] = { en = 'Noctohelix II', skillchain = { 'Compression' }, delay = 5 },
    [892] = { en = 'Luminohelix II', skillchain = { 'Transfixion' }, delay = 5 },
};

skills[11] = { -- NPC TP skills
    [829] = { en = 'Great Wheel', skillchain = { 'Fragmentation', 'Scission' } },
    [830] = { en = 'Light Blade', skillchain = { 'Light', 'Fusion' } },
    [838] = { en = 'Howling Moon', skillchain = { 'Darkness', 'Distortion' } },
    [839] = { en = 'Howling Moon', skillchain = { 'Darkness', 'Distortion' } },
    [938] = { en = 'Circle Blade', skillchain = { 'Reverberation', 'Impaction' } },
    [939] = { en = 'Swift Blade', skillchain = { 'Gravitation' } },
    [940] = { en = 'Rampage', skillchain = { 'Scission' } },
    [941] = { en = 'Calamity', skillchain = { 'Scission', 'Impaction' } },
    [943] = { en = 'Vorpal Blade', skillchain = { 'Scission', 'Impaction' } },
    [944] = { en = 'Spinning Scythe', skillchain = { 'Reverberation', 'Scission' } },
    [945] = { en = 'Guillotine', skillchain = { 'Induration' } },
    [946] = { en = 'Tachi: Yukikaze', skillchain = { 'Induration', 'Detonation' } },
    [947] = { en = 'Tachi: Gekko', skillchain = { 'Distortion', 'Reverberation' } },
    [948] = { en = 'Tachi: Kasha', skillchain = { 'Fusion', 'Compression' } },
    [951] = { en = 'Hurricane Wing', skillchain = { 'Scission', 'Detonation' } },
    [953] = { en = 'Dragon Breath', skillchain = { 'Light', 'Fusion' } },
    [956] = { en = 'Hurricane Wing', skillchain = { 'Scission', 'Detonation' } },
    [968] = { en = 'Red Lotus Blade', skillchain = { 'Liquefaction', 'Detonation' } },
    [969] = { en = 'Flat Blade', skillchain = { 'Impaction' } },
    [970] = { en = 'Savage Blade', skillchain = { 'Fragmentation', 'Scission' } },
    [973] = { en = 'Red Lotus Blade', skillchain = { 'Liquefaction', 'Detonation' } },
    [975] = { en = 'Vorpal Blade', skillchain = { 'Scission', 'Impaction' } },
    [979] = { en = 'Power Slash', skillchain = { 'Transfixion' } },
    [980] = { en = 'Freezebite', skillchain = { 'Induration', 'Detonation' } },
    [981] = { en = 'Ground Strike', skillchain = { 'Fragmentation', 'Distortion' } },
    [985] = { en = 'Stellar Burst', skillchain = { 'Darkness', 'Gravitation' } },
    [986] = { en = 'Vortex', skillchain = { 'Distortion', 'Reverberation' } },
    [987] = { en = 'Shockwave', skillchain = { 'Reverberation' } },
    [1027] = { en = 'Combo', skillchain = { 'Impaction' } },
    [1029] = { en = 'One-Ilm Punch', skillchain = { 'Compression' } },
    [1030] = { en = 'Backhand Blow', skillchain = { 'Detonation' } },
    [1031] = { en = 'Spinning Attack', skillchain = { 'Liquefaction', 'Impaction' } },
    [1032] = { en = 'Howling Fist', skillchain = { 'Transfixion', 'Impaction' } },
    [1033] = { en = 'Dragon Kick', skillchain = { 'Fragmentation' } },
    [1034] = { en = 'Asuran Fists', skillchain = { 'Gravitation', 'Liquefaction' } },
    [1039] = { en = 'Hurricane Wing', skillchain = { 'Scission', 'Detonation' } },
    [1041] = { en = 'Dragon Breath', skillchain = { 'Light', 'Fusion' } },
    [1088] = { en = 'Goblin Rush', skillchain = { 'Fusion', 'Impaction' } },
    [1089] = { en = 'Bomb Toss', skillchain = { 'Liquefaction' } },
    [1090] = { en = 'Bomb Toss', skillchain = { 'Liquefaction' } },
    [1188] = { en = 'Final Heaven', skillchain = { 'Light', 'Fusion' } },
    [1189] = { en = 'Mercy Stroke', skillchain = { 'Darkness', 'Gravitation' } },
    [1190] = { en = 'Knights of Round', skillchain = { 'Light', 'Fusion' } },
    [1191] = { en = 'Scourge', skillchain = { 'Light', 'Fusion' } },
    [1192] = { en = 'Onslaught', skillchain = { 'Darkness', 'Gravitation' } },
    [1193] = { en = 'Metatron Torment', skillchain = { 'Light', 'Fusion' } },
    [1194] = { en = 'Catastrophe', skillchain = { 'Darkness', 'Gravitation' } },
    [1195] = { en = 'Geirskogul', skillchain = { 'Light', 'Distortion' } },
    [1196] = { en = 'Blade: Metsu', skillchain = { 'Darkness', 'Fragmentation' } },
    [1197] = { en = 'Tachi: Kaiten', skillchain = { 'Light', 'Fragmentation' } },
    [1198] = { en = 'Randgrith', skillchain = { 'Light', 'Fragmentation' } },
    [1199] = { en = 'Gate of Tartarus', skillchain = { 'Darkness', 'Distortion' } },
    [1201] = { en = 'Coronach', skillchain = { 'Darkness', 'Fragmentation' } },
    [1390] = { en = 'Amatsu: Torimai', skillchain = { 'Transfixion', 'Scission' } },
    [1391] = { en = 'Amatsu: Kazakiri', skillchain = { 'Scission', 'Detonation' } },
    [1392] = { en = 'Amatsu: Yukiarashi', skillchain = { 'Induration', 'Detonation' } },
    [1393] = { en = 'Amatsu: Tsukioboro', skillchain = { 'Distortion', 'Reverberation' } },
    [1394] = { en = 'Amatsu: Hanaikusa', skillchain = { 'Fusion', 'Compression' } },
    [1395] = { en = 'Amatsu: Tsukikage', skillchain = { 'Darkness', 'Fragmentation' } },
    [1397] = { en = 'Oisoya', skillchain = { 'Light', 'Distortion' } },
    [1444] = { en = 'Vorpal Blade', skillchain = { 'Scission', 'Impaction' } },
    [1476] = { en = 'Red Lotus Blade', skillchain = { 'Liquefaction', 'Detonation' } },
    [1477] = { en = 'Flat Blade', skillchain = { 'Impaction' } },
    [1478] = { en = 'Savage Blade', skillchain = { 'Fragmentation', 'Scission' } },
    [1481] = { en = 'Red Lotus Blade', skillchain = { 'Liquefaction', 'Detonation' } },
    [1483] = { en = 'Vorpal Blade', skillchain = { 'Scission', 'Impaction' } },
    [1489] = { en = 'Nullifying Dropkick', skillchain = { 'Induration', 'Detonation', 'Impaction' } },
    [1490] = { en = 'Auroral Uppercut', skillchain = { 'Light', 'Fragmentation' } },
    [1508] = { en = 'Luminous Lance', skillchain = { 'Light', 'Fusion' }, delay = 7 },
    [1510] = { en = 'Revelation', skillchain = { 'Fusion', 'Transfixion' }, delay = 6 },
    [1517] = { en = 'Goblin Rush', skillchain = { 'Fusion', 'Impaction' } },
    [1520] = { en = 'Howling Moon', skillchain = { 'Darkness', 'Distortion' } },
    [1586] = { en = 'Wild Oats', skillchain = { 'Transfixion' } },
    [1618] = { en = 'Uppercut', skillchain = { 'Liquefaction' } },
    [1737] = { en = 'Vorpal Blade', skillchain = { 'Scission', 'Impaction' } },
    [1854] = { en = 'Stellar Burst', skillchain = { 'Darkness', 'Gravitation' } },
    [1914] = { en = 'Great Wheel', skillchain = { 'Fragmentation', 'Scission' } },
    [1936] = { en = 'Shibaraku', skillchain = { 'Darkness', 'Gravitation' } },
    [1940] = { en = 'Chimera Ripper', skillchain = { 'Induration', 'Detonation' } },
    [1941] = { en = 'String Clipper', skillchain = { 'Scission', 'Impaction' } },
    [1942] = { en = 'Arcuballista', skillchain = { 'Liquefaction', 'Transfixion' } },
    [1943] = { en = 'Slapstick', skillchain = { 'Reverberation', 'Impaction' } },
    [1982] = { en = 'Nullifying Dropkick', skillchain = { 'Induration', 'Detonation', 'Impaction' } },
    [1983] = { en = 'Auroral Uppercut', skillchain = { 'Light', 'Fragmentation' } },
    [1998] = { en = 'Hane Fubuki', skillchain = { 'Transfixion' } },
    [2001] = { en = 'Happobarai', skillchain = { 'Reverberation', 'Impaction' } },
    [2065] = { en = 'Cannibal Blade', skillchain = { 'Compression', 'Reverberation' } },
    [2066] = { en = 'Daze', skillchain = { 'Transfixion' } },
    [2067] = { en = 'Knockout', skillchain = { 'Scission', 'Detonation' } },
    [2088] = { en = 'Victory Beacon', skillchain = { 'Light', 'Distortion' } },
    [2089] = { en = 'Salamander Flame', skillchain = { 'Light', 'Fusion' } },
    [2090] = { en = 'Typhonic Arrow', skillchain = { 'Light', 'Fragmentation' } },
    [2091] = { en = 'Meteoric Impact', skillchain = { 'Darkness', 'Fragmentation' } },
    [2092] = { en = 'Scouring Bubbles', skillchain = { 'Darkness', 'Distortion' } },
    [2134] = { en = 'Victory Beacon', skillchain = { 'Light', 'Distortion' } },
    [2135] = { en = 'Salamander Flame', skillchain = { 'Light', 'Fusion' } },
    [2136] = { en = 'Typhonic Arrow', skillchain = { 'Light', 'Fragmentation' } },
    [2137] = { en = 'Meteoric Impact', skillchain = { 'Darkness', 'Fragmentation' } },
    [2138] = { en = 'Scouring Bubbles', skillchain = { 'Darkness', 'Distortion' } },
    [2140] = { en = 'Peacebreaker', skillchain = { 'Distortion', 'Reverberation' } },
    [2272] = { en = 'Bear Killer', skillchain = { 'Reverberation', 'Impaction' } },
    [2273] = { en = 'Uriel Blade', skillchain = { 'Light', 'Fragmentation' } },
    [2274] = { en = 'Spine Chiller', skillchain = { 'Distortion', 'Detonation' } },
    [2278] = { en = 'Glory Slash', skillchain = { 'Light', 'Fusion' } },
    [2280] = { en = 'Iainuki', skillchain = { 'Light', 'Fragmentation' }, delay = 7 },
    [2299] = { en = 'Bone Crusher', skillchain = { 'Fragmentation' } },
    [2300] = { en = 'Armor Piercer', skillchain = { 'Gravitation' } },
    [2301] = { en = 'Magic Mortar', skillchain = { 'Fusion' } },
    [2386] = { en = 'Cobra Clamp', skillchain = { 'Fragmentation', 'Distortion' } },
    [2444] = { en = 'Dancer\'s Fury', skillchain = { 'Fragmentation', 'Scission' } },
    [2445] = { en = 'Whirling Edge', skillchain = { 'Distortion', 'Reverberation' } },
    [2468] = { en = 'King Cobra Clamp', skillchain = { 'Fragmentation', 'Distortion' } },
    [2469] = { en = 'Wasp Sting', skillchain = { 'Scission' } },
    [2470] = { en = 'Dancing Edge', skillchain = { 'Scission', 'Detonation' } },
    [2472] = { en = 'Songbird Swoop', skillchain = { 'Reverberation', 'Impaction' } },
    [2476] = { en = 'Gyre Strike', skillchain = { 'Fragmentation' } },
    [2477] = { en = 'Stag\'s Charge', skillchain = { 'Gravitation', 'Induration' } },
    [2478] = { en = 'Orcsbane', skillchain = { 'Light', 'Distortion' } },
    [2479] = { en = 'Temblor Blade', skillchain = { 'Reverberation', 'Impaction' } },
    [2486] = { en = 'Salvation Scythe', skillchain = { 'Darkness' } },
    [2487] = { en = 'Salvation Scythe', skillchain = { 'Darkness' } },
    [2588] = { en = 'Debonair Rush', skillchain = { 'Scission', 'Detonation' } },
    [2589] = { en = 'Iridal Pierce', skillchain = { 'Light', 'Fragmentation' } },
    [2590] = { en = 'Lunar Revolution', skillchain = { 'Gravitation', 'Reverberation' } },
    [2594] = { en = 'Quietus Sphere', skillchain = { 'Darkness', 'Gravitation' } },
    [2743] = { en = 'String Shredder', skillchain = { 'Distortion', 'Scission' } },
    [2744] = { en = 'Armor Shatterer', skillchain = { 'Fusion', 'Impaction' } },
    [2891] = { en = 'Grapeshot', skillchain = { 'Reverberation', 'Transfixion' } },
    [2892] = { en = 'Pirate Pummel', skillchain = { 'Fusion', 'Impaction' } },
    [2893] = { en = 'Powder Keg', skillchain = { 'Fusion', 'Compression' } },
    [2894] = { en = 'Walk the Plank', skillchain = { 'Light', 'Distortion' } },
    [2895] = { en = 'Knuckle Sandwich', skillchain = { 'Fusion', 'Compression' } },
    [2896] = { en = 'Imperial Authority', skillchain = { 'Fragmentation', 'Distortion' } },
    [2897] = { en = 'Sixth Element', skillchain = { 'Darkness', 'Gravitation' } },
    [2898] = { en = 'Shield Subverter', skillchain = { 'Light', 'Fusion' } },
    [2899] = { en = 'Shining Summer Samba', skillchain = { 'Liquefaction', 'Transfixion' } },
    [2900] = { en = 'Lovely Miracle Waltz', skillchain = { 'Liquefaction', 'Scission', 'Impaction' } },
    [2901] = { en = 'Neo Crystal Jig', skillchain = { 'Fusion', 'Transfixion' } },
    [2902] = { en = 'Super Crusher Jig', skillchain = { 'Gravitation', 'Reverberation' }, delay = 7 },
    [3161] = { en = 'Camaraderie of the Crevasse', skillchain = { 'Detonation', 'Impaction' } },
    [3162] = { en = 'Into the Light', skillchain = { 'Fusion', 'Impaction' } },
    [3163] = { en = 'Arduous Decision', skillchain = { 'Fragmentation', 'Compression' } },
    [3164] = { en = '12 Blades of Remorse', skillchain = { 'Light', 'Distortion' } },
    [3168] = { en = 'Aurous Charge', skillchain = { 'Liquefaction', 'Transfixion' } },
    [3169] = { en = 'Howling Gust', skillchain = { 'Fragmentation', 'Compression' }, delay = 6 },
    [3170] = { en = 'Righteous Rasp', skillchain = { 'Fusion', 'Transfixion' } },
    [3171] = { en = 'Starward Yowl', skillchain = { 'Gravitation', 'Reverberation' } },
    [3172] = { en = 'Stalking Prey', skillchain = { 'Light', 'Fragmentation' } },
    [3176] = { en = 'Chant du Cygne', skillchain = { 'Light', 'Distortion' } },
    [3179] = { en = 'Chant du Cygne', skillchain = { 'Light', 'Distortion' } },
    [3185] = { en = 'Cloudsplitter', skillchain = { 'Darkness', 'Fragmentation' } },
    [3188] = { en = 'Tachi: Fudo', skillchain = { 'Light', 'Distortion' } },
    [3189] = { en = 'King Cobra Clamp', skillchain = { 'Fragmentation', 'Distortion' } },
    [3190] = { en = 'Red Lotus Blade', skillchain = { 'Liquefaction', 'Detonation' } },
    [3192] = { en = 'Vorpal Blade', skillchain = { 'Scission', 'Impaction' } },
    [3197] = { en = 'Ground Strike', skillchain = { 'Fragmentation', 'Distortion' } },
    [3198] = { en = 'Grapeshot', skillchain = { 'Reverberation', 'Transfixion' } },
    [3199] = { en = 'Pirate Pummel', skillchain = { 'Fusion', 'Impaction' } },
    [3200] = { en = 'Powder Keg', skillchain = { 'Fusion', 'Compression' } },
    [3201] = { en = 'Walk the Plank', skillchain = { 'Light', 'Distortion' } },
    [3202] = { en = 'Uriel Blade', skillchain = { 'Light', 'Fragmentation' } },
    [3203] = { en = 'Scouring Bubbles', skillchain = { 'Darkness', 'Distortion' } },
    [3204] = { en = 'Amatsu: Tsukikage', skillchain = { 'Darkness', 'Fragmentation' } },
    [3213] = { en = 'Vortex', skillchain = { 'Distortion', 'Reverberation' } },
    [3214] = { en = 'Light Blade', skillchain = { 'Light', 'Fusion' } },
    [3215] = { en = 'Peacebreaker', skillchain = { 'Distortion', 'Reverberation' } },
    [3216] = { en = 'Red Lotus Blade', skillchain = { 'Liquefaction', 'Detonation' } },
    [3217] = { en = 'Savage Blade', skillchain = { 'Fragmentation', 'Scission' } },
    [3231] = { en = 'Debonair Rush', skillchain = { 'Scission', 'Detonation' } },
    [3232] = { en = 'Iridal Pierce', skillchain = { 'Light', 'Fragmentation' } },
    [3233] = { en = 'Lunar Revolution', skillchain = { 'Gravitation', 'Reverberation' } },
    [3234] = { en = 'Nullifying Dropkick', skillchain = { 'Induration', 'Detonation', 'Impaction' } },
    [3235] = { en = 'Auroral Uppercut', skillchain = { 'Light', 'Fragmentation' } },
    [3236] = { en = 'Knuckle Sandwich', skillchain = { 'Fusion', 'Compression' } },
    [3237] = { en = 'Victory Beacon', skillchain = { 'Light', 'Distortion' } },
    [3238] = { en = 'Salamander Flame', skillchain = { 'Light', 'Fusion' } },
    [3239] = { en = 'Typhonic Arrow', skillchain = { 'Light', 'Fragmentation' } },
    [3240] = { en = 'Meteoric Impact', skillchain = { 'Darkness', 'Fragmentation' } },
    [3243] = { en = 'Imperial Authority', skillchain = { 'Fragmentation', 'Distortion' } },
    [3244] = { en = 'Sixth Element', skillchain = { 'Darkness', 'Gravitation' } },
    [3245] = { en = 'Shield Subverter', skillchain = { 'Light', 'Fusion' } },
    [3252] = { en = 'Bisection', skillchain = { 'Scission', 'Detonation' } },
    [3253] = { en = 'Leaden Salute', skillchain = { 'Gravitation', 'Transfixion' } },
    [3254] = { en = 'Akimbo Shot', skillchain = { 'Compression' }, delay = 5 },
    [3255] = { en = 'Grisly Horizon', skillchain = { 'Darkness', 'Distortion' } },
    [3256] = { en = 'Hane Fubuki', skillchain = { 'Transfixion' } },
    [3257] = { en = 'Shibaraku', skillchain = { 'Darkness', 'Gravitation' } },
    [3259] = { en = 'Happobarai', skillchain = { 'Reverberation', 'Impaction' } },
    [3261] = { en = 'Bomb Toss', skillchain = { 'Liquefaction' } },
    [3262] = { en = 'Goblin Rush', skillchain = { 'Fusion', 'Impaction' } },
    [3263] = { en = 'Bear Killer', skillchain = { 'Reverberation', 'Impaction' } },
    [3264] = { en = 'Salvation Scythe', skillchain = { 'Darkness' } },
    [3283] = { en = 'Iniquitous Stab', skillchain = { 'Gravitation', 'Transfixion' } },
    [3284] = { en = 'Shockstorm Edge', skillchain = { 'Detonation', 'Impaction' } },
    [3285] = { en = 'Choreographed Carnage', skillchain = { 'Darkness', 'Distortion' } },
    [3286] = { en = 'Lock and Load', skillchain = { 'Fusion', 'Reverberation' } },
    [3292] = { en = 'Gyre Strike', skillchain = { 'Fragmentation' } },
    [3293] = { en = 'Stag\'s Charge', skillchain = { 'Gravitation', 'Induration' } },
    [3294] = { en = 'Orcsbane', skillchain = { 'Light', 'Distortion' } },
    [3295] = { en = 'Songbird Swoop', skillchain = { 'Reverberation', 'Impaction' } },
    [3296] = { en = 'Temblor Blade', skillchain = { 'Reverberation', 'Impaction' } },
    [3297] = { en = 'Cobra Clamp', skillchain = { 'Fragmentation', 'Distortion' } },
    [3303] = { en = 'Feast of Arrows', skillchain = { 'Gravitation', 'Transfixion' } },
    [3305] = { en = 'Regurgitated Swarm', skillchain = { 'Fusion', 'Compression' }, delay = 7 },
    [3306] = { en = 'Setting the Stage', skillchain = { 'Gravitation', 'Induration' } },
    [3307] = { en = 'Last Laugh', skillchain = { 'Darkness', 'Gravitation' } },
    [3310] = { en = 'Dancer\'s Fury', skillchain = { 'Fragmentation', 'Scission' } },
    [3311] = { en = 'Whirling Edge', skillchain = { 'Distortion', 'Reverberation' } },
    [3314] = { en = 'True Strike', skillchain = { 'Detonation', 'Impaction' } },
    [3315] = { en = 'Hexa Strike', skillchain = { 'Fusion' } },
    [3322] = { en = 'Critical Mass', skillchain = { 'Fusion', 'Impaction' } },
    [3323] = { en = 'Fiery Tailings', skillchain = { 'Light', 'Fusion' } },
    [3336] = { en = 'Howling Moon', skillchain = { 'Darkness', 'Distortion' } },
    [3337] = { en = 'Lunar Bay', skillchain = { 'Gravitation', 'Transfixion' } },
    [3351] = { en = 'Wild Oats', skillchain = { 'Transfixion' } },
    [3356] = { en = 'Uppercut', skillchain = { 'Liquefaction' } },
    [3381] = { en = 'Frenzied Thrust', skillchain = { 'Fragmentation', 'Transfixion' } },
    [3382] = { en = 'Sinner\'s Cross', skillchain = { 'Gravitation', 'Scission' } },
    [3383] = { en = 'Open Coffin', skillchain = { 'Fusion', 'Compression' } },
    [3385] = { en = 'Hemocladis', skillchain = { 'Darkness', 'Distortion' } },
    [3411] = { en = 'Power Slash', skillchain = { 'Transfixion' } },
    [3412] = { en = 'Freezebite', skillchain = { 'Induration', 'Detonation' } },
    [3413] = { en = 'Combo', skillchain = { 'Impaction' } },
    [3414] = { en = 'One-Ilm Punch', skillchain = { 'Compression' } },
    [3415] = { en = 'Howling Fist', skillchain = { 'Transfixion', 'Impaction' } },
    [3416] = { en = 'Dragon Kick', skillchain = { 'Fragmentation' } },
    [3417] = { en = 'Asuran Fists', skillchain = { 'Gravitation', 'Liquefaction' } },
    [3418] = { en = 'Amatsu: Torimai', skillchain = { 'Transfixion', 'Scission' } },
    [3419] = { en = 'Amatsu: Kazakiri', skillchain = { 'Scission', 'Detonation' } },
    [3420] = { en = 'Amatsu: Yukiarashi', skillchain = { 'Induration', 'Detonation' } },
    [3421] = { en = 'Amatsu: Tsukioboro', skillchain = { 'Distortion', 'Reverberation' } },
    [3422] = { en = 'Amatsu: Hanaikusa', skillchain = { 'Fusion', 'Compression' } },
    [3423] = { en = 'Wasp Sting', skillchain = { 'Scission' } },
    [3424] = { en = 'Dancing Edge', skillchain = { 'Scission', 'Detonation' } },
    [3425] = { en = 'Flat Blade', skillchain = { 'Impaction' } },
    [3431] = { en = 'Fast Blade', skillchain = { 'Scission' } },
    [3432] = { en = 'Savage Blade', skillchain = { 'Fragmentation', 'Scission' } },
    [3434] = { en = 'Tachi: Kamai', skillchain = { 'Gravitation', 'Scission' } },
    [3435] = { en = 'Iainuki', skillchain = { 'Light', 'Fragmentation' }, delay = 7 },
    [3436] = { en = 'Tachi: Goten', skillchain = { 'Transfixion', 'Impaction' } },
    [3437] = { en = 'Tachi: Kasha', skillchain = { 'Fusion', 'Compression' } },
    [3438] = { en = 'Dragon Breath', skillchain = { 'Light', 'Fusion' } },
    [3439] = { en = 'Hurricane Wing', skillchain = { 'Scission', 'Detonation' } },
    [3445] = { en = 'Merciless Strike', skillchain = { 'Detonation', 'Impaction' } },
    [3448] = { en = 'Uppercut', skillchain = { 'Liquefaction' } },
    [3454] = { en = 'Coming Up Roses', skillchain = { 'Light', 'Fusion' }, delay = 7 },
    [3466] = { en = 'Paralyzing Microtube', skillchain = { 'Induration' }, delay = 6 },
    [3467] = { en = 'Silencing Microtube', skillchain = { 'Liquefaction', 'Detonation' }, delay = 6 },
    [3468] = { en = 'Binding Microtube', skillchain = { 'Gravitation', 'Induration' }, delay = 6 },
    [3469] = { en = 'Twirling Dervish', skillchain = { 'Light', 'Fusion' }, delay = 8 },
    [3470] = { en = 'Great Wheel', skillchain = { 'Fragmentation', 'Scission' } },
    [3471] = { en = 'Light Blade', skillchain = { 'Light', 'Fusion' } },
    [3472] = { en = 'Vortex', skillchain = { 'Distortion', 'Reverberation' } },
    [3473] = { en = 'Stellar Burst', skillchain = { 'Darkness', 'Gravitation' } },
    [3487] = { en = 'Sidewinder', skillchain = { 'Reverberation', 'Transfixion', 'Detonation' } },
    [3488] = { en = 'Arching Arrow', skillchain = { 'Fusion' } },
    [3489] = { en = 'Stellar Arrow', skillchain = { 'Darkness', 'Gravitation' } },
    [3490] = { en = 'Lux Arrow', skillchain = { 'Fragmentation', 'Distortion' } },
    [3491] = { en = 'Grapeshot', skillchain = { 'Reverberation', 'Transfixion' } },
    [3492] = { en = 'Pirate Pummel', skillchain = { 'Fusion', 'Impaction' } },
    [3493] = { en = 'Powder Keg', skillchain = { 'Fusion', 'Compression' } },
    [3494] = { en = 'Walk the Plank', skillchain = { 'Light', 'Distortion' } },
    [3495] = { en = 'Ground Strike', skillchain = { 'Fragmentation', 'Distortion' } },
    [3496] = { en = 'Hollow Smite', skillchain = { 'Light', 'Fragmentation' } },
    [3497] = { en = 'Sarva\'s Storm', skillchain = { 'Darkness', 'Distortion' } },
    [3498] = { en = 'Sarva\'s Storm', skillchain = { 'Darkness', 'Distortion' } },
    [3499] = { en = 'Soturi\'s Fury', skillchain = { 'Light', 'Fragmentation' } },
    [3500] = { en = 'Celidon\'s Torment', skillchain = { 'Light', 'Fragmentation' } },
    [3501] = { en = 'Tachi: Mudo', skillchain = { 'Light', 'Distortion' } },
    [3503] = { en = 'Justicebreaker', skillchain = { 'Darkness', 'Gravitation' }, delay = 5 },
    [3536] = { en = 'Spine Chiller', skillchain = { 'Distortion', 'Detonation' } },
    [3537] = { en = 'Quietus Sphere', skillchain = { 'Darkness', 'Gravitation' } },
    [3538] = { en = 'Null Blast', skillchain = { 'Fusion', 'Compression' } },
    [3542] = { en = 'Oisoya', skillchain = { 'Light', 'Distortion' } },
    [3543] = { en = 'Knuckle Sandwich', skillchain = { 'Fusion', 'Compression' } },
    [3544] = { en = 'Whirling Edge', skillchain = { 'Distortion', 'Reverberation' } },
    [3551] = { en = 'Lunar Bay', skillchain = { 'Gravitation', 'Transfixion' } },
    [3556] = { en = 'Amatsu: Fuga', skillchain = { 'Impaction' }, delay = 6 },
    [3557] = { en = 'Amatsu: Kyori', skillchain = { 'Induration' }, delay = 7 },
    [3558] = { en = 'Amatsu: Hanadoki', skillchain = { 'Reverberation', 'Impaction' } },
    [3559] = { en = 'Amatsu: Choun', skillchain = { 'Liquefaction' } },
    [3560] = { en = 'Amatsu: Gachirin', skillchain = { 'Light', 'Fragmentation' }, delay = 7 },
    [3561] = { en = 'Amatsu: Suien', skillchain = { 'Fusion' }, delay = 6 },
    [3579] = { en = 'Expunge Magic', skillchain = { 'Distortion', 'Scission' } },
    [3580] = { en = 'Harmonic Displacement', skillchain = { 'Fusion', 'Reverberation' } },
    [3581] = { en = 'Sight Unseen', skillchain = { 'Fragmentation', 'Compression' } },
    [3582] = { en = 'Darkest Hour', skillchain = { 'Gravitation', 'Liquefaction' } },
    [3585] = { en = 'Naakual\'s Vengeance', skillchain = { 'Light', 'Fusion' }, delay = 7 },
    [3591] = { en = 'Tartaric Sigil', skillchain = { 'Compression', 'Scission' } },
    [3592] = { en = 'Null Field', skillchain = { 'Fusion', 'Transfixion' } },
    [3593] = { en = 'Alabaster Burst', skillchain = { 'Distortion', 'Detonation' } },
    [3594] = { en = 'Noble Frenzy', skillchain = { 'Gravitation', 'Scission' } },
    [3595] = { en = 'Fulminous Fury', skillchain = { 'Fragmentation', 'Scission' }, delay = 6 },
    [3596] = { en = 'No Quarter', skillchain = { 'Light', 'Distortion' }, delay = 7 },
    [3611] = { en = 'Inexorable Strike', skillchain = { 'Light', 'Fusion' } },
    [3617] = { en = 'Feast of Arrows', skillchain = { 'Gravitation', 'Transfixion' } },
    [3618] = { en = 'Regurgitated Swarm', skillchain = { 'Fusion', 'Compression' }, delay = 7 },
    [3619] = { en = 'Setting the Stage', skillchain = { 'Gravitation', 'Induration' } },
    [3620] = { en = 'Last Laugh', skillchain = { 'Darkness', 'Gravitation' } },
    [3621] = { en = 'Luminous Lance', skillchain = { 'Light', 'Fusion' }, delay = 7 },
    [3623] = { en = 'Revelation', skillchain = { 'Fusion', 'Transfixion' }, delay = 6 },
    [3632] = { en = 'Frenzied Thrust', skillchain = { 'Fragmentation', 'Transfixion' } },
    [3633] = { en = 'Sinner\'s Cross', skillchain = { 'Gravitation', 'Scission' } },
    [3634] = { en = 'Open Coffin', skillchain = { 'Fusion', 'Compression' } },
    [3636] = { en = 'Hemocladis', skillchain = { 'Darkness', 'Distortion' } },
    [3637] = { en = 'Shining Summer Samba', skillchain = { 'Liquefaction', 'Transfixion' } },
    [3638] = { en = 'Lovely Miracle Waltz', skillchain = { 'Liquefaction', 'Scission', 'Impaction' } },
    [3639] = { en = 'Neo Crystal Jig', skillchain = { 'Fusion', 'Transfixion' } },
    [3640] = { en = 'Super Crusher Jig', skillchain = { 'Gravitation', 'Reverberation' }, delay = 7 },
    [3645] = { en = 'Inexorable Strike', skillchain = { 'Light', 'Fusion' } },
    [3647] = { en = 'Merciless Strike', skillchain = { 'Detonation', 'Impaction' } },
    [3653] = { en = 'Tartaric Sigil', skillchain = { 'Compression', 'Scission' } },
    [3654] = { en = 'Null Field', skillchain = { 'Fusion', 'Transfixion' } },
    [3655] = { en = 'Alabaster Burst', skillchain = { 'Distortion', 'Detonation' } },
    [3656] = { en = 'Noble Frenzy', skillchain = { 'Gravitation', 'Scission' } },
    [3657] = { en = 'Fulminous Fury', skillchain = { 'Fragmentation', 'Scission' }, delay = 6 },
    [3658] = { en = 'No Quarter', skillchain = { 'Light', 'Distortion' }, delay = 7 },
    [3677] = { en = 'Camaraderie of the Crevasse', skillchain = { 'Detonation', 'Impaction' } },
    [3678] = { en = 'Into the Light', skillchain = { 'Fusion', 'Impaction' } },
    [3679] = { en = 'Arduous Decision', skillchain = { 'Fragmentation', 'Compression' } },
    [3680] = { en = '12 Blades of Remorse', skillchain = { 'Light', 'Distortion' } },
    [3684] = { en = 'Aurous Charge', skillchain = { 'Liquefaction', 'Transfixion' } },
    [3685] = { en = 'Howling Gust', skillchain = { 'Fragmentation', 'Compression' }, delay = 6 },
    [3686] = { en = 'Righteous Rasp', skillchain = { 'Fusion', 'Transfixion' } },
    [3687] = { en = 'Starward Yowl', skillchain = { 'Gravitation', 'Reverberation' } },
    [3688] = { en = 'Stalking Prey', skillchain = { 'Light', 'Fragmentation' } },
    [3691] = { en = 'Bludgeon', skillchain = { 'Fusion' } },
    [3699] = { en = 'Expunge Magic', skillchain = { 'Distortion', 'Scission' } },
    [3700] = { en = 'Harmonic Displacement', skillchain = { 'Fusion', 'Reverberation' } },
    [3701] = { en = 'Sight Unseen', skillchain = { 'Fragmentation', 'Compression' } },
    [3702] = { en = 'Darkest Hour', skillchain = { 'Gravitation', 'Liquefaction' } },
    [3705] = { en = 'Naakual\'s Vengeance', skillchain = { 'Light', 'Fusion' }, delay = 7 },
    [3707] = { en = 'Circle Blade', skillchain = { 'Reverberation', 'Impaction' } },
    [3708] = { en = 'Swift Blade', skillchain = { 'Gravitation' } },
    [3709] = { en = 'Chant du Cygne', skillchain = { 'Light', 'Distortion' } },
    [3711] = { en = 'Vorpal Blade', skillchain = { 'Scission', 'Impaction' } },
    [3713] = { en = 'Chant du Cygne', skillchain = { 'Light', 'Distortion' } },
    [3715] = { en = 'Rampage', skillchain = { 'Scission' } },
    [3716] = { en = 'Calamity', skillchain = { 'Scission', 'Impaction' } },
    [3718] = { en = 'Cloudsplitter', skillchain = { 'Darkness', 'Fragmentation' } },
    [3719] = { en = 'Spinning Scythe', skillchain = { 'Reverberation', 'Scission' } },
    [3721] = { en = 'Guillotine', skillchain = { 'Induration' } },
    [3722] = { en = 'Tachi: Yukikaze', skillchain = { 'Induration', 'Detonation' } },
    [3723] = { en = 'Tachi: Gekko', skillchain = { 'Distortion', 'Reverberation' } },
    [3725] = { en = 'Tachi: Kasha', skillchain = { 'Fusion', 'Compression' } },
    [3726] = { en = 'Tachi: Fudo', skillchain = { 'Light', 'Distortion' } },
    [3732] = { en = 'Amatsu: Fuga', skillchain = { 'Impaction' }, delay = 6 },
    [3733] = { en = 'Amatsu: Kyori', skillchain = { 'Induration' }, delay = 7 },
    [3734] = { en = 'Amatsu: Hanadoki', skillchain = { 'Reverberation', 'Impaction' } },
    [3735] = { en = 'Amatsu: Choun', skillchain = { 'Liquefaction' } },
    [3736] = { en = 'Amatsu: Gachirin', skillchain = { 'Light', 'Fragmentation' }, delay = 7 },
    [3737] = { en = 'Amatsu: Suien', skillchain = { 'Fusion' }, delay = 6 },
    [3740] = { en = 'Final Exam', skillchain = { 'Light', 'Fusion' } },
    [3741] = { en = 'Doctor\'s Orders', skillchain = { 'Darkness', 'Gravitation' } },
    [3742] = { en = 'Empirical Research', skillchain = { 'Fragmentation', 'Transfixion' } },
    [3743] = { en = 'Lesson in Pain', skillchain = { 'Distortion', 'Scission' } },
    [3840] = { en = 'Foot Kick', skillchain = { 'Reverberation' } },
    [3842] = { en = 'Whirl Claws', skillchain = { 'Impaction' } },
    [3843] = { en = 'Head Butt', skillchain = { 'Detonation' } },
    [3845] = { en = 'Wild Oats', skillchain = { 'Transfixion' } },
    [3846] = { en = 'Leaf Dagger', skillchain = { 'Scission' } },
    [3849] = { en = 'Razor Fang', skillchain = { 'Impaction' } },
    [3850] = { en = 'Claw Cyclone', skillchain = { 'Scission' } },
    [3851] = { en = 'Tail Blow', skillchain = { 'Impaction' } },
    [3853] = { en = 'Blockhead', skillchain = { 'Reverberation' } },
    [3854] = { en = 'Brain Crush', skillchain = { 'Liquefaction' } },
    [3857] = { en = 'Lamb Chop', skillchain = { 'Impaction' } },
    [3859] = { en = 'Sheep Charge', skillchain = { 'Reverberation' } },
    [3863] = { en = 'Big Scissors', skillchain = { 'Scission' } },
    [3866] = { en = 'Needleshot', skillchain = { 'Transfixion' } },
    [3867] = { en = '??? Needles', skillchain = { 'Darkness', 'Fragmentation' } },
    [3868] = { en = 'Frogkick', skillchain = { 'Compression' } },
    [3875] = { en = 'Power Attack', skillchain = { 'Reverberation' } },
    [3877] = { en = 'Rhino Attack', skillchain = { 'Detonation' } },
    [3885] = { en = 'Mandibular Bite', skillchain = { 'Detonation' } },
    [3891] = { en = 'Nimble Snap', skillchain = { 'Impaction' } },
    [3892] = { en = 'Cyclotail', skillchain = { 'Impaction' } },
    [3894] = { en = 'Double Claw', skillchain = { 'Liquefaction' } },
    [3895] = { en = 'Grapple', skillchain = { 'Reverberation' } },
    [3897] = { en = 'Spinning Top', skillchain = { 'Impaction' } },
    [3900] = { en = 'Suction', skillchain = { 'Compression' } },
    [3904] = { en = 'Sudden Lunge', skillchain = { 'Impaction' } },
    [3905] = { en = 'Spiral Spin', skillchain = { 'Scission' } },
    [3909] = { en = 'Scythe Tail', skillchain = { 'Liquefaction' } },
    [3910] = { en = 'Ripper Fang', skillchain = { 'Induration' } },
    [3911] = { en = 'Chomp Rush', skillchain = { 'Darkness', 'Gravitation' } },
    [3915] = { en = 'Back Heel', skillchain = { 'Reverberation' } },
    [3919] = { en = 'Tortoise Stomp', skillchain = { 'Liquefaction' } },
    [3922] = { en = 'Wing Slap', skillchain = { 'Gravitation', 'Liquefaction' } },
    [3923] = { en = 'Beak Lunge', skillchain = { 'Scission' } },
    [3925] = { en = 'Recoil Dive', skillchain = { 'Transfixion' } },
    [3927] = { en = 'Sensilla Blades', skillchain = { 'Scission' } },
    [3928] = { en = 'Tegmina Buffet', skillchain = { 'Distortion', 'Detonation' } },
    [3930] = { en = 'Swooping Frenzy', skillchain = { 'Fusion', 'Reverberation' } },
    [3931] = { en = 'Sweeping Gouge', skillchain = { 'Induration' } },
    [3933] = { en = 'Pentapeck', skillchain = { 'Light', 'Distortion' } },
    [3934] = { en = 'Tickling Tendrils', skillchain = { 'Impaction' } },
    [3938] = { en = 'Somersault', skillchain = { 'Compression' } },
    [3941] = { en = 'Pecking Flurry', skillchain = { 'Transfixion' } },
    [3942] = { en = 'Sickle Slash', skillchain = { 'Transfixion' } },
    [4050] = { en = 'Wild Oats', skillchain = { 'Transfixion' } },
    [4124] = { en = 'Bomb Toss', skillchain = { 'Liquefaction' } },
    [4158] = { en = 'Blade: Metsu', skillchain = { 'Darkness', 'Fragmentation' } },
    [4211] = { en = 'Iniquitous Stab', skillchain = { 'Gravitation', 'Transfixion' } },
    [4212] = { en = 'Shockstorm Edge', skillchain = { 'Detonation', 'Impaction' } },
    [4213] = { en = 'Choreographed Carnage', skillchain = { 'Darkness', 'Distortion' } },
    [4214] = { en = 'Lock and Load', skillchain = { 'Fusion', 'Reverberation' } },
};

-- Pet skills as triggered by player.
-- Separated from skills as triggered by pet to ease support for private servers
skills.playerPet = { -- BST/SMN Player Pet Skills
    [513] = { en = 'Poison Nails', skillchain = { 'Transfixion' } },
    [521] = { en = 'Regal Scratch', skillchain = { 'Scission' } },
    [528] = { en = 'Moonlit Charge', skillchain = { 'Compression' } },
    [529] = { en = 'Crescent Fang', skillchain = { 'Transfixion' } },
    [534] = { en = 'Eclipse Bite', skillchain = { 'Gravitation', 'Scission' } },
    [544] = { en = 'Punch', skillchain = { 'Liquefaction' } },
    [546] = { en = 'Burning Strike', skillchain = { 'Impaction' } },
    [547] = { en = 'Double Punch', skillchain = { 'Compression' } },
    [550] = { en = 'Flaming Crush', skillchain = { 'Fusion', 'Reverberation' } },
    [560] = { en = 'Rock Throw', skillchain = { 'Scission' } },
    [562] = { en = 'Rock Buster', skillchain = { 'Reverberation' } },
    [563] = { en = 'Megalith Throw', skillchain = { 'Induration' } },
    [566] = { en = 'Mountain Buster', skillchain = { 'Gravitation', 'Induration' } },
    [570] = { en = 'Crag Throw', skillchain = { 'Gravitation', 'Scission' } },
    [576] = { en = 'Barracuda Dive', skillchain = { 'Reverberation' } },
    [578] = { en = 'Tail Whip', skillchain = { 'Detonation' } },
    [582] = { en = 'Spinning Dive', skillchain = { 'Distortion', 'Detonation' } },
    [592] = { en = 'Claw', skillchain = { 'Detonation' } },
    [598] = { en = 'Predator Claws', skillchain = { 'Fragmentation', 'Scission' } },
    [608] = { en = 'Axe Kick', skillchain = { 'Induration' } },
    [612] = { en = 'Double Slap', skillchain = { 'Scission' } },
    [614] = { en = 'Rush', skillchain = { 'Distortion', 'Scission' } },
    [624] = { en = 'Shock Strike', skillchain = { 'Impaction' } },
    [630] = { en = 'Chaotic Strike', skillchain = { 'Fragmentation', 'Transfixion' } },
    [634] = { en = 'Volt Strike', skillchain = { 'Fragmentation', 'Scission' } },
    [656] = { en = 'Camisado', skillchain = { 'Compression' } },
    [667] = { en = 'Blindside', skillchain = { 'Gravitation', 'Transfixion' } },
    [672] = { en = 'Foot Kick', skillchain = { 'Reverberation' } },
    [674] = { en = 'Whirl Claws', skillchain = { 'Impaction' } },
    [675] = { en = 'Head Butt', skillchain = { 'Detonation' } },
    [677] = { en = 'Wild Oats', skillchain = { 'Transfixion' } },
    [678] = { en = 'Leaf Dagger', skillchain = { 'Scission' } },
    [681] = { en = 'Razor Fang', skillchain = { 'Impaction' } },
    [682] = { en = 'Claw Cyclone', skillchain = { 'Scission' } },
    [683] = { en = 'Tail Blow', skillchain = { 'Impaction' } },
    [685] = { en = 'Blockhead', skillchain = { 'Reverberation' } },
    [686] = { en = 'Brain Crush', skillchain = { 'Liquefaction' } },
    [689] = { en = 'Lamb Chop', skillchain = { 'Impaction' } },
    [691] = { en = 'Sheep Charge', skillchain = { 'Reverberation' } },
    [695] = { en = 'Big Scissors', skillchain = { 'Scission' } },
    [698] = { en = 'Needleshot', skillchain = { 'Transfixion' } },
    [699] = { en = '??? Needles', skillchain = { 'Darkness', 'Fragmentation' } },
    [700] = { en = 'Frogkick', skillchain = { 'Compression' } },
    [707] = { en = 'Power Attack', skillchain = { 'Reverberation' } },
    [709] = { en = 'Rhino Attack', skillchain = { 'Detonation' } },
    [717] = { en = 'Mandibular Bite', skillchain = { 'Detonation' } },
    [723] = { en = 'Nimble Snap', skillchain = { 'Impaction' } },
    [724] = { en = 'Cyclotail', skillchain = { 'Impaction' } },
    [726] = { en = 'Double Claw', skillchain = { 'Liquefaction' } },
    [727] = { en = 'Grapple', skillchain = { 'Reverberation' } },
    [728] = { en = 'Spinning Top', skillchain = { 'Impaction' } },
    [732] = { en = 'Suction', skillchain = { 'Compression' } },
    [736] = { en = 'Sudden Lunge', skillchain = { 'Impaction' } },
    [737] = { en = 'Spiral Spin', skillchain = { 'Scission' } },
    [743] = { en = 'Scythe Tail', skillchain = { 'Liquefaction' } },
    [744] = { en = 'Ripper Fang', skillchain = { 'Induration' } },
    [745] = { en = 'Chomp Rush', skillchain = { 'Darkness', 'Gravitation' } },
    [749] = { en = 'Back Heel', skillchain = { 'Reverberation' } },
    [753] = { en = 'Tortoise Stomp', skillchain = { 'Liquefaction' } },
    [756] = { en = 'Wing Slap', skillchain = { 'Gravitation', 'Liquefaction' } },
    [757] = { en = 'Beak Lunge', skillchain = { 'Scission' } },
    [759] = { en = 'Recoil Dive', skillchain = { 'Transfixion' } },
    [761] = { en = 'Sensilla Blades', skillchain = { 'Scission' } },
    [762] = { en = 'Tegmina Buffet', skillchain = { 'Distortion', 'Detonation' } },
    [764] = { en = 'Swooping Frenzy', skillchain = { 'Fusion', 'Reverberation' } },
    [765] = { en = 'Sweeping Gouge', skillchain = { 'Induration' } },
    [767] = { en = 'Pentapeck', skillchain = { 'Light', 'Distortion' } },
    [768] = { en = 'Tickling Tendrils', skillchain = { 'Impaction' } },
    [772] = { en = 'Somersault', skillchain = { 'Compression' } },
    [776] = { en = 'Pecking Flurry', skillchain = { 'Transfixion' } },
    [777] = { en = 'Sickle Slash', skillchain = { 'Transfixion' } },
    [780] = { en = 'Regal Gash', skillchain = { 'Distortion', 'Detonation' } },
    [961] = { en = 'Welt', skillchain = { 'Scission' } },
    [964] = { en = 'Roundhouse', skillchain = { 'Detonation' } },
    [970] = { en = 'Hysteric Assault', skillchain = { 'Fragmentation', 'Transfixion' } },
};

-- *** Modify key IDs as needed for private server ***
-- Pet skills as triggered by pet
-- Separated from skills as triggered by player to ease support for private servers
-- ASB ID values - https://github.com/AirSkyBoat/AirSkyBoat/blob/staging/sql/mob_skills.sql
-- LSB ID values - https://github.com/LandSandBoat/server/blob/base/sql/mob_skills.sql
skills[13] = {                     -- BST/SMN Pet Skills
    [513] = skills.playerPet[513], -- ASB:  907 -- {en='Poison Nails',skillchain={'Transfixion'}},
    [521] = skills.playerPet[521], -- ASB: xxxx -- {en='Regal Scratch',skillchain={'Scission'}},
    [528] = skills.playerPet[528], -- ASB:  831 -- {en='Moonlit Charge',skillchain={'Compression'}},
    [529] = skills.playerPet[529], -- ASB:  832 -- {en='Crescent Fang',skillchain={'Transfixion'}},
    [534] = skills.playerPet[534], -- ASB:  836 -- {en='Eclipse Bite',skillchain={'Gravitation','Scission'}},
    [544] = skills.playerPet[544], -- ASB:  840 -- {en='Punch',skillchain={'Liquefaction'}},
    [546] = skills.playerPet[546], -- ASB:  842 -- {en='Burning Strike',skillchain={'Impaction'}},
    [547] = skills.playerPet[547], -- ASB:  843 -- {en='Double Punch',skillchain={'Compression'}},
    [550] = skills.playerPet[550], -- ASB:  846 -- {en='Flaming Crush',skillchain={'Fusion','Reverberation'}},
    [560] = skills.playerPet[560], -- ASB:  849 -- {en='Rock Throw',skillchain={'Scission'}},
    [562] = skills.playerPet[562], -- ASB:  851 -- {en='Rock Buster',skillchain={'Reverberation'}},
    [563] = skills.playerPet[563], -- ASB:  852 -- {en='Megalith Throw',skillchain={'Induration'}},
    [566] = skills.playerPet[566], -- ASB:  855 -- {en='Mountain Buster',skillchain={'Gravitation','Induration'}},
    [570] = skills.playerPet[570], -- ASB: xxxx -- {en='Crag Throw',skillchain={'Gravitation','Scission'}},
    [576] = skills.playerPet[576], -- ASB:  858 -- {en='Barracuda Dive',skillchain={'Reverberation'}},
    [578] = skills.playerPet[578], -- ASB:  860 -- {en='Tail Whip',skillchain={'Detonation'}},
    [582] = skills.playerPet[582], -- ASB:  864 -- {en='Spinning Dive',skillchain={'Distortion','Detonation'}},
    [592] = skills.playerPet[592], -- ASB:  867 -- {en='Claw',skillchain={'Detonation'}},
    [598] = skills.playerPet[598], -- ASB:  873 -- {en='Predator Claws',skillchain={'Fragmentation','Scission'}},
    [608] = skills.playerPet[608], -- ASB:  876 -- {en='Axe Kick',skillchain={'Induration'}},
    [612] = skills.playerPet[612], -- ASB:  880 -- {en='Double Slap',skillchain={'Scission'}},
    [614] = skills.playerPet[614], -- ASB:  882 -- {en='Rush',skillchain={'Distortion','Scission'}},
    [624] = skills.playerPet[624], -- ASB:  885 -- {en='Shock Strike',skillchain={'Impaction'}},
    [630] = skills.playerPet[630], -- ASB:  891 -- {en='Chaotic Strike',skillchain={'Fragmentation','Transfixion'}},
    [634] = skills.playerPet[634], -- ASB: xxxx -- {en='Volt Strike',skillchain={'Fragmentation','Scission'}},
    [656] = skills.playerPet[656], -- ASB: 1903 -- {en='Camisado',skillchain={'Compression'}},
    [667] = skills.playerPet[667], -- ASB: xxxx -- {en='Blindside',skillchain={'Gravitation','Transfixion'}},
    [672] = skills.playerPet[672], -- ASB:  257 -- {en='Foot Kick',skillchain={'Reverberation'}},
    [674] = skills.playerPet[674], -- ASB:  259 -- {en='Whirl Claws',skillchain={'Impaction'}},
    [675] = skills.playerPet[675], -- ASB:  300 -- {en='Head Butt',skillchain={'Detonation'}},
    [677] = skills.playerPet[677], -- ASB:  302 -- {en='Wild Oats',skillchain={'Transfixion'}},
    [678] = skills.playerPet[678], -- ASB:  305 -- {en='Leaf Dagger',skillchain={'Scission'}},
    [681] = skills.playerPet[681], -- ASB:  271 -- {en='Razor Fang',skillchain={'Impaction'}},
    [682] = skills.playerPet[682], -- ASB:  273 -- {en='Claw Cyclone',skillchain={'Scission'}},
    [683] = skills.playerPet[683], -- ASB:  366 -- {en='Tail Blow',skillchain={'Impaction'}},
    [685] = skills.playerPet[685], -- ASB:  368 -- {en='Blockhead',skillchain={'Reverberation'}},
    [686] = skills.playerPet[686], -- ASB:  369 -- {en='Brain Crush',skillchain={'Liquefaction'}},
    [689] = skills.playerPet[689], -- ASB:  260 -- {en='Lamb Chop',skillchain={'Impaction'}},
    [691] = skills.playerPet[691], -- ASB:  262 -- {en='Sheep Charge',skillchain={'Reverberation'}},
    [695] = skills.playerPet[695], -- ASB:  444 -- {en='Big Scissors',skillchain={'Scission'}},
    [698] = skills.playerPet[698], -- ASB:  321 -- {en='Needleshot',skillchain={'Transfixion'}},
    [699] = skills.playerPet[699], -- ASB: 3867 -- {en='??? Needles',skillchain={'Darkness','Fragmentation'}},
    [700] = skills.playerPet[700], -- ASB:  308 -- {en='Frogkick',skillchain={'Compression'}},
    [707] = skills.playerPet[707], -- ASB:  338 -- {en='Power Attack',skillchain={'Reverberation'}},
    [709] = skills.playerPet[709], -- ASB:  340 -- {en='Rhino Attack',skillchain={'Detonation'}},
    [717] = skills.playerPet[717], -- ASB:  279 -- {en='Mandibular Bite',skillchain={'Detonation'}},
    [723] = skills.playerPet[723], -- ASB:  518 -- {en='Nimble Snap',skillchain={'Impaction'}},
    [724] = skills.playerPet[724], -- ASB:  519 -- {en='Cyclotail',skillchain={'Impaction'}},
    [726] = skills.playerPet[726], -- ASB:  362 -- {en='Double Claw',skillchain={'Liquefaction'}},
    [727] = skills.playerPet[727], -- ASB:  363 -- {en='Grapple',skillchain={'Reverberation'}},
    [728] = skills.playerPet[728], -- ASB:  365 -- {en='Spinning Top',skillchain={'Impaction'}},
    [732] = skills.playerPet[732], -- ASB:  414 -- {en='Suction',skillchain={'Compression'}},
    [736] = skills.playerPet[736], -- ASB: 2178 -- {en='Sudden Lunge',skillchain={'Impaction'}},
    [737] = skills.playerPet[737], -- ASB: 2181 -- {en='Spiral Spin',skillchain={'Scission'}},
    [743] = skills.playerPet[743], -- ASB:  380 -- {en='Scythe Tail',skillchain={'Liquefaction'}},
    [744] = skills.playerPet[744], -- ASB:  374 -- {en='Ripper Fang',skillchain={'Induration'}},
    [745] = skills.playerPet[745], -- ASB:  379 -- {en='Chomp Rush',skillchain={'Darkness','Gravitation'}},
    [749] = skills.playerPet[749], -- ASB:  576 -- {en='Back Heel',skillchain={'Reverberation'}},
    [753] = skills.playerPet[753], -- ASB:  806 -- {en='Tortoise Stomp',skillchain={'Liquefaction'}},
    [756] = skills.playerPet[756], -- ASB: 1714 -- {en='Wing Slap',skillchain={'Gravitation','Liquefaction'}},
    [757] = skills.playerPet[757], -- ASB: 1715 -- {en='Beak Lunge',skillchain={'Scission'}},
    [759] = skills.playerPet[759], -- ASB:  641 -- {en='Recoil Dive',skillchain={'Transfixion'}},
    [761] = skills.playerPet[761], -- ASB: 2946 -- {en='Sensilla Blades',skillchain={'Scission'}},
    [762] = skills.playerPet[762], -- ASB: 2947 -- {en='Tegmina Buffet',skillchain={'Distortion','Detonation'}},
    [764] = skills.playerPet[764], -- ASB: 3065 -- {en='Swooping Frenzy',skillchain={'Fusion','Reverberation'}},
    [765] = skills.playerPet[765], -- ASB: xxxx -- {en='Sweeping Gouge',skillchain={'Induration'}},
    [767] = skills.playerPet[767], -- ASB: 3064 -- {en='Pentapeck',skillchain={'Light','Distortion'}},
    [768] = skills.playerPet[768], -- ASB: 3097 -- {en='Tickling Tendrils',skillchain={'Impaction'}},
    [772] = skills.playerPet[772], -- ASB:  318 -- {en='Somersault',skillchain={'Compression'}},
    [776] = skills.playerPet[776], -- ASB: 1699 -- {en='Pecking Flurry',skillchain={'Transfixion'}},
    [777] = skills.playerPet[777], -- ASB:  810 -- {en='Sickle Slash',skillchain={'Transfixion'}},
    [780] = skills.playerPet[780], -- ASB: xxxx -- {en='Regal Gash',skillchain={'Distortion','Detonation'}},
    [961] = skills.playerPet[961], -- ASB: xxxx -- {en='Welt',skillchain={'Scission'}},
    [964] = skills.playerPet[964], -- ASB: xxxx -- {en='Roundhouse',skillchain={'Detonation'}},
    [970] = skills.playerPet[970], -- ASB: xxxx -- {en='Hysteric Assault',skillchain={'Fragmentation','Transfixion'}},
};

skills[14] = { -- DNC/SAM chainbound abilities
    [209] = { en = 'Wild Flourish', skillchain = { 'Compression', 'Liquefaction', 'Induration', 'Reverberation', 'Scission' } },
    [320] = { en = 'Konzen-ittai', skillchain = { 'Light', 'Darkness', 'Gravitation', 'Fragmentation', 'Distortion', 'Compression', 'Liquefaction', 'Induration', 'Reverberation', 'Scission' } },
};

skills.immanence = { -- SCH Immanence properties
    [1] = { en = 'Fire', skillchain = { 'Liquefaction' } },
    [2] = { en = 'Ice', skillchain = { 'Induration' } },
    [3] = { en = 'Wind', skillchain = { 'Detonation' } },
    [4] = { en = 'Earth', skillchain = { 'Scission' } },
    [5] = { en = 'Lightning', skillchain = { 'Impaction' } },
    [6] = { en = 'Water', skillchain = { 'Reverberation' } },
    [7] = { en = 'Light', skillchain = { 'Transfixion' } },
    [8] = { en = 'Dark', skillchain = { 'Compression' } },
};

--=============================================================================
-- Addon Variables
--=============================================================================

local chains = T {
    debug = false,
    forceAeonic = 0,        -- set from 0 to 3
    forceImmanence = false, -- boolean
    forceAffinity = false,  -- boolean
};

-- store player ID
-- * capture on init
local playerID;

-- store list of valid player/pet skills
-- * capture bluskill on 0x44 packet or first GetSkillchains call
-- * capture wepskill on 0xAC packet or first GetSkillchains call
-- * capture petskill on 0xAC packet or first GetSkillchains call
-- * capture schskill on load
local actionTable = T {
    schskill = skills.immanence,
};

-- store per player buff information
-- * player/buff added through action packet
-- * buff deleted through action packet when used or through presentevent on timeout
-- * player deleted through present event when no buff active
local playerTable = T {
};

-- store per target information on properties and duration
-- * target added through action packet
-- * target deleted through present event on timeout
local targetTable = T {
};

-- static information on skillchains
local chainInfo = T {
    Radiance      = T { level = 4, burst = T { 'Fire', 'Wind', 'Lightning', 'Light' } },
    Umbra         = T { level = 4, burst = T { 'Earth', 'Ice', 'Water', 'Dark' } },
    Light         = T { level = 3, burst = T { 'Fire', 'Wind', 'Lightning', 'Light' },
        aeonic = T { level = 4, skillchain = 'Radiance' },
        Light  = T { level = 4, skillchain = 'Light' },
    },
    Darkness      = T { level = 3, burst = T { 'Earth', 'Ice', 'Water', 'Dark' },
        aeonic   = T { level = 4, skillchain = 'Umbra' },
        Darkness = T { level = 4, skillchain = 'Darkness' },
    },
    Gravitation   = T { level = 2, burst = T { 'Earth', 'Dark' },
        Distortion    = T { level = 3, skillchain = 'Darkness' },
        Fragmentation = T { level = 2, skillchain = 'Fragmentation' },
    },
    Fragmentation = T { level = 2, burst = T { 'Wind', 'Lightning' },
        Fusion     = T { level = 3, skillchain = 'Light' },
        Distortion = T { level = 2, skillchain = 'Distortion' },
    },
    Distortion    = T { level = 2, burst = T { 'Ice', 'Water' },
        Gravitation = T { level = 3, skillchain = 'Darkness' },
        Fusion      = T { level = 2, skillchain = 'Fusion' },
    },
    Fusion        = T { level = 2, burst = T { 'Fire', 'Light' },
        Fragmentation = T { level = 3, skillchain = 'Light' },
        Gravitation   = T { level = 2, skillchain = 'Gravitation' },
    },
    Compression   = T { level = 1, burst = T { 'Darkness' },
        Transfixion = T { level = 1, skillchain = 'Transfixion' },
        Detonation  = T { level = 1, skillchain = 'Detonation' },
    },
    Liquefaction  = T { level = 1, burst = T { 'Fire' },
        Impaction = T { level = 2, skillchain = 'Fusion' },
        Scission  = T { level = 1, skillchain = 'Scission' },
    },
    Induration    = T { level = 1, burst = T { 'Ice' },
        Reverberation = T { level = 2, skillchain = 'Fragmentation' },
        Compression   = T { level = 1, skillchain = 'Compression' },
        Impaction     = T { level = 1, skillchain = 'Impaction' },
    },
    Reverberation = T { level = 1, burst = T { 'Water' },
        Induration = T { level = 1, skillchain = 'Induration' },
        Impaction  = T { level = 1, skillchain = 'Impaction' },
    },
    Transfixion   = T { level = 1, burst = T { 'Light' },
        Scission      = T { level = 2, skillchain = 'Distortion' },
        Reverberation = T { level = 1, skillchain = 'Reverberation' },
        Compression   = T { level = 1, skillchain = 'Compression' },
    },
    Scission      = T { level = 1, burst = T { 'Earth' },
        Liquefaction  = T { level = 1, skillchain = 'Liquefaction' },
        Reverberation = T { level = 1, skillchain = 'Reverberation' },
        Detonation    = T { level = 1, skillchain = 'Detonation' },
    },
    Detonation    = T { level = 1, burst = T { 'Wind' },
        Compression = T { level = 2, skillchain = 'Gravitation' },
        Scission    = T { level = 1, skillchain = 'Scission' },
    },
    Impaction     = T { level = 1, burst = T { 'Lightning' },
        Liquefaction = T { level = 1, skillchain = 'Liquefaction' },
        Detonation   = T { level = 1, skillchain = 'Detonation' },
    },
};

-- IMGUI RGB color format {red, green, blue, alpha}
local colors = {};                             -- Color codes by Sammeh
colors.Light = { 1.0, 1.0, 1.0, 1.0 };         --'0xFFFFFFFF';
colors.Dark = { 0.0, 0.0, 0.8, 1.0 };          --'0x0000CCFF';
colors.Ice = { 0.0, 1.0, 1.0, 1.0 };           --'0x00FFFFFF';
colors.Water = { 0.0, 1.0, 1.0, 1.0 };         --'0x00FFFFFF';
colors.Earth = { 0.6, 0.5, 0.0, 1.0 };         --'0x997600FF';
colors.Wind = { 0.4, 1.0, 0.4, 1.0 };          --'0x66FF66FF';
colors.Fire = { 1.0, 0.0, 0.0, 1.0 };          --'0xFF0000FF';
colors.Lightning = { 1.0, 0.0, 1.0, 1.0 };     --'0xFF00FFFF';
colors.Gravitation = { 0.4, 0.2, 0.0, 1.0 };   --'0x663300FF';
colors.Fragmentation = { 1.0, 0.6, 1.0, 1.0 }; --'0xFA9CF7FF';
colors.Fusion = { 1.0, 0.4, 0.4, 1.0 };        --'0xFF6666FF';
colors.Distortion = { 0.2, 0.6, 1.0, 1.0 };    --'0x3399FFFF';
colors.Darkness = colors.Dark;
colors.Umbra = colors.Dark;
colors.Compression = colors.Dark;
colors.Radiance = colors.Light;
colors.Transfixion = colors.Light;
colors.Induration = colors.Ice;
colors.Reverberation = colors.Water;
colors.Scission = colors.Earth;
colors.Detonation = colors.Wind;
colors.Liquefaction = colors.Fire;
colors.Impaction = colors.Lightning;

local statusID = {
    AL  = 163, -- Azure Lore
    CA  = 164, -- Chain Affinity
    AM1 = 270, -- Aftermath: Lv.1
    AM2 = 271, -- Aftermath: Lv.2
    AM3 = 272, -- Aftermath: Lv.3
    IM  = 470  -- Immanence
};

local MessageTypes = T {
    2,   -- '<caster> casts <spell>. <target> takes <amount> damage'
    --100, -- 'The <player> uses ..' -- Causes Super Jump to match as Spinning Axe if enabled
    110, -- '<user> uses <ability>. <target> takes <amount> damage.'
    --161, -- Additional effect: <number> HP drained from <target>.
    --162, -- Additional effect: <number> MP drained from <target>.
    185, -- 'player uses, target takes 10 damage. DEFAULT'
    187, -- '<user> uses <skill>. <amount> HP drained from <target>'
    317, -- 'The <player> uses .. <target> takes .. points of damage.'
    --529, -- '<user> uses <ability>. <target> is chainbound.',
    802  -- 'The <user> uses <skill>. <number> HP drained from <target>.'
}

local PetMessageTypes = T {
    110, -- '<user> uses <ability>. <target> takes <amount> damage.'
    317  -- 'The <player> uses .. <target> takes .. points of damage.'
};

local ChainBuffTypes = T {
    [statusID.AL] = { duration = 30 }, -- 40 with relic hands
    [statusID.CA] = { duration = 30 },
    [statusID.IM] = { duration = 60 }
};

local EquipSlotNames = T {
    [1] = 'Main',
    --[2] = 'Sub',
    [3] = 'Range',
    --[4] = 'Ammo',
    --[5] = 'Head',
    --[6] = 'Body',
    --[7] = 'Hands',
    --[8] = 'Legs',
    --[9] = 'Feet',
    --[10] = 'Neck',
    --[11] = 'Waist',
    --[12] = 'Ear1',
    --[13] = 'Ear2',
    --[14] = 'Ring1',
    --[15] = 'Ring2',
    --[16] = 'Back'
};

local SkillPropNames = T {
    [1] = 'Light',
    [2] = 'Darkness',
    [3] = 'Gravitation',
    [4] = 'Fragmentation',
    [5] = 'Distortion',
    [6] = 'Fusion',
    [7] = 'Compression',
    [8] = 'Liquefaction',
    [9] = 'Induration',
    [10] = 'Reverberation',
    [11] = 'Transfixion',
    [12] = 'Scission',
    [13] = 'Detonation',
    [14] = 'Impaction',
    [15] = 'Radiance',
    [16] = 'Umbra'
};

--=============================================================================
-- Return count of requested buff. Return zero if buff is not active.
---@param matchBuff string Name of buff to check
---@return integer count
--=============================================================================
-- based on code from LuAshitacast by Thorny
--=============================================================================
local GetBuffCount = function(matchBuff)
    local count = 0;
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    if (type(matchBuff) == 'string') then
        local matchText = string.lower(matchBuff);
        for _, buff in pairs(buffs) do
            local buffString = AshitaCore:GetResourceManager():GetString("buffs.names", buff);
            if (buffString ~= nil) and (string.lower(buffString) == matchText) then
                count = count + 1;
            end
        end
    elseif (type(matchBuff) == 'number') then
        for _, buff in pairs(buffs) do
            if (buff == matchBuff) then
                count = count + 1;
            end
        end
    end
    return count;
end

--=============================================================================
-- Return equipment data
---@return table equipTable Current equipment information
--=============================================================================
-- based on code from LuAshitacast by Thorny
--=============================================================================
-- Combined gData.GetEquipment and gEquip.GetCurrentEquip
--=============================================================================
local GetEquipment = function()
    local inventoryManager = AshitaCore:GetMemoryManager():GetInventory();
    local equipTable = {};

    for k, v in pairs(EquipSlotNames) do
        local equippedItem = inventoryManager:GetEquippedItem(k - 1);
        local index = bit.band(equippedItem.Index, 0x00FF);
        local eqEntry = {};
        if (index == 0) then
            eqEntry.Container = 0;
            eqEntry.Item = nil;
        else
            eqEntry.Container = bit.band(equippedItem.Index, 0xFF00) / 256;
            eqEntry.Item = inventoryManager:GetContainerItem(eqEntry.Container, index);
            if (eqEntry.Item.Id == 0) or (eqEntry.Item.Count == 0) then
                eqEntry.Item = nil;
            end
        end
        if (type(eqEntry) == 'table') and (eqEntry.Item ~= nil) then
            local resource = AshitaCore:GetResourceManager():GetItemById(eqEntry.Item.Id);
            if (resource ~= nil) then
                local singleTable = {};
                singleTable.Container = eqEntry.Container;
                singleTable.Item = eqEntry.Item;
                singleTable.Name = resource.Name[1];
                singleTable.Resource = resource;
                equipTable[v] = singleTable;
            end
        end
    end

    return equipTable;
end

--=============================================================================
-- Return player data
---@return table playerTable Current player information
--=============================================================================
-- based on code from LuAshitacast by Thorny
--=============================================================================
local GetPlayer = function()
    local playerTable = {};
    local pParty = AshitaCore:GetMemoryManager():GetParty();
    local pPlayer = AshitaCore:GetMemoryManager():GetPlayer();

    local mainJob = pPlayer:GetMainJob();
    playerTable.MainJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", mainJob);
    playerTable.MainJobLevel = pPlayer:GetJobLevel(mainJob);
    playerTable.MainJobSync = pPlayer:GetMainJobLevel();
    playerTable.Name = pParty:GetMemberName(0);

    local subJob = pPlayer:GetSubJob();
    playerTable.SubJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", subJob);
    playerTable.SubJobLevel = pPlayer:GetJobLevel(subJob);
    playerTable.SubJobSync = pPlayer:GetSubJobLevel();
    playerTable.TP = pParty:GetMemberTP(0);

    return playerTable;
end

--=============================================================================
-- Return table with current weaponskill data
---@return table skillTable Currently available weapon skills
--=============================================================================
local GetWeaponskills = function()
    local skillTable = T {};
    local pPlayer = AshitaCore:GetMemoryManager():GetPlayer();

    for k, v in pairs(skills[3]) do
        if v and pPlayer:HasWeaponSkill(k) then
            skillTable:append(v);
        end
    end

    return skillTable;
end

--=============================================================================
-- Return table with current pet skill data
---@return table skillTable Currently available pet skills
--=============================================================================
local function GetPetskills()
    local skillTable = T {};
    local pPlayer = AshitaCore:GetMemoryManager():GetPlayer();

    for k, v in pairs(skills.playerPet) do
        if v and pPlayer:HasAbility(k + 512) then
            skillTable:append(v);
        end
    end

    return skillTable;
end

--=============================================================================
-- Define blu offset data for use by GetBluskills()
--=============================================================================
local blu = {
    offset = ffi.cast('uint32_t*',
        ashita.memory.find('FFXiMain.dll', 0, 'C1E1032BC8B0018D????????????B9????????F3A55F5E5B', 10, 0))
};

--=============================================================================
-- Returns the table of current set BLU spells.
---@return table skillTable The current set BLU spells.
--=============================================================================
-- based on code from blusets by Atom0s
--=============================================================================
function GetBluskills()
    local skillTable = T {};

    local ptr = ashita.memory.read_uint32(AshitaCore:GetPointerManager():Get('inventory'));
    if (ptr == 0) then
        return T {};
    end
    ptr = ashita.memory.read_uint32(ptr);
    if (ptr == 0) then
        return T {};
    end
    --local spellTable = T(ashita.memory.read_array((ptr + blu.offset[0]) + (blu.is_blu_main() and 0x04 or 0xA0), 0x14));
    local spellTable = T(ashita.memory.read_array((ptr + blu.offset[0]) + 0x04, 0x14));

    for _, v in pairs(spellTable) do
        if skills[4][v + 512] then
            skillTable:append(skills[4][v + 512]);
        end
    end

    return skillTable;
end

--=============================================================================
---Return current aftermath level
---@return integer
--=============================================================================
local GetAftermathLevel = function()
    return GetBuffCount(statusID.AM1) + 2 * GetBuffCount(statusID.AM2) + 3 * GetBuffCount(statusID.AM3) +
        chains.forceAeonic;
end

--=============================================================================
---Return action property table with aeonic property added
---@param action table Action information
---@param actor integer Actor ID
---@return table propertyTable Updated property table
--=============================================================================
local GetAeonicProperty = function(action, actor)
    local propertyTable = table.copy(action.skillchain);

    if action.aeonic and (action.weapon or chains.forceAeonic > 0) and actor == playerID and GetAftermathLevel() > 0 then
        local main = GetEquipment().Main;
        local range = GetEquipment().Range;
        local validMain = action.weapon == (main and main.Name) or chains.forceAeonic > 0;
        local validRange = action.weapon == (range and range.Name);
        if validMain or validRange then
            table.insert(propertyTable, 1, action.aeonic);
        end
    end

    return propertyTable;
end

--=============================================================================
-- Return formatted table of valid skillchain options
---@param target number ServerID of target
---@return table chainTable Current skillchain options
--=============================================================================
local GetSkillchains = function(target)
    local actions = T {};
    local chainTable = T {};
    local levelTable = T { {}, {}, {}, {} };

    local mainJob = GetPlayer().MainJob;
    local enableSCH = mainJob == 'SCH' and ((playerTable[playerID] and playerTable[playerID][statusID.IM]) or
        chains.forceImmanence);
    local enableBLU = mainJob == 'BLU' and ((playerTable[playerID] and playerTable[playerID][statusID.AL]) or
        (playerTable[playerID] and playerTable[playerID][statusID.CA]) or
        chains.forceAffinity);

    -- Create weaponskill table if it does not already exist
    -- Will update through incoming 0xAC packets
    if not actionTable.wepskill then
        actionTable.wepskill = GetWeaponskills();
    end

    -- Create petskill table if it does not already exist
    -- Will update through incoming 0xAC packets
    if T { 'BST', 'SMN' }:contains(mainJob) and not actionTable.petskill then
        actionTable.petskill = GetPetskills();
    end

    -- Create bluskill table if it does not already exist
    -- Will update through incoming 0x44 packets
    if mainJob == 'BLU' and not actionTable.bluskill then
        actionTable.bluskill = GetBluskills();
    end

    -- Initialize actions with weaponskills
    if chains.settings.display.weapon then
        actions = actions:extend(actionTable.wepskill);
    end

    -- Add skill tables based on job and active buffs
    if chains.settings.display.pet and mainJob:any('BST', 'SMN') and actionTable.petskill then
        actions = actions:extend(actionTable.petskill);
    elseif chains.settings.display.spell and enableBLU and actionTable.bluskill then
        actions = actions:extend(actionTable.bluskill);
    elseif chains.settings.display.spell and enableSCH and actionTable.schskill then
        actions = actions:extend(actionTable.schskill);
    end

    -- Search for valid skillchains and store into a table per skillchain level
    -- iterate over current abilities
    for _, action in pairs(actions) do
        -- insert aeonic property
        local actionProperty = GetAeonicProperty(action, playerID);

        -- iterate over 1st property (target property)
        for _, prop1 in pairs(target.property) do
            local match = nil;

            -- iterate over 2nd property (action property) and exit after first match
            for _, prop2 in pairs(actionProperty) do
                match = chainInfo[prop1][prop2];
                if match then break end
            end

            -- store first match and exit
            if match then
                -- check for ultimate skillchain
                local checkAeonic = chainInfo[prop1].level == 3 and (target.step + GetAftermathLevel()) >= 4;
                if checkAeonic and chainInfo[prop1]['aeonic'] then
                    match = chainInfo[prop1]['aeonic'];
                end

                -- add skillchain information to table
                local skillchain = {
                    outText = ('%-17s>> Lv.%d'):fmt(action.en, match.level),
                    outProp = match.skillchain,
                }
                table.insert(levelTable[match.level], skillchain);
                break;
            end;
        end
    end

    -- Sort results to a single table based on skillchain level
    for x = 4, 1, -1 do
        for _, v in pairs(levelTable[x]) do
            table.insert(chainTable, v);
        end
    end

    return chainTable;
end

--=============================================================================
-- Reset stored skillchain lists for each active target
-- This would trigger on weapon, ability and pet changes
--=============================================================================
local function ResetSkillchains()
    for _, v in pairs(targetTable) do
        v.skillchains = nil;
    end
end

--=============================================================================
-- Return true if another player belongs to the player's alliance.
---@param id number ServerId
---@return boolean
--=============================================================================
local function isPlayerInAlliance(id)
    local pParty = AshitaCore:GetMemoryManager():GetParty();

    for i = 0, 17 do
        if pParty:GetMemberIsActive(i) == 1 and pParty:GetMemberServerId(i) == id then
            return true
        end
    end

    return false
end

--=============================================================================
-- Return true if a pet belongs to the player's alliance.
---@param id number ServerId
---@return boolean
--=============================================================================
local function isPetInAlliance(id)
    local pParty = AshitaCore:GetMemoryManager():GetParty();
    local pEntity = AshitaCore:GetMemoryManager():GetEntity();

    for i = 0, 17 do
        if pParty:GetMemberIsActive(i) == 1 then
            local playerIndex = pParty:GetMemberTargetIndex(i);
            local petIndex = pEntity:GetPetTargetIndex(playerIndex);
            if pEntity:GetServerId(petIndex) == id then
                return true;
            end
        end
    end

    return false
end

--=============================================================================
-- Print formatted error information
--=============================================================================
-- Copied from tHotBar by Thorny as part of ParseActionPacket
--=============================================================================
local function Error(text)
    local color = ('\30%c'):format(68);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end

--=============================================================================
-- Return action packet data in a table format
---@param e table Incoming packet table
---@return table pendingActionPacket Parsed action packet table
--=============================================================================
-- Based on code from tHotBar by Thorny
-- https://github.com/Windower/Lua/blob/dev/addons/libs/packets/data.lua
-- https://github.com/Windower/Lua/blob/dev/addons/libs/packets/fields.lua
--=============================================================================
local function ParseActionPacket(e)
    local bitData;
    local bitOffset;
    local maxLength = e.size * 8;

    local function UnpackBits(length)
        if ((bitOffset + length) > maxLength) then
            maxLength = 0; --Using this as a flag since any malformed fields mean the data is trash anyway.
            return 0;
        end
        local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
        bitOffset = bitOffset + length;
        return value;
    end

    local pendingActionPacket = T {};
    bitData = e.data_raw;
    bitOffset = 40;

    pendingActionPacket.UserId = UnpackBits(32);
    local targetCount = UnpackBits(6);
    bitOffset = bitOffset + 4;               --Unknown 4 bits
    pendingActionPacket.Type = UnpackBits(4);
    pendingActionPacket.Id = UnpackBits(32); --{unknown[15:0], param[15:0]}
    bitOffset = bitOffset + 32;              --Unknown 32 bits --{recast[31:0]}?

    pendingActionPacket.Targets = T {};
    for i = 1, targetCount do
        local target = T {};
        target.Id = UnpackBits(32);
        local actionCount = UnpackBits(4);
        target.Actions = T {};
        for j = 1, actionCount do
            local action = {};
            action.Reaction = UnpackBits(5);
            action.Animation = UnpackBits(12);
            action.SpecialEffect = UnpackBits(7);
            action.Knockback = UnpackBits(3);
            action.Param = UnpackBits(17);
            action.Message = UnpackBits(10);
            action.Flags = UnpackBits(31);

            local hasAdditionalEffect = (UnpackBits(1) == 1);
            if hasAdditionalEffect then
                local additionalEffect = {};
                additionalEffect.Damage = UnpackBits(10); --{effect[3:0],animation[5:0]}
                additionalEffect.Param = UnpackBits(17);
                additionalEffect.Message = UnpackBits(10);
                action.AdditionalEffect = additionalEffect;
            end

            local hasSpikesEffect = (UnpackBits(1) == 1);
            if hasSpikesEffect then
                local spikesEffect = {};
                spikesEffect.Damage = UnpackBits(10); --{effect[3:0],animation[5:0]}
                spikesEffect.Param = UnpackBits(14);
                spikesEffect.Message = UnpackBits(10);
                action.SpikesEffect = spikesEffect;
            end

            target.Actions:append(action);
        end
        pendingActionPacket.Targets:append(target);
    end

    if (maxLength == 0) then
        Error(string.format('Malformed action packet detected.  Type:$H%u$R User:$H%u$R Targets:$H%u$R',
            pendingActionPacket.Type, pendingActionPacket.UserId, #pendingActionPacket.Targets));
        pendingActionPacket.Targets = T {}; --Blank targets so that it doesn't register bad info later.
    end

    return pendingActionPacket;
end

local load_cb = 'load_cb' .. tostring {}; -- Unique cb handle
--=============================================================================
-- event: load
-- desc: Event called when the addon is being loaded.
--=============================================================================
ashita.events.register('load', load_cb, function()
    playerID = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
end);

local packet_in_cb = 'packet_in_cb' .. tostring {}; -- Unique cb handle
--=============================================================================
-- event: packet_in
-- desc: Event called when the addon is processing incoming packets.
--=============================================================================
ashita.events.register('packet_in', packet_in_cb, function(e)
    --[[ Valid Arguments
        e.id                 - (ReadOnly) The id of the packet.
        e.size               - (ReadOnly) The size of the packet.
        e.data               - (ReadOnly) The data of the packet.
        e.data_raw           - The raw data pointer of the packet. (Use with FFI.)
        e.data_modified      - The modified data.
        e.data_modified_raw  - The modified raw data. (Use with FFI.)
        e.chunk_size         - The size of the full packet chunk that contained the packet.
        e.chunk_data         - The data of the full packet chunk that contained the packet.
        e.chunk_data_raw     - The raw data pointer of the full packet chunk that contained the packet. (Use with FFI.)
        e.injected           - (ReadOnly) Flag that states if the packet was injected by Ashita or an addon/plugin.
        e.blocked            - Flag that states if the packet has been, or should be, blocked.
    --]]

    -- Action
    --[[ actionPacket.Type
        [1] = 'Melee attack',
        [2] = 'Ranged attack finish',
        [3] = 'Weapon Skill finish',
        [4] = 'Casting finish',
        [5] = 'Item finish',
        [6] = 'Job Ability',
        [7] = 'Weapon Skill start',
        [8] = 'Casting start',
        [9] = 'Item start',
        [11] = 'NPC TP finish',
        [12] = 'Ranged attack start',
        [13] = 'Avatar TP finish',
        [14] = 'Job Ability DNC',
        [15] = 'Job Ability RUN',
    --]]
    if e.id == 0x28 then
        -- Save a little bit of processing for packets that won't relate to SC..
        local type = ashita.bits.unpack_be(e.data_raw, 82, 4); -- byte: 0xA, bit: 0x2
        if not T { 3, 4, 6, 11, 13, 14 }:contains(type) then
            return;
        end

        local actionPacket = ParseActionPacket(e);

        -- Only the primary target and action are parsed assuming that is all that apply
        local actor = actionPacket.UserId;
        local target = actionPacket.Targets[1];

        -- exit if target is nil due to corrupted packet
        if not target then
            return;
        end

        local targetAction = target.Actions[1];

        -- Overload packet type for pet actions (?)
        -- Prevents Weapon Bash from matching as an actionSkill
        local category = PetMessageTypes:contains(targetAction.Message) and 13 or actionPacket.Type;

        -- capture valid action skill and added effect property if there is a match
        local actionSkill = skills[category] and skills[category][bit.band(actionPacket.Id, 0xFFFF)];
        local effectProperty = targetAction.AdditionalEffect and
            SkillPropNames[bit.band(targetAction.AdditionalEffect.Damage, 0x3F)];

        --debug ===============================================================
        if chains.debug and T { 3, 6, 13, 14 }:contains(actionPacket.Type) then
            local out = ('Type: %s -> %s, Id: %s'):fmt(actionPacket.Type, category, actionPacket.Id);
            if actionSkill then
                out = out .. (' Skill: %s'):fmt(actionSkill.en);
            end
            print(chat.header('0x28'):append(chat.error(out)));
            if targetAction then
                out = ('Action Message: %s'):fmt(targetAction.Message);
                if targetAction.AdditionalEffect then
                    out = out .. (' Effect: %s'):fmt(targetAction.AdditionalEffect.Damage);
                end
                if effectProperty then
                    out = out .. (' Property: %s'):fmt(effectProperty);
                end
            end
            print(chat.header('0x28'):append(chat.error(out)));
        end
        --=====================================================================

        -- exit if actor is not in alliance
        if not (isPlayerInAlliance(actor) or isPetInAlliance(actor)) then
            return;
        end

        -- Check for valid action skill with valid added effect propery - after first setp
        if actionSkill and effectProperty then
            local step = (targetTable[target.Id] and targetTable[target.Id].step or 1) + 1
            local delay = actionSkill and actionSkill.delay or 3
            local level = chainInfo[effectProperty].level

            -- Check for Lv.3 -> Lv.3 and bump to Lv.4 for closure
            if level == 3 and targetTable[target.Id] and targetTable[target.Id].property[1] == effectProperty and actionSkill.skillchain and actionSkill.skillchain[1] == effectProperty then
                level = 4;
            end
            local closed = level == 4;

            targetTable[target.Id] = {
                en = actionSkill.en,
                property = { effectProperty },
                ts = os.time(),
                dur = 8 - step + delay,
                wait = delay,
                step = step,
                closed = closed,
            };

            -- Check for valid actor skill with valid message - generic first step (excluding chainbound)
            -- Include spells when SCH Immanence or BLU Azure Lore / Chain Affinity is active
            -- Immanence and Chain Affinity buff status cleared on use
        elseif actionSkill and MessageTypes:contains(targetAction.Message) and (actionPacket.Type ~= 4 or (playerTable[actor])) then
            local delay = actionSkill and actionSkill.delay or 3
            targetTable[target.Id] = {
                en = actionSkill.en,
                property = GetAeonicProperty(actionSkill, actor),
                ts = os.time(),
                dur = 7 + delay,
                wait = delay,
                step = 1,
            };

            -- Check for valid actor skill with chainbound message - chainbound first step
            -- Could be combined with previous first setp check
        elseif actionSkill and (targetAction.Message == 529) then
            targetTable[target.Id] = {
                en = actionSkill.en,
                property = actionSkill.skillchain,
                ts = os.time(),
                dur = 9,
                wait = 2,
                step = 1,
                bound = targetAction.Param,
            };
        end

        -- Clear out used spell abilities
        if actionSkill and actionPacket.Type == 4 and playerTable[actor] then
            local buffID = playerTable[actor][statusID.CA] and statusID.CA or
                playerTable[actor][statusID.IM] and statusID.IM;
            if buffID then
                playerTable[actor][buffID] = nil;
            end
        end

        -- Capture buff information for each player
        if actionPacket.Type == 6 and ChainBuffTypes:containskey(targetAction.Param) then
            playerTable[actor] = playerTable[actor] or {};
            playerTable[actor][targetAction.Param] = os.time() + ChainBuffTypes[targetAction.Param].duration;
        end

        -- Action Message - Clear buff when getting '206 - ${target}'s ${status} effect wears off'.
        --  only works to clear local player
    elseif e.id == 0x29 and struct.unpack('H', e.data, 0x18 + 1) == 206 and struct.unpack('I', e.data, 8 + 1) == playerID then
        local effect = struct.unpack('H', e.data, 0xC + 1)
        if playerTable[playerID] and playerTable[playerID][effect] then
            playerTable[playerID][effect] = nil;
        end

        -- Character Abilities (Weaponskills and BST/SMN PetSkills)
    elseif e.id == 0x0AC then --and e.data:sub(5) ~= actionTable.lastAC then
        actionTable.wepskill = T {};
        actionTable.petskill = T {};

        -- Packet contains one bit per ability to indicate if the ability is available
        -- * Byte in packet = floor(abilityID / 8) + 1
        -- * Bit in byte = abilityID % 8
        -- Logic does the following:
        -- * extract byte
        -- * shift bits right to move relavent bit to bit[0]
        -- * mask upper bits and compare to 1 (or >0)
        -- * alt equation: bit.band(bit.rshift(data:byte(math.floor(k/8)+1),(k%8)),0x01) == 1

        -- Weaponskills
        local data = e.data:sub(5);
        for k, v in pairs(skills[3]) do
            if math.floor((data:byte(math.floor(k / 8) + 1) % 2 ^ (k % 8 + 1)) / 2 ^ (k % 8)) == 1 then
                table.insert(actionTable.wepskill, v);
            end
        end

        -- BST/SMN PetSkills - fix: skip if not BST or SMN?
        data = e.data:sub(69);
        for k, v in pairs(skills.playerPet) do
            if math.floor((data:byte(math.floor(k / 8) + 1) % 2 ^ (k % 8 + 1)) / 2 ^ (k % 8)) == 1 then
                table.insert(actionTable.petskill, v);
            end
        end

        -- Reset skillchains on all active targets
        ResetSkillchains();

        --actionTable.lastAC = e.data:sub(5); --dedupe?

        -- BLU spells - e.data:byte(5) == 0x10 indicates BLU, e.data:byte(6) == 0 indicates main job
    elseif e.id == 0x44 and e.data:byte(5) == 0x10 and e.data:byte(6) == 0 then -- and e.data:sub(9, 18) ~= actionTable.last44 then
        actionTable.bluskill = T {};

        --Iterate through bytes 8+1 through 27+1 - corresponds to the 20 BLU spell slots
        for x = 8 + 1, 27 + 1 do
            local match = skills[4][e.data:byte(x) + 512]
            if match then
                table.insert(actionTable.bluskill, match);
            end
        end

        --actionTable.last44 = e.data:sub(9, 18); --dedupe?
    end
end);

local function resultOfWs(targetId, wsName)
    local target = targetTable[targetId];

    if (not target) then
        return;
    end

    local mainJob = GetPlayer().MainJob;
    local enableSCH = mainJob == 'SCH' and ((playerTable[playerID] and playerTable[playerID][statusID.IM]) or
        chains.forceImmanence);
    local enableBLU = mainJob == 'BLU' and ((playerTable[playerID] and playerTable[playerID][statusID.AL]) or
        (playerTable[playerID] and playerTable[playerID][statusID.CA]) or
        chains.forceAffinity);

    local res = AshitaCore:GetResourceManager():GetAbilityByName(wsName, 2);

    local action
    if (not res) then
        if (enableSCH or enableBLU) then
            res = AshitaCore:GetResourceManager():GetSpellByName(wsName, 2);

            if (not res) then
                return;
            end

            action = skills[4][res.Id];
        end

        return;
    else
        action = skills[3][res.Id];
    end

    local actionProperty = GetAeonicProperty(action, playerID);

    for _, prop1 in pairs(target.property) do
        local match = nil;

        for _, prop2 in pairs(actionProperty) do
            match = chainInfo[prop1][prop2];
            if (match) then break; end
        end

        if (match) then
            -- check for ultimate skillchain
            local checkAeonic = chainInfo[prop1].level == 3 and (target.step + GetAftermathLevel()) >= 4;
            if checkAeonic and chainInfo[prop1]['aeonic'] then
                match = chainInfo[prop1]['aeonic'];
            end


            return match.skillchain;
        end
    end
end

local function getChain(targetId)
    local now = os.time();

    -- Remove stale playerTable entries
    for pk, pv in pairs(playerTable) do
        for bk, bv in pairs(playerTable[pk]) do
            if now > bv then
                playerTable[pk][bk] = nil;
            end
        end
        if table.length(pv) == 0 then
            playerTable[pk] = nil;
        end
    end

    -- Remove stale targetTable entries
    for k, v in pairs(targetTable) do
        if v.ts and now - v.ts > 10 then
            targetTable[k] = nil;
        end
    end

    local hasChain = targetId ~= nil and targetTable[targetId] and
        targetTable[targetId].dur - (now - targetTable[targetId].ts) > 0;

    if (not hasChain) then
        return;
    end

    local timediff = now - targetTable[targetId].ts; -- Time since last ws

    local chain = T {};

    if (targetTable[targetId].closed) then
        chain.status = 'closed';
    elseif (timediff < targetTable[targetId].wait) then
        chain.status = 'wait';
    else
        chain.status = 'open';
    end

    chain.waitTimer = targetTable[targetId].ts + targetTable[targetId].wait;
    chain.chainTimer = targetTable[targetId].ts + targetTable[targetId].dur;

    if (targetTable[targetId].step > 1) then
        chain.burstTimer = targetTable[targetId].ts + 10;
        chain.burstElements = chainInfo[targetTable[targetId].property[1]].burst;
    else
        chain.burstTimer = 0;
    end

    chain.properties = targetTable[targetId].property;

    chain.resultOfWs = function(wsName)
        return resultOfWs(targetId, wsName);
    end

    -- Need to return:
    --   Properties
    --   Elements
    --   Status
    --   waitTimer
    --   chainTimer
    --   burstTimer

    return chain;
end

return getChain;
