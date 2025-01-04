return {
    Cichol   = {
        VIT_WSD = {
            name = "Cichol's Mantle",
            augments = {
                'VIT+20', 'Accuracy+20 Attack+20', 'VIT+10',
                'Weapon skill damage +10%', 'Phys. dmg. taken-10%'
            }
        },
        DEX_DA = {
            name = "Cichol's Mantle",
            augments = {
                'DEX+20', 'Accuracy+20 Attack+20', 'Accuracy+10',
                '"Dbl.Atk."+10', 'Phys. dmg. taken-10%'
            }
        },
        DEX_STP = {
            name = "Cichol's Mantle",
            augments = {
                'DEX+20', 'Accuracy+20 Attack+20', 'Accuracy+10',
                '"Store TP"+10', 'Phys. dmg. taken-10%'
            }
        },
        DEX_Crit = {
            name = "Cichol's Mantle",
            augments = {
                'DEX+20', 'Accuracy+20 Attack+20', 'DEX+10', 'Crit.hit rate+10',
                'Phys. dmg. taken-10%'
            }
        },
        STR_DA = {
            name = "Cichol's Mantle",
            augments = {
                'STR+20', 'Accuracy+20 Attack+20', 'STR+10', '"Dbl.Atk."+10',
                'Phys. dmg. taken-10%'
            }
        },
        STR_WSD = {
            name = "Cichol's Mantle",
            augments = {
                'STR+20', 'Accuracy+20 Attack+20', 'STR+10',
                'Weapon skill damage +10%', 'Phys. dmg. taken-10%'
            }
        }
    },
    Odyssean = {
        Head = {
            MAB_WSD = {
                name = "Odyssean Helm",
                augments = {
                    'Mag. Acc.+15 "Mag.Atk.Bns."+15', 'Weapon skill damage +4%',
                    '"Mag.Atk.Bns."+12'
                }
            },
            FC = {
                name = "Odyssean Helm",
                augments = {
                    'Mag. Acc.+14 "Mag.Atk.Bns."+14', '"Fast Cast"+4', 'MND+1',
                    'Mag. Acc.+5', '"Mag.Atk.Bns."+2'
                }
            }
        },
        Body = { FC = 'Odyssean Breastplate' },
        Hands = {
            VIT_WSD = {
                name = "Odyssean Gauntlets",
                augments = { 'Accuracy+25', 'Weapon skill damage +3%', 'VIT+4' }
            },
            STR_WSD = {
                name = "Odyssean Gauntlets",
                augments = { 'Accuracy+2', 'Weapon skill damage +4%', 'STR+15' }
            },
            MAB_WSD = {
                name = "Odyssean Gauntlets",
                augments = {
                    'Mag. Acc.+20 "Mag.Atk.Bns."+20', '"Mag.Atk.Bns."+18'
                }
            }
        },
        Legs = {
            TH = {
                name = "Odyssean Cuisses",
                augments = {
                    'Enmity-2', 'Crit. hit damage +2%', '"Treasure Hunter"+2',
                    'Accuracy+10 Attack+10'
                }
            },
            VIT_WSD = {
                name = "Valor. Hose",
                augments = {
                    'Accuracy+15 Attack+15', 'Weapon skill damage +4%', 'VIT+7',
                    'Accuracy+14', 'Attack+2'
                }
            },
            FC = { -- ! MAKE THIS
                name = "Odyssean Cuisses",
                augments = {
                    'Accuracy+25 Attack+25', 'Weapon skill damage +3%', 'AGI+6'
                }
            },
            STP = {
                name = "Odyssean Cuisses",
                augments = { 'Attack+20', '"Store TP"+7', 'VIT+8', 'Accuracy+13' }
            }
        },
        Feet = {
            MAB_WSD = {
                name = "Odyssean Greaves",
                augments = {
                    '"Mag.Atk.Bns."+25', 'Weapon skill damage +2%', 'STR+7'
                }
            },
            FC = { -- ! Make this
                name = "Odyssean Greaves",
                augments = {
                    '"Mag.Atk.Bns."+25', 'Weapon skill damage +2%', 'STR+7'
                }
            }
        }
    },

    Valorous = {
        Body = {
            DA = 'Agoge Lorica +3', -- ! MAKE THIS
            STP = {
                name = "Valorous Mail",
                augments = {
                    'INT+10', 'MND+4', '"Store TP"+9',
                    'Mag. Acc.+1 "Mag.Atk.Bns."+1'
                }
            },
            STR_Crit = 'Dagon Breastplate', -- ! MAKE THIS
            MAB_WSD = {
                name = "Valorous Mail",
                augments = {
                    '"Mag.Atk.Bns."+22', 'Weapon skill damage +3%',
                    'Accuracy+14 Attack+14', 'Mag. Acc.+17 "Mag.Atk.Bns."+17'
                }
            }
        },
        Hands = { STR_Crit = {} },
        Legs = {
            STR_WSD = { -- ! switch these to valorous
                name = "Odyssean Cuisses",
                augments = {
                    'Accuracy+25 Attack+25', 'Weapon skill damage +4%', 'STR+6',
                    'Accuracy+12'
                }
            },
            STR_Crit = {
                name = "Valor. Hose",
                augments = { 'Crit. hit damage +4%', 'STR+13', 'Attack+12' }
            }
        }
    },

    Argosy   = {
        Body = {
            PathD = {
                name = "Argosy Hauberk +1",
                augments = { 'STR+12', 'Attack+20', '"Store TP"+6' }
            }
        },
        Hands = {
            PathD = {
                name = "Argosy Mufflers +1",
                augments = { 'STR+20', '"Dbl.Atk."+3', 'Haste+3%' }
            }
        },
        Legs = {
            PathD = {
                name = "Argosy Breeches +1",
                augments = { 'STR+12', 'Attack+25', '"Store TP"+6' }
            }
        }
    },


    Lustratio_Head_PathA = { Name = 'Lustratio Cap +1', AugPath = 'A' },
    Lustratio_Body_PathA = { Name = 'Lustr. Harness +1', AugPath = 'A' },
    Lustratio_Legs_PathB = { Name = 'Lustr. Subligar +1', AugPath = 'B' },
    Lustratio_Feet_PathD = { Name = 'Lustra. Leggings +1', AugPath = 'D' },

    Emicho               = {
        Body = {
            PathB = {
                name = "Emicho Haubert +1",
                augments = { 'HP+65', 'DEX+12', 'Accuracy+20' }
            }
        },
        Hands = {
            PathB = { -- ! MAKE THIS
                name = "Emi. Gauntlets +1",
                augments = { 'Accuracy+25', '"Dual Wield"+6', 'Pet: Accuracy+25' }
            },
            PathD = {
                name = "Emi. Gauntlets +1",
                augments = { 'Accuracy+25', '"Dual Wield"+6', 'Pet: Accuracy+25' }
            }
        }
    },

    Souveran_Head_PathD  = T { Name = 'Souv. Schaller +1', AugPath = 'D' },
    Souveran_Head_PathC  = T { Name = 'Souv. Schaller +1', AugPath = 'C' },
    Souveran_Body_PathC  = T { Name = 'Souv. Cuirass +1', AugPath = 'C' },
    Souveran_Hands_PathC = T { Name = 'Souv. Handsch. +1', AugPath = 'C' },
    Souveran_Legs_PathC  = T { Name = 'Souv. Diechlings +1', AugPath = 'C' },

    MoonlightRing1       = { Name = 'Moonlight Ring', bag = 'wardrobe2', priority = 15 },
    MoonlightRing2       = { Name = 'Moonlight Ring', bag = 'wardrobe3', priority = 15 },

    Malevolence1         = {
        Name = "Malevolence",
        augments = {
            'INT+10', 'Mag. Acc.+10', '"Mag.Atk.Bns."+10', '"Fast Cast"+5'
        },
        bag = 'wardrobe',
        alias = 'Malevolence'
    },
    Malevolence2         = {
        Name = "Malevolence",
        augments = {
            'INT+10', 'Mag. Acc.+10', '"Mag.Atk.Bns."+10', '"Fast Cast"+5'
        },
        bag = 'wardrobe2',
        alias = 'Malevolence'
    },

    MacheEarring1        = {
        Name = 'Mache Earring +1',
        bag = 'wardrobe1',
    },
    MacheEarring2        = {
        Name = 'Mache Earring +1',
        bag = 'wardrobe2',
    },

    Ogma_Tank            = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' } },
    Ogma_Reso            = { Name = 'Ogma\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'STR+30', [4] = 'Attack+20', [5] = 'Accuracy+20' } },
    Ogma_Acc             = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = '"Store TP"+10', [5] = 'DEX+20' } },
    Ogma_FC              = { Name = 'Ogma\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'HP+80', [5] = 'Evasion+20' } },
    Ogma_Dimidi          = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Accuracy+20', [3] = 'Weapon skill damage +10%', [4] = 'Attack+20', [5] = 'DEX+30' } },
    Ogma_Enmity          = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+80', [4] = 'Mag. Evasion+20', [5] = 'Enmity+10' } },
    Ogma_Lunge           = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+30', [5] = 'Magic Damage+20' } },


    Herc_Head_WSD     = { Name = 'Herculean Helm', Augment = { [1] = 'Accuracy+29', [2] = 'Weapon skill damage +3%', [3] = 'DEX+13' } },
    Herc_Head_MAB     = { Name = 'Herculean Helm', Augment = { [1] = 'Pet: "Dbl.Atk."+3', [2] = '"Mag. Atk. Bns."+36', [3] = 'Accuracy+18', [4] = 'Mag. Acc.+17', [5] = 'Attack+18', [6] = 'Pet: Crit.hit rate +3' } },
    Herc_Body_QA      = { Name = 'Herculean Vest', Augment = { [1] = 'Pet: "Mag. Atk. Bns."+22', [2] = 'Quadruple Attack +3', [3] = 'Accuracy+6', [4] = 'Attack+6', [5] = 'DEX+6' } },
    Herc_Body_WSD     = { Name = 'Herculean Vest', Augment = { [1] = 'Accuracy+39', [2] = 'Weapon skill damage +4%', [3] = 'Attack+24', [4] = 'DEX+4' } },
    Herc_Hands_WSD    = { Name = 'Herculean Gloves', Augment = { [1] = 'Pet: Rng. Acc.+8', [2] = 'Attack+19', [3] = 'Weapon skill damage +8%', [4] = 'Accuracy+19', [5] = 'Pet: Accuracy+8', [6] = 'STR+15' } },
    Herc_Legs_WSD_MAB = { Name = 'Herculean Trousers', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+31', [3] = '"Mag. Atk. Bns."+28' } },
    Herc_Feet_MAB     = { Name = 'Herculean Boots', Augment = { [1] = 'INT+5', [2] = 'Mag. Acc.+30', [3] = '"Mag. Atk. Bns."+32' } },
    Herc_Feet_STP     = { Name = 'Herculean Boots', Augment = { [1] = 'DEX+4', [2] = '"Store TP"+7', [3] = '"Mag. Atk. Bns."+14' } },
    Herc_Feet_TA      = { Name = 'Herculean Boots', Augment = { [1] = '"Triple Atk."+4', [2] = 'Attack+24', [3] = 'Accuracy+13' } },


    Adhemar_Body_PathB  = { Name = 'Adhemar Jacket +1', AugPath = 'B' },
    Adhemar_Hands_PathA = { Name = 'Adhemar Wrist. +1', AugPath = 'A' },
    Adhemar_Hands_PathB = { Name = 'Adhemar Wrist. +1', AugPath = 'B' },

    Carmine_Head_PathD  = { Name = 'Carmine Mask +1', AugPath = 'D' },
    Carmine_Legs_PathA  = { Name = 'Carmine Cuisses +1', AugPath = 'A' },
    Carmine_Feet_PathD  = { Name = 'Carmine Greaves +1', AugPath = 'D' },

    Rudianos_FC_Midcast = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Fast Cast"+10', [3] = 'Mag. Evasion+30', [4] = 'HP+60', [5] = 'Evasion+20' } },
    Rudianos_Tank       = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' } },
    Rudianos_Cure       = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Cure" potency +10%', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Evasion+20' } },
}
