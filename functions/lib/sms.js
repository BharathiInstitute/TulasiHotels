"use strict";
/**
 * SMS Fallback Integration via MSG91
 *
 * Functions:
 * - sendOrderReadySMS: SMS when takeaway order is ready for pickup
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
exports.sendOrderReadySMS = void 0;
const functions = __importStar(require("firebase-functions"));
const getMSG91Config = () => {
    var _a, _b;
    return ({
        authKey: ((_a = functions.config().msg91) === null || _a === void 0 ? void 0 : _a.auth_key) || process.env.MSG91_AUTH_KEY || "",
        senderId: ((_b = functions.config().msg91) === null || _b === void 0 ? void 0 : _b.sender_id) || "TULASI",
        baseUrl: "https://api.msg91.com/api/v5/flow/",
    });
};
/**
 * Send an SMS via MSG91 Flow API
 */
async function sendSMS(phone, flowId, variables) {
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
            Object.assign({ mobiles: normalizedPhone }, variables),
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
    }
    catch (error) {
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
exports.sendOrderReadySMS = functions
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
    await sendSMS(after.customerPhone, "order_ready_pickup", // MSG91 flow ID — configure in MSG91 dashboard
    {
        orderNumber: String(after.orderNumber || ""),
        shopName: after.shopName || "Tulasi Hotels",
    });
});
//# sourceMappingURL=sms.js.map