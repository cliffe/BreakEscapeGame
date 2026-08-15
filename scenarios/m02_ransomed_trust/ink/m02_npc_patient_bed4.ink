// ===========================================
// Ward Patient: Bed 4 -- Mr Pryce (ventilated, cardiac)
// Mission 2: Ransomed Trust
//
// He can speak, barely -- four or five words between breaths. That is the
// point of him: the ward is not a set of statistics, it is a retired bus
// engineer from Peckham who is awake and knows exactly what the dark screen
// above his head means.
// ===========================================

VAR spoke_to_player = false
VAR read_chart = false

=== start ===
{spoke_to_player:
    -> returning
}
~ spoke_to_player = true

Narrator: Mr Pryce is awake. The ventilator beside him cycles on its own power; the monitor above the bed, which should be reporting him to the nurses' station, is dark.

Narrator: His eyes track to you, then to the dead screen above the bed.

Mr Pryce: ...you the one.

Mr Pryce: *breath* Fixing it.

* [I am. Systems should be back tonight.]
    Mr Pryce: *long breath* Good.
    Mr Pryce: Sister's been. Every fifteen minutes. *breath* All night.
    Mr Pryce: She's tired. Tell someone.
    -> hub

* [Yes. How are you doing, Mr Pryce?]
    Narrator: One hand moves, barely.

    Mr Pryce: Breathing.
    Mr Pryce: Machine's doing it. *breath* But it's getting done.
    Mr Pryce: Forty years I fixed buses. *breath* Never trusted a thing with no gauge on it.
    -> hub

* [Rest. I'll come back when it's done.]
    Mr Pryce: *breath* Mm.
    -> hub

=== hub ===
+ {not read_chart} [Check the paper chart at the foot of the bed.]
    -> the_chart

+ [I'll let you rest.]
    Mr Pryce: *breath* Go on.
    #exit_conversation
    -> hub

=== the_chart ===
~ read_chart = true

Narrator: Blood pressure 138 over 86. Sats 94 percent. Last observation recorded fourteen minutes ago in biro, initialled A.D.

Narrator: The monitor above the bed would have written this line every thirty seconds and flagged anything drifting. Tonight it depends entirely on when a nurse can next get back down the row.

Narrator: He watches you read it.

Mr Pryce: Fourteen minutes.

Mr Pryce: *breath* Long time, fourteen minutes.

-> hub

=== returning ===
Mr Pryce: *eyes open* ...still here.
-> hub
