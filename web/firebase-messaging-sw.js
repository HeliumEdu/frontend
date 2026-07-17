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

const NOTIFICATIONS_ROUTE = '/planner?dialog=notifications';

// Builds the deep-link path for a reminder's linked entity (course, homework,
// or event), mirroring reminderEntityRoute() in lib/config/app_router.dart.
// The reminder payload nests each relation as a full object (ReminderExtended
// serializer), but tolerate a bare id too. Falls back to the notifications list
// when there's no linked entity.
function entityId(value) {
  if (value == null) return null;
  return typeof value === 'object' ? value.id : value;
}

function reminderRoute(jsonPayload) {
  const courseId = entityId(jsonPayload.course);
  const homeworkId = entityId(jsonPayload.homework);
  const eventId = entityId(jsonPayload.event);
  if (courseId != null) return `/classes/${courseId}/details`;
  if (homeworkId != null) return `/planner/assignment/${homeworkId}/details`;
  if (eventId != null) return `/planner/event/${eventId}/details`;
  return NOTIFICATIONS_ROUTE;
}

// Handle notification taps. Deep-links to the reminder's entity when known
// (route stashed on the notification's `data` at display time), else the
// notifications list. This handler is required for macOS/desktop notification
// center taps, which route through the service worker rather than the page's
// onclick handler.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const route = event.notification.data?.route || NOTIFICATIONS_ROUTE;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ('focus' in client) {
          return client.focus().then((c) => c.navigate(route));
        }
      }
      return clients.openWindow(route);
    })
  );
});

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  // A dismiss data push (reminder dismissed on another device) clears the
  // already-shown notification, which the SW filed under tag = reminder id.
  if (payload.data?.action === 'dismiss') {
    const reminderId = payload.data.reminder_id;
    if (!reminderId) return;
    return self.registration
      .getNotifications({ tag: reminderId })
      .then((notifications) => notifications.forEach((n) => n.close()));
  }

  // If any tab is visible, the Dart foreground handler will show the notification.
  // Skip here to avoid a duplicate — onBackgroundMessage and onMessage are not
  // strictly mutually exclusive in Chrome's Firebase web SDK implementation.
  return clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
    if (windowClients.some(client => client.visibilityState === 'visible')) return;

    let notificationTitle, notificationBody, reminderId, route;
    try {
      const jsonPayload = JSON.parse(payload.data?.json_payload || '{}');
      notificationTitle = jsonPayload.notification_title;
      notificationBody = jsonPayload.notification_body || '';
      reminderId = jsonPayload.id?.toString() ?? null;
      route = reminderRoute(jsonPayload);
    } catch (e) {
      console.warn('[firebase-messaging-sw.js] Failed to parse json_payload', e);
      return;
    }

    if (!notificationTitle) return;

    const notificationOptions = {
      body: notificationBody,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: reminderId ?? notificationTitle,
      data: { route },
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
});
