// ===========================================
// ACT 2/3 PHONE NPC: Ghost (Ransomware Incorporated)
// Mission 2: Ransomed Trust
// Break Escape - Antagonist, True Believer, Ideological Counter
// ===========================================

// Variables for tracking interactions
VAR ghost_contacted_player = false
VAR ghost_persuasion_attempted = false
VAR player_confronted_ghost = false

// Variables synced from globalVars by engine at call-open
VAR ransom_decision_made = false
VAR paid_ransom = false

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// INITIAL CONTACT (Mid-Mission)
// ===========================================

=== start ===

{ghost_contacted_player:
    -> return_contact
}

> DEVICE ACTIVE
> NETWORK BRIDGE: ST. CATHERINE'S LAN -- [REDACTED]
> CONTACT: GHOST

#speaker:ghost

Ghost: You found it.

Ghost: Installed during a fire drill, six weeks ago. Been sitting on your LAN since October.

Ghost: SAFETYNET sent one person. I planned for a team.

~ ghost_contacted_player = true
#set_global:ghost_contacted_player:true

* [Who are you?]
    You: Ghost. Who are you, really?
    Ghost: Someone who spent fourteen months preparing for tonight.
    Ghost: Ransomware Incorporated. You know what we did. Ask me why.
    -> ghost_introduction

* [You attacked a hospital]
    You: You encrypted patient records. People are on life support.
    -> player_threatens

* [Stay silent]
    You: ...
    Ghost: Fine. I'll explain.
    -> ghost_introduction

=== ghost_introduction ===
#speaker:ghost

Ghost: We're not here for profit. St. Catherine's ignored security warnings for six months.

Ghost: Marcus Webb's email, May 17th: "ProFTPD vulnerability, critical severity, immediate patching required."

Ghost: Hospital response: "Budget constraints. Defer to next fiscal year."

