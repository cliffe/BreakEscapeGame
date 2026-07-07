// ===========================================
// Patrol NPC: Roaming Ward Nurse (ambiance / stakes)
// Mission 2: Ransomed Trust
// Brief, focused single-line responses. No branching.
// She is on manual obs rounds and hasn't the time to stop.
// ===========================================

=== start ===
#speaker:roaming_ward_nurse
Nurse: *doesn't slow down* Can't stop, love -- manual obs on all six beds, every fifteen minutes, no monitors.

Nurse: If it's the systems you're here for, get on with it. These patients haven't got all night.

+ [Sorry -- carry on]
    #speaker:roaming_ward_nurse
    Nurse: Right. *moves to the next bed*
    #exit_conversation
    -> DONE
+ [Anything you need?]
    #speaker:roaming_ward_nurse
    Nurse: Their charts back on a screen. That's all. Go and make that happen.
    #exit_conversation
    -> DONE
