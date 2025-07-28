# J-Roller Enhanced v2.0

**The Ultimate Corsair Auto-Roller**

J-Roller Enhanced combines the sophisticated rolling intelligence of J-Roller with the advanced features of AshitaRoller to create the definitive Corsair automation addon for FFXI.

## ✨ What Makes This Special

This enhanced version integrates **all the advanced tech from AshitaRoller** into J-Roller's superior foundation:
- ✅ **AshitaRoller's sophisticated double-up logic** (gamble mode, bust immunity, conservative strategies)
- ✅ **AshitaRoller's advanced Snake Eye strategies** (unlucky avoidance, lucky targeting, smart cooldown management)
- ✅ **AshitaRoller's convenience features** (presets, party alerts, engaged mode, town mode)
- ✅ **J-Roller's modern architecture** (clean modular code, robust packet handling, smart state management)
- ✅ **Enhanced GUI with comprehensive tooltips** (automatically disables Roll 2 for sub-COR, gear icon toggle)

## 🎯 **Core Features**

### **🧠 Advanced Rolling Intelligence**
- **Conservative Strategy**: Stops on 8+ (good rolls), smart handling of unlucky high numbers
- **Gamble Mode**: Aggressive double-11 targeting with bust immunity exploitation
- **Bust Immunity Control**: Optional toggle for aggressive Roll 2 when Roll 1 is 11
- **Safe Mode**: Ultra-conservative subjob-like behavior (only double-up on 1-5)
- **Smart Unlucky Handling**: Snake Eye to avoid disaster, conservative when unavailable
- **Risk Assessment**: Uses Fold availability and bust immunity for intelligent decisions

### **👥 Enhanced Job Support**
- **Main COR (mainjob == 17)**: Full feature set with sophisticated double-up logic
- **Sub COR (subjob == 17)**: Simplified single-roll mode, GUI automatically disables Roll 2
- **Real-Time Detection**: GUI updates dynamically when job changes
- **Visual Feedback**: Clear indication of current mode through disabled controls

### **🎲 Merit Ability Mastery**
- **Smart Snake Eye Usage**: Prioritizes unlucky avoidance above all else
  - Unlucky numbers (highest priority - avoid disaster)
  - Roll 10 and lucky-1 (for optimal results)
  - Respects cooldowns with accurate recast detection
- **Intelligent Fold Usage**: Strategic bust recovery and risk assessment
- **Manual Override**: Complete control with auto-detection backup
- **Crooked Cards Strategy**: Flexible normal vs "save for Roll 2" modes

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
- **Town Mode**: Optional toggle to prevent rolling in cities and safe zones
- **Incapacitation Checks**: Stops during Amnesia, Petrification, Stun, etc.
- **Stealth Awareness**: Pauses during Sneak/Invisible
- **Engaged Mode**: Optional setting to only roll while in combat
- **Smart Cooldown Detection**: Accurate recast timing prevents ability spam
- **Timeout Protection**: Prevents hanging on failed actions
- **Modular Architecture**: Clean separation of concerns for reliability

### **🎨 Smart GUI**
- **Dual Interface**: Draggable J-GUI overlay + comprehensive ImGui settings menu
- **Gear Icon Toggle**: Convenient gear icon between status and roll dropdowns  
- **Comprehensive Tooltips**: Helpful explanations for every setting and feature
- **Job Mode Awareness**: Automatically disables Roll 2 controls for sub-COR
- **Real-Time Status**: Shows current activity (Enabled/Sleeping/Idle/Action)
- **Organized Sections**: Combat Options, Ability Usage, Advanced Rolling, Merit Abilities
- **Quick Presets**: One-click access to optimized roll combinations
- **Rectangle Layout**: Improved horizontal layout for better space utilization

