// ===========================================
// OPERATIVE RELAY - ENTROPY, Inverter Room patrol
// Mission 4: Critical Failure
//
// Combat is NOT narrated here. The fight is owned by the engine's hostile
// model (behavior.hostile + patrol route in scenario.json.erb, plus the
// #hostile tag below). This script covers the detection beat, the
// surrender/interrogation, and a coherent post-KO state.
//
// Relay carries the Master keycard, which gates the plant room and is on the
// critical path -- it must remain recoverable however this resolves.
// ===========================================

// Ink-owned state
VAR relay_alerted_team = false
VAR radio_interrupted = false
VAR relay_told_count = false
VAR relay_told_devices = false
VAR relay_secured_done = false

// Engine-owned, synced in from globalVariables. NEVER assign from ink.
VAR operative_relay_defeated = false

// ===========================================
// ENTRY
// ===========================================

=== start ===
{operative_relay_defeated: -> relay_down}
{radio_interrupted or relay_alerted_team: -> relay_standoff}
-> relay_patrol_alert

// ===========================================
// DETECTION
// ===========================================

=== relay_patrol_alert ===
Narrator: She comes round the end of the inverter cabinets mid-stride and stops dead.

ENTROPY Operative 'Relay': Inverter room's closed. Has been all week.

* [Then why are you walking it?]
    ENTROPY Operative 'Relay': *already reaching for the radio* Because I'm meant to be.
    -> relay_alerts_team

* [Radio. Down. Now.]
    ~ radio_interrupted = true
    Narrator: Her hand stops halfway. She weighs it, and leaves the radio where it is.
    ENTROPY Operative 'Relay': Easy.
    -> relay_standoff

* [Three charge stations, all bypassed. Was that you?]
    ~ radio_interrupted = true
    Narrator: That stops her more effectively than the first option would have. She had not expected anyone to have looked.
    ENTROPY Operative 'Relay': *slowly* ...You've been in the cabinets.
    -> relay_standoff

=== relay_alerts_team ===
~ relay_alerted_team = true

ENTROPY Operative 'Relay': All units, inverter room. We have company.

Narrator: She clips the radio back on her belt with the unhurried confidence of someone who expects to win this.

#hostile
#exit_conversation
-> start

// ===========================================
// STANDOFF
// ===========================================

=== relay_standoff ===
{operative_relay_defeated: -> relay_down}

ENTROPY Operative 'Relay': You're not getting to those rack banks.

* [I don't need to. I need you to understand what they'll do.]
    -> relay_doubt

* [Walk away. I'm not here for you.]
    ENTROPY Operative 'Relay': *shakes her head, almost friendly* No, you're really not going to be able to do that.
    -> relay_refuses

+ [Say nothing.]
    Narrator: She reads the silence correctly.
    -> relay_refuses

=== relay_doubt ===
ENTROPY Operative 'Relay': Thermal runaway in a sealed hall. I know exactly what they'll do.

ENTROPY Operative 'Relay': I did the modelling.

Narrator: There is no flinch in it. She is not a technician who was lied to; she costed this and came anyway.

* [You modelled the casualties and came anyway.]
    ENTROPY Operative 'Relay': I modelled the grid.
    ENTROPY Operative 'Relay': The casualties were a line in the same spreadsheet.
    -> relay_refuses

* [Then you know the night crew is still in Hall 2.]
    ENTROPY Operative 'Relay': *beat* They were told to clear at midnight.
    ENTROPY Operative 'Relay': If they didn't, that's on them.
    -> relay_refuses

=== relay_refuses ===
ENTROPY Operative 'Relay': Last chance to be somewhere else.

#hostile
#exit_conversation
-> start

// ===========================================
// SUBDUED
// ===========================================

=== relay_down ===
{relay_secured_done: -> relay_secured_hub}

Narrator: She is down against the base of an inverter cabinet, one arm across her ribs, still doing arithmetic behind her eyes.

ENTROPY Operative 'Relay': Fine. I yield.

-> relay_interrogation

=== relay_interrogation ===
* {not relay_told_count} [How many of you are here?]
    ~ relay_told_count = true
    ENTROPY Operative 'Relay': Four. Cipher, me, Static, Voltage.
    ENTROPY Operative 'Relay': If you got this far you've met Cipher.
    ENTROPY Operative 'Relay': Voltage won't yield. Don't plan around it.
    -> relay_interrogation

* {not relay_told_devices} [Where are the bypass devices?]
    ~ relay_told_devices = true
    ENTROPY Operative 'Relay': Charge stations. Three of them, in here.
    ENTROPY Operative 'Relay': Bypass hardware on all three, remote controllable. You'd have to physically pull them.
    -> relay_interrogation

* [Who gave you the casualty figure?]
    ENTROPY Operative 'Relay': *closes her eyes* Blackout signs the models.
    ENTROPY Operative 'Relay': Voltage just runs the site.
    -> relay_interrogation

+ [Secure her and move on.]
    #exit_conversation
    -> relay_secure_her

=== relay_secure_her ===
~ relay_secured_done = true

Narrator: You tie her off to the cabinet frame and lift the master card from her jacket.

#complete_task:neutralize_operative_relay
-> start

=== relay_secured_hub ===
Narrator: Relay is secured against the inverter cabinet, watching the hydrogen panel more than she watches you.

+ {not relay_told_count} [How many of you are here?]
    ~ relay_told_count = true
    ENTROPY Operative 'Relay': Four. Voltage is the one that matters.
    -> relay_secured_hub

+ {not relay_told_devices} [Where are the bypass devices?]
    ~ relay_told_devices = true
    ENTROPY Operative 'Relay': Three charge stations, in here. Pull them by hand.
    -> relay_secured_hub

+ [Leave her.]
    #exit_conversation
    ENTROPY Operative 'Relay': *watching the panel* Amber's not the one to worry about.
    -> relay_secured_hub
