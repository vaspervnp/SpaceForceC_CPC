# Game Design Document: **Space Force C** (Amstrad CPC Mode 0)

---

## 1. Introduction & Technical Specifications

**Space Force C** is an arcade multi-directional scrolling shooter designed exclusively for the **Amstrad CPC** in **Mode 0** (160x200 pixels, 16 simultaneous colors from a 27-color palette).

*   **Mode & Colors:** Mode 0, leveraging the rich 16-color palette for vibrant, humorous graphics and a retro-futuristic aesthetic.
*   **Framerate & Movement:** Steady **25 FPS**, with **Double Buffering** (screen flipping in memory for zero flickering) and **smooth 2-pixel movement** for a smooth sense of speed.
*   **Ship Dimensions:** **24x24 pixels**. The ship features multiple sprites depending on tilt and direction (up, down, left, right, diagonal) as it automatically adapts for flight in a vacuum (space) and atmosphere (Earth).

---

## 2. Plot & Humor

In the distant year 2442, the **Space Force** is humanity's cosmic defense. Unfortunately, the best pilots are on leave due to mass food poisoning from space moussaka. Thus, Earth's safety falls into the hands of **Wing C**—the team with the lowest score at the space academy (they passed navigation courses with a borderline 5/10 and consistently confused the warp drive with the automatic coffee maker).

### The Mystery of the Ants
Alien invaders (the *Katsarophobians*) invade space and Earth with an absurd goal: **to steal all the ants on the planet**. 
* **The Reason:** Their empire suffers from incurable insomnia and they discovered that the biological fluid of Earth ants, when mixed with galactic cocoa, creates the ultimate sedative tea (known as *Mirmikochai*). Without it, their Emperor cannot sleep and goes berserk, threatening to destroy the universe because "his nerves are acting up."

Wing C is called upon to save the ants, even though the team leader hates insects because they stung him at an elementary school extracurricular picnic.

---

## 3. Wing C's Ship: *The Flying Patates*

*   **Size:** 24x24 pixels.
*   **Dynamic Sprites:** The ship features 8 different angles/tilts. When turning sharply, it tilts dramatically (while the pilots scream on the intercoms), and changes outer fins depending on whether it's in the vacuum of space or Earth's atmosphere (on Earth, it also emits a bit of black exhaust smoke).

---

## 4. Weapon System & Power-Ups

### The Player's 3 Different (and Funny) Weapons
1.  **Disco-Ray:** Emits a beam of neon light forcing aliens to rhythmically dance the "Macarena" until they burst from exhaustion and embarrassment.
2.  **Mega-Baguette Launcher:** Shoots hard, stale French baguettes that pierce alien shields like a hot knife through butter.
3.  **Sneeze Cannon:** A biological ultra-recoil attack that sprays green allergy particles, breaking up enemy structures.

### Alien Weapons (Also Funny)
*   **Laser Spaghetti:** Fires sticky digital pasta that wraps around the ship and reduces movement speed.
*   **Bureaucracy Beam:** Throws pink tax forms (E9 tax forms) onto the ship's windshield, blinding the pilot.
*   **Bad Breath Torpedoes:** Torpedoes with a foul garlic smell that make high-speed zigzag movements due to motion sickness.

### Power-Ups & Ship Upgrades
*   **Shield Bubble Wrap:** Protects the ship and makes a satisfying "pop" sound when it breaks.
*   **Espresso Boost:** Temporarily increases movement speed and makes pilots talk three times faster.
*   **Ant-Magnet:** Automatically collects stolen ants left behind by enemies for bonus points.
*   **Upgrades:** Engine upgrade, double/triple baguette gun, and automatic insecticide sprayer.

---

## 5. Level Structure (8 Levels)

The game is divided into 2 worlds (4 levels in Space and 4 on Earth). Each level ends with an epic, funny Boss.

### Part A: Space (Levels 1-4)
1.  **Level 1: The Asteroid Belt of Lost Luggage**
    *   *Environment:* Asteroids resembling lost suitcases and socks.
    *   *Boss:* **Lord Garbage-Can** (A giant metal trash can throwing old Amstrad hardware).
2.  **Level 2: The Nebula of Bureaucracy**
    *   *Environment:* Space stations full of waiting lines and stamps.
    *   *Boss:* **The Grand Inspector** (A massive flying red stamp trying to "reject" your ship).
3.  **Level 3: Galaxy's Trashcan City**
    *   *Environment:* Space debris and old alien consoles.
    *   *Boss:* **Mecha-Trashcan 3000** (A robot made of old floppy disks).
4.  **Level 4: The Lunar Ant-Hill**
    *   *Environment:* The moon full of artificial underground ant tunnels.
    *   *Boss:* **General Formix** (A giant alien ant with a military helmet and sunglasses).

### Part B: Earth (Levels 5-8)
5.  **Level 5: Traffic on Attiki Odos (Rush Hour)**
    *   *Environment:* Skyscrapers, neon signs, and traffic-jammed flying cars.
    *   *Boss:* **The Undefeated Toll Booth** (A toll-booth monstrosity demanding coins and launching safety barriers).
6.  **Level 6: The Underground Tunnels (Megara)**
    *   *Environment:* Underground caves with tree roots and panicked giant ants.
    *   *Boss:* **Queen Ant-Zilla** (The ant queen grown large from radioactive tea).
7.  **Level 7: The Acropolis Parking Lot**
    *   *Environment:* Ancient monuments and tourists with cameras taking pictures amidst the battle.
    *   *Boss:* **Parthenon-Bot 2.0** (An ancient temple transforming into a Mecha Transformer).
8.  **Level 8: The Mothership's Kitchen (Over Athens)**
    *   *Environment:* The interior of the invaders' main ship, full of giant pots of *Mirmikochai*.
    *   *Boss:* **Chef Xylokorinthos** (The Supreme Alien Chef with 6 arms, throwing hot soups and pans at you).

---

## 6. Ending Scene
After defeating Chef Xylokorinthos, millions of ants are freed and return to Earth forming a massive message in the sky: *"THANK YOU WING C (YOU ALMOST MESSED IT UP)"*. Wing C gets a promotion... meaning they are assigned to clean the space station's toilets.