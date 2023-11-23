local nas = T {
    T {
        spellName = 'Cursna',
        debuffs = { 'Curse', 'Doom' }
    },
    T {
        spellName = 'Stona',
        debuffs = { 'Petrification' }
    },
    T {
        spellName = 'Paralyna',
        debuffs = { 'Paralysis' }
    },
    T {
        spellName = 'Cure',
        debuffs = { 'Sleep' }
    },
    T {
        spellName = 'Blindna',
        debuffs = { 'Blindness' }
    },
    T {
        spellName = 'Poisona',
        debuffs = { 'Poison' }
    },
    T {
        spellName = 'Silena',
        debuffs = { 'Silence' }
    },
    T {
        spellName = 'Viruna',
        debuffs = { 'Disease', 'Plague' }
    },
    T {
        spellName = 'Erase',
        debuffs = {
            'Bio',
            'Dia',
            'Weight',
            'Bind',
            'Shock',
            'Rasp',
            'Choke',
            'Frost',
            'Burn',
            'Drown',
            'Elegy',
            'Slow',
            'Requiem',
            'Addle',
            'STR Down',
            'DEX Down',
            'VIT Down',
            'AGI Down',
            'INT Down',
            'MND Down',
            'CHR Down',
            'Max HP Down',
            'Max MP Down',
            'Accuracy Down',
            'Attack Down',
            'Evasion Down',
            'Flash',
            'Magic Acc Down',
            'Magic Atk Down',
            'Helix',
            'Max TP Down',
            'Lullaby'
        }
    }
};

for _, v in ipairs(nas) do
    v.spell = AshitaCore:GetResourceManager():GetSpellByName(v.spellName, 2);
    for i, u in ipairs(v.debuffs) do
        v.debuffs[i] = string.lower(u);
    end
end

return nas;
