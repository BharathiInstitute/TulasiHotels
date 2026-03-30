# Tulasi Hotels — Feature Plan

## Order → Prepare → Serve → Bill Flow

---

## 1. What You Already Have (Reusable from Tulasi Stores)

| Module | Reuse As |
|---|---|
| **Auth & User Setup** | Same — hotel owner login, shop setup becomes hotel setup |
| **Products** | Rename to **Menu Items** — name, price, category, stock |
| **Billing & Cart** | Evolve into **Order + Billing** — cart becomes order, payment stays |
| **Khata (Credit)** | Keep for **Corporate/Room Credit** — companies or guests on credit |
| **Reports/Dashboard** | Extend — add table-wise, waiter-wise, kitchen performance reports |
| **Subscriptions** | Same — plan limits apply to orders/tables instead of bills/products |
| **Notifications (FCM)** | Extend — kitchen alerts, order-ready notifications |
| **Settings** | Add hotel-specific settings (table count, kitchen sections, etc.) |
| **Receipt/Printer** | Extend — KOT (Kitchen Order Ticket) print + bill print |
| **Offline-first Firestore** | Same — critical for hotels with spotty WiFi |

---

## 2. New Features Needed (Hotel-Specific)

### Phase 1 — Core Hotel Operations

#### 2.1 Table Management

| Item | Details |
|---|---|
| **Model** | `TableModel` — id, number, label, capacity, floor, status (available / occupied / reserved / billing) |
| **Firestore** | `users/{uid}/tables/{tableId}` |
| **Screen** | Floor-plan grid view showing all tables with color-coded status |
| **Actions** | Tap table → Open order for that table, merge tables, transfer order between tables |
| **Why** | Every hotel/restaurant operation starts with "which table" |

#### 2.2 Order Workflow (The Core Change)

Replace the current **direct cart → bill** flow with a staged **Order lifecycle**:

```
┌──────────┐    ┌──────────┐    ┌───────────┐    ┌──────────┐    ┌──────────┐
│  NEW      │───▶│ PLACED   │───▶│ PREPARING │───▶│  READY   │───▶│  SERVED  │──▶ BILL
│  ORDER    │    │ (KOT     │    │ (Kitchen  │    │ (Ring    │    │ (At      │
│ (Waiter)  │    │  Printed)│    │  Working) │    │  bell)   │    │  Table)  │
└──────────┘    └──────────┘    └───────────┘    └──────────┘    └──────────┘
```

| Item | Details |
|---|---|
| **Model** | `OrderModel` — id, orderNumber, tableId, tableName, items[], status (enum: `placed → preparing → ready → served → billed → cancelled`), waiterId, createdAt, updatedAt, notes, orderType (dine-in / takeaway / delivery / room-service) |
| **OrderItem** | Extends `CartItem` — add: itemNotes (e.g. "no onion"), modifiers[], status (per-item: pending / preparing / ready / served), kotNumber |
| **Firestore** | `users/{uid}/orders/{orderId}` |
| **Providers** | `activeOrdersProvider` (stream of non-billed orders), `tableOrderProvider(tableId)`, `kitchenOrdersProvider` (items grouped by status) |
| **Key Feature** | **Partial serving** — some items ready, others still cooking. Each item tracks its own status |
| **Key Feature** | **Order amendment** — waiter can add items to an existing open order (new KOT generated for additions only) |

#### 2.3 Kitchen Display System (KDS)

| Item | Details |
|---|---|
| **Screen** | `KitchenDisplayScreen` — full-screen view for kitchen staff (tablet mounted in kitchen) |
| **Layout** | Card-based: each order is a card showing table number, items, time elapsed, priority |
| **Actions** | Tap item → mark "preparing", tap card → mark all "ready" |
| **Color coding** | Green = new, Yellow = preparing, Red = overdue (>15 min configurable) |
| **Sound alert** | New order arrives → audible notification |
| **Auto-print** | KOT (Kitchen Order Ticket) auto-prints when order placed |
| **Multi-section** | Optional: separate displays for different kitchen sections (bar, main kitchen, tandoor) |
| **Firestore** | Reads from `users/{uid}/orders/` where status IN [placed, preparing] — real-time stream |

#### 2.4 KOT (Kitchen Order Ticket) Printing

