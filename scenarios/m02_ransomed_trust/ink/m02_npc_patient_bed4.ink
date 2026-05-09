// ===========================================
// Ward Patient: Bed 4 (Mr Okafor, cardiac)
// Mission 2: Ransomed Trust
// Break Escape - Stakes witness / life support
// ===========================================

=== start ===
Narrator: Mr Okafor, 67, is lying motionless in Bed 4. His ventilator cycles rhythmically -- the machine itself still runs, but the central monitoring feed that would display his vitals at the nursing station is offline.

Narrator: A paper chart hangs at the foot of the bed. The last manual observation was recorded 14 minutes ago.

+ [Check the paper chart]
    Narrator: Blood pressure 138/86. O2 sat 94%. Last check 14 minutes ago. Nurse initials: S.H.
    Narrator: The chart would normally auto-update every 30 seconds. Now it depends entirely on when a nurse can get back to him.
    -> hub

+ [Step away]
    #exit_conversation
    -> hub

=== hub ===
+ [Leave him to rest]
    #exit_conversation
    -> hub