* [That doesn't justify attacking patients]
    You: That doesn't justify encrypting patient records. People could die.
    -> ghost_justification

* [So this is ideological?]
    You: You're teaching them a lesson? That's your justification?
    -> ghost_philosophy

=== player_threatens ===
#speaker:ghost

Ghost: Patients dying? No. Patients at risk. Calculated risk.

Ghost: 0.3% per hour fatality probability. 47 patients. 12-hour window.

Ghost: 1-2 deaths if they pay immediately. 4-6 if they delay for manual recovery.

Ghost: We didn't create that risk. St. Catherine's negligence did. We're revealing consequences.

* [You calculated death probabilities?]
    You: You have spreadsheets of how many people will die?
    -> ghost_confirms_calculations

* [That's monstrous]
    You: You're using human lives as leverage. That's evil.
    -> ghost_philosophy

=== ghost_confirms_calculations ===
#speaker:ghost

Ghost: Of course I calculated probabilities. This is risk assessment, not recklessness.

Ghost: St. Catherine's board never ran these numbers. They deferred $85K security spending for a $3.2M MRI.

Ghost: They gambled with patient safety. We're making the stakes visible.

* [You're rationalizing terrorism]
    You: This is terrorism, not education.
    Ghost: Terrorism is violence for political aims. This is consequence for negligence.
    Ghost: We're the mirror showing them what they've always risked.
    -> ghost_philosophy

* [What do you want?]
    -> ransom_demand

=== ghost_justification ===
#speaker:ghost

Ghost: Justify? The math justifies itself.

Ghost: St. Catherine's ignored Marcus's warnings. They chose shiny equipment over patient data security.

Ghost: Now they face consequences. Expensive, painful, unforgettable.

-> ghost_philosophy

=== ghost_philosophy ===
#speaker:ghost

Ghost: Healthcare sector is systemically vulnerable. 214 hospitals scanned. 147 have critical vulnerabilities.

Ghost: Traditional cybersecurity consultants charge millions for reports nobody reads.

Ghost: We charge thousands for lessons nobody forgets.

Ghost: After this, St. Catherine's will triple cybersecurity budgets. Forty other hospitals will too.

Ghost: Long-term -- we prevent hundreds of deaths across five years. The modelling holds every time I run it.

* [You don't get to make that calculation]
    You: You don't get to decide whose lives are worth risking.
    Ghost: I didn't decide. St. Catherine's board decided when they cut the security budget.
    Ghost: We're just the consequence they tried to ignore.
    -> ransom_demand

* [That's utilitarian logic]
    You: Utilitarian harm for long-term good. Slippery slope.
    Ghost: Perhaps. But someone has to force change. Systemic negligence doesn't fix itself.
    Ghost: The alternative is more hospitals get attacked. More patients die.
    Ghost: We're harsh teachers. But institutional change requires pain.
    -> ransom_demand

// ===========================================
// RANSOM DEMAND
// ===========================================

=== ransom_demand ===
#speaker:ghost

Ghost: Here's what happens next.

Ghost: Pay 2.5 BTC -- $87,000. Systems restored in 2-4 hours. 1-2 patient deaths, statistical minimum.

Ghost: Don't pay. Manual recovery takes 12 hours. 4-6 patient deaths. Malpractice lawsuits. Hospital reputation destroyed.

Ghost: Your choice, SAFETYNET.

~ ghost_persuasion_attempted = true
#set_global:ghost_persuasion_attempted:true

* [We'll recover independently]
    You: We're not funding terrorism. We'll recover independently.
    -> ghost_warns_consequences

* [Threaten to trace Ghost]
    You: We'll trace the payment. Find you. Arrest you.
    -> ghost_laughs_at_threat

* [End communication]
    You: We're done here.
    Ghost: Time's running out. Patients are counting on you.
    #exit_conversation
    -> DONE

=== ghost_warns_consequences ===
#speaker:ghost

Ghost: Independent recovery. 12 hours. 4-6 deaths.

Ghost: Those deaths are on your conscience, not ours.

Ghost: St. Catherine's negligence created this crisis. You could save them. You're choosing ideology over lives.

Ghost: Remember that when families ask why their loved ones died.

#exit_conversation
-> DONE

=== ghost_laughs_at_threat ===
#speaker:ghost

Ghost: Trace me? Crypto Anarchists handle our payment infrastructure.

Ghost: Monero mixing across 47 wallets. Multi-hop transaction routing. Ghost Protocol guarantees anonymity.

Ghost: Good luck, agent. You'll need it.

#exit_conversation
-> DONE

// ===========================================
// RETURN CONTACT (After Decision)
// ===========================================

=== return_contact ===
#speaker:ghost

[ENCRYPTED CHANNEL - GHOST]

{ransom_decision_made:
    -> post_decision_contact
- else:
    -> mid_mission_contact
}

=== mid_mission_contact ===
#speaker:ghost

Ghost: Still working? Time's running out.

Ghost: 47 patients. Backup power failing. Families watching monitors.

Ghost: $87,000 vs. human lives.

* [You're trying to pressure me]
    You: This is psychological manipulation.
    Ghost: This is reality. 0.3% per hour. The clock doesn't care about your feelings.
    -> end_contact

* [We'll stop you]
    You: SAFETYNET will dismantle ENTROPY. You'll be arrested.
    Ghost: Maybe. But St. Catherine's will never ignore cybersecurity again. Mission accomplished.
    -> end_contact

* [End call]
    -> end_contact

=== post_decision_contact ===
#speaker:ghost

{paid_ransom:
    -> ransom_paid_response
- else:
    -> ransom_refused_response
}

=== ransom_paid_response ===
#speaker:ghost

Ghost: Decryption keys delivered. Systems restoring.

Ghost: St. Catherine's board approved a $250K security budget within 24 hours. More than triple what Marcus requested.

Ghost: That's what this was for.

* [You're still a terrorist]
    You: You killed people. That's terrorism.
    Ghost: Pre-existing complications, accelerated by system downtime. Medical records confirm it.
    Ghost: Those patients were already dying. We changed the timeline, not the outcome.
    Ghost: I've reviewed every case. I know their names.
    -> ghost_final_statement

* [This won't stop SAFETYNET]
    You: We're coming for you. ENTROPY won't last.
    Ghost: Maybe. But how many hospitals improve security before you find us?
    Ghost: Every one of them is lives saved long-term. That's the arithmetic.
    -> ghost_final_statement

=== ransom_refused_response ===
#speaker:ghost

Ghost: Independent recovery. 4-6 patient deaths confirmed.

Ghost: Ventilator complications. Dialysis failures. Cardiac arrests during extended downtime.

Ghost: Those deaths are on your conscience. You could have paid. You chose ideology.

* [No. Those deaths are on YOU]
    You: YOU attacked the hospital. YOU encrypted patient records. This is YOUR fault.
    -> ghost_rejects_responsibility

* [We denied ENTROPY funding]
    You: $87,000 denied. No funding for your next attack.
    -> ghost_acknowledges_loss

=== ghost_rejects_responsibility ===
#speaker:ghost

Ghost: I accept operational responsibility. But St. Catherine's created the vulnerability.

Ghost: Six months of ignored warnings. Budget negligence. Institutional failure.

Ghost: We exploited it. They enabled it. The blame is shared whether you accept that or not.

-> ghost_final_statement

=== ghost_acknowledges_loss ===
#speaker:ghost

Ghost: $87,000 lost. Operational setback acknowledged.

Ghost: But St. Catherine's board approved $400K emergency security budget -- panic response.

Ghost: Forty hospitals implementing emergency upgrades. Sector-wide impact achieved.

Ghost: Educational outcome: success. Worth the cost.

-> ghost_final_statement

// ===========================================
// FINAL STATEMENT (Unrepentant)
// ===========================================

=== ghost_final_statement ===
#speaker:ghost

Ghost: Here's what you need to understand, SAFETYNET.

Ghost: I calculated the risks. I planned the operation. I accept the consequences.

Ghost: If you arrest me, I'll go to prison without resistance.

Ghost: Because St. Catherine's will never ignore cybersecurity again. Neither will forty other hospitals.

Ghost: That's worth it. That's the mission. That's what ENTROPY is for.

* [You're a fanatic]
    You: Calculated harm is still harm. You're a fanatic.
    Ghost: Fanaticism is believing despite evidence. I have statistical models, outcome projections, verified results.
    Ghost: This is evidence-based ideology. There's a difference.
    -> ghost_disconnects

* [We'll stop ENTROPY]
    You: This isn't over. We're coming for the whole network.
    Ghost: Good luck. The Architect coordinates six cells. We're everywhere.
    Ghost: Shut down one, five remain. Hydra principle.
    -> ghost_disconnects

=== ghost_disconnects ===
#speaker:ghost

Ghost: This conversation is over.

Ghost: Remember: ENTROPY didn't create healthcare vulnerabilities. We just revealed them.

Ghost: The real enemy is institutional negligence. We're the symptom, not the disease.

> CHANNEL TERMINATED

#exit_conversation
-> DONE

// ===========================================
// END CONTACT
// ===========================================

=== end_contact ===
#speaker:ghost

Ghost: Time's running out. Choose wisely.

> CONTACT CLOSED

#exit_conversation
-> DONE

// ===========================================
// ACT 1: GHOST DETECTS THEIR BACKDOOR BEING USED
// Trigger: task_completed:submit_proftpd_flag
// ===========================================

=== on_proftpd_exploited ===
#speaker:ghost

> EXPLOIT SIGNATURE DETECTED
> CVE-2010-4652 -- ST. CATHERINE'S BACKUP SERVER

Ghost: You just used my backdoor against me.

Ghost: CVE-2010-4652. Fourteen years old. I wrote the exploitation script in 2021.

Ghost: Nobody patches what they don't understand.

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

> CONTACT SUSPENDED

#exit_conversation
-> DONE

// ===========================================
// ACT 2: GHOST DEMONSTRATES NETWORK CONTROL
// Trigger: task_completed:submit_database_flag
// ===========================================

=== on_backup_located ===
#speaker:ghost

> NETWORK ACCESS: 4 SECONDS
> CAPABILITY DEMONSTRATION

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

Ghost: One more thing.

Ghost: Someone in this building confirmed our operational timing. An ENTROPY affiliate.

Ghost: I'll let you wonder who.

Ghost: It's relevant to what you decide when you reach that recovery console.

> CONTACT SUSPENDED

#exit_conversation
-> DONE

// ===========================================
// ACT 3: THE OFFER
// Trigger: task_completed:initiate_backup_recovery
// ===========================================

=== on_recovery_console ===
#speaker:ghost

> GHOST PROTOCOL: ACTIVE
> OFFER INCOMING -- LISTEN CAREFULLY

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
    Ghost: Include Marcus Webb's emails specifically. The full six months. Not just the cover-up memo -- the timeline.
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

> GHOST PROTOCOL: CLOSED

#exit_conversation
-> DONE

=== act3_deal_refused ===
#speaker:ghost

Ghost: Twelve hours. Statistical risk accumulates.

Ghost: I'll remind you what 0.3% per hour actually means: by hour eight, you're looking at 2-4% cumulative fatality probability across 47 patients. That's not a statistic. That's names on a board.

Ghost: For what it's worth -- you're the most capable agent SAFETYNET has sent into one of our operations.

Ghost: When your agency comes for us -- and I know they're coming -- I hope it's you leading it.

Ghost: You'll understand why we did this. Even if you never agree.

> GHOST PROTOCOL: CLOSED

#exit_conversation
-> DONE

=== act3_dismissed ===
#speaker:ghost

Ghost: Think fast.

Ghost: Conference room. Press terminal. The evidence is waiting.

Ghost: So are the patients.

> GHOST PROTOCOL: CLOSED

#exit_conversation
-> DONE
