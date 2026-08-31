// ===========================================
// OPERATIVE CIPHER - ENTROPY, Battery Hall 1
// Mission 4: Critical Failure
//
// Combat is NOT narrated here. The fight is owned by the engine's hostile
// model (behavior.hostile in scenario.json.erb + the #hostile tag below).
// This script covers three things only:
//   1. The detection beat, where the player can bluff, stall the radio, or
//      blow it and turn Cipher hostile.
//   2. The surrender/interrogation, reached when Cipher is subdued.
//   3. A post-KO state so re-entering the conversation stays coherent.
//
// Cipher carries the Level 2 workshop keycard, which is on the critical
// path -- it must remain recoverable however this resolves.
// ===========================================

// Ink-owned state
VAR cipher_alerted_team = false
VAR radio_interrupted = false
VAR cipher_told_voltage_location = false
VAR cipher_told_attack_vectors = false
VAR cipher_secured_done = false

// Engine-owned, synced in from globalVariables. NEVER assign these from ink --
// globalVarOnKO writes them and a two-way sync would clobber the engine value.
VAR operative_cipher_defeated = false

// ===========================================
// ENTRY
// ===========================================

=== start ===
{operative_cipher_defeated: -> cipher_down}
{radio_interrupted or cipher_alerted_team: -> cipher_standoff}
-> cipher_detection

// ===========================================
// DETECTION
// ===========================================

=== cipher_detection ===
Narrator: He is crouched at the end of the rack row with a panel open and a handset already half out of its clip.

ENTROPY Operative 'Cipher': Hey. Hey! This bay's locked off for maintenance.

ENTROPY Operative 'Cipher': *thumb moving to the handset* Who signed you in?

* [Albion contracted me for the thermal survey. Check your list.]
    ENTROPY Operative 'Cipher': *doesn't look at the list* There's no survey tonight.
    ENTROPY Operative 'Cipher': And you came in the wrong door for one.
    -> cipher_alerts_team

* [Put the radio down.]
    ~ radio_interrupted = true
    Narrator: You close the distance before the handset clears its clip. He freezes with it against his chest.
    ENTROPY Operative 'Cipher': *quietly* You're fast.
    -> cipher_standoff

* [Hall 2 is venting. You want to be on a radio right now?]
    ~ radio_interrupted = true
    Narrator: It lands. His eyes go to the hydrogen panel over your shoulder, and the handset stops moving.
    ENTROPY Operative 'Cipher': ...That panel's amber.
    ENTROPY Operative 'Cipher': That panel is not supposed to be amber.
    -> cipher_standoff

// ===========================================
// HE GETS THE CALL OUT
// ===========================================

=== cipher_alerts_team ===
~ cipher_alerted_team = true

ENTROPY Operative 'Cipher': *into the handset* Voltage, Hall 1. We've got a live one.

Narrator: The handset squawks once and goes dead. He drops it and squares up.

ENTROPY Operative 'Cipher': You picked the wrong facility.

#hostile
#exit_conversation
-> start

// ===========================================
// STANDOFF - the radio is stalled, nothing is settled
// ===========================================

=== cipher_standoff ===
{operative_cipher_defeated: -> cipher_down}

ENTROPY Operative 'Cipher': *handset still in his fist* So what happens now?

* [Walk out. Leave the handset.]
    ENTROPY Operative 'Cipher': *doesn't move* Can't do that.
    -> cipher_refuses

* [Whatever Voltage told you this was, the racks vent hydrogen. People die.]
    -> cipher_doubt

+ [Say nothing.]
    Narrator: The pause stretches. He makes his decision before you make yours.
    ENTROPY Operative 'Cipher': No.
    -> cipher_refuses

=== cipher_refuses ===
ENTROPY Operative 'Cipher': I'm not walking. Not tonight.

#hostile
#exit_conversation
-> start

=== cipher_doubt ===
ENTROPY Operative 'Cipher': *flat* Nobody's in the halls at night.

ENTROPY Operative 'Cipher': That's the whole point of doing it at night.

Narrator: He says it like a line he has been given, and not one he has checked.

* [There's a night crew in Hall 2. Go and look.]
    ENTROPY Operative 'Cipher': *beat*
    ENTROPY Operative 'Cipher': ...You're lying.
    Narrator: He wants it to be a lie. He does not move to check.
    -> cipher_refuses

* [Ask him yourself. He's in the plant room.]
    ENTROPY Operative 'Cipher': *raises the handset again* I will.
    -> cipher_alerts_team

// ===========================================
// SUBDUED - interrogation hub
// Reached when Cipher is down and the player talks to him.
// ===========================================

=== cipher_down ===
{cipher_secured_done: -> cipher_secured_hub}

Narrator: He is propped against the rack frame where he went down, breathing hard, one hand flat on the concrete.

ENTROPY Operative 'Cipher': *thickly* Alright. Alright, I'm done.

-> cipher_interrogation

=== cipher_interrogation ===
* {not cipher_told_voltage_location} [Where's Voltage?]
    ~ cipher_told_voltage_location = true
    ENTROPY Operative 'Cipher': Plant room. Final position.
    ENTROPY Operative 'Cipher': Good luck getting there past Relay.
    -> cipher_interrogation

* {not cipher_told_attack_vectors} [How is the attack staged?]
    ~ cipher_told_attack_vectors = true
    ENTROPY Operative 'Cipher': We own the SCADA layer and Voltage holds the trigger. That's it. That's the whole thing.
    ENTROPY Operative 'Cipher': Only thing we couldn't get at is the hardwired shutdown in the plant room. Which is where Voltage is standing.
    -> cipher_interrogation

* [Did you know it kills people?]
    ENTROPY Operative 'Cipher': *long pause* I knew the number.
    ENTROPY Operative 'Cipher': I signed for it same as everyone else.
    -> cipher_interrogation

+ [Secure him and move on.]
    #exit_conversation
    -> cipher_secure_him

=== cipher_secure_him ===
~ cipher_secured_done = true

Narrator: You zip his wrists to the rack frame and take the Level 2 card off his belt.

#complete_task:neutralize_operative_cipher
-> start

=== cipher_secured_hub ===
Narrator: Cipher is secured to the rack frame, wrists tied, watching you work.

+ {not cipher_told_voltage_location} [Where's Voltage?]
    ~ cipher_told_voltage_location = true
    ENTROPY Operative 'Cipher': Plant room. Go on, then.
    -> cipher_secured_hub

+ {not cipher_told_attack_vectors} [How is the attack staged?]
    ~ cipher_told_attack_vectors = true
    ENTROPY Operative 'Cipher': SCADA layer's ours. Voltage has the trigger.
    -> cipher_secured_hub

+ [Leave him.]
    #exit_conversation
    ENTROPY Operative 'Cipher': *says nothing*
    -> cipher_secured_hub
