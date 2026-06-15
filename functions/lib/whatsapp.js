"use strict";
/**
 * WhatsApp Business API Integration via MSG91
 *
 * Functions:
 * - sendOrderConfirmation: WhatsApp message when customer places an order
 * - sendFeedbackRequest: WhatsApp after bill is created with feedback link
 * - sendReservationReminder: Scheduled check for upcoming reservations
 * - sendDailySummary: Nightly revenue summary to hotel owner
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendDailySummaryWhatsApp = exports.sendReservationReminder = exports.sendFeedbackRequest = exports.sendOrderConfirmation = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
// Lazy-load to avoid issues if env vars aren't set
const getMSG91Config = () => {
    var _a, _b;
    return ({
        authKey: ((_a = functions.config().msg91) === null || _a === void 0 ? void 0 : _a.auth_key) || process.env.MSG91_AUTH_KEY || "",
        templateNamespace: ((_b = functions.config().msg91) === null || _b === void 0 ? void 0 : _b.template_namespace) || process.env.MSG91_TEMPLATE_NAMESPACE || "",
        baseUrl: "https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/",
    });
};
/**
 * Send a WhatsApp message via MSG91
 */
async function sendWhatsApp(phone, templateId, params) {
    const config = getMSG91Config();
    if (!config.authKey) {
        console.warn("⚠️ MSG91 auth key not configured — skipping WhatsApp send");
        return false;
    }
    // Normalize phone to include country code
    const normalizedPhone = phone.startsWith("+") ? phone : `+91${phone.replace(/^0+/, "")}`;
    const payload = {
        integrated_number: config.templateNamespace,
        content_type: "template",
        payload: {
            to: normalizedPhone,
            type: "template",
            template: {
                name: templateId,
                language: { code: "en", policy: "deterministic" },
                components: Object.entries(params).map(([, value]) => ({
                    type: "body",
                    parameters: [{ type: "text", text: value }],
                })),
            },
        },
    };
    try {
        const response = await fetch(config.baseUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "authkey": config.authKey,
            },
            body: JSON.stringify(payload),
        });
        if (!response.ok) {
            const errorText = await response.text();
            console.error(`❌ WhatsApp send failed: ${response.status} ${errorText}`);
            return false;
        }
        console.log(`✅ WhatsApp sent to ${normalizedPhone} (template: ${templateId})`);
        return true;
    }
    catch (error) {
        console.error("❌ WhatsApp send error:", error);
        return false;
    }
}
/**
 * #90 Order Confirmation — send WhatsApp when a customer order is placed
 */
exports.sendOrderConfirmation = functions
    .region("asia-south1")
    .firestore.document("users/{uid}/orders/{orderId}")
    .onCreate(async (snapshot) => {
    const order = snapshot.data();
    if (!order || !order.customerPhone || !order.isCustomerOrder) {
        return;
    }
    const itemNames = (order.items || [])
        .map((i) => i.name)
        .join(", ");
    await sendWhatsApp(order.customerPhone, "order_confirmation", {
        orderNumber: String(order.orderNumber || ""),
        items: itemNames,
        eta: "20 minutes",
    });
});
/**
 * #93 Feedback Request — send WhatsApp after bill is created
 */
exports.sendFeedbackRequest = functions
    .region("asia-south1")
    .firestore.document("users/{uid}/bills/{billId}")
    .onCreate(async (snapshot, context) => {
    var _a;
    const bill = snapshot.data();
    if (!bill || !bill.customerPhone) {
        return;
    }
    const uid = context.params.uid;
    const billId = context.params.billId;
    const feedbackUrl = `https://tulasihotels.web.app/rate/${uid}?billId=${billId}`;
    // Fetch hotel name
    let hotelName = "Tulasi Hotels";
    try {
        const userDoc = await admin.firestore().doc(`users/${uid}`).get();
        hotelName = ((_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.shopName) || hotelName;
    }
    catch (_e) {
        // Use default name
    }
    await sendWhatsApp(bill.customerPhone, "feedback_request", {
        hotelName: hotelName,
        feedbackLink: feedbackUrl,
    });
});
/**
 * #94 Reservation Reminder — every 30 minutes, check for reservations 2 hours away
 */
exports.sendReservationReminder = functions
    .region("asia-south1")
    .pubsub.schedule("every 30 minutes")
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
    const now = new Date();
    const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    const twoAndHalfHours = new Date(now.getTime() + 2.5 * 60 * 60 * 1000);
    // Query all users' reservations that are upcoming in the next 2–2.5 hour window
    const usersSnapshot = await admin.firestore().collection("users").get();
    for (const userDoc of usersSnapshot.docs) {
        const uid = userDoc.id;
        const shopName = userDoc.data().shopName || "Tulasi Hotels";
        const reservationsSnapshot = await admin.firestore()
            .collection(`users/${uid}/reservations`)
            .where("status", "==", "confirmed")
            .where("dateTime", ">=", admin.firestore.Timestamp.fromDate(twoHoursFromNow))
            .where("dateTime", "<", admin.firestore.Timestamp.fromDate(twoAndHalfHours))
            .get();
        for (const resDoc of reservationsSnapshot.docs) {
            const reservation = resDoc.data();
            if (reservation.phone) {
                await sendWhatsApp(reservation.phone, "reservation_reminder", {
                    guestName: reservation.guestName || "Guest",
                    hotelName: shopName,
                    time: new Date(reservation.dateTime.toDate()).toLocaleTimeString("en-IN", {
                        hour: "2-digit",
                        minute: "2-digit",
                    }),
                    partySize: String(reservation.partySize || 1),
                });
            }
        }
    }
    console.log("✅ sendReservationReminder: Completed");
});
/**
 * #105 Daily Summary — send nightly revenue summary to hotel owner via WhatsApp
 */
exports.sendDailySummaryWhatsApp = functions
    .region("asia-south1")
    .pubsub.schedule("every day 22:00")
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
    const usersSnapshot = await admin.firestore().collection("users").get();
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);
    for (const userDoc of usersSnapshot.docs) {
        const uid = userDoc.id;
        const userData = userDoc.data();
        const ownerPhone = userData.phone;
        if (!ownerPhone)
            continue;
        // Aggregate today's revenue
        const billsSnapshot = await admin.firestore()
            .collection(`users/${uid}/bills`)
            .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(todayStart))
            .where("createdAt", "<=", admin.firestore.Timestamp.fromDate(todayEnd))
            .get();
        let totalRevenue = 0;
        let orderCount = 0;
        for (const billDoc of billsSnapshot.docs) {
            const bill = billDoc.data();
            totalRevenue += bill.total || 0;
            orderCount++;
        }
        if (orderCount > 0) {
            await sendWhatsApp(ownerPhone, "daily_summary", {
                hotelName: userData.shopName || "Your Hotel",
                revenue: `₹${totalRevenue.toFixed(0)}`,
                orders: String(orderCount),
                avgTicket: orderCount > 0 ? `₹${(totalRevenue / orderCount).toFixed(0)}` : "₹0",
            });
        }
    }
    console.log("✅ sendDailySummaryWhatsApp: Completed");
});
//# sourceMappingURL=whatsapp.js.map