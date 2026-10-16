Yes. Since you already have the **core discovery UI** built, the next step is not "add more screens." It is to turn the frontend into a **complete product flow**, where every user action has a defined state and endpoint.

For Tiermetry, I'd structure the frontend checklist around **user journeys**, not individual screens. Otherwise you end up with 47 beautiful pages and one button that leads directly into the void, which is a depressingly common startup tradition.

# Tiermetry Frontend Completion Checklist

> **Audit convention (2026-08-22):** `[x] ✓` means source, responsive UI, and its backing contract were verified. `[ ]` means the item is incomplete, presentation-only, mock-backed, or still depends on an undeployed migration or production provider.

## 0. Global foundation

Before finishing individual features, make sure these exist everywhere.

### App-wide UI

* [ ] Splash screen
* [x] ✓ First-launch onboarding
* [x] ✓ Login
* [x] ✓ Sign up
* [x] ✓ OTP verification
* [x] ✓ Forgot password / account recovery
* [x] ✓ Session persistence
* [x] ✓ Logout
* [ ] Global loading state
* [x] ✓ Global error state
* [x] ✓ Network-offline state
* [x] ✓ Empty states
* [x] ✓ Skeleton loaders
* [x] ✓ Pull-to-refresh
* [x] ✓ Toast/snackbar system
* [x] ✓ Confirmation dialogs
* [x] ✓ Bottom sheets
* [x] ✓ Modal system
* [ ] Deep-link handling
* [x] ✓ Back-navigation behavior
* [x] ✓ Authentication-required redirect

### Global navigation

* [x] ✓ Home
* [x] ✓ Arena
* [x] ✓ Events
* [x] ✓ Profile
* [x] ✓ Persistent bottom navigation
* [x] ✓ Active/inactive navigation states
* [x] ✓ Navigation restoration after returning from child pages

---

# 1. First Launch → Account Setup

This is the actual beginning of the product.

### First launch

* [ ] Splash
* [x] ✓ App initialization
* [x] ✓ Check authentication state
* [x] ✓ Check whether onboarding has been completed
* [x] ✓ Check whether profile setup is complete

### Onboarding

* [x] ✓ What Tiermetry is
* [x] ✓ Arena / gaming venues
* [x] ✓ Events & competitions
* [x] ✓ Points / rewards
* [x] ✓ Personalized recommendations

### Authentication

* [x] ✓ Login screen
* [x] ✓ Sign-up screen
* [ ] Phone/email input
* [x] ✓ OTP screen
* [x] ✓ OTP resend timer
* [x] ✓ OTP error state
* [x] ✓ Account creation success
* [x] ✓ Login failure
* [ ] Existing-account detection

### Initial profile setup

* [x] ✓ Name
* [x] ✓ Username
* [x] ✓ Profile picture
* [ ] Date of birth if required
* [x] ✓ City/location
* [x] ✓ Gaming interests
* [x] ✓ Preferred platforms
* [x] ✓ Preferred games
* [ ] Initial preferences
* [ ] Skip option where appropriate
* [x] ✓ Profile completion state

---

# 2. HOME

Your Home page shouldn't just be a pretty dashboard. It should become the **personalized command center**.

## Home structure

* [x] ✓ Greeting
* [x] ✓ User profile shortcut
* [x] ✓ Location selector
* [x] ✓ Search
* [x] ✓ Notifications
* [x] ✓ Current points
* [x] ✓ Wallet/payment shortcut
* [ ] Upcoming booking
* [x] ✓ Upcoming event
* [ ] Recommended arenas
* [ ] Sponsored arenas
* [ ] Trending arenas
* [ ] Trending games
* [ ] Recommended events
* [ ] Nearby venues
* [ ] Recently visited
* [ ] Recently booked
* [ ] Continue browsing
* [ ] Referral CTA
* [ ] Points/rewards CTA

## Home interactions

* [x] ✓ Arena card → arena details
* [x] ✓ Event card → event details
* [x] Booking card → booking details
* [x] Upcoming event → event management
* [x] Notification → notification detail
* [ ] Points → points history

## Home states

* [x] No bookings
* [x] No events
* [x] No recommendations
* [x] Location unavailable
* [x] Network failure
* [x] ✓ Loading
* [ ] Personalized content unavailable
---

# 3. ARENA

