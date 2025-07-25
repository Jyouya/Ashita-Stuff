# J-Roller Enhanced v2.0

**The Ultimate Corsair Auto-Roller**

J-Roller Enhanced combines the sophisticated rolling intelligence of J-Roller with the advanced features of AshitaRoller to create the definitive Corsair automation addon for FFXI.

## ✨ What Makes This Special

This enhanced version integrates **all the advanced tech from AshitaRoller** into J-Roller's superior foundation:
- ✅ **AshitaRoller's sophisticated double-up logic** (gamble mode, bust immunity, complex decision trees)
- ✅ **AshitaRoller's advanced Snake Eye strategies** (lucky-1 targeting, unlucky avoidance, end-game optimization)
- ✅ **AshitaRoller's convenience features** (presets, party alerts, engaged mode, crooked cards strategy)
- ✅ **J-Roller's modern architecture** (clean code, robust packet handling, modular design)
- ✅ **Enhanced GUI with subjob mode** (automatically disables Roll 2 for sub-COR)

## 🎯 **Core Features**

### **🧠 Advanced Rolling Intelligence**
- **Gamble Mode**: Exploits bust immunity when `lastRoll == 11` for aggressive double-11 strategies
- **Risk Assessment**: Uses Fold availability to determine safe risk levels  
- **Crooked Cards Integration**: Different strategies for crooked vs normal rolls
- **Roll Time Tracking**: 240-second optimization windows for both rolls
- **End-Game Snake Eye**: Strategic usage when both rolls are active

### **👥 Enhanced Job Support**
- **Main COR (mainjob == 17)**: Full feature set with sophisticated double-up logic
- **Sub COR (subjob == 17)**: Simplified single-roll mode, GUI automatically disables Roll 2
- **Real-Time Detection**: GUI updates dynamically when job changes
- **Visual Feedback**: Clear indication of current mode through disabled controls

### **🎲 Merit Ability Mastery**
- **Advanced Snake Eye Logic**: Multiple conditions for optimal usage
  - Roll 10 (always good for 11)
  - Lucky-1 (to guarantee lucky with Snake Eye)  
  - Unlucky number (to avoid it with Snake Eye)
  - End-of-roll optimization when both rolls are up
- **Fold Integration**: Smart bust recovery with Fold availability assessment
- **Manual Control**: Override auto-detection with manual on/off settings

### **🎮 Preset Roll Combinations**
Quick access to optimized roll setups:
- **`tp`** - Samurai Roll + Fighter's Roll (STP + Double Attack)
- **`acc`** - Samurai Roll + Hunter's Roll (STP + Accuracy)  
- **`ws`** - Chaos Roll + Fighter's Roll (Attack + Double Attack)
- **`nuke/magic/burst/matk`** - Wizard's Roll + Warlock's Roll (MAB + MACC)
- **`pet/petphy`** - Companion's Roll + Beast Roll (Pet Regen/Regain + Pet Attack)
- **`petacc`** - Companion's Roll + Drachen Roll (Pet Regen + Pet Accuracy)
- **`petnuke/petmag`** - Puppet Roll + Companion's Roll (Pet MAB + Pet Regen)
- **`exp/cap/cp`** - Corsair's Roll + Dancer's Roll (EXP + Regen)
- **`speed/movespeed/bolt`** - Bolter's Roll + Bolter's Roll (Movement Speed)
- **`melee`** - Samurai Roll + Chaos Roll (STP + Attack)

### **🛡️ Safety & Intelligence**
- **Town Rolling Enabled**: Can roll in towns
- **Incapacitation Checks**: Stops during Amnesia, Petrification, Stun, etc.
- **Stealth Awareness**: Pauses during Sneak/Invisible
- **Engaged Mode**: Optional setting to only roll while in combat
- **Phantom Roll Cooldown**: Smart detection prevents spam when ability on cooldown
- **Timeout Protection**: Prevents hanging on failed actions

### **🎨 Smart GUI**
- **Job Mode Awareness**: Roll 2 shows "N/A (Sub COR)" and is disabled for subjob mode
- **Real-Time Status**: Shows current activity (Enabled/Sleeping/Idle/Action)
- **Draggable Interface**: Persistent position saving
- **Clean Layout**: 3x2 grid layout optimized for visibility

### **⚙️ Advanced Settings (From AshitaRoller)**
- **`crooked2`**: Use Crooked Cards on roll 2 (default: on)
- **`randomdeal`**: Use Random Deal for ability resets (default: on)
- **`oldrandomdeal`**: Random Deal mode - on = reset Snake/Fold, off = reset Crooked Cards (default: off)
- **`partyalert`**: Warn party 8 seconds before rolling (default: off)
- **`gamble`**: Abuse bust immunity for maximum double-11 attempts (default: off)
- **`engaged`**: Only roll while engaged in combat (default: off)
- **`hasSnakeEye/hasFold`**: Manual merit ability control (default: on)

