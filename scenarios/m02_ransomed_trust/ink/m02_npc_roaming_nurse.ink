// ===========================================
// Patrol NPC: Nurse Priya Raval (ambience / stakes)
// Mission 2: Ransomed Trust
// Brief, focused single-line responses. No branching.
// She is on manual obs rounds and has not got time to stop for you.
// Yorkshire, brisk, not unkind -- just genuinely busy.
// ===========================================

=== start ===
Nurse Raval: *doesn't slow down* Can't stop, love -- manual obs on all six, every fifteen minutes, no monitors.

Nurse Raval: If it's the computers you're here for, get on with it. These lot haven't got all night.

+ [Sorry. Carry on.]
    Nurse Raval: Aye. *already at the next bed*
    #exit_conversation
    -> DONE

+ [Anything you need?]
    Nurse Raval: Their charts back on a screen so I can look at six people at once again.
    Nurse Raval: That's it. That's the whole list. Go and do that.
    #exit_conversation
    -> DONE

+ [Fifteen minutes is a long gap on an ECMO bed.]
    Narrator: She stops, just for a second.

    Nurse Raval: It is.
    Nurse Raval: That's why Sister's not left bay two since three o'clock. Now shift, you're stood where I need to be.
    #exit_conversation
    -> DONE
