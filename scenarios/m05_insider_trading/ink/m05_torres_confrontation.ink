// ===========================================
// Mission 5: Torres Confrontation - Act 3
// Critical Choice with 5 Ending Paths
// ===========================================

// Choice tracking
VAR final_choice = ""  // "turn_double_agent", "arrest", "combat_nonlethal", "combat_lethal", "public_exposure"
VAR confront_stance = ""  // "sympathetic" or "hardline" — how the player framed Torres, paid back in the debrief
VAR torres_turned = false
VAR torres_arrested = false
VAR torres_killed = false
VAR elena_treatment_funded = false
VAR entropy_program_exposed = false

// External variables
VAR player_name = "Agent 0x00"
VAR evidence_level = 0
VAR found_medical_bills = false
VAR found_torres_journal = false
VAR found_briefcase_comms = false
VAR flag4_submitted = false // Architect communications

// ===========================================
// CONFRONTATION START (Evidence Gated)
// ===========================================

=== start ===
#speaker:narrator

{evidence_level >= 4:
    -> confrontation_scene
- else:
    You need more evidence before confronting Torres.

    {not flag4_submitted:
        Exploit the Bludit server to find The Architect's communications.
    }
    {not found_medical_bills:
        Search Torres' office for personal evidence.
    }

    #exit_conversation
    -> END
}

=== confrontation_scene ===
#speaker:narrator

[8:14 PM. Server room.]

You find David Torres alone at a terminal, USB drive connected, progress bar at 94%.

The final exfiltration. Project Heisenberg's last 27%.

He doesn't turn around.

#speaker:david_torres
#display:torres-stressed

David Torres: I know you're there. Patricia sent you, didn't she?

David Torres: Security consultant. More like SAFETYNET agent.

