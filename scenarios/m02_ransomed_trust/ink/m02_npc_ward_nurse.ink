// ===========================================
// ACT 1 NPC: Ward Nurse
// Mission 2: Ransomed Trust
// Break Escape - Patient Advocate, Stakes Witness
// ===========================================

// Variables for tracking conversation
VAR nurse_spoke_about_patients = false
VAR nurse_spoke_about_manual = false

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// FIRST ENCOUNTER
// ===========================================

=== start ===
#speaker:ward_nurse

*She's moving between beds, writing observations on paper -- barely glances up.*

Nurse: I'm sorry, are you authorised to be in here? This is a restricted ward.

* [Show your consultant badge]
    You: Security consultant. Dr. Kim authorised full access.
    Nurse: *sighs* Right. The IT people. Please -- tell me you can fix the monitors.
    -> stakes_conversation

* [Explain the urgency]
    You: I need to understand the patient situation. What are we dealing with?
    ~ nurse_spoke_about_patients = true
    Nurse: *looks up* You want to know what we're dealing with? Come with me.
    -> ward_tour

* [Ask what she needs]
    You: What do you need right now?
    Nurse: *flat* The computers back. All of them. Right now.
    -> stakes_conversation

=== ward_tour ===
#speaker:ward_nurse

*She gestures at the row of beds.*

Nurse: Bed one -- Mr. Okafor. 67. Ventilator. The machine runs on its own power, but the monitoring feeds into the central system. Which is down.

Nurse: Bed three -- Mrs. Hargreaves. ECMO. If that system fails without warning, she has maybe four minutes.

Nurse: Six beds. Six patients. And that's just this bay. There are two more wards.

* [How are you managing?]
    You: How are you coping without the electronic systems?
    -> discuss_manual_work

* [What happens at 12 hours?]
    You: The backup generator -- what happens when it runs out?
    -> discuss_timeline

=== stakes_conversation ===
#speaker:ward_nurse

~ nurse_spoke_about_patients = true

Nurse: 47 patients across three wards. Ventilators, ECMO, dialysis -- all networked through the central system.

Nurse: The machines themselves still run. But monitoring, alarms, medication records -- all gone.

Nurse: We're doing everything on paper. Two nurses for 47 patients with no electronic support.

#complete_task:talk_to_ward_nurse

* [How long can you sustain this?]
    You: How long can you keep this up manually?
    -> discuss_timeline

* [What's the biggest risk?]
    You: What are you most worried about?
    Nurse: Missing something. A reading that would have triggered an alarm. A medication conflict in the records we can't access.
    Nurse: Every hour without monitoring is another hour where we might miss the thing that kills someone.
    -> hub

=== discuss_manual_work ===
#speaker:ward_nurse

~ nurse_spoke_about_manual = true

Nurse: Obs every 15 minutes. Manual blood pressure, pulse oximetry, temperature. Writing everything down.

Nurse: Medication schedules -- we printed everything at 2am when the system first went down. Before the printers died too.

Nurse: We're managing. But "managing" isn't good enough for ICU-level patients. Not for 12 hours.

#complete_task:talk_to_ward_nurse

+ [I'll do everything I can]
    You: I'm going to recover those systems. I promise.
    Nurse: *quietly* Don't make promises. Just fix it.
    -> hub

+ [Ask about the generator]
    -> discuss_timeline

=== discuss_timeline ===
#speaker:ward_nurse

Nurse: Backup generator gives us maybe 12 hours from lockdown. We're four hours in.

Nurse: Eight hours. That's what you have.

Nurse: The board's talking about paying that ransom. I don't understand the politics. I just know that if those monitoring systems don't come back...

Nurse: *looks at Bed One* Statistical risk goes up every hour. The registrar did the math. I told him I didn't want to hear the numbers.

#complete_task:talk_to_ward_nurse

* [I understand. I'll work as fast as I can.]
    You: I understand the stakes. I'm working as fast as I can.
    Nurse: Good. Now please -- let me work.
    -> hub

* [What do you know about the IT admin?]
    You: Do you know Marcus Webb, the IT admin?
    Nurse: Marcus? He's been here all night. He warned them, you know. Months ago.
    Nurse: Nobody listened. And now here we are.
    -> hub

// ===========================================
// CONVERSATION HUB (Repeatable Dialogue)
// ===========================================

=== hub ===
+ {not nurse_spoke_about_patients} [Ask about the patients]
    -> stakes_conversation

+ {not nurse_spoke_about_manual} [Ask how they're managing]
    -> discuss_manual_work

+ {true} [Leave her to her work]
    #speaker:ward_nurse
    Nurse: Please hurry.
    #exit_conversation
    -> DONE