| Item | Details |
|---|---|
| **What** | Printed slip sent to kitchen when order is placed |
| **Content** | Order #, Table #, Items with quantities & notes, Time, Waiter name |
| **When** | Auto-print on order placement + on order amendment (only new items) |
| **How** | Extend existing `ThermalPrinterService` — add `printKOT(order)` method |
| **Multi-printer** | Different printers for different sections (bar printer, kitchen printer) |

#### 2.5 Billing Enhancement (Order → Bill)

| Item | Details |
|---|---|
| **Flow** | Waiter selects table → Reviews served items → Generates bill → Payment |
| **Change** | Bill is now created FROM an order (not from a fresh cart) |
| **BillModel update** | Add: `orderId`, `tableId`, `waiterId`, `orderType`, `serviceCharge`, `gstBreakdown` |
| **Split bill** | Split by items or by equal share among guests |
| **Discount** | Percentage or flat discount with reason |
| **Service charge** | Configurable % (typically 5–10%) |
| **GST** | CGST + SGST or IGST auto-calculated per item category (food 5%, AC restaurant 18%) |
| **Print** | Final bill print (extend existing receipt) |

---

### Phase 2 — Staff & Menu Management

#### 2.6 Staff / Waiter Management

| Item | Details |
|---|---|
| **Model** | `StaffModel` — id, name, phone, role (waiter / chef / manager / cashier), pin (4-digit for quick login), isActive |
| **Firestore** | `users/{uid}/staff/{staffId}` |
| **Screen** | Staff list, add/edit staff, assign roles |
| **Quick Login** | Staff PIN entry instead of full auth (staff are sub-users under hotel owner) |
| **Tracking** | Orders per waiter, tables served, performance metrics |

#### 2.7 Menu Management (Enhanced Products)

| Item | Details |
|---|---|
| **Rename** | Products → Menu Items |
| **Categories** | Starters, Main Course, Breads, Rice, Beverages, Desserts (customizable) |
| **Modifiers/Add-ons** | `ModifierGroup` (e.g. "Spice Level": mild/medium/hot) and `AddOn` (e.g. "Extra cheese ₹30") |
| **Availability** | Per-item toggle — "86'd" / unavailable (kitchen ran out), time-based (lunch-only, dinner-only) |
| **Veg/Non-Veg** | Tag for Indian menu compliance |
| **Food images** | Optional photo per dish |
| **Combo/Thali** | Group items as combo with bundle pricing |

#### 2.8 Order Types

| Type | Details |
|---|---|
| **Dine-in** | Linked to table, standard flow |
| **Takeaway/Parcel** | No table, counter pickup, parcel charges optional |
| **Delivery** | Customer address, delivery partner, phone, delivery charge |
| **Room Service** | Room number instead of table (for hotel stays) |

---

### Phase 3 — Advanced Hotel Features

#### 2.9 Room Management (Hotel-Specific)

| Item | Details |
|---|---|
| **Model** | `RoomModel` — id, number, floor, type (single/double/suite), status (available / occupied / checkout / maintenance), guestName, checkIn, checkOut, rate |
| **Firestore** | `users/{uid}/rooms/{roomId}` |
| **Screen** | Room grid with status colors, check-in/checkout flow |
| **Integration** | Room service orders linked to room; charges added to room bill |
| **Folio** | Running tab per room — food + room charge + extras, settled at checkout |

#### 2.10 Guest Management (Enhanced Khata)

| Item | Details |
|---|---|
| **Extend** | CustomerModel → `GuestModel` — add: roomId, idProof, checkIn, checkOut, companyName, GST |
| **Corporate billing** | Link guest to company, aggregate bills for corporate settlement |
| **Guest history** | Past stays, preferences, spend analytics |

#### 2.11 Inventory / Stock Deduction

| Item | Details |
|---|---|
| **Model** | `IngredientModel` — id, name, unit, currentStock, reorderLevel |
| **Recipe mapping** | Each menu item maps to ingredients with quantities |
| **Auto-deduction** | When order is served, ingredient stock decreases |
| **Alerts** | Low stock notifications to manager |

#### 2.12 Multi-Kitchen / Section Routing

| Item | Details |
|---|---|
| **How** | Each menu item tagged with kitchen section (Main Kitchen, Tandoor, Bar, Cold Kitchen) |
| **KOT routing** | Order items split by section → separate KOTs to each section |
| **KDS view** | Each section sees only their items |

