# Permission Centralization Plan

## Completion Status
All phases in this plan are complete as of 2026-07-24.

Completion notes:
- Phase 1 complete: `PermissionCenter` API contract documented with class-level usage example; legacy helpers are explicitly deprecated.
- Phase 2 complete: shell navigation visibility uses center-owned checks.
- Phase 3 complete: targeted screens use unified resolved/loading/denied pattern with `PermissionDeniedView`.
- Phase 4 complete: action-denied strings unified through `PermissionCenter.deniedActionMessage(...)` across targeted modules.
- Phase 5 complete: role templates moved to central policy layer in `lib/features/permissions/permission_policy.dart`; `PermissionConfig` remains a catalog.
- Phase 6 complete: legacy evaluators are compatibility wrappers over center; duplicate evaluation bodies removed.
- Phase 7 complete: center-first tests and wrapper parity coverage added/updated.
- Phase 8 complete: panel catalog and route-to-panel normalization added in `lib/features/permissions/permission_panel.dart`; center and mutation checks now evaluate through panel anchors.
- Phase 9 complete: permission assignment UIs migrated to panel-first editing and panel-normalized saves for staff/member flows.

Primary verification artifacts:
- `test/services/permission_center_test.dart`
- `test/services/permission_panel_test.dart`
- `test/services/staff_permissions_test.dart`
- `test/routing/staff_route_filter_test.dart`
- `test/integration/staff_role_flow_test.dart`
- `test/routing/route_guard_test.dart`

## Goal
Move all permission evaluation, access state, denied messaging, and route/action gating to one central module so behavior is consistent across web, mobile, and desktop.

Primary center:
- `lib/features/permissions/permission_center.dart`

## Current Status (Already Done)
- Central core file exists: `permission_center.dart`.
- Route permission provider delegates to center.
- Service-layer mutation guard delegates to center.
- Router redirects use center for staff/member route checks.
- Shared denied UI component exists: `permission_denied_view.dart`.

## Scope
Centralize these domains:
1. View permission checks for screens and routes.
2. CRUD action checks for create/update/delete flows.
3. Home/fallback route resolution when denied.
4. Denied message generation.
5. Navigation visibility checks.
6. Permission templates and defaults (staff/member roles).

Out of scope for phase 1:
- Firestore security rules.
- Subscription feature gating logic (plan limits), except where permission and plan-gate overlap in UI messaging.

## Architecture Target
Single source of truth:
- `PermissionCenter` owns all checks and permission messages.

Thin wrappers only:
- Providers: assemble context and call center.
- Router: ask center for canView + fallback route.
- Services: ask center for hasAction.
- UI: ask provider/center for state; show shared denied view.

## Phase Plan

### Phase 1: Stabilize and Freeze Contracts
Objective: define final public API and stop adding new permission logic outside center.

Tasks:
1. Freeze APIs in `permission_center.dart`:
   - `resolveRouteState`
   - `canView`
   - `hasAction`
   - `homeRoute`
   - denied message helpers
2. Add class-level docs and usage examples.
3. Mark old helpers as deprecated (not removed yet):
   - `StaffPermissions.canAccess`, `hasAction`, `homeRoute`, `canViewRoute`
   - `MemberPermissionGuard.canAccess`, `hasAction`, `homeRoute`, `canViewRoute`

Acceptance:
- No new feature PR introduces direct permission logic outside center.

### Phase 2: Move Navigation Visibility to Center
Objective: remove split logic in shell files.

Tasks:
1. Add to center:
   - `visibleNavIndices(...)`
   - `canSeeNavRoute(...)`
2. Replace shell checks in:
   - `lib/features/shell/app_shell.dart`
   - `lib/features/shell/web_shell.dart`
3. Remove direct usages of `StaffPermissions.canViewRoute` and `MemberPermissionGuard.canViewRoute` in shells.

Acceptance:
- All sidebar/drawer visibility decisions call center only.

### Phase 3: Unify Screen-Level View Guards
Objective: standardize no-access UX.

Tasks:
1. For each protected screen, read `routePermissionProvider(route)`.
2. Standard pattern:
   - unresolved -> loader
   - no view -> `PermissionDeniedView(PermissionCenter.deniedViewMessage(route))`
   - allowed -> render screen
