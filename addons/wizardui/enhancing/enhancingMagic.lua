local enhancingMagic = T {
    ['Aurorastorm'] = { 'Aurorastorm II', 'Auororastorm' },
    ['Firestorm'] = { 'Firestorm II', 'Firestorm' },
    ['Flurry'] = { 'Flurry II', 'Flurry' },
    ['Hailstorm'] = { 'Hailstorm II', 'Hailstorm' },
    ['Haste'] = { 'Haste II', 'Haste' },
    ['Phalanx'] = { 'Phalanx II', 'Phalanx' },
    ['Protect'] = { 'Protect V', 'Protect IV', 'Protect III', 'Protect II', 'Protect' },
    ['Protectra'] = { 'Protectra V', 'Protectra IV', 'Protectra III', 'Protectra II', 'Protectra' },
    ['Rainstorm'] = { 'Rainstorm II', 'Rainstorm' },
    ['Refresh'] = { 'Refresh III', 'Refresh II', 'Refresh' },
    ['Regen'] = { 'Regen V', 'Regen IV', 'Regen III', 'Regen II', 'Regen' },
    ['Sandstorm'] = { 'Sandstorm II', 'Sandstorm' },
    ['Shell'] = { 'Shell V', 'Shell IV', 'Shell III', 'Shell II', 'Shell' },
    ['Shellra'] = { 'Shellra V', 'Shellra IV', 'Shellra III', 'Shellra II', 'Shellra' },
    ['Temper'] = { 'Temper II', 'Temper' },
    ['Windstorm'] = { 'Windstorm II', 'Windstorm' },
};

enhancingMagic = setmetatable(enhancingMagic, {
    __index = function(t, k)
        t[k] = { k };
        return t[k];
    end
});

return enhancingMagic;
