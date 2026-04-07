// Import Firebase scripts for service worker
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase in the service worker with web configuration
firebase.initializeApp({
  apiKey: "AIzaSyCY_r9WBr_QOfui39GKjwLr-cRx0gaA8XM",
  authDomain: "auth.heliumedu.com",
  projectId: "helium-edu",
  storageBucket: "helium-edu.firebasestorage.app",
  messagingSenderId: "643279973445",
  appId: "1:643279973445:web:18d70bb986764d56dec72c",
  measurementId: "G-5FNS68QLK4",
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle notification taps. Routes the user to /planner?dialog=notifications.
// This handler is required for macOS/desktop notification center taps, which
// route through the service worker rather than the page's onclick handler.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ('focus' in client) {
          return client.focus().then((c) => c.navigate('/planner?dialog=notifications'));
        }
      }
      return clients.openWindow('/planner?dialog=notifications');
    })
  );
});

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  // If any tab is visible, the Dart foreground handler will show the notification.
  // Skip here to avoid a duplicate — onBackgroundMessage and onMessage are not
  // strictly mutually exclusive in Chrome's Firebase web SDK implementation.
  return clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
    if (windowClients.some(client => client.visibilityState === 'visible')) return;

    let notificationTitle = 'Helium Notification';
    let notificationBody = '';
    let reminderId = null;
    try {
      const jsonPayload = JSON.parse(payload.data?.json_payload || '{}');
      reminderId = jsonPayload.id?.toString() ?? null;
      notificationTitle = jsonPayload.notification_title || notificationTitle;
      notificationBody = jsonPayload.notification_body || '';
    } catch (e) {
      console.warn('[firebase-messaging-sw.js] Failed to parse json_payload', e);
    }

    const notificationOptions = {
      body: notificationBody,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: reminderId ?? notificationTitle,
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
});
