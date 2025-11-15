// Firebase Messaging service worker for web push notifications
// Generated baseline. Customize for background notification handling.
// Requires: add your measurementId if needed, and ensure VAPID key setup in main app.

importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

// These values should match DefaultFirebaseOptions.web in firebase_options.dart
firebase.initializeApp({
  apiKey: 'AIzaSyAfAhogbQ8tU2KJNHVNwBSKm7Af-M4FMVA',
  appId: '1:459245424017:web:a9265cf2cb75b1e4ed5e30',
  messagingSenderId: '459245424017',
  projectId: 'flutter-ai-playground-620c6',
  authDomain: 'flutter-ai-playground-620c6.firebaseapp.com',
  storageBucket: 'flutter-ai-playground-620c6.firebasestorage.app'
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw] Received background message', payload);
  const notificationTitle = payload.notification?.title || 'HemoAI';
  const notificationOptions = {
    body: payload.notification?.body || 'New health update',
    icon: '/icons/Icon-192.png'
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
