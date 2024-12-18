local rollsByName = T {
    ['Snake Eye'] = T {
        en = 'Snake Eye',
        id = 197,
        param = 177,
    },
    ['Double-Up'] = T {
        en = 'Double-Up',
        id = 194,
        param = 123,
    },
    ['Random Deal'] = T {
        en = 'Random Deal',
        id = 196,
        param = 133,
    },
    ['Fold'] = T {
        en = 'Fold',
        id = 198,
        param = 178,
    },
    ['Crooked Cards'] = T {
        en = 'Crooked Cards',
        id = 96,
        param = 392,
    },
    -- Phantom rolls
    ['Fighter\'s Roll'] = T {
        en = 'Fighter\'s Roll',
        id = 193,
        param = 98,
        lucky = 5,
        unlucky = 9,
    },
    ['Monk\'s Roll'] = T {
        en = 'Monk\'s Roll',
        id = 193,
        param = 99,
        lucky = 3,
        unlucky = 7,
    },
    ['Healer\'s Roll'] = T {
        en = 'Healer\'s Roll',
        id = 193,
        param = 100,
        lucky = 3,
        unlucky = 7,
    },
    ['Wizard\'s Roll'] = T {
        en = 'Wizard\'s Roll',
        id = 193,
        param = 101,
        lucky = 5,
        unlucky = 9,
    },
    ['Warlock\'s Roll'] = T {
        en = 'Warlock\'s Roll',
        id = 193,
        param = 102,
        lucky = 4,
        unlucky = 8,
    },
    ['Rogue\'s Roll'] = T {
        en = 'Rogue\'s Roll',
        id = 193,
        param = 103,
        lucky = 5,
        unlucky = 9,
    },
    ['Gallant\'s Roll'] = T {
        en = 'Gallant\'s Roll',
        id = 193,
        param = 104,
        lucky = 3,
        unlucky = 7,
    },
    ['Chaos Roll'] = T {
        en = 'Chaos Roll',
        id = 193,
        param = 105,
        lucky = 4,
        unlucky = 8,
    },
    ['Beast Roll'] = T {
        en = 'Beast Roll',
        id = 193,
        param = 106,
        lucky = 4,
        unlucky = 8,
    },
    ['Choral Roll'] = T {
        en = 'Choral Roll',
        id = 193,
        param = 107,
        lucky = 2,
        unlucky = 6,
    },
    ['Hunter\'s Roll'] = T {
        en = 'Hunter\'s Roll',
        id = 193,
        param = 108,
        lucky = 4,
        unlucky = 8,
    },
    ['Samurai Roll'] = T {
        en = 'Samurai Roll',
        id = 193,
        param = 109,
        lucky = 2,
        unlucky = 6,
    },
    ['Ninja Roll'] = T {
        en = 'Ninja Roll',
        id = 193,
        param = 110,
        lucky = 4,
        unlucky = 8,
    },
    ['Drachen Roll'] = T {
        en = 'Drachen Roll',
        id = 193,
        param = 111,
        lucky = 4,
        unlucky = 8,
    },
    ['Evoker\'s Roll'] = T {
        en = 'Evoker\'s Roll',
        id = 193,
        param = 112,
        lucky = 5,
        unlucky = 9,
    },
    ['Magus\'s Roll'] = T {
        en = 'Magus\'s Roll',
        id = 193,
        param = 113,
        lucky = 2,
        unlucky = 6,
    },
    ['Corsair\'s Roll'] = T {
        en = 'Corsair\'s Roll',
        id = 193,
        param = 114,
        lucky = 5,
        unlucky = 9,
    },
    ['Puppet Roll'] = T {
        en = 'Puppet Roll',
        id = 193,
        param = 115,
        lucky = 3,
        unlucky = 7,
    },
    ['Dancer\'s Roll'] = T {
        en = 'Dancer\'s Roll',
        id = 193,
        param = 116,
        lucky = 3,
        unlucky = 7,
    },
    ['Scholar\'s Roll'] = T {
        en = 'Scholar\'s Roll',
        id = 193,
        param = 117,
        lucky = 2,
        unlucky = 6,
    },
    ['Bolter\'s Roll'] = T {
        en = 'Bolter\'s Roll',
        id = 193,
        param = 118,
        lucky = 3,
        unlucky = 9,
    },
    ['Caster\'s Roll'] = T {
        en = 'Caster\'s Roll',
        id = 193,
        param = 119,
        lucky = 2,
        unlucky = 7,
    },
    ['Courser\'s Roll'] = T {
        en = 'Courser\'s Roll',
        id = 193,
        param = 120,
        lucky = 3,
        unlucky = 9,
    },
    ['Blitzer\'s Roll'] = T {
        en = 'Blitzer\'s Roll',
        id = 193,
        param = 121,
        lucky = 4,
        unlucky = 9,
    },
    ['Tactician\'s Roll'] = T {
        en = 'Tactician\'s Roll',
        id = 193,
        param = 122,
        lucky = 5,
        unlucky = 8,
    },
    ['Naturalist\'s Roll'] = T {
        en = 'Naturalist\'s Roll',
        id = 193,
        param = 390,
        lucky = 3,
        unlucky = 7,
    },
    ['Runeist\'s Roll'] = T {
        en = 'Runeist\'s Roll',
        id = 193,
        param = 391,
        lucky = 4,
        unlucky = 8,
    },
    ['Allies\' Roll'] = T {
        en = 'Allies\' Roll',
        id = 193,
        param = 302,
        lucky = 3,
        unlucky = 10,
    },
    ['Miser\'s Roll'] = T {
        en = 'Miser\'s Roll',
        id = 193,
        param = 303,
        lucky = 5,
        unlucky = 7,
    },
    ['Companion\'s Roll'] = T {
        en = 'Companion\'s Roll',
        id = 193,
        param = 304,
        lucky = 2,
        unlucky = 10,
    },
    ['Avenger\'s Roll'] = T {
        en = 'Avenger\'s Roll',
        id = 193,
        param = 305,
        lucky = 4,
        unlucky = 8,
    },
};

local rollsByParam = T {};

for k, v in pairs(rollsByName) do
    rollsByParam[v.param] = v;
end

return { rollsByName = rollsByName, rollsByParam = rollsByParam };
