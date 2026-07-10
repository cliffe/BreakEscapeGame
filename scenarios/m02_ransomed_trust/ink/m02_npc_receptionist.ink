// ===========================================
// ACT 1 NPC: Hospital Receptionist
// Mission 2: Ransomed Trust
// Break Escape - Information Gatekeeper
// ===========================================

// External variables (set by game)
EXTERNAL player_name()

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

=== hub ===
+ [I should get moving.]
    #speaker:receptionist
    Receptionist: Good luck. We're all counting on you.
    #exit_conversation
    -> hub