---

### Phase 4 — Analytics & Extras

#### 2.13 Enhanced Reports

- **Table-wise revenue** — which tables generate most revenue
- **Waiter performance** — orders served, average order value, tips
- **Kitchen efficiency** — average prep time per item, per section
- **Peak hour analysis** — order volume by hour
- **Menu item popularity** — most/least ordered items, item profitability
- **Food cost analysis** — ingredient cost vs. selling price

#### 2.14 Customer-Facing Features

- **Digital menu** — QR code on table → web menu (no app needed for customers)
- **Self-order** — Customer scans QR, browses menu, places order
- **Feedback** — Post-meal rating (food, service, ambiance)
- **Bill on phone** — Customer scans QR to view & pay bill

---

## 3. Firestore Schema (New / Modified Collections)

```
users/{uid}/
├── profile              (+ hotelName, hotelType, tableCount, gstRate)
├── tables/
│   └── {tableId}        (TableModel)
├── rooms/
│   └── {roomId}         (RoomModel)
├── staff/
│   └── {staffId}        (StaffModel)
├── menu_items/          (renamed from products/)
│   └── {itemId}         (MenuItemModel + modifiers, section, vegTag)
├── orders/
│   └── {orderId}        (OrderModel with items[], status, tableId)
├── bills/
│   └── {billId}         (+ orderId, tableId, waiterId, serviceCharge, gst)
├── customers/           (existing — used for corporate/walk-in credit)
│   └── {customerId}
│       └── transactions/
├── guests/
│   └── {guestId}        (GuestModel — hotel room guests)
├── ingredients/
│   └── {ingredientId}   (IngredientModel)
└── expenses/            (existing)
    └── {expenseId}
```

---

## 4. Implementation Priority

| Priority | Feature | Effort | Depends On |
|----------|---------|--------|------------|
| **P0** | Table Management (model + grid screen) | 3–4 days | — |
| **P0** | Order Model + Order Lifecycle | 4–5 days | Tables |
| **P0** | Order Screen (waiter takes order at table) | 3–4 days | Order Model |
| **P0** | Kitchen Display Screen (KDS) | 3–4 days | Order Model |
| **P0** | KOT Printing | 2 days | Order Model + Printer |
| **P0** | Billing from Order (close table → bill) | 3 days | Orders + existing Billing |
| **P1** | Menu Management (categories, modifiers, veg tag) | 3–4 days | — |
| **P1** | Staff Management + PIN login | 3 days | — |
| **P1** | Order Types (takeaway, delivery) | 2 days | Orders |
| **P1** | Split Bill & Discounts | 2–3 days | Billing |
| **P1** | Service charge + GST calculation | 2 days | Billing |
| **P2** | Room Management | 4–5 days | — |
| **P2** | Guest Management + Room Folio | 3–4 days | Rooms |
| **P2** | Multi-kitchen section routing | 2–3 days | KDS |
| **P2** | Ingredient stock management | 4–5 days | Menu Items |
| **P3** | Enhanced Reports (table/waiter/kitchen) | 3–4 days | Orders data |
| **P3** | QR Digital Menu + Self-Order | 5–6 days | Menu Items |
| **P3** | Customer Feedback | 2 days | Billing |

---

## 5. Key Architecture Decisions

1. **Order ≠ Bill** — Orders are living documents (items added/modified until billed). Bills are immutable final records (same as today).

2. **Table is the anchor** — Every dine-in interaction starts with selecting a table. The table status drives the restaurant floor view.

3. **Per-item status tracking** — Each item in an order has its own status. This enables partial serving and accurate kitchen tracking.

4. **KOT is a snapshot** — When an order changes (items added), a NEW KOT is printed with only the new items. Original KOT is not reprinted.

5. **Staff PIN, not full auth** — Waiters/chefs don't need Firebase accounts. They use a 4-digit PIN under the owner's account. All data still lives under `users/{uid}/`.

6. **Backward compatible** — Keep existing billing flow working for non-table orders (takeaway/counter). Table linking is optional.

7. **Real-time everything** — Kitchen display, floor view, and waiter screens all use Firestore real-time streams (same pattern as existing providers).

---

## 6. Summary

**P0 alone gives you a functional hotel/restaurant POS** with the full Order → Prepare → Serve → Bill cycle. Each subsequent phase adds depth without blocking the core flow.
