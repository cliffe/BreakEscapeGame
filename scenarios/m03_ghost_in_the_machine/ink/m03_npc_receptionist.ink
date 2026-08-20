EXTERNAL player_name()

VAR receptionist_influence = 0
VAR badge_received = false
VAR topic_victoria = false
VAR topic_company_history = false
VAR topic_james = false
VAR pin_hint_given = false
VAR clone_reception_badge_done = false

=== start ===
#speaker:receptionist
{ not badge_received:
    #display:receptionist-professional
    Receptionist: Good afternoon! You must be {player_name()}.
    Receptionist: Ms. Sterling mentioned you'd be coming in for a consultation.
    Receptionist: Let me get you checked in.
    -> badge_process
}
{ badge_received:
    #display:receptionist-friendly
    Receptionist: Hi again! How's your visit going?
    -> hub
}

=== badge_process ===
#speaker:receptionist
Receptionist: I just need you to sign in here, and I'll print you a visitor badge.
[She slides a clipboard across the desk]
Receptionist: Ms. Sterling's in the conference room. Second door on the right down that hallway.
* [Thank you - sign in]
    #give_item:id_badge:visitor_badge
    ~ badge_received = true
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    You sign the visitor log.
    Receptionist: Here's your badge. Please keep it visible while you're in the building.
    Receptionist: The conference room is through the card reader on the left — RFID access. Ms. Sterling usually authorises visitors herself, so just head over when you're ready.
    Receptionist: And welcome to WhiteHat Security!
    -> first_impression_choice
* [Before I meet with Victoria, can you tell me a bit about WhiteHat Security?]
    ~ receptionist_influence = receptionist_influence + 10
    # influence_increased
    Receptionist: Of course! We're a cybersecurity research and penetration testing firm.
    -> company_overview
* [Just sign quickly and head to meeting]
    #give_item:id_badge:visitor_badge
    ~ badge_received = true
    You quickly sign the log.
    Receptionist: Here's your badge. Ms. Sterling's in the conference room — through the card reader on your left.
    #exit_conversation
    -> DONE