## 📋 **Commands**

### **Basic Commands**
```bash
/roller                    # Show detailed status and current configuration
/roller start|stop         # Enable/disable auto-rolling
/roller roll1 <name>       # Set first roll (supports fuzzy matching)
/roller roll2 <name>       # Set second roll (disabled for sub-COR)
```

### **Preset Commands**
```bash
/roller tp                 # TP setup (Samurai + Fighter)
/roller acc                # Accuracy setup (Samurai + Hunter)
/roller ws                 # Weapon skill setup (Chaos + Fighter) 
/roller nuke               # Magic setup (Wizard + Warlock)
/roller pet                # Pet setup (Companion + Beast)
/roller exp                # Experience setup (Corsair + Dancer)
/roller speed              # Movement speed (Bolter + Bolter)
/roller melee              # Melee setup (Samurai + Chaos)
```

### **Advanced Settings**
```bash
/roller engaged on|off     # Only roll while engaged
/roller crooked2 on|off    # Use Crooked Cards on roll 2  
/roller randomdeal on|off  # Enable Random Deal usage
/roller oldrandomdeal on|off # Random Deal mode (Snake/Fold vs Crooked)
/roller partyalert on|off  # Alert party before rolling
/roller gamble on|off      # Gamble mode for bust immunity exploitation
/roller once               # Roll both rolls once then stop
```

### **Merit Ability Control**
```bash
/roller snakeeye on|off    # Manual Snake Eye control
/roller fold on|off        # Manual Fold control
/roller debug              # Show internal state for troubleshooting
```

## 🚀 **Installation**

1. Place the entire `j-roller` folder in your `addons` directory
2. Load with `/addon load j-roller` or add to your startup
3. Configure your preferred rolls or use presets
4. Start rolling with `/roller start`

## 💡 **Usage Examples**

```bash
# Quick setup for different scenarios
/roller tp && /roller start           # TP party setup
/roller nuke && /roller gamble on     # Magic burst with aggressive mode
/roller pet && /roller engaged on     # Pet party, only roll when fighting

# Advanced configuration
/roller crooked2 on                   # Use Crooked Cards on both rolls
/roller partyalert on                 # Warn party before rolling  
/roller randomdeal on                 # Enable ability resets
/roller oldrandomdeal off             # Focus on resetting Crooked Cards

# Sub-COR usage (automatically detected)
/roller acc                           # Sets Roll 1 to Samurai, Roll 2 disabled
/roller start                         # Only Roll 1 will be used
```

## 🔍 **Fuzzy Name Matching** 

The addon supports intelligent roll name matching:
- **Partial names**: `wiz` → Wizard's Roll, `sam` → Samurai Roll
- **Job abbreviations**: `rdm` → Warlock's Roll, `war` → Fighter's Roll
- **Effect names**: `macc` → Warlock's Roll, `stp` → Samurai Roll, `acc` → Hunter's Roll
- **Common terms**: `nuke` → Wizard's Roll, `crit` → Rogue's Roll, `def` → Gallant's Roll
- **Stats**: `attack` → Chaos Roll, `double attack` → Fighter's Roll, `refresh` → Evoker's Roll

## ⚡ **Performance & Reliability**

- **Modern Architecture**: Clean separation of concerns with modular design
- **Efficient Sleep/Wake**: Minimizes resource usage during idle periods
- **Robust Packet Integration**: Reliable action confirmation and roll detection
- **Error Handling**: Graceful recovery from unexpected situations
- **Real-Time Updates**: Dynamic job detection and GUI updates

## 🏆 **Technical Achievements**

This enhanced version successfully integrates:
1. **AshitaRoller's sophisticated rolling algorithms** - Complex decision trees for optimal play
2. **J-Roller's clean architecture** - Maintainable, extensible codebase
3. **Enhanced GUI functionality** - Smart subjob mode with automatic control disabling
4. **Advanced state tracking** - Roll times, crooked status, bust immunity detection
5. **Comprehensive preset system** - Quick access to optimized configurations

## 📜 **Credits**

- **Original J-Roller**: Jyouya - Advanced rolling intelligence and modern architecture
- **AshitaRoller**: Selindrile, Lumlum, Palmer - Sophisticated algorithms and convenience features  
- **Enhanced Integration**: Palmer (Zodiarchy @ Asura) - Combining the best of both addons
