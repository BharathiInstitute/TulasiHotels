// Firebase Cloud Messaging service worker for web push notifications.
// This file must be in web/ root for FCM to handle background messages.

importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyBPk0ATdBY6g_cGEJerP1m2RSEICWe7Qpc",
    authDomain: "login1-aa21c.firebaseapp.com",
    projectId: "login1-aa21c",
    storageBucket: "login1-aa21c.firebasestorage.app",
    messagingSenderId: "883551466761",
    appId: "1:883551466761:web:c79809059abc26268b8fd8",
});

const messaging = firebase.messaging();

// Handle background messages (when tab is not focused)
messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Background message received:', payload);

    const notificationTitle = payload.notification?.title || 'New Notification';
    const notificationOptions = {
        body: payload.notification?.body || '',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});
