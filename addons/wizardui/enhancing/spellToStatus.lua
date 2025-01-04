return setmetatable({
    Baramnesra = 'Baramnesia',
    Barpoisonra = 'Barpoison',
    Barsleepra = 'Barsleep',
    Barpetra = 'Barpetrify',
    Barsilencera = 'Barsilence',
    Barparalyzra = 'Barparalyze',
    Barblindra = 'Barblind',

    Barfira = 'Barfire',
    Barwatera = 'Barwater',
    Barthundra = 'Barthunder',
    Barstonra = 'Barstone',
    Baraera = 'Baraero',
    Barblizzara = 'Barblizzard',

    Protectra = 'Protect',
    Shellra = 'Shell',

    Adloquium = 'Regain',
    Crusade = 'Enmity Boost',
    Temper = 'Multi Strikes',

    Cocoon = 'Defense Boost',
    Reprisal = 'Reprisal',
    Phalanx = 'Phalanx',
    Aquaveil = 'Aquaveil',
    Stoneskin = 'Stoneskin',
    Blink = 'Blink',
    Foil = 'Foil',

    ['Boost-STR'] = 'STR Boost',
    ['Boost-MND'] = 'MND Boost',
    ['Boost-DEX'] = 'DEX Boost',
    ['Boost-VIT'] = 'VIT Boost',
    ['Boost-AGI'] = 'AGI Boost',
    ['Boost-INT'] = 'INT Boost',
    ['Boost-CHR'] = 'CHR Boost',

    ['Gain-STR'] = 'STR Boost',
    ['Gain-MND'] = 'MND Boost',
    ['Gain-DEX'] = 'DEX Boost',
    ['Gain-VIT'] = 'VIT Boost',
    ['Gain-AGI'] = 'AGI Boost',
    ['Gain-INT'] = 'INT Boost',
    ['Gain-CHR'] = 'CHR Boost',
}, {
    __index = function(t,k)
        return k
     end
});