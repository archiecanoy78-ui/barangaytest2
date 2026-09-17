# Implementation Plan - Redesigned Panic Button & SOS Workflow

Enhance the emergency response system by redesigning the Panic Button and introducing a more rigorous SOS submission workflow.

## User Review Required

> [!IMPORTANT]
> - **Redesigned Panic Button**: I will transform the static red container into a large, animated, high-visibility "SOS" pulse button in the `EmergencyScreen`.
> - **Confirmation & Reasons**: Clicking the button will trigger a multi-step confirmation process:
>   1. **"Are you sure?"**: A critical confirmation step.
>   2. **Reason Selection**: A selection of urgent reasons (e.g., Medical, Fire, Crime, Accident).
>   3. **Additional Details**: An optional text field for specific context.

## Proposed Changes

### [Resident UI]
#### [MODIFY] [emergency_screen.dart](file:///C:/Users/Archie%20J.%20Canoy/barangaytest/lib/resident/screens/emergency_screen.dart)
- Replace the current "PANIC BUTTON" container with a prominent, circular "SOS" button featuring a pulsating animation.
- Connect the button to a new confirmation workflow (similar to `showSOSModal` but more prominent).

#### [MODIFY] [sos_modal.dart](file:///C:/Users/Archie%20J.%20Canoy/barangaytest/lib/widgets/sos_modal.dart)
- Update the SOS modal design to be more urgent and user-friendly.
- Ensure it includes the "Reasons" selection if it wasn't already comprehensive.

### [State Management]
- No major changes required as the existing `addReport` logic supports SOS flags.

## Verification Plan

### Manual Verification
1. Navigate to the **Emergency** tab.
2. Tap the new **Panic Button**.
3. Confirm the "Are you sure?" prompt.
4. Select a reason (e.g., "Fire") and provide details.
5. Submit and verify that the SOS is dispatched (red banner appears for staff).
