# Mission 2 Field Guides (Ransomed Trust)

This folder contains source markdown for optional in-game field guides delivered by Agent 0x99.

## Delivery Model
- Guides are optional support content delivered through phone dialogue.
- Delivery is milestone-driven via `eventMappings` in `scenario.json.erb`.
- Guide items are provided through Agent 0x99 `itemsHeld` entries and `#give_item` dialogue tags.

## Current Guides
1. `SAFETYNET_FIELD_GUIDE_Reconnaissance_and_Network_Mapping.md`
2. `SAFETYNET_FIELD_GUIDE_Vulnerability_Analysis_and_Attack_Surface.md`
3. `SAFETYNET_FIELD_GUIDE_ProFTPD_Exploitation_Workflow.md`

## Mirror Publishing (HacktivityLabSheets)
Each guide is mirrored to hidden game-fragment pages:
- `/_labs/m02_ransomed_trust/safetynet-field-guide-reconnaissance-and-network-mapping.md`
- `/_labs/m02_ransomed_trust/safetynet-field-guide-vulnerability-analysis-and-attack-surface.md`
- `/_labs/m02_ransomed_trust/safetynet-field-guide-proftpd-exploitation-workflow.md`

These pages must include:
- `game_fragment: true`
- A stable `permalink`

## Authoring Rules
- Reminder of objective/context is encouraged.
- Technical workflow should be complete enough for a learner who opts in for help.
- Avoid narrative spoilers, hardcoded mission answers, and explicit answer chains.
- Keep commands generic with placeholders (`{TARGET_IP}`, `{PORT}`, etc.).
- Keep source and mirrored pages synchronized when updating content.