This is your primary **discovery → booking** funnel.

## Arena listing page

* [x] ✓ Search
* [ ] Location
* [x] ✓ Filter
* [x] ✓ Sort
* [x] ✓ Categories
* [x] Nearby
* [ ] Popular
* [ ] Recommended
* [x] Sponsored
* [ ] Recently viewed
* [ ] Recently booked

### Filters

* [x] Distance
* [x] ✓ Price
* [x] ✓ Rating
* [x] Platform
* [x] PC
* [x] PS5
* [x] Xbox
* [x] VR
* [x] Racing
* [x] Pool
* [x] Bowling
* [x] Other activities
* [x] Availability
* [x] ✓ Open now
* [x] Offers
* [x] Amenities

### Sorting

* [x] Recommended
* [x] Distance
* [x] ✓ Rating
* [x] ✓ Price low → high
* [x] ✓ Price high → low
* [x] ✓ Popularity
* [x] ✓ Newest

### Listing card

Every card should support:

* [x] ✓ Store image
* [x] ✓ Store name
* [x] ✓ Rating
* [x] ✓ Review count
* [x] Distance
* [x] ✓ Location
* [x] Starting price
* [x] ✓ Available services
* [x] Open/closed
* [x] Sponsored badge
* [x] Favorite
* [x] ✓ Quick booking

---

# 4. ARENA → STORE DETAILS

You said this part is already largely developed. Now make sure it is **functionally complete**.

## Store details

