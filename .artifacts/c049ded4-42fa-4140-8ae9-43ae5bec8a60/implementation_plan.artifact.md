# Implementation Plan - Navigation Refactor & Announcement Posting

This plan addresses the following requirements:
1.  Enable announcement posting for the Staff role.
2.  Remove the "Reports" tab from the Barangay Admin/Captain account and replace it with a "Directory" tab.
3.  Ensure the Directory allows officials to edit resident information.
4.  Remove the "Users" tab from the Staff account (already hidden, but we will ensure clean logic).

## User Review Required

> [!IMPORTANT]
> - **Admin Reports**: Per your request, the **Reports** tab will be **removed** for the Admin/Captain account. They will focus on the **Directory** and high-level dashboard metrics instead.
> - **Consolidated Directory**: The existing "User Management" screen will be renamed and repurposed as the **Directory**, serving as the central hub for managing residents and staff.

## Proposed Changes

### Staff Module

#### [MODIFY] [staff_main.dart](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/lib/staff/staff_main.dart)
- Update the `screens` and `navItems` logic:
    - **Barangay Staff**: Dash, Reports, Inbox, Map.
    - **Barangay Admin**: Dash, Directory (using `ManagementScreen`), Inbox, Map.
- Ensure only 4 tabs are shown for both roles to maintain a clean layout.

#### [MODIFY] [dashboard_screen.dart](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/lib/staff/screens/dashboard_screen.dart)
- Add a **"Quick Actions"** section at the bottom of the dashboard.
- Include a **"Post Announcement"** button that opens the announcement creation modal.
- This will be available for all official roles (Staff and Admin).

#### [MODIFY] [management_screen.dart](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/lib/staff/screens/management_screen.dart)
- Rename the screen title to **"Directory"**.
- Ensure editing capabilities are prominent for Admin/Official users.

## Verification Plan

### Manual Verification
1.  **Staff Login**:
    - Verify tabs are: Dash, Reports, Inbox, Map.
    - Verify "Post Announcement" is available on the Dashboard.
2.  **Admin Login**:
    - Verify tabs are: Dash, Directory, Inbox, Map.
    - Verify "Reports" is missing.
    - Verify "Directory" allows editing resident data.