3. Prioritize high-traffic files first:
   - billing, products, khata, orders, tables, staff
4. Then apply to feature screens:
   - reservations, coupons, inventory, reports, compliance

Acceptance:
- No custom ad-hoc view-denied widgets remain in targeted modules.

### Phase 4: Unify Action Gating and Messages
Objective: create/update/delete checks and messages become uniform.

Tasks:
1. Keep service-level checks in `ModuleMutationGuard` as mandatory backend gate.
2. In UI actions, use provider state booleans (`canCreate`, `canUpdate`, `canDelete`) for button enable/disable.
3. Replace hard-coded denied strings with center message helpers.
4. Ensure snackbars/dialogs use same phrasing app-wide.

Acceptance:
- Mutation attempts from UI and direct service calls produce consistent denial messages.

### Phase 5: Centralize Role Template Mapping
Objective: keep role defaults and module actions in one policy layer.

Tasks:
1. Keep `PermissionConfig` as static policy catalog (routes, categories, supported actions).
2. Move role-template decisions to center-facing policy functions (or dedicated policy class under permissions feature).
3. Make:
   - staff role defaults
   - member role defaults
   derive from same action catalog.
4. Keep `store_role.dart` thin (data enum only if possible).

Acceptance:
- Role-based default permission maps come from one policy flow.

### Phase 6: Remove Legacy Duplication
Objective: delete old duplicate logic after migration.

Tasks:
1. Remove duplicate evaluation bodies from:
   - `staff_permissions.dart`
   - `member_permission_guard.dart`
2. Keep compatibility wrappers temporarily, then remove in next release.
3. Update imports across codebase to center/provider usage.

Acceptance:
- No active permission logic remains outside center + policy catalog.

### Phase 7: Test Migration and Coverage
Objective: protect behavior while refactoring.

Tasks:
1. Add `permission_center_test.dart` for:
   - staff/member/owner/no-context combinations
   - route resolution and action checks
   - denied messages and home route
2. Refactor existing tests that currently target old classes:
   - `test/services/staff_permissions_test.dart`
   - `test/routing/staff_route_filter_test.dart`
   - `test/integration/staff_role_flow_test.dart`
3. Keep temporary parity tests asserting old wrappers == center outcomes.

Acceptance:
- All permission tests pass with center as primary engine.

## File-by-File Migration Checklist

Core:
- `lib/features/permissions/permission_center.dart`
- `lib/features/permissions/providers/route_permission_provider.dart`
- `lib/features/permissions/services/module_mutation_guard.dart`
- `lib/features/permissions/widgets/permission_denied_view.dart`

Router:
- `lib/router/app_router.dart`

Shell and nav:
- `lib/features/shell/app_shell.dart`
- `lib/features/shell/web_shell.dart`

Legacy permission engines (to deprecate/remove):
- `lib/features/staff/services/staff_permissions.dart`
- `lib/features/admin/services/member_permission_guard.dart`

Policy catalog:
- `lib/features/staff/models/permission_config.dart`
- `lib/features/admin/models/store_role.dart`

## Rollout Strategy
1. Keep backward-compatible wrappers for 1 release.
2. Add telemetry logs for denied actions/routes during migration.
3. Enable strict lint/check: block new direct uses of old APIs in new files.
4. Remove wrappers only after test parity and one stable release cycle.

## Risks and Mitigations
1. Risk: accidental access regression for owner/member/staff.
   - Mitigation: add matrix tests before deleting wrappers.
2. Risk: hidden route checks in less-used screens.
   - Mitigation: grep sweep for direct permission methods and strings.
3. Risk: inconsistent snackbar/empty state UX.
   - Mitigation: enforce shared denied widget/message helpers.

## Definition of Done
1. All permission checks flow through `PermissionCenter` (or center-owned policy/provider).
2. All protected screens show uniform denied view/message.
3. Router/service/UI behavior is consistent across platforms.
4. Legacy duplicate logic removed or fully inert wrappers only.
5. Test suite updated with parity and central coverage.
