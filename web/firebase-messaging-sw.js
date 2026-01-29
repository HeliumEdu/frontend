// Import Firebase scripts for service worker
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase in the service worker with web configuration
firebase.initializeApp({
  apiKey: "AIzaSyCY_r9WBr_QOfui39GKjwLr-cRx0gaA8XM",
  authDomain: "helium-edu.firebaseapp.com",
  projectId: "helium-edu",
  storageBucket: "helium-edu.firebasestorage.app",
  messagingSenderId: "643279973445",
  appId: "1:643279973445:web:18d70bb986764d56dec72c",
  measurementId: "G-5FNS68QLK4",
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'Helium Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
