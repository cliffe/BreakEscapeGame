// ===========================================
// SECURITY GUARD - ENTRY CHECKPOINT
// Mission 4: Critical Failure
// Break Escape - Facility Entry Social Engineering
// ===========================================

// Variables for tracking entry approach
VAR guard_suspicious = false
VAR entry_method = ""            // credentials, smooth_talk, stealth

// External variables (set by game)
EXTERNAL player_name()
EXTERNAL chen_trust_level()

// ===========================================
// ENTRY DIALOGUE
// Location: Main Entrance
// Task 1.1: Enter Facility
// ===========================================

=== security_guard_entry ===
#speaker:security_guard

// Guard at desk, looks up as player approaches

Morning. Kind of early for visitors.

* [Present state auditor credentials]
    You: State EPA auditor. I'm here for an inspection.
    -> guard_credentials_check

* [I'm here for an inspection]
    You: I'm here for an inspection of the facility.
    -> guard_inspection_response

* [Bypass guard, attempt stealth entry]
    You: (Attempt to slip past the guard)
    -> guard_stealth_attempt

=== guard_credentials_check ===
#speaker:security_guard

// Guard examines credentials

State auditor? This early?

// Guard examines badge, checks clipboard

Alright, sign in here.

// Guard hands clipboard

Mr. Chen mentioned something about a surprise inspection. He's not happy about it, fair warning.

* [I'll keep that in mind. Thank you]
    You: I'll keep that in mind. Thank you.
    -> guard_entry_granted

* [It's routine. Where can I find him?]
    You: It's routine procedure. Where can I find Mr. Chen?
    -> guard_directions

=== guard_directions ===
#speaker:security_guard

Administration offices, down that hall.

Should be in his office or the Control Room at this hour.

-> guard_entry_granted

=== guard_entry_granted ===
#speaker:security_guard

~ entry_method = "credentials"

Go on through. Badge scanner there will let you in.

// Interior door unlocks

// TRIGGERS: Task 1.1 complete (enter_facility)

-> END

=== guard_inspection_response ===
#speaker:security_guard

Inspection? Nobody told me about any inspection.

* [It's a surprise inspection. Check with your supervisor]
    You: It's a surprise inspection. You can check with your supervisor if needed.
    -> guard_confused_allows

* [Show credentials]
    You: Here are my credentials.
    -> guard_credentials_check

=== guard_confused_allows ===
#speaker:security_guard

// Guard confused but doesn't want to challenge authority

Uh... okay. Sign in anyway. Cover my bases.

// Guard hands clipboard

-> guard_entry_granted

=== guard_stealth_attempt ===
#speaker:security_guard

~ guard_suspicious = true

// Player attempts to bypass guard - guard notices

Hey! Where do you think you're going?

* [Run past guard]
    You: (Sprint past the guard toward the door)
    -> guard_alarm_raised

* [Smooth talk out of situation]
    You: Sorry, I'm testing your entry protocols. Part of the security audit.
    -> guard_smooth_talk

* [Show credentials]
    You: My apologies. Here are my credentials.
    -> guard_credentials_check

=== guard_alarm_raised ===
#speaker:security_guard

~ guard_suspicious = true

// Guard raises alarm - fails stealth entry

Security! We've got an intruder!

// Player must leave and try alternate entry (loading dock)

// TRIGGERS: Alarm raised, stealth entry failed

-> END

=== guard_smooth_talk ===
#speaker:security_guard

// Guard considers the explanation

Security audit? Testing entry protocols?

* [Convince guard]
    You: Yes, exactly. You challenged me appropriately. That's a pass.
    -> guard_fooled

* [Guard doesn't buy it]
    // Guard remains skeptical
    -> guard_demands_credentials

=== guard_fooled ===
#speaker:security_guard

Oh. Uh, okay. Should I still log you in?

* [Yes, proper procedure]
    You: Yes, that would be proper procedure.
    -> guard_entry_granted

=== guard_demands_credentials ===
#speaker:security_guard

~ guard_suspicious = true

Right. I need to see some ID before I let you through.

-> guard_credentials_check