* [x] ✓ Image gallery
* [x] ✓ Store name
* [x] ✓ Rating
* [x] ✓ Reviews
* [x] ✓ Location
* [x] Map
* [x] ✓ Opening hours
* [x] ✓ About
* [x] ✓ Amenities
* [x] ✓ Rules
* [x] ✓ Available platforms
* [x] ✓ Available games
* [x] ✓ Pricing
* [ ] Offers
[//]: # (* [ ] Memberships if applicable) on hold for now
* [x] ✓ Photos
* [x] ✓ Reviews
* [ ] Store policies

### Actions

* [x] ✓ Book now
* [ ] Navigate
* [x] ✓ Share
* [ ] Favorite
* [ ] Report
* [ ] View reviews

---

# 5. STORE → SERVICE SELECTION

This is one of the most important screens in the entire application.

### Service selection

* [x] ✓ Select service
* [x] PS5
* [x] PC
* [x] Xbox
* [x] VR
* [x] Racing simulator
* [x] Other activities

For each service:

* [x] ✓ Available units
* [x] ✓ Pricing
* [x] ✓ Duration
* [x] Capacity
* [x] Minimum booking
* [x] Maximum booking
* [x] ✓ Available slots

### Quantity

Example:

> PS5
> ₹200/hour
> 4 available

* [x] ✓ Increase quantity
* [x] ✓ Decrease quantity
* [x] ✓ Capacity validation
* [x] ✓ Price recalculation
* [x] ✓ Duration selection
* [x] ✓ Date selection
* [x] ✓ Time selection

---

# 6. BOOKING FLOW

This should be treated as its own complete subsystem.

Implementation note: Tiermetry uses a fast 4-step arena booking flow, not a separate 5-screen wizard:

1. Arena details → select service/unit.
2. Booking bottom sheet → date, time, duration, participants, add-ons, and review brief.
3. Checkout invoice → final billing/taxes and payment method.
4. Payment result → confirmed, failed, or cancelled state.

The detailed checklist below is still maintained as coverage for the combined flow.

## Booking Step 1 → Service / Unit selection

* [x] ✓ Service
* [x] ✓ Quantity
* [x] ✓ Duration
* [x] ✓ Date
* [x] ✓ Time

## Booking Step 2 → Details

* [x] ✓ User information
* [x] ✓ Participants
* [ ] Special requests
* [ ] Coupon
* [ ] Points usage
* [ ] Referral benefit if applicable

## Booking Step 3 → Price / Invoice

Display a proper breakdown:

* [x] ✓ Base price
* [x] ✓ Quantity
* [x] ✓ Duration
* [x] ✓ Taxes
* [x] ✓ Platform fee
* [ ] Discount
* [ ] Points discount
* [x] ✓ Final total

## Booking Step 4 → Payment

* [x] ✓ Payment method
* [x] ✓ UPI
* [x] ✓ Card
* [x] ✓ Wallet if applicable
* [x] ✓ Payment processing state
* [x] ✓ Payment success
* [x] ✓ Payment failure
* [x] ✓ Payment timeout
* [x] ✓ Payment cancelled

## Booking Step 5 → Confirmation / Result

* [x] ✓ Booking success
* [x] ✓ Booking ID
* [x] ✓ Store
* [x] ✓ Date
* [x] ✓ Time
* [x] ✓ Services
* [x] ✓ Quantity
* [x] ✓ Amount
* [ ] Payment status
* [ ] QR/code if required
* [ ] Add to calendar
* [ ] Directions
* [x] ✓ Share booking
* [x] ✓ Cancel booking

---

# 7. BOOKING MANAGEMENT

This is where your example:

> book → confirmation → transaction → update → confirmed

becomes an actual system.

## My Bookings

Separate:

### Upcoming

* [x] ✓ Upcoming bookings
* [x] ✓ Booking card
* [x] ✓ Booking status
* [x] ✓ Countdown
* [x] ✓ Store information
* [x] ✓ Date/time
* [x] ✓ QR/code

### Completed

* [x] ✓ Past bookings
* [x] ✓ Booking details
* [x] ✓ Receipt
* [x] ✓ Review
* [x] ✓ Rebook

### Cancelled

* [x] ✓ Cancelled bookings
* [x] ✓ Cancellation reason
* [x] ✓ Refund status

---

# 8. BOOKING DETAILS

Every booking should have a dedicated detail page.

* [x] ✓ Booking ID
* [x] ✓ Booking status
* [x] ✓ Payment status
* [x] ✓ Store
* [x] ✓ Location
* [x] ✓ Service
* [x] ✓ Quantity
* [x] ✓ Date
* [x] ✓ Time
* [x] ✓ Duration
* [x] ✓ Price breakdown
* [x] ✓ Payment method
* [x] ✓ QR/check-in
* [x] ✓ Cancellation policy
* [x] ✓ Cancellation
* [ ] Directions
* [x] ✓ Receipt
* [ ] Report issue

### Booking states

You need explicit UI for:

* [x] ✓ Pending
* [x] ✓ Confirmed
* [x] ✓ Checked-in
* [x] ✓ In-progress
* [x] ✓ Completed
* [x] ✓ Cancelled
* [x] ✓ Refund pending
* [x] ✓ Refunded
* [x] ✓ Failed
* [x] ✓ Expired
* [x] ✓ No-show

---

<!-- This part is not needed -->
<!-- # 9. MODIFY BOOKING

Users should not need to recreate the booking because they selected 6 PM instead of 7 PM. Civilization has suffered enough.

* [ ] Change date
* [ ] Change time
* [ ] Change duration
* [ ] Change quantity
* [ ] Change service
* [ ] Recalculate price
* [ ] Show price difference
* [ ] Confirm modification
* [ ] Payment adjustment
* [ ] Modification success
* [ ] Modification failure

--- -->

# 10. CANCELLATION + REFUND

## Cancellation

* [x] ✓ Cancel button
* [x] ✓ Cancellation policy
* [x] ✓ Refund calculation
* [x] ✓ Cancellation reason
* [x] ✓ Confirmation
* [x] ✓ Cancellation processing
* [x] ✓ Cancellation success

## Refund

* [x] ✓ Refund initiated
* [x] ✓ Refund pending
* [x] ✓ Refund completed
* [x] ✓ Refund failed
* [x] ✓ Refund amount
* [x] ✓ Expected timeline
* [x] ✓ Transaction reference

---

# 11. EVENTS

This is your second major funnel.

## Events listing

* [x] Featured events
* [x] Upcoming events
* [x] Ongoing events
* [x] Completed events
* [x] ✓ Competitions
* [x] ✓ Tournaments
* [x] Community events
* [x] ✓ Search
* [x] ✓ Filter
* [x] Sort
* [x] ✓ Categories

### Filters

* [x] ✓ Game
* [x] Platform
* [x] Location
* [x] Entry fee
* [x] Prize pool
* [x] Date
* [x] Team/solo
* [x] Online/offline
* [x] Registration open

---

# 12. EVENT DETAILS

* [x] ✓ Event banner
* [x] ✓ Event title
* [x] ✓ Organizer
* [x] ✓ Venue
* [x] ✓ Date
* [x] ✓ Time
* [x] ✓ Registration deadline
* [x] ✓ Entry fee
* [x] Prize pool
* [x] Participants
* [x] ✓ Maximum capacity
* [x] Current registrations
* [ ] Game
* [ ] Platform
* [ ] Rules
* [ ] Format
* [ ] Schedule
* [ ] Bracket
* [ ] Rewards
* [ ] FAQs
* [ ] Contact organizer

### Actions

* [x] ✓ Register
* [x] ✓ Join event
* [x] ✓ Share
* [ ] Favorite
* [ ] Report

---

# 13. EVENT REGISTRATION

This is registration-platform scope for closed testing. Standard events
(concerts, yoga, stand-up, workshops, etc.) collect attendee registrations.
Competitions/tournaments collect individual or team registrations and payment
state only; match operations, brackets, results, and winners are deferred.

### Registration

* [x] ✓ Event attendee registration
* [x] ✓ Competition individual/team selection
* [x] ✓ Player/attendee details
* [x] ✓ Team creation
* [x] ✓ Team name
* [ ] Team logo
* [x] ✓ Add teammates
* [ ] Invite teammates
* [ ] Verify players
* [x] ✓ Accept rules
* [x] ✓ Entry fee
* [ ] Coupon
* [x] ✓ Points
* [x] ✓ Test payment capture
* [ ] Production payment provider settlement

### Registration confirmation

* [x] ✓ Registration ID
* [x] ✓ Event details
* [x] ✓ Team details
* [x] ✓ Participants
* [x] ✓ Payment status
* [ ] QR/check-in
* [x] ✓ Event schedule

---

# 14. EVENT MANAGEMENT

Once registered:

* [x] ✓ My Events
* [x] ✓ Upcoming
* [x] ✓ Ongoing
* [x] ✓ Completed
* [x] ✓ Registration status
* [x] ✓ Event / tournament / competition type labels
* [x] ✓ Team registration summary
* [x] ✓ Participant status
* [ ] Event announcements
* [x] ✓ Notifications
* [ ] Check-in
* [x] ✓ Event rules

<!-- Later tournament-management update, not part of the current registration-platform scope:
* [ ] Teammate invite / roster editing
* [ ] Match schedule
* [ ] Match result
* [ ] Bracket
* [ ] Leaderboard
-->

### Competition states

* [x] ✓ Registration open
* [x] ✓ Registration closed
* [ ] Registration pending
* [x] ✓ Confirmed
* [ ] Check-in open
* [ ] Checked in
* [ ] Event completed

<!-- Later tournament-management update:
* [ ] Match assigned
* [ ] Match ongoing
* [ ] Won
* [ ] Lost
* [ ] Eliminated
* [ ] Finalist
* [ ] Winner
-->

---

# 15. PAYMENTS

Don't bury payments inside bookings. You need a central transaction system.

## Wallet / payments

* [x] ✓ Wallet balance
* [x] ✓ Add money if applicable
* [x] ✓ Payment methods
* [x] ✓ Saved methods
* [x] ✓ Transaction history
* [x] ✓ Transaction details
* [ ] Refunds
* [x] ✓ Failed payments
* [ ] Pending payments

## Transaction detail

* [x] ✓ Transaction ID
* [x] ✓ Date
* [x] ✓ Type
* [x] ✓ Amount
* [x] ✓ Status
* [x] ✓ Related booking/event
* [x] ✓ Payment method
* [x] ✓ Invoice
* [x] ✓ Refund information

### Transaction states

* [x] ✓ Initiated
* [ ] Processing
* [x] ✓ Successful
* [x] ✓ Failed
* [x] ✓ Cancelled
* [x] ✓ Pending
* [x] ✓ Refunded
* [ ] Partially refunded

---

# 16. POINT SYSTEM

This should become a visible progression system, not just a number somewhere.

## Points dashboard

* [ ] Current points
* [ ] Lifetime points
* [ ] Points earned
* [ ] Points spent
* [ ] Points expiring
* [ ] Current tier/level
* [ ] Progress to next tier

## Points history

* [ ] Booking reward
* [ ] Event reward
* [ ] Referral reward
* [ ] Promotional reward
* [ ] Points redemption
* [ ] Expiration
* [ ] Adjustment

## Rewards

* [x] ✓ Available rewards
* [x] ✓ Reward details
* [x] ✓ Points required
* [x] Redeem
* [x] ✓ Redemption confirmation
* [ ] Redemption history

---

# 17. REFERRALS

## Referral dashboard

* [x] ✓ Referral code
* [x] ✓ Referral link
* [x] ✓ Share
* [x] ✓ Copy code
* [ ] Referral count
* [x] ✓ Successful referrals
* [ ] Pending referrals
* [x] ✓ Rewards earned
* [x] ✓ Referral history

## Referral flow

**User A**

→ shares referral

→ User B signs up

→ User B completes qualifying action

→ User A receives reward

Frontend needs:

* [ ] Invite screen
* [ ] Deep-link handling
* [ ] Referral attribution state
* [ ] Reward pending
* [ ] Reward received
* [ ] Referral failed/ineligible

---

# 18. PROFILE

You already have the profile shell, so now finish the actual destinations.

## Profile

* [x] ✓ Profile header
* [x] ✓ Avatar
* [x] ✓ Name
* [x] ✓ Username
* [x] ✓ Points
* [x] ✓ Tier
* [ ] Stats
* [x] ✓ Edit profile

### Profile sections

* [x] ✓ Personal information
* [x] ✓ Account settings
* [x] ✓ Privacy
* [x] ✓ Security
* [x] ✓ Notifications
* [x] ✓ Payment methods
* [x] ✓ Addresses/location
* [x] ✓ Preferences
* [x] ✓ Gaming preferences
* [x] ✓ My bookings
* [x] ✓ My events
* [x] ✓ Points
* [x] ✓ Referrals
* [x] ✓ Transactions
* [x] ✓ Favorites
* [x] ✓ Reviews
* [x] Help & support
* [x] Terms
* [x] ✓ Privacy policy
* [x] ✓ Delete account
* [x] ✓ Logout

---

# 19. USER ACTIVITY

This is important for your recommendation engine later.

## Activity

* [ ] Recently viewed arenas
* [ ] Recently viewed events
* [ ] Search history
* [ ] Favorite arenas
* [ ] Favorite games
* [ ] Bookings
* [ ] Event participation
* [x] ✓ Reviews
* [ ] Points activity
* [ ] Referral activity

## User statistics

Potentially:

* [ ] Total bookings
* [ ] Total events
* [ ] Hours played
* [ ] Money spent
* [ ] Points earned
* [ ] Favorite game
* [ ] Favorite arena
* [ ] Activity frequency

---

# 20. RECOMMENDATIONS

The frontend needs to support recommendation **explanations**, not just silently shove things into the user's face like every algorithm ever invented.

* [ ] Recommended arenas
* [ ] Recommended events
* [ ] Recommended games
* [ ] Based on location
* [ ] Based on activity
* [ ] Based on bookings
* [ ] Based on interests
* [ ] Similar venues
* [ ] Similar events
* [ ] Recently popular

### Recommendation UI

* [ ] "Recommended for you"
* [ ] "Because you played..."
* [ ] "Popular near you"
* [ ] "You may also like..."
* [ ] Dismiss recommendation
* [ ] Not interested

---

# 21. SPONSORED LISTINGS

Sponsored content needs a distinct frontend system.

* [ ] Sponsored arena cards
* [ ] Sponsored event cards
* [ ] Sponsored placement
* [ ] Sponsored badge
* [ ] Sponsored detail page
* [ ] Campaign landing page
* [ ] Offer/discount
* [ ] CTA tracking
* [ ] Impression tracking
* [ ] Click tracking

Don't make sponsored content visually indistinguishable from organic recommendations. That's how you create a trust problem for the sake of three pixels and a marketing department.

---

# 22. SEARCH

I'd make this a global system.

## Search

* [x] ✓ Search arenas
* [x] ✓ Search events
* [ ] Search games
* [ ] Search locations
* [ ] Search suggestions
* [ ] Recent searches
* [ ] Trending searches
* [x] ✓ Search results
* [ ] Search filters
* [ ] Empty results
* [ ] Typo/no-result handling

### Search result types

```text
Arenas
Events
Games
Locations
```

---

# 23. FAVORITES

* [ ] Favorite arena
* [ ] Favorite event
* [ ] Favorite game
* [ ] Remove favorite
* [x] ✓ Favorites page
* [ ] Empty favorites
* [ ] Availability changes
* [ ] Event reminders

---

# 24. REVIEWS

After a completed booking/event:

* [ ] Review prompt
* [ ] Rating
* [ ] Written review
* [ ] Photos if supported
* [ ] Edit review
* [ ] Delete review
* [ ] Review history
* [ ] Store review display
* [ ] Review moderation state

---

# 25. NOTIFICATIONS

You will need this much earlier than you think.

## Notification center

* [ ] Booking confirmation
* [ ] Booking reminder
* [ ] Booking modification
* [ ] Cancellation
* [ ] Refund
* [ ] Event registration
* [ ] Event reminder
* [ ] Match notification
* [ ] Event result
* [ ] Points earned
* [ ] Referral reward
* [ ] Promotional notification
* [ ] Sponsored promotion
* [ ] System notification

### Notification states

* [ ] Read
* [ ] Unread
* [ ] Deleted
* [ ] Deep-linked destination

---

# 26. SUPPORT

* [ ] Help center
* [ ] FAQ
* [ ] Contact support
* [ ] Create ticket
* [ ] Ticket details
* [ ] Ticket status
* [ ] Conversation
* [ ] Attachments
* [ ] Booking-linked support
* [ ] Payment-linked support

### Ticket states

* [ ] Open
* [ ] In progress
* [ ] Waiting for user
* [ ] Resolved
* [ ] Closed

---

# 27. ANALYTICS FRONTEND

Your backend can eventually calculate everything, but the frontend needs to **emit the events**.

Track:

### Discovery

* [ ] App opened
* [ ] Home viewed
* [ ] Arena viewed
* [ ] Event viewed
* [ ] Search performed
* [ ] Filter applied
* [ ] Listing clicked
* [ ] Recommendation clicked
* [ ] Sponsored listing clicked

### Booking

* [ ] Service selected
* [ ] Date selected
* [ ] Slot selected
* [ ] Booking started
* [ ] Booking abandoned
* [ ] Payment started
* [x] ✓ Payment successful
* [ ] Booking confirmed
* [ ] Booking cancelled
* [ ] Booking completed

### Events

* [ ] Event viewed
* [ ] Registration started
* [ ] Team created
* [ ] Registration completed
* [ ] Registration abandoned
* [ ] Event checked in
* [ ] Match viewed
* [ ] Result viewed

### Engagement

* [ ] Favorite added
* [ ] Favorite removed
* [ ] Review submitted
* [ ] Referral shared
* [ ] Referral completed
* [ ] Reward redeemed

---

# 28. GLOBAL ERROR / EDGE-CASE SYSTEM

This is the part developers conveniently forget until production starts eating users.

Every major flow needs:

* [ ] Loading
* [ ] Empty
* [ ] Error
* [ ] Retry
* [ ] Offline
* [ ] Timeout
* [ ] Unauthorized
* [ ] Forbidden
* [ ] Resource unavailable
* [ ] Session expired
* [ ] Server error

For booking specifically:

* [ ] Slot became unavailable
* [ ] Price changed
* [ ] Venue closed
* [x] ✓ Booking expired
* [ ] Payment succeeded but booking failed
* [ ] Booking succeeded but confirmation request failed
* [x] ✓ Duplicate booking prevention
* [x] ✓ Double payment prevention

---

# 29. Frontend Architecture Checklist

Don't just build screens. Build reusable systems.

### Components

* [x] ✓ ArenaCard
* [x] ✓ EventCard
* [ ] BookingCard
* [ ] ServiceSelector
* [ ] TimeSlotSelector
* [ ] PriceBreakdown
* [ ] PaymentMethodSelector
* [ ] TransactionCard
* [ ] PointsCard
* [ ] ReferralCard
* [ ] RecommendationSection
* [ ] SponsoredCard
* [ ] RatingComponent
* [x] ✓ EmptyState
* [x] ✓ ErrorState
* [x] ✓ LoadingSkeleton
* [ ] StatusBadge
* [ ] ConfirmationModal

### State management

Separate:

* [x] ✓ Authentication state
* [x] ✓ User state
* [x] ✓ Arena state
* [x] ✓ Event state
* [x] ✓ Booking state
* [x] ✓ Payment state
* [ ] Points state
* [ ] Referral state
* [ ] Notification state
* [ ] Recommendation state

### API/data layer

* [ ] API service layer
* [x] ✓ Models
* [ ] DTOs
* [x] ✓ Serialization
* [x] ✓ Error handling
* [x] ✓ Request state
* [ ] Cache strategy
* [x] ✓ Pagination
* [x] ✓ Infinite scrolling
* [x] ✓ Refresh
* [x] ✓ Retry
* [ ] Optimistic updates where appropriate

---

# 30. The Complete Tiermetry User Journey

This is the **master flow** I'd use to determine whether the frontend is actually finished.

```text
APP LAUNCH
   ↓
SPLASH
   ↓
ONBOARDING
   ↓
LOGIN / SIGNUP
   ↓
PROFILE SETUP
   ↓
HOME
   │
   ├───────────────┐
   ↓               ↓
ARENA            EVENTS
   ↓               ↓
LISTINGS         EVENT LIST
   ↓               ↓
STORE            EVENT DETAILS
DETAILS              ↓
   ↓              REGISTER
SERVICE               ↓
SELECTION          PAYMENT
   ↓                  ↓
DATE/TIME         CONFIRMATION
   ↓                  ↓
BOOKING DETAILS   MY EVENTS
   ↓                  ↓
PAYMENT           EVENT MANAGEMENT
   ↓
CONFIRMATION
   ↓
MY BOOKINGS
   ↓
BOOKING DETAILS
   │
   ├── Modify
   ├── Cancel
   ├── Refund
   ├── Review
   └── Rebook
```

And running alongside everything:

```text
USER
  │
  ├── PROFILE
  │     ├── Personal Data
  │     ├── Settings
  │     ├── Favorites
  │     ├── Bookings
  │     ├── Events
  │     ├── Transactions
  │     ├── Points
  │     └── Referrals
  │
  ├── POINTS
  │     ├── Earn
  │     ├── Spend
  │     ├── History
  │     └── Rewards
  │
  ├── PAYMENTS
  │     ├── Transactions
  │     ├── Refunds
  │     └── Payment Methods
  │
  ├── NOTIFICATIONS
  │
  ├── SEARCH
  │
  └── ACTIVITY
        ├── Viewed
        ├── Booked
        ├── Played
        └── Interacted
```

# Recommended development order

**Do not build these in random UI order.** Build them in dependency order:

| Phase  | Build                                    |
| ------ | ---------------------------------------- |
| **01** | Auth + onboarding + user state           |
| **02** | Arena → Listing → Store Details          |
| **03** | Service → Date → Time → Booking          |
| **04** | Payment → Confirmation → Transactions    |
| **05** | My Bookings → Modify → Cancel → Refund   |
| **06** | Events → Details → Registration          |
| **07** | Event payment → Confirmation → My Events |
| **08** | Event management → Match/Bracket/Results |
| **09** | Profile sub-pages                        |
| **10** | Points + rewards                         |
| **11** | Referrals                                |
| **12** | Notifications                            |
| **13** | Favorites + Reviews                      |
| **14** | Search + advanced filters                |
| **15** | Recommendations                          |
| **16** | Sponsored listings                       |
| **17** | Analytics instrumentation                |
| **18** | Error/edge-case pass                     |
| **19** | Performance + loading states             |
| **20** | Final UX consistency pass                |

## The definition of "frontend complete"

For **every major feature**, don't mark it complete merely because the screen exists.

Use this:

> **Discover → View → Select → Configure → Review → Pay → Confirm → Manage → Modify/Cancel → Complete → Review → Analyze**

If a feature doesn't have the appropriate states across that lifecycle, it's **UI-complete, not product-complete**.

For Tiermetry specifically, I'd consider the first serious frontend milestone reached when these two vertical slices work end-to-end:

### 🎮 Arena vertical slice

**Home → Arena → Store → Service → Slot → Booking → Payment → Confirmation → My Booking → Modify/Cancel → Transaction**

### 🏆 Event vertical slice

**Home/Events → Event → Register → Team → Payment → Confirmation → My Event → Check-in → Match → Result → Rewards**

Once those two work, the remaining profile, points, referral, recommendation, analytics, and polish systems can be layered onto a functioning product rather than decorating a very sophisticated collection of buttons.
