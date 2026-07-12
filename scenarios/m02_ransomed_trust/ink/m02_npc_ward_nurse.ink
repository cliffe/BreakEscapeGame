// ===========================================
// ACT 1 NPC: Ward Nurse
// Mission 2: Ransomed Trust
// Break Escape - Patient Advocate, Stakes Witness
// ===========================================

// Variables for tracking conversation
VAR influence = 0                 // rapport with the ward nurse (visible via #influence tags)
VAR nurse_spoke_about_patients = false
VAR nurse_spoke_about_manual = false
// Did the player engage with the patients as people, or treat this purely
// as a systems job? Determines whether she volunteers the safe override
// or sends them to dig it up themselves. (Not a hard gate -- Kim's desk
// note, the founding plaque, and the PIN cracker are all backups.)
VAR showed_empathy = false

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// FIRST ENCOUNTER
// ===========================================

=== start ===
#speaker:narrator
Narrator: The ward nurse moves between beds, writing observations on paper -- barely glancing up.

#speaker:ward_nurse
Nurse: I'm sorry, are you authorised to be in here? This is a restricted ward.

* [Security consultant. Dr. Kim authorised full access.]
    Nurse: *sighs* Right. The IT people. Please -- tell me you can fix the monitors.
    -> stakes_conversation

* [I need to understand the patient situation. What are we dealing with?]
    ~ nurse_spoke_about_patients = true
    ~ showed_empathy = true
    ~ influence += 1
    # influence_increased
    Nurse: *looks up* You want to know what we're dealing with? Come with me.
    -> ward_tour

* [What do you need right now?]
    Nurse: *flat* The computers back. All of them. Right now.
    -> stakes_conversation

=== ward_tour ===
#speaker:narrator
Narrator: She gestures at the row of beds.

#speaker:ward_nurse
Nurse: Bed four -- Mr. Okafor. 67. Ventilator. The machine runs on its own power, but the monitoring feeds into the central system. Which is down.

Nurse: Bed two -- Mrs. Hargreaves. ECMO. If that system fails without warning, she has maybe four minutes.

Nurse: Six beds. Six patients. And that's just this bay. There are two more wards.

* [How are you coping without the electronic systems?]
    -> discuss_manual_work

* [The backup generator -- what happens when it runs out?]
    -> discuss_timeline

=== stakes_conversation ===
#speaker:ward_nurse

~ nurse_spoke_about_patients = true

Nurse: 47 patients across three wards. Ventilators, ECMO, dialysis -- all networked through the central system.

Nurse: The machines themselves still run. But monitoring, alarms, medication records -- all gone.

Nurse: We're doing everything on paper. Two nurses for 47 patients with no electronic support.

#complete_task:talk_to_ward_nurse

* [How long can you keep this up manually?]
    -> discuss_timeline

* [What are you most worried about?]
    ~ showed_empathy = true
    ~ influence += 1
    # influence_increased
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

+ [I'm going to recover those systems. I promise.]
    Nurse: *quietly* Don't make promises. Just fix it.
    -> hub

+ [What happens when the generator runs out?]
    -> discuss_timeline

=== discuss_timeline ===
#speaker:ward_nurse

Nurse: Backup generator gives us maybe 12 hours from lockdown. We're four hours in.

Nurse: Eight hours. That's what you have.

Nurse: The board's talking about paying that ransom. I don't understand the politics. I just know that if those monitoring systems don't come back...

Nurse: *looks at Bed One* Statistical risk goes up every hour. The registrar did the math. I told him I didn't want to hear the numbers.

Nurse: The emergency equipment storage is at the end of the south corridor. That's where the backup kit is.

{showed_empathy:
    Nurse: There's a PIN safe on it. The override's never once changed in all my years here -- it's the hospital's founding year. If knowing that gets those monitors back a minute sooner, then take it and go.
- else:
    Nurse: There's a PIN safe on it. Old institutional code -- the sort of thing that's written down in half a dozen places if you actually stop and look. I haven't the time to walk you through it. I've patients to watch.
}

#complete_task:talk_to_ward_nurse
#complete_task:gather_pin_clues

* [I understand the stakes. I'm working as fast as I can.]
    Nurse: Good. Now please -- let me work.
    -> hub

* [Do you know Marcus Webb, the IT admin?]
    Nurse: Marcus? He's been here all night. He warned them, you know. Months ago.
    Nurse: Nobody listened. And now here we are.
    -> hub

// ===========================================
// CONVERSATION HUB (Repeatable Dialogue)
// ===========================================

=== hub ===
+ {not nurse_spoke_about_patients} [How many patients are we talking about?]
    -> stakes_conversation

+ {not nurse_spoke_about_manual} [How are you managing without the systems?]
    -> discuss_manual_work

+ [I'll let you get back to it.]
    #speaker:ward_nurse
    Nurse: Please hurry.
    #exit_conversation
    -> hub