### **⚙️ Advanced Settings**
- **`crooked2`**: Save Crooked Cards for Roll 2 only vs normal (use on Roll 1, Random Deal resets) (default: off)
- **`randomdeal`**: Use Random Deal for cooldown resets (default: on)  
- **`oldrandomdeal`**: Random Deal mode - on = reset Snake Eye/Fold, off = reset Crooked Cards (default: off)
- **`partyalert`**: Alert party 8 seconds before rolling (default: off)
- **`gamble`**: Aggressive double-11 targeting with bust immunity exploitation (default: off)
- **`bustimmunity`**: Exploit bust immunity for aggressive Roll 2 when Roll 1 is 11 (default: on)
- **`safemode`**: Ultra-conservative mode - only double-up on rolls 1-5 like sub COR (default: off)
- **`engaged`**: Only roll while engaged in combat (default: off)
- **`townmode`**: Prevent rolling in towns and safe zones (default: off)
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
/roller engaged on|off        # Only roll while engaged
/roller crooked2 on|off       # Save Crooked Cards for Roll 2 only
/roller randomdeal on|off     # Enable Random Deal usage
/roller oldrandomdeal on|off  # Random Deal mode (Snake/Fold vs Crooked)
/roller partyalert on|off     # Alert party before rolling
/roller gamble on|off         # Aggressive mode for double 11s
/roller bustimmunity on|off   # Exploit bust immunity
/roller safemode on|off       # Ultra-conservative mode
/roller townmode on|off       # Prevent rolling in towns
/roller once                  # Roll both rolls once then stop
/roller menu                  # Toggle ImGui settings menu
```

### **🖥️ ImGui Settings Menu**
The comprehensive settings interface accessed with `/roller menu` or the gear icon provides:
- **Basic Controls**: Start/stop, roll selection, one-shot rolling with tooltips
- **Quick Presets**: One-click combat, magic, pet, and utility setups  
- **Advanced Settings**: Combat options, ability usage, advanced rolling modes
- **Merit Abilities**: Manual Snake Eye and Fold control with auto-detection override
- **Status & Debug**: Real-time info, debug commands, and troubleshooting
- **Help & Commands**: Complete command reference and chat help integration

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

# Conservative vs aggressive strategies
/roller safemode on                   # Ultra-safe: only double-up on 1-5
/roller bustimmunity off              # Conservative Roll 2 even with immunity
/roller gamble on                     # Aggressive double-11 targeting

# Crooked Cards strategies  
/roller crooked2 on                   # Save Crooked Cards for Roll 2 only
/roller crooked2 off                  # Normal: use on Roll 1, Random Deal resets for Roll 2

# Situational settings
/roller townmode on                   # Prevent rolling in towns
/roller partyalert on                 # Warn party before rolling

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

- **Modular Architecture**: Separated into interface.lua, strategy.lua, commands.lua, state.lua
- **Clean Dependencies**: Proper dependency injection and state management
- **Efficient Sleep/Wake**: Minimizes resource usage during idle periods
- **Robust Packet Integration**: Reliable action confirmation and roll detection
- **Smart Queue Management**: Proper timing for Random Deal and ability execution
- **Error Handling**: Graceful recovery from unexpected situations with timeout protection
- **Real-Time Updates**: Dynamic job detection, GUI updates, and accurate cooldown tracking

## 🏆 **Technical Achievements**

This enhanced version successfully integrates:
1. **Complete modular refactor** - Clean separation into interface, strategy, commands, and state modules
2. **AshitaRoller's sophisticated algorithms** - Advanced decision trees with conservative and aggressive modes
3. **Enhanced GUI with tooltips** - Comprehensive help system and gear icon integration
4. **Smart cooldown management** - Accurate recast detection and Random Deal timing optimization
5. **Flexible strategy system** - Multiple rolling modes (normal, gamble, safe, bust immunity)
6. **Robust state management** - Proper job detection, town mode, and setting persistence
7. **Advanced Crooked Cards logic** - Dual strategies for optimal ability usage patterns

## 📜 **Credits**

- **Original J-Roller**: Jyouya - Advanced rolling intelligence and modern architecture
- **AshitaRoller**: Selindrile, Lumlum, Palmer - Sophisticated algorithms and convenience features  
- **Enhanced Integration**: Palmer (Zodiarchy @ Asura) - Combining the best of both addons