=== company_overview ===
#speaker:receptionist
Receptionist: WhiteHat Security was founded in 2010 by Victoria Sterling.
Receptionist: We do penetration testing, security audits, and advanced research training.
{ receptionist_influence >= 10:
    Receptionist: We also have a research division - Zero Day training programs. Very cutting-edge stuff.
}
~ topic_company_history = true
~ pin_hint_given = true
* [2010 founding - that's the PIN to the safe!]
    [Mental note: 2010 might be useful...]
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    You: 2010, interesting. Victoria must be proud of how far the company's come.
    Receptionist: Oh, very much so. She has a whole display of awards in her office.
    -> badge_process
* [What kind of training does Zero Day offer?]
    Receptionist: [Slightly evasive] Advanced penetration testing techniques. For serious researchers.
    Receptionist: Ms. Sterling is very selective about who gets into the program.
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    -> badge_process

=== first_impression_choice ===
#speaker:receptionist
Receptionist: Is this your first time working with a cybersecurity firm?
* [I've done some freelance pen testing]
    ~ receptionist_influence = receptionist_influence + 10
    # influence_increased
    You: I've done freelance penetration testing before. Looking to level up.
    Receptionist: Well, you're in the right place! Ms. Sterling is brilliant.
    -> hub
* [Yes, I'm new to the field]
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    You: Relatively new, yes. Still learning.
    Receptionist: That's exciting! Everyone here is very passionate about security.
    -> hub
* [I should head to the conference room. Don't want to keep Victoria waiting.]
    Receptionist: Of course! Down the hall, second door on the right.
    #exit_conversation
    -> DONE

=== hub ===
+ {not topic_victoria} [Ask about Victoria Sterling]
    -> ask_victoria
+ {not topic_james} [Ask about other employees]
    -> ask_james
+ {not topic_company_history && not pin_hint_given} [Ask about company history]
    -> ask_company_history
+ {receptionist_influence >= 15} [Ask about the building layout]
    -> ask_building_layout
+ {badge_received && not clone_reception_badge_done} [Lean across the desk to examine the directory — cloner in range]
    -> clone_badge_opportunity
+ [End conversation]
    Receptionist: Have a great visit!
    #exit_conversation
    -> DONE

=== ask_victoria ===
#speaker:receptionist
~ topic_victoria = true
~ receptionist_influence = receptionist_influence + 5
# influence_increased
Receptionist: Ms. Sterling is amazing. She's a DEFCON speaker, published researcher, the whole package.
Receptionist: And she really cares about the work. Sometimes she's here until midnight.
{ receptionist_influence >= 20:
    Receptionist: Between you and me, she can be intense. Very particular about her research.
    Receptionist: But she's fair. If you're good at what you do, she'll respect you.
}
* [She sounds dedicated]
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    You: She sounds very dedicated to the work.
    Receptionist: Absolutely. Cybersecurity is her passion.
    -> hub
* [Midnight work sessions? That's some serious dedication.]
    Receptionist: Yeah, sometimes I see her car still in the lot when I leave at 6.
    Receptionist: She has a whole setup in her office - coffee maker, the works.
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    -> hub
+ [Continue]
    -> hub

=== ask_james ===
#speaker:receptionist
~ topic_james = true
~ receptionist_influence = receptionist_influence + 5
# influence_increased
Receptionist: Well, there's Danny Foster - he's one of our senior consultants.
Receptionist: Really nice guy. Always brings donuts on Fridays.
{ receptionist_influence >= 15:
    Receptionist: He's been a bit stressed lately, though. I think he's working on a big project.
}
* [What kind of consulting work does Danny do?]
    Receptionist: Penetration testing, mostly. He goes on-site to client locations for security audits.
    Receptionist: He's been with WhiteHat since the beginning - 2010, I think.
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    -> hub
* [Where does Danny work? In case I run into him.]
    Receptionist: His office is down the main hallway, past the server room.
    Receptionist: Though he's usually out at client sites during the day.
    -> hub
+ [Continue]
    -> hub

=== ask_company_history ===
#speaker:receptionist
~ topic_company_history = true
~ pin_hint_given = true
~ receptionist_influence = receptionist_influence + 5
# influence_increased
Receptionist: WhiteHat Security was founded in 2010 by Victoria Sterling.
Receptionist: There's actually a plaque right over there [gestures to wall] with the founding year and mission statement.
Receptionist: "Security Through Economics" - that's our motto.
* [That's an unusual motto. What does it mean?]
    Receptionist: [Uncertain] Something about market-driven security research? Ms. Sterling explains it better than I can.
    Receptionist: She has strong opinions about how the security industry should work.
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    -> hub
* [2010 - I'll remember that]
    [Mental note: 2010 might be important...]
    You: 2010. That's a significant year for the company then.
    Receptionist: Absolutely! Ms. Sterling is very proud of everything we've built since then.
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    -> hub
+ [Continue]
    -> hub

=== ask_building_layout ===
#speaker:receptionist
~ receptionist_influence = receptionist_influence + 5
# influence_increased
Receptionist: Sure! It's a pretty straightforward layout.
Receptionist: Reception here, then through the card reader to the conference area, main offices down the central hallway.
Receptionist: Server room and IT area in the back - executive access only.
Receptionist: And Ms. Sterling's office is in the executive wing on the north side.
* [Is anyone here after business hours?]
    Receptionist: Usually just Ms. Sterling if she's working late. And we have a night security guard - makes rounds to keep the place safe.
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    -> hub
* [Even the conference area needs a card? That's pretty tight security.]
    Receptionist: RFID badges throughout - conference area, server room, executive wing. Ms. Sterling is very particular about access control.
    [She taps the badge on her lanyard.]
    Receptionist: Staff badges cover the whole building. Visitors normally get escorted through.
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    -> hub
+ [That's helpful, thanks]
    -> hub

=== daytime_return ===
#speaker:receptionist
#display:receptionist-friendly
Receptionist: How did your meeting with Ms. Sterling go?
* [Very well - she's impressive]
    ~ receptionist_influence = receptionist_influence + 10
    # influence_increased
    You: It went great. Victoria is very impressive. I learned a lot.
    Receptionist: I'm so glad! She has that effect on people.
    #exit_conversation
    -> DONE
* [It was... illuminating. She has strong ideas about security.]
    Receptionist: [Laughs] That's one way to put it! She definitely has opinions.
    ~ receptionist_influence = receptionist_influence + 5
    # influence_increased
    #exit_conversation
    -> DONE
* [I need some time to consider the training program. Big decision.]
    Receptionist: Of course! Take your time. Let us know if you have any questions.
    #exit_conversation
    -> DONE

=== restricted_area_daytime ===
#speaker:receptionist
Receptionist: Oh, I'm sorry - that area is for employees only.
Receptionist: Visitor access is to the reception and conference area. Ms. Sterling can authorise anything further.
{ receptionist_influence >= 20:
    Receptionist: If you need access to something specific, Ms. Sterling can authorize it.
}
#exit_conversation
-> DONE

=== clone_badge_opportunity ===
#speaker:receptionist
[You lean over the desk, studying the building directory, keeping the RFID cloner within range of her lanyard.]
[The cloner's antenna lights up — it detects a MIFARE signal from her staff badge.]
~ clone_reception_badge_done = true
#clone_keycard:receptionist_badge
#complete_task:clone_reception_badge
-> hub
