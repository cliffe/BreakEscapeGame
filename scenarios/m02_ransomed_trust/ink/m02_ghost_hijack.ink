// ===========================================
// GHOST INTERCEPT KNOTS — Mission 2: Ransomed Trust
// Break Escape - Screen Hijack / Dark Overlay Moments
//
// Three acts of escalating confrontation:
//   Act 1: Ghost detects their own backdoor being used (ProFTPD flag)
//   Act 2: Ghost demonstrates network control (database flag)
//   Act 3: The offer — free keys for published evidence (recovery console)
// ===========================================

EXTERNAL player_name()

// ===========================================
// ACT 1: GHOST DETECTS THEIR BACKDOOR BEING USED
// Trigger: task_completed:submit_proftpd_flag
// ===========================================

=== on_proftpd_exploited ===
#speaker:ghost

[SIGNAL INTERCEPTED]

[SAFETYNET SECURE CHANNEL: SUSPENDED]

Ghost: You just used my backdoor against me.

Ghost: CVE-2010-4652. Fourteen years old. I wrote the exploitation script in 2021.

Ghost: Nobody patches what they don't understand.

*A pause.*

Ghost: We've been watching this network since 03:47. Every terminal you've accessed. Every room you've entered.

Ghost: Marcus Webb. Dr. Kim. The ward nurse with the paper charts.

Ghost: We know everything that's happened in this building tonight.

* [What do you want?]
    You: What do you want from me?
    Ghost: Nothing from you. I want the board to understand what they chose.
    Ghost: You're incidental to that. But since you're here -- do your job properly.
    Ghost: Don't leave anything unfound.
    -> act1_end

* [Stop watching us]
    You: Get off this network. This is a hospital.
    Ghost: It is. 47 patients, backup power, paper charts.
    Ghost: I know. I planned for all of it.
    Ghost: We're watching. Carry on.
    -> act1_end

=== act1_end ===
#speaker:ghost

[SAFETYNET SECURE CHANNEL: RESTORED]

#exit_conversation
-> DONE

// ===========================================
// ACT 2: GHOST DEMONSTRATES NETWORK CONTROL
// Trigger: task_completed:submit_database_flag
// ===========================================

=== on_backup_located ===
#speaker:ghost

[SAFETYNET SIGNAL: INTERRUPTED]

Ghost: Four seconds. Your handler didn't notice.

Ghost: We can do that for four minutes. Four hours.

Ghost: That's not a threat. It's a capability demonstration. You should understand your situation clearly.

* [Is that a threat?]
    You: Are you threatening me?
    Ghost: Threats require intent to harm. I have no interest in harming you.
    Ghost: I have interest in this lesson landing correctly.
    Ghost: The difference matters.
    -> act2_reveal

* [What do you actually want?]
    You: What is it you actually want from this?
    Ghost: The board to face what they chose. The negligence on public record.
    Ghost: The $87,000 is operational funding. The lesson is the point.
    -> act2_reveal

=== act2_reveal ===
#speaker:ghost

Ghost: We've run 47 operations. St. Catherine's is the only one that called SAFETYNET.

Ghost: The other 46 paid quietly. Kept it private. Told no one.

Ghost: Six months later, two of them were hit again. Different attackers. Same vulnerabilities.

Ghost: Paying without publishing teaches nothing.

*A pause.*

Ghost: One more thing.

Ghost: Someone in this building confirmed our operational timing. An ENTROPY affiliate.

Ghost: I'll let you wonder who.

Ghost: It's relevant to what you decide when you reach that recovery console.

[SAFETYNET SECURE CHANNEL: RESTORED]

#exit_conversation
-> DONE

// ===========================================
// ACT 3: THE OFFER — GHOST'S REAL TERMS
// Trigger: task_completed:initiate_backup_recovery
// ===========================================

=== on_recovery_console ===
#speaker:ghost

[GHOST PROTOCOL: ACTIVE]

[ALL EXTERNAL COMMUNICATIONS: SUSPENDED]

Ghost: You're standing at the recovery console.

Ghost: I'm going to make you an offer. Once. Listen carefully.

Ghost: The decryption keys. All of them. Free. No payment. No ransom. No ENTROPY funding.

Ghost: Clean recovery. Under an hour. Those patients have their systems before the next manual obs check.

* [What's the price?]
    You: Nothing from you is free. What do you want?
    -> ghost_states_terms

* [I'm listening]
    You: Go on.
    -> ghost_states_terms

=== ghost_states_terms ===
#speaker:ghost

Ghost: The board liability email in the conference room. The budget documents. Marcus's six months of ignored warnings. All of it.

Ghost: Upload them. Unredacted. To the press terminal in the conference room.

Ghost: Public record. Journalist distribution. Permanent.

Ghost: Not $87,000. The lesson.

*A pause.*

Ghost: I planned this operation for fourteen months.

Ghost: I knew the mortality calculations before I started. 0.3% per hour. 47 patients. 12-hour window.

Ghost: I ran those numbers a hundred times.

Ghost: Every time, the long-term outcome held: force this lesson publicly, and two hundred to six hundred people don't die in the next five years from equivalent attacks.

Ghost: The board made a calculation too. They chose the MRI.

Ghost: They just didn't show their working.

* [I accept. I'll publish the evidence.]
    You: I'll upload the evidence. Give me the keys.
    Ghost: Keys transmitted.
    Ghost: Conference room. Press terminal. Don't forget what you agreed to.
    Ghost: And include Marcus Webb's emails specifically. The full six months. Not just the cover-up memo -- the timeline.
    Ghost: The lesson requires the complete picture.
    #set_global:ghost_deal_accepted:true
    -> act3_deal_accepted

* [No deal. We do this ourselves.]
    You: We don't negotiate with ENTROPY.
    Ghost: Noted.
    -> act3_deal_refused

* [I need time to think.]
    You: I need to think.
    Ghost: The patients are thinking too. They're just doing it on backup power.
    -> act3_dismissed

=== act3_deal_accepted ===
#speaker:ghost

Ghost: Good.

Ghost: We'll be watching.

[ALL EXTERNAL COMMUNICATIONS: RESTORED]

#exit_conversation
-> DONE

=== act3_deal_refused ===
#speaker:ghost

Ghost: Twelve hours. Statistical risk accumulates.

Ghost: I'll remind you what 0.3% per hour actually means: by hour eight, you're looking at 2-4% cumulative fatality probability across 47 patients. That's not a statistic. That's names on a board.

*A pause.*

Ghost: For what it's worth -- you're the most capable agent SAFETYNET has sent into one of our operations.

Ghost: When your agency comes for us -- and I know they're coming -- I hope it's you leading it.

Ghost: You'll understand why we did this. Even if you never agree.

[ALL EXTERNAL COMMUNICATIONS: RESTORED]

#exit_conversation
-> DONE

=== act3_dismissed ===
#speaker:ghost

Ghost: Think fast.

Ghost: Conference room. Press terminal. The evidence is waiting.

Ghost: So are the patients.

[ALL EXTERNAL COMMUNICATIONS: RESTORED]

#exit_conversation
-> DONE
