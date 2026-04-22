# FCM Node Sender

This folder contains a minimal Node.js sender for Firebase Cloud Messaging.

## 1) Install dependencies

npm install

## 2) Add credentials

1. Download your Firebase Admin SDK service account JSON.
2. Save it as server/serviceAccountKey.json.
3. Copy .env.example to .env and adjust values.

## 3) Send a notification

Use one of the following:

node send_notification.js --token YOUR_DEVICE_TOKEN

node send_notification.js --token YOUR_DEVICE_TOKEN --title "Campus Alert" --body "Event starts at 4 PM"

You can also put the token in .env as FCM_DEVICE_TOKEN and run:

npm start
