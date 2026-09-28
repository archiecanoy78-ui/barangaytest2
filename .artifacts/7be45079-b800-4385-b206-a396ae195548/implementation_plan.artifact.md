# Implementation Plan - Blue & White Palette Recolor, Announcement Fix, & Table Cleanup

## Problem Description
1. **Announcement Edit Dropdown Crash**: Assertion error when editing announcements with legacy zone values (e.g. `'Zone 1-4'`) that weren't in `_zoneOptions`.
2. **Table Checkboxes**: Checkboxes in complaints table need to be removed.
3. **Global Blue + White Recolor**: Recolor portal using a clean blue & white palette defined in a centralized `app_colors.dart` file and built into `PortalTheme`.
4. **Dashboard & Status Badge Refinements**: Standardize Needs Attention strip, Purok normalization & sorting, friendly reference numbers (`BRGY-2026-0012`), and exact status badge colors.

## Proposed Changes

### 1. Centralized Colors (`app_colors.dart`)
- [NEW] `lib/staff/widgets/app_colors.dart`: Define all requested palette colors (`primary`, `primaryDark`, `primaryHover`, `blue50`, `blue100`, `pageBackground`, `surface`, `border`, `textPrimary`, `textSecondary`, `textMuted`, `danger`, `success`, `warning`).

### 2. ThemeData & Surfaces (`portal_theme.dart`)
- Update `PortalTheme` to use `AppColors`, setting `surfaceTintColor: Colors.transparent` across `CardThemeData`, `DialogThemeData`, `DrawerThemeData`, `AppBarTheme`, etc.
- Update button themes and `InputDecorationTheme`.

### 3. Announcement Edit Fix (`announcement_management_page.dart`)
- Expand `_zoneOptions` to include legacy zone values (`'All Zones'`, `'Zone 1-4'`, `'Health Center'`, etc.) alongside purok options so editing existing announcements never throws an assertion error.

### 4. Complaint Table Cleanup & Purok Normalization (`complaint_list_page.dart`, `dashboard_screen.dart`, `status_badge.dart`)
- Remove checkboxes / selection from `DataTable` in `ComplaintListPage`.
- Render friendly reference numbers (`BRGY-2026-XXXX`) instead of raw IDs.
- Normalize Purok values (trim + Title Case) and sort Purok bars from highest to lowest.
- Update `StatusBadge` colors to match exact specification (`Pending` = amber, `Assigned` = blue, `In Progress` = orange, `Under Investigation` = purple, `Resolved` = green, `Closed` = gray) with 6px dot and 6px radius.

## Verification Plan
- Run `flutter analyze` to ensure zero compilation or type errors.
- Verify announcement editing modal, table checkboxes removal, and palette consistency.
