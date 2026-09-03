# Google Play Console Permissions Declaration Justification

This document provides ready-to-submit justifications for Google Play Console policy compliance for **رفيقي (Rafeeqi)** (com.abdulrahman.rafeeqi).

---

## 1. FOREGROUND_SERVICE_SPECIAL_USE

### Purpose & User-Facing Feature:
**Persistent Live Prayer Countdown in Notification Drawer**

### Subtype Defined in AndroidManifest:
Prayer Times Live Countdown (ndroid.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE)

### Declaration Details:
- **What is the user-facing purpose of this foreground service?**
  Rafeeqi provides an active, persistent status bar notification displaying a real-time countdown to the next Islamic prayer time. This informs users in real time of remaining prayer intervals without requiring them to open the app repeatedly throughout the day.
- **Why can't this task be deferred or run in the background without a foreground service?**
  Android system battery optimizations (Doze mode / App Standby) throttle standard background tasks, periodic workers, and alarms. Accurate, second-by-second countdown and timely updates in the ongoing notification card require active foreground service execution with an ongoing user-visible notification as mandated by Android's background execution limits.
- **How does the user initiate or control this feature?**
  The user toggles the prayer countdown notification from the app settings. A persistent notification is displayed in the notification drawer with an action to open the app or dismiss the service.

---

## 2. RECEIVE_BOOT_COMPLETED

### Purpose:
**Rescheduling Exact Prayer Notifications and Alarms Upon Device Restart**

### Declaration Details:
- **What is the user-facing purpose of this permission?**
  Islamic prayer times change daily according to geographical astronomical calculations (Fajr, Dhuhr, Asr, Maghrib, Isha). Scheduled system alarms set via AlarmManager and AwesomeNotifications are automatically wiped by the Android operating system whenever the device reboots or powers off.
- **Why is this permission required?**
  Without RECEIVE_BOOT_COMPLETED, any phone restart would permanently silence all scheduled prayer adhan notifications and the 10-minute reminder notifications until the user manually relaunches the app. Listening to the BOOT_COMPLETED broadcast enables Rafeeqi to immediately recalculate and re-register the daily prayer notification alarms for the current location without requiring manual user intervention.
