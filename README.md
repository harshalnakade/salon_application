# 💇‍♀️ Salon Booking App

A **full-featured salon booking and management app** built with **Flutter (Frontend)** and **Supabase (Backend)**. It enables salon owners to manage services and appointments while allowing customers to book slots and explore salons efficiently.

---

##  Features

###  User Roles
- **Customer** – Can browse salons, book appointments, and leave reviews.
- **Salon Owner** – Manages salon details, services, appointments, and images.
- **Admin** – Can manage the entire platform.

### Salon Owners Can:
- Register/Login securely.
- Add and manage salon profiles.
- Add, edit, or delete services offered.
- Upload salon images to Supabase Storage.
- View and manage appointments.
- Monitor real-time walk-in queues.
- Reply to customer reviews.

###  Customers Can:
- Register/Login securely.
- Explore salons and services.
- Book appointments by selecting services and available time slots.
- Leave reviews and ratings after visits.

---

##  Database Schema (Supabase)

The app uses multiple interconnected tables:

| Table | Description |
|-------|-------------|
| `users` | Stores customers, salon owners, and admin info |
| `salons` | Represents salons owned by users |
| `services` | Lists services offered by each salon |
| `appointments` | Tracks bookings between customers and salons |
| `appointment_services` | Many-to-many relation for services per appointment |
| `reviews` | Reviews left by customers after appointments |
| `salon_images` | Stores URLs to images in Supabase Storage |
| `walk_in_queue` | Live tracking of walk-in wait times per salon |



---

## 🛠Tech Stack

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Database**: Supabase PostgreSQL
- **Authentication**: Email/Password
- **Storage**: Supabase Storage for image handling
- **State Management**: Provider (or any used by you)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- Supabase project setup
- Android/iOS Emulator or real device

### Steps
1. Clone this repo:
   ```bash
   git clone https://github.com/harshalnakade/salon_application.git
   cd salon_application
