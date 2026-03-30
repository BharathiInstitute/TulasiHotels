/**
 * SMS Fallback Integration via MSG91
 *
 * Functions:
 * - sendOrderReadySMS: SMS when takeaway order is ready for pickup
 */

import * as functions from "firebase-functions";

const getMSG91Config = () => ({
    authKey: functions.config().msg91?.auth_key || process.env.MSG91_AUTH_KEY || "",
    senderId: functions.config().msg91?.sender_id || "TULASI",
    baseUrl: "https://api.msg91.com/api/v5/flow/",
});

/**
 * Send an SMS via MSG91 Flow API
 */
async function sendSMS(
    phone: string,
    flowId: string,
    variables: Record<string, string>
): Promise<boolean> {
    const config = getMSG91Config();
    if (!config.authKey) {
        console.warn("⚠️ MSG91 auth key not configured — skipping SMS send");
        return false;
    }

    // Normalize phone to include country code
    const normalizedPhone = phone.startsWith("+") ? phone : `+91${phone.replace(/^0+/, "")}`;

    const payload = {
        flow_id: flowId,
        sender: config.senderId,
        recipients: [
            {
                mobiles: normalizedPhone,
                ...variables,
            },
        ],
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
            console.error(`❌ SMS send failed: ${response.status} ${errorText}`);
            return false;
        }

        console.log(`✅ SMS sent to ${normalizedPhone} (flow: ${flowId})`);
        return true;
    } catch (error) {
        console.error("❌ SMS send error:", error);
        return false;
    }
}

/**
 * #91 Order Ready SMS — send SMS when takeaway order is marked ready
 *
 * Triggers on orders.onUpdate:
 *  - status changes to "ready"
 *  - orderType is "takeaway"
 *  - customerPhone exists
 */
export const sendOrderReadySMS = functions
    .region("asia-south1")
    .firestore.document("users/{uid}/orders/{orderId}")
    .onUpdate(async (change) => {
        const before = change.before.data();
        const after = change.after.data();

        // Only trigger when status changes to "ready"
        if (before.status === after.status || after.status !== "ready") {
            return;
        }

        // Only for takeaway orders with a customer phone
        if (after.orderType !== "takeaway" || !after.customerPhone) {
            return;
        }

        await sendSMS(
            after.customerPhone,
            "order_ready_pickup",  // MSG91 flow ID — configure in MSG91 dashboard
            {
                orderNumber: String(after.orderNumber || ""),
                shopName: after.shopName || "Tulasi Hotels",
            }
        );
    });
