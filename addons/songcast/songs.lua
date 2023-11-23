local songTypes = T {
    ['Foe Requiem'] = 'Requiem',
    ['Foe Requiem II'] = 'Requiem',
    ['Foe Requiem III'] = 'Requiem',
    ['Foe Requiem IV'] = 'Requiem',
    ['Foe Requiem V'] = 'Requiem',
    ['Foe Requiem VI'] = 'Requiem',
    ['Foe Requiem VII'] = 'Requiem',
    ['Foe Requiem VIII'] = 'Requiem',

    ['Horde Lullaby'] = 'Lullaby',
    ['Horde Lullaby II'] = 'Lullaby',
    ['Foe Lullaby'] = 'Lullaby',
    ['Foe Lullaby II'] = 'Lullaby',

    ['Army\'s Paeon'] = 'Paeon',
    ['Army\'s Paeon II'] = 'Paeon',
    ['Army\'s Paeon III'] = 'Paeon',
    ['Army\'s Paeon IV'] = 'Paeon',
    ['Army\'s Paeon V'] = 'Paeon',
    ['Army\'s Paeon VI'] = 'Paeon',
    ['Army\'s Paeon VII'] = 'Paeon',
    ['Army\'s Paeon VIII'] = 'Paeon',

    ['Mage\'s Ballad'] = 'Ballad',
    ['Mage\'s Ballad II'] = 'Ballad',
    ['Mage\'s Ballad III'] = 'Ballad',

    ['Knight\'s Minne'] = 'Minne',
    ['Knight\'s Minne II'] = 'Minne',
    ['Knight\'s Minne III'] = 'Minne',
    ['Knight\'s Minne IV'] = 'Minne',
    ['Knight\'s Minne V'] = 'Minne',

    ['Valor Minuet'] = 'Minuet',
    ['Valor Minuet II'] = 'Minuet',
    ['Valor Minuet III'] = 'Minuet',
    ['Valor Minuet IV'] = 'Minuet',
    ['Valor Minuet V'] = 'Minuet',

    ['Sword Madrigal'] = 'Madrigal',
    ['Blade Madrigal'] = 'Madrigal',

    ['Hunter\'s Prelude'] = 'Prelude',
    ['Archer\'s Prelude'] = 'Prelude',

    ['Sheepfoe Mambo'] = 'Mambo',
    ['Dragonfoe Mambo'] = 'Mambo',

    ['Fowl Aubade'] = 'Aubade',

    ['Herb Pastoral'] = 'Pastoral',

    ['Chocobo Hum'] = 'Hum',

    ['Shining Fantasia'] = 'Fantasia',

    ['Scop\'s Operetta'] = 'Operetta',
    ['Puppet\'s Operetta'] = 'Operetta',
    ['Jester\'s Operetta'] = 'Operetta',

    ['Gold Capriccio'] = 'Capriccio',

    ['Devotee Serenade'] = 'Serenade',

    ['Warding Round'] = 'Round',

    ['Goblin Gavotte'] = 'Gavotte',

    ['Cactaur Fugue'] = 'Fugue',

    ['Honor March'] = 'March',
    ['Advancing March'] = 'March',
    ['Victory March'] = 'March',

    ['Aria of Passion'] = 'Aria',

    ['Battlefield Elegy'] = 'Elegy',
    ['Carnage Elegy'] = 'Elegy',
    ['Massacre Elegy'] = 'Elegy',

    ['Sinewy Etude'] = 'Etude',
    ['Dextrous Etude'] = 'Etude',
    ['Vivacious Etude'] = 'Etude',
    ['Quick Etude'] = 'Etude',
    ['Learned Etude'] = 'Etude',
    ['Spirited Etude'] = 'Etude',
    ['Enchanting Etude'] = 'Etude',
    ['Herculean Etude'] = 'Etude',
    ['Uncanny Etude'] = 'Etude',
    ['Vital Etude'] = 'Etude',
    ['Swift Etude'] = 'Etude',
    ['Sage Etude'] = 'Etude',
    ['Logical Etude'] = 'Etude',
    ['Bewitching Etude'] = 'Etude',

    ['Fire Carol'] = 'Carol',
    ['Ice Carol'] = 'Carol',
    ['Wind Carol'] = 'Carol',
    ['Earth Carol'] = 'Carol',
    ['Lightning Carol'] = 'Carol',
    ['Water Carol'] = 'Carol',
    ['Light Carol'] = 'Carol',
    ['Dark Carol'] = 'Carol',

    ['Fire Carol II'] = 'Carol',
    ['Ice Carol II'] = 'Carol',
    ['Wind Carol II'] = 'Carol',
    ['Earth Carol II'] = 'Carol',
    ['Lightning Carol II'] = 'Carol',
    ['Water Carol II'] = 'Carol',
    ['Light Carol II'] = 'Carol',
    ['Dark Carol II'] = 'Carol',

    ['Fire Threnody'] = 'Threnody',
    ['Ice Threnody'] = 'Threnody',
    ['Wind Threnody'] = 'Threnody',
    ['Earth Threnody'] = 'Threnody',
    ['Lightning Threnody'] = 'Threnody',
    ['Water Threnody'] = 'Threnody',
    ['Light Threnody'] = 'Threnody',
    ['Dark Threnody'] = 'Threnody',

    ['Fire Threnody II'] = 'Threnody',
    ['Ice Threnody II'] = 'Threnody',
    ['Wind Threnody II'] = 'Threnody',
    ['Earth Threnody II'] = 'Threnody',
    ['Lightning Threnody II'] = 'Threnody',
    ['Water Threnody II'] = 'Threnody',
    ['Light Threnody II'] = 'Threnody',
    ['Dark Threnody II'] = 'Threnody',

    ['Magic Finale'] = 'Finale',

    ['Goddess\'s Hymnus'] = 'Hymnus',

    ['Chocobo Mazurka'] = 'Mazurka',
    ['Raptor Mazurka'] = 'Mazurka',

    ['Maiden\'s Virelai'] = 'Virelai',

    ['Foe Sirvente'] = 'Sirvente',

    ['Adventurer\'s Dirge'] = 'Dirge',

    ['Sentinel\'s Scherzo'] = 'Scherzo',

    ['Pining Nocturne'] = 'Nocturne'
};

local songTable = T {};

for k, v in pairs(songTypes) do
    local song = AshitaCore:GetResourceManager():GetSpellByName(k, 2);
    if (song) then
        songTable[k] = T {
            type = v,
            level = song.LevelRequired[10],
            range = song.AreaRange > 0 and 10 or 0
        };
    end
end

return songTable;
