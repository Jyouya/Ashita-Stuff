local function G(t)
    return setmetatable(t, {
        __tostring = function(self)
            return self.alias or self.Name;
        end
    })
end

return {
    Camulus_DA = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Magic dmg. taken -10%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+30' } },
    Camulus_DW = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Accuracy+30', [3] = 'DEX+20', [4] = 'Attack+20', [5] = '"Dual Wield"+10' } },
    Camulus_rSTP = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Rng.Acc.+20', [3] = 'AGI+30', [4] = '"Store TP"+10', [5] = 'Rng.Atk.+20' } },
    Camulus_AM3 = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Rng.Acc.+20', [3] = 'Crit.hit rate+10', [4] = 'AGI+30', [5] = 'Rng.Atk.+20' } },
    Camulus_Savage = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
    Camulus_LastStand = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Rng.Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Rng.Atk.+20' } },
    Camulus_LeadenSalute = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
    Camulus_AeolianEdge = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'INT+30', [3] = 'Weapon skill damage +10%', [4] = 'Mag. Acc.+20', [5] = 'Magic Damage+20' } },
    Camulus_Snapshot = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'INT+20', [3] = '"Snapshot"+10', [4] = 'Mag. Evasion+20', [5] = 'Evasion+20' } },
    Camulus_Fastcast = { Name = 'Camulus\'s Mantle', Augment = { [1] = '"Fast Cast"+10', [2] = 'HP+60' } },
    Camulus_QuickdrawDamage = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },

    Herc_Feet_DT = { Name = 'Herculean Boots', Augment = { [1] = 'Damage taken-3%', [2] = 'Phys. dmg. taken -2%', [3] = 'Mag. Acc.+3', [4] = 'Accuracy+11', [5] = '"Mag. Atk. Bns."+3', [6] = 'Pet: "Dbl. Atk."+3', [7] = 'Attack+11' } },
    Herc_Feet_WSDAGI = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+29', [2] = 'AGI+8', [3] = 'Attack+30', [4] = 'Weapon skill damage +4%' } },
    Herc_Feet_TA = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+29', [2] = '"Triple Atk."+4', [3] = 'DEX+5' } },

    Herc_Legs_Sagage = { Name = 'Herculean Trousers', Augment = { [1] = '"Mag. Atk. Bns."+3', [2] = 'Mag. Acc.+3', [3] = 'Weapon skill damage +7%', [4] = 'Attack+23', [5] = '"Store TP"+4', [6] = 'Accuracy+19' } },
    Herc_Legs_Leaden = { Name = 'Herculean Trousers', Augment = { [1] = 'Weapon skill damage +1%', [2] = 'INT+9', [3] = 'Mag. Acc.+31', [4] = '"Mag. Atk. Bns."+34' } },
    Herc_Legs_Phalanx = { Name = 'Herculean Trousers', Augment = { [1] = 'Weapon skill damage +5%', [2] = 'Phalanx +5', [3] = 'Attack+9', [4] = 'Accuracy+9' } },
    Herc_Legs_TreasureHunter = { Name = 'Herculean Trousers', Augment = { [1] = 'Accuracy+15', [2] = 'Attack+3', [3] = '"Treasure Hunter"+2' } },

    Herc_Hands_Leaden = { Name = 'Herculean Gloves', Augment = { [1] = 'Accuracy+2', [2] = 'Mag. Acc.+20', [3] = 'Attack+2', [4] = '"Mag. Atk. Bns."+49' } },

    Herc_Head_Wildfire = { Name = 'Herculean Helm', Augment = { [1] = 'CHR+1', [2] = 'Mag. Acc.+18', [3] = '"Mag. Atk. Bns."+48' } },
    Herc_Head_Savage = { Name = 'Herculean Helm', Augment = { [1] = 'Pet: Rng. Acc.+26', [2] = 'Mag. Acc.+7', [3] = 'Weapon skill damage +8%', [4] = 'Attack+3', [5] = 'Pet: Accuracy+26', [6] = 'Accuracy+3' } },

    Adhemar_Head_PathD = { Name = 'Adhemar Bonnet +1', AugPath = 'D' },
    Adhemar_Body_PathA = { Name = 'Adhemar Jacket +1', AugPath = 'A' },
    Adhemar_Legs_PathC = { Name = 'Adhemar Kecks +1', AugPath = 'C' },
    Adhemar_Legs_PathD = { Name = 'Adhemar Kecks +1', AugPath = 'D' },
    Adhemar_Hands_PathA = { Name = 'Adhemar Wrist +1', AugPath = 'A' },
    Adhemar_Hands_PathC = { Name = 'Adhemar Wrist +1', AugPath = 'C' },

    Carmine_Head_D = { Name = 'Carmine Mask +1', AugPath = 'D' },
    Carmine_Feet_D = { Name = 'Carmine Greaves +1', AugPath = 'D' },

    Rostam_A = { alias = 'RostamA', Name = "Rostam", AugPath = 'A' },
    Rostam_B = { alias = 'RostamB', Name = "Rostam", AugPath = 'B' },
    Rostam_C = { alias = 'RostamC', Name = "Rostam", AugPath = 'C' },
};