+ [It's over. Step away from the computer.]
    You: It's over. Step away from the computer.
    #speaker:narrator
    He turns slowly to face you.
    #speaker:david_torres
    David Torres: Is it?
    -> torres_confrontation

+ [I know everything. The Bludit server. The Recruiter. ENTROPY.]
    You: I've seen the communications. The payment records. All of it.
    David Torres: Then you know more than I did when I started.
    -> torres_confrontation

// ===========================================
// MAIN CONFRONTATION DIALOGUE
// ===========================================

=== torres_confrontation ===
#speaker:david_torres
#display:torres-defensive

David Torres: Let me guess. You found the medical bills. Elena's diagnosis.

David Torres: Stage 3 cancer. $380,000 in debt.

{found_torres_journal:
    David Torres: Did you read my journal too? See me lie to myself for three months?
}

+ [ENTROPY manipulated you. You didn't know what you were doing.]
    You: They lied. Told you it was for journalists, right?
    ~ confront_stance = "sympathetic"
    #set_global:confront_stance:sympathetic
    -> torres_knows_truth

+ [You knew exactly what you were doing.]
    You: The Architect's authorisation was explicit. The dispatch network. The casualty projection.
    ~ confront_stance = "hardline"
    #set_global:confront_stance:hardline
    -> torres_knows_truth

=== torres_knows_truth ===
#speaker:david_torres
#display:torres-breaking

{flag4_submitted:
    David Torres: "Investigative journalists exposing military corruption." That's what the Recruiter said. For about two weeks.

    David Torres: Then they showed me the casualty projections.
}

David Torres: I've known for two months. It was never going overseas. ENTROPY wants the dispatch network for themselves.

David Torres: Thirty to forty-five people dead the first time they use it. Ambulances that don't arrive in time.

+ [You knew people would die. Why did you keep going?]
    You: You KNEW people would die. Why?
    -> torres_rationalization

+ [You're no different from ENTROPY's other radicals.]
    You: You're no different from ENTROPY's other radicals.
    #speaker:narrator
    He starts to answer, then stops himself.
    -> torres_rationalization

=== torres_rationalization ===
#speaker:david_torres
#display:torres-conflicted

David Torres: Because the system is corrupt. The military-industrial complex profits from endless war—

David Torres: Because Elena was dying and I had no choice—

David Torres: Because thirty to forty-five people is... is...

David Torres: Is thirty to forty-five families. Like Elena. Like Sofia and Miguel.

{found_torres_journal:
    David Torres: You read my journal. You saw the cognitive dissonance.
    David Torres: "System must collapse for greater good." "Collateral damage is necessary for change."
    David Torres: I was lying to myself.
}

-> evidence_revelation

=== evidence_revelation ===
#speaker:david_torres

David Torres: What did I become?

David Torres: Three months ago I was trying to save my wife. Now I'm...

David Torres: I'm about to get people killed.

#speaker:narrator

This is it. The choice.

-> final_choice_moment

// ===========================================
// CRITICAL CHOICE - 4 CONVERSATION PATHS + COMBAT
// ===========================================

=== final_choice_moment ===
#speaker:narrator

What do you do?

+ [You're not too far gone. Help us, and we'll help Elena.]
    #complete_task:confront_torres
    ~ final_choice = "turn_double_agent"
    -> turn_double_agent_path

+ [You're under arrest for espionage and treason.]
    #complete_task:confront_torres
    ~ final_choice = "arrest"
    -> arrest_path

+ [Drop the philosophy. Fight or surrender. Your choice.]
    #complete_task:confront_torres
    -> combat_offer

+ [I'm exposing everything. ENTROPY's program, your crimes, all of it.]
    #complete_task:confront_torres
    ~ final_choice = "public_exposure"
    -> public_exposure_path

// ===========================================
// PATH 1: TURN DOUBLE AGENT
// ===========================================

=== turn_double_agent_path ===
#speaker:david_torres
#display:torres-hopeful

You: You've been radicalized for three months. Not three years.

You: You still have cognitive dissonance. You're not fully committed to their ideology.

You: That means you can come back.

David Torres: Come back how?

+ [Work for us. Feed ENTROPY false data. Map their network.]
    You: Witness protection. New identity. And Elena gets treatment.
    -> torres_deal_offered

=== torres_deal_offered ===
#speaker:david_torres

David Torres: Elena's treatment? Full coverage?

You: Witness protection program. Experimental treatment included.

{flag4_submitted:
    You: I found the target database. 47 other people ENTROPY's evaluating.
    You: People like you. Desperate. Vulnerable. About to be radicalized.
    David Torres: Forty-seven more?
}

David Torres: What do you need from me?

+ [Everything. The Recruiter's identity, comm protocols, payment chains.]
    You: And you keep meeting them. Pass false data. Lead us to their network.
    -> torres_accepts_turn

=== torres_accepts_turn ===
#speaker:david_torres
#display:torres-determined

David Torres: Okay. Okay, I'll do it.

David Torres: I'll help you save the other 47. The ones who haven't... who aren't monsters yet.

David Torres: And Elena?

You: Treatment starts next week. SAFETYNET will handle everything.

~ torres_turned = true
~ elena_treatment_funded = true
#complete_task:make_critical_choice

David Torres: Thank you. Thank god.

-> stop_upload

// ===========================================
// PATH 2: ARREST (Standard Justice)
// ===========================================

=== arrest_path ===
#speaker:david_torres
#display:torres-resigned

You: David Torres, you're under arrest for espionage, theft of classified materials, and conspiracy.

David Torres: I know.

David Torres: Do I get a lawyer?

+ [Yes. You have rights.]
    You: Federal custody. You'll be processed, arraigned. Standard procedure.
    David Torres: What about Elena? The kids?
    -> arrest_family_question

+ [You'll get due process.]
    David Torres: That's not an answer.
    -> arrest_family_question

=== arrest_family_question ===
#speaker:david_torres

David Torres: Elena's treatment. The $380,000. If I'm in prison...

David Torres: She dies. Sofia and Miguel watch their mother die.

+ [SAFETYNET might fund treatment as part of a cooperation deal.]
    You: If you provide full intelligence on ENTROPY. Names, locations, protocols.
    David Torres: I'll cooperate. Fully. Whatever you need.
    ~ elena_treatment_funded = true
    -> arrest_cooperation

+ [That's not my jurisdiction.]
    You: I'm an agent, not a social worker.
    David Torres: Of course.
    -> arrest_no_cooperation

=== arrest_cooperation ===
#speaker:david_torres

David Torres: I'll tell you everything about the Insider Threat Initiative.

David Torres: The Recruiter. The 23 other placements. The 47 targets.

David Torres: Just... please. Elena.

~ torres_arrested = true
~ final_choice = "arrest"
#complete_task:make_critical_choice

You: Stop the upload first. Then we'll debrief.

-> stop_upload

=== arrest_no_cooperation ===
#speaker:david_torres

David Torres: Then I want my lawyer. Now.

David Torres: I'm not saying anything else.

~ torres_arrested = true
~ final_choice = "arrest"
#complete_task:make_critical_choice

You: Fine. But that upload stops. Now.

-> stop_upload

// ===========================================
// PATH 3: COMBAT — TORRES GOES HOSTILE
// ===========================================
// Decision C: combat is resolved by the engine, not in prose.
// The player's fate for Torres is decided AFTER the knockout,
// in post_ko_choice below (reached via the npc_ko event).

=== combat_offer ===
#speaker:david_torres
#display:torres-hostile
#hostile:david_torres

You: No more talk. No more philosophy. Hands up, or I use force.

David Torres: You're not taking me. Elena needs me.

#speaker:narrator

He backs toward the terminal and lunges.

#exit_conversation
-> END

// ===========================================
// POST-KNOCKOUT: DECIDE HIS FATE
// Entered via the david_torres npc_ko eventMapping
// ===========================================

=== post_ko_choice ===
#speaker:narrator

Torres is down. The terminal still reads 97% complete.

You have a few seconds before backup arrives to decide how this gets written up.

+ [Cuff him. He answers for this in a courtroom, not on a floor.]
    ~ final_choice = "combat_nonlethal"
    ~ torres_arrested = true
    #complete_task:make_critical_choice
    -> post_ko_arrest

+ [Leave him for SAFETYNET cleanup. What happens to him next isn't on you.]
    ~ final_choice = "combat_lethal"
    ~ torres_killed = true
    #complete_task:make_critical_choice
    -> post_ko_handoff

=== post_ko_arrest ===
#speaker:narrator

You cancel the upload — 97% complete, the last 3% stays secure — and radio it in.

Torres wakes up in federal custody. Elena and the kids get a phone call, not a visit from a coroner.

#set_global:final_choice:combat_nonlethal
#exit_conversation
-> END

=== post_ko_handoff ===
#speaker:narrator

You cancel the upload — 97% complete, the last 3% stays secure — and walk out.

Whatever SAFETYNET's cleanup team decides to do with an unconscious ENTROPY asset is not a call you're sticking around for.

#set_global:final_choice:combat_lethal
#exit_conversation
-> END

// ===========================================
// PATH 4: PUBLIC EXPOSURE (Nuclear Option)
// ===========================================

=== public_exposure_path ===
#speaker:david_torres
#display:torres-horrified

You: I'm not arresting you, David.

You: I'm exposing ENTROPY's entire Insider Threat Initiative.

You: Your case. The 23 other placements. The 47 targets. All of it.

You: Every major news outlet. WikiLeaks. The whole playbook.

David Torres: You'll destroy everyone. The other targets—

You: They'll be warned. ENTROPY's program will be burned.

David Torres: And me? My family?

+ [You'll be named publicly. There's no protecting you.]
    You: Elena will read about your espionage in the news.
    You: Sofia and Miguel will see their father's face on TV.
    -> public_exposure_consequence

=== public_exposure_consequence ===
#speaker:david_torres

David Torres: My children. They're eight and eleven.

David Torres: This will follow them their entire lives.

You: You should have thought of that before committing espionage.

~ entropy_program_exposed = true
~ torres_arrested = true  // Will be arrested after exposure
~ final_choice = "public_exposure"
#complete_task:make_critical_choice

David Torres: I did this to save them. And you're going to destroy them anyway.

-> stop_upload

// ===========================================
// STOP UPLOAD SEQUENCE (conversational paths)
// ===========================================

=== stop_upload ===
#speaker:narrator

{torres_turned or torres_arrested:
    David Torres: Upload cancelled. 97% complete. Last 3% stays here.
- else:
    You force Torres away from the terminal.
    You: Cancel it. Now.
    David Torres: Done.
}

{torres_turned:
    #speaker:david_torres
    David Torres: What happens now?
    You: Debrief. Witness protection processing. Elena gets moved to a secure facility for treatment.
    David Torres: And the 47 others?
    You: We save as many as we can.
}

{torres_arrested:
    #speaker:david_torres
    David Torres: Federal prison. How long?
    You: 15 to 25 years for espionage. Maybe less with cooperation.
    {elena_treatment_funded:
        David Torres: But Elena gets treatment?
        You: SAFETYNET will honor the deal.
    - else:
        David Torres: Elena will be dead before I get out.
    }
}

{entropy_program_exposed:
    #speaker:david_torres
    David Torres: When does it go public?
    You: Within the week. Gives SAFETYNET time to warn the 47 targets.
    David Torres: And then my face is everywhere.
}

#speaker:narrator

Mission complete. ENTROPY's operation stopped.

The cost? That depends on the choice you made.

{final_choice == "turn_double_agent":
    #set_global:final_choice:turn_double_agent
}
{final_choice == "arrest":
    #set_global:final_choice:arrest
}
{final_choice == "public_exposure":
    #set_global:final_choice:public_exposure
}

#exit_conversation
-> END
