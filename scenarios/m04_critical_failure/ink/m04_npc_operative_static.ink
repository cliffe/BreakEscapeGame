// ===========================================
// OPERATIVE STATIC - ENTROPY, Voltage's backup (Plant Room)
// Mission 4: Critical Failure
//
// Combat is NOT narrated here. The fight is owned by the engine's hostile
// model (behavior.hostile + the #hostile tag below). Static is the last body
// between the player and Voltage, so this script is deliberately short: a
// challenge, and a post-KO interrogation that is the mission's cleanest
// source of Architect intelligence.
//
// NOTE: voltage_captured is ENGINE-owned (globalVarOnKO on the voltage NPC).
// It is declared here so it syncs IN and can be read. It is never assigned --
// assigning it would write a stale false back over the engine's true.
// ===========================================

// Ink-owned state
VAR static_challenged = false
VAR static_told_architect = false
VAR static_told_operations = false
VAR static_secured_done = false

// Engine-owned, synced in from globalVariables. NEVER assign these from ink.
VAR voltage_captured = false
VAR operative_static_defeated = false

// ===========================================
// ENTRY
// ===========================================

=== start ===
{operative_static_defeated: -> static_down}
{static_challenged: -> static_standoff}
-> static_voltage_support

// ===========================================
// THE CHALLENGE
// ===========================================

=== static_voltage_support ===
~ static_challenged = true

Narrator: He steps out from behind the plant room door frame, putting himself squarely between you and the man at the laptop.

ENTROPY Operative 'Static': Voltage. Company.

Narrator: Behind him, Voltage does not look up from the screen.

ENTROPY Operative 'Static': He doesn't need long. I just need you to be slow.

-> static_standoff

=== static_standoff ===
{operative_static_defeated: -> static_down}

* [You're standing in a room that's about to catch fire.]
    ENTROPY Operative 'Static': *doesn't move* Then we'd better be quick.
    -> static_refuses

* [He's not going to wait for you. Look at him.]
    Narrator: For a fraction of a second, Static's eyes flick sideways to the laptop, and to the man who has still not looked up.
    ENTROPY Operative 'Static': *evenly* He doesn't have to wait for me.
    ENTROPY Operative 'Static': That's the job.
    -> static_refuses

+ [Move him.]
    -> static_refuses

=== static_refuses ===
ENTROPY Operative 'Static': Not past me.

#hostile
#exit_conversation
-> start

// ===========================================
// SUBDUED
// ===========================================

=== static_down ===
{static_secured_done: -> static_secured_hub}

{voltage_captured:
    Narrator: He is on the floor of the plant room with his back to the wall, and he has already seen Voltage face down in cuffs across the room. Whatever he was holding out for is gone.
    ENTROPY Operative 'Static': *hoarse* It's over, then.
- else:
    Narrator: He is on the floor with his back to the wall, and there is a door standing open at the far end of the plant room that was shut when you came in.
    ENTROPY Operative 'Static': *with grim satisfaction* He got out. That's what the job was.
}

-> static_interrogation

=== static_interrogation ===
* {not static_told_architect} [Who is The Architect?]
    ~ static_told_architect = true
    ENTROPY Operative 'Static': Nobody's met them. That's the point of them.
    ENTROPY Operative 'Static': Directives come down, cells execute. Blackout signs off Critical Mass, Loom runs Social Fabric.
    ENTROPY Operative 'Static': Above that it's just a voice that's always right.
    -> static_interrogation

* {not static_told_operations} [How many operations like this are planned?]
    ~ static_told_operations = true
    ENTROPY Operative 'Static': Tonight? Every cell, 0800, simultaneous.
    ENTROPY Operative 'Static': After tonight is Phase 3, and Phase 3 is multi-city.
    ENTROPY Operative 'Static': This one was the small one.
    -> static_interrogation

* [Did anyone tell you the casualty number?]
    ENTROPY Operative 'Static': *tired* Everyone knows the number.
    ENTROPY Operative 'Static': You sign for it when you take the cell. That's what taking the cell means.
    -> static_interrogation

+ [Secure him and move on.]
    #exit_conversation
    -> static_secure_him

=== static_secure_him ===
~ static_secured_done = true

Narrator: You secure him to the pipework and check him for a radio.

// NOTE: there is no `neutralize_operative_static` task in scenario.json.erb --
// Static is unscored backup, unlike Cipher and Relay. If Phase 2's aim
// restructure gives him one, complete it here.
-> start

=== static_secured_hub ===
Narrator: Static is tied off to the pipework, head back against the wall.

+ {not static_told_architect} [Who is The Architect?]
    ~ static_told_architect = true
    ENTROPY Operative 'Static': A voice that's always right. Nobody's met them.
    -> static_secured_hub

+ {not static_told_operations} [How many operations like this are planned?]
    ~ static_told_operations = true
    ENTROPY Operative 'Static': Every cell, 0800. Then Phase 3, multi-city.
    -> static_secured_hub

+ [Leave him.]
    #exit_conversation
    ENTROPY Operative 'Static': *says nothing*
    -> static_secured_hub
