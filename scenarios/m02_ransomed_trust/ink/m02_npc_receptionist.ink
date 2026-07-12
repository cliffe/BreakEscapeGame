// ===========================================
// ACT 1 NPC: Hospital Receptionist
// Mission 2: Ransomed Trust
// Break Escape - Information Gatekeeper
//
// Primary job: signpost the player to Dr. Kim.
// But a player who actually engages her gets something the others can't
// give -- an early, optional breadcrumb toward the ENTROPY inside asset.
// She works the front desk; she's the one person who'd notice a man who
// never signs her visitor log. Pure foreshadowing (no puzzle flags), so
// the curious player walks in already suspicious of the plainclothes
// "supervisor" by the conference room.
// ===========================================

// External variables (set by game)
EXTERNAL player_name()

// Local conversation tracking
VAR asked_situation = false
VAR observed_stranger = false

// ===========================================
// FIRST ENCOUNTER
// ===========================================

=== start ===
#speaker:receptionist

Receptionist: *looks up from paper forms* Sorry -- everything's manual right now. The computers are... well, you've probably heard.

* [I'm looking for Dr. Kim. She's expecting me.]
    -> direct_to_kim

* [I'm the cybersecurity consultant. Here for the ransomware response.]
    -> introduce_as_consultant

* [How bad is it in there?]
    -> ask_situation

=== introduce_as_consultant ===
#speaker:receptionist

Receptionist: Oh thank goodness. Dr. Kim said you'd be coming.

Receptionist: She's down the west corridor -- the admin block. Her office is on the left.

Receptionist: You can't miss it. She'll be the one who looks like she hasn't slept in two days.

#unlock_task:meet_dr_kim

+ [Thanks. I'll find her.]
    -> hub

+ [How bad is it in there?]
    -> ask_situation

=== direct_to_kim ===
#speaker:receptionist

Receptionist: Dr. Kim, yes. She's in the admin block -- west corridor, first door on the left.

Receptionist: She's been managing the response since 3am. Please tell me you can fix this.

#unlock_task:meet_dr_kim

+ [We're going to do everything we can.]
    Receptionist: Good. Those patients need their monitoring systems back.
    -> hub

+ [How bad is it in there?]
    -> ask_situation

=== ask_situation ===
#speaker:receptionist
~ asked_situation = true

Receptionist: It's -- it's bad. All the computers went down at 2:47am. Everything.

Receptionist: Patient monitoring, records, medication schedules... the ward nurses are doing everything on paper.

Receptionist: 47 patients on life support. The backup generators have maybe 12 hours.

* [That's serious. I need to speak to Dr. Kim immediately.]
    Receptionist: West corridor, admin block. First door on the left.
    #unlock_task:meet_dr_kim
    -> hub

* [Has anyone contacted the police?]
    Receptionist: IT crimes unit. They said they're -- *checks notes* -- "monitoring the situation."
    Receptionist: Whatever that means. Dr. Kim's down the west corridor if you need her.
    #unlock_task:meet_dr_kim
    -> hub

// ===========================================
// CONVERSATION HUB
// ===========================================

=== hub ===
+ {not observed_stranger} [Before I go -- you're on this desk all night. Anyone come through who doesn't belong?]
    -> observe_stranger

+ {not asked_situation} [How bad is it in there?]
    -> ask_situation

+ [I should get moving.]
    #speaker:receptionist
    Receptionist: Good luck. We're all counting on you.
    #exit_conversation
    -> hub

// ===========================================
// OPTIONAL: EARLY BREADCRUMB TOWARD THE INSIDE ASSET
// Foreshadowing only -- rewards the curious player with a head start.
// Matches the asset's own cover ("posted since the summer", conference
// room / comms relay) so it pays off when they meet him later.
// ===========================================

=== observe_stranger ===
#speaker:receptionist
~ observed_stranger = true

Receptionist: *lowers her voice* ...Now you mention it. There's a man on the night security detail. Plain suit -- no uniform, no scrubs. Very polite. Keeps himself down by the conference room and the comms relay.

Receptionist: Everyone signs this log. Every contractor, every engineer, all night long. He never has. Says he's "posted," like that's answer enough.

Receptionist: Probably nothing. They keep telling me it's crisis protocol. But you did ask.

+ [How long has he been around?]
    #speaker:receptionist
    Receptionist: Since the summer, he tells me. Funny thing -- I've worked this desk eleven years, and I'd never once clapped eyes on him before all this started.
    -> hub

+ [Which way is the conference room?]
    #speaker:receptionist
    Receptionist: East side, past the wards. But you'll want Dr. Kim first -- west corridor, admin block.
    #unlock_task:meet_dr_kim
    -> hub

+ [Thanks. I'll keep an eye out.]
    #speaker:receptionist
    Receptionist: Probably just me being jumpy. It's been that kind of night.
    -> hub
