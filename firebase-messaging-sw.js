importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCbwxFAuCHpPKSs5KPsrdXkMzx4rQUQCDc",
  authDomain: "eleva-aed15.firebaseapp.com",
  projectId: "eleva-aed15",
  storageBucket: "eleva-aed15.firebasestorage.app",
  messagingSenderId: "795412805345",
  appId: "1:795412805345:web:bfa8cb45c394e7e255e9a0",
  measurementId: "G-QQ0E5S7Q2F"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const notification = message.notification;
  if (!notification) return;

  return self.registration.showNotification(notification.title, {
    body: notification.body,
    icon: "/icons/Icon-192.png",
  });
});
