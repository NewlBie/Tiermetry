Yes. Since you already have the **core discovery UI** built, the next step is not "add more screens." It is to turn the frontend into a **complete product flow**, where every user action has a defined state and endpoint.

For Tiermetry, I'd structure the frontend checklist around **user journeys**, not individual screens. Otherwise you end up with 47 beautiful pages and one button that leads directly into the void, which is a depressingly common startup tradition.

# Tiermetry Frontend Completion Checklist

## 0. Global foundation

Before finishing individual features, make sure these exist everywhere.

### App-wide UI

* [ ] Splash screen
* [ ] First-launch onboarding
* [ ] Login
* [ ] Sign up
* [ ] OTP verification
* [ ] Forgot password / account recovery
* [ ] Session persistence
* [ ] Logout
* [ ] Global loading state
* [ ] Global error state
* [ ] Network-offline state
* [ ] Empty states
* [ ] Skeleton loaders
* [ ] Pull-to-refresh
* [ ] Toast/snackbar system
* [ ] Confirmation dialogs
* [ ] Bottom sheets
* [ ] Modal system
* [ ] Deep-link handling
* [ ] Back-navigation behavior
* [ ] Authentication-required redirect

### Global navigation

* [ ] Home
* [ ] Arena
* [ ] Events
* [ ] Profile
* [ ] Persistent bottom navigation
* [ ] Active/inactive navigation states
* [ ] Navigation restoration after returning from child pages

---

# 1. First Launch → Account Setup

This is the actual beginning of the product.

### First launch

* [ ] Splash
* [ ] App initialization
* [ ] Check authentication state
* [ ] Check whether onboarding has been completed
* [ ] Check whether profile setup is complete

### Onboarding

* [ ] What Tiermetry is
* [ ] Arena / gaming venues
* [ ] Events & competitions
* [ ] Points / rewards
* [ ] Personalized recommendations

### Authentication

* [ ] Login screen
* [ ] Sign-up screen
* [ ] Phone/email input
* [ ] OTP screen
* [ ] OTP resend timer
* [ ] OTP error state
* [ ] Account creation success
* [ ] Login failure
* [ ] Existing-account detection

### Initial profile setup

* [ ] Name
* [ ] Username
* [ ] Profile picture
* [ ] Date of birth if required
* [ ] City/location
* [ ] Gaming interests
* [ ] Preferred platforms
* [ ] Preferred games
* [ ] Initial preferences
* [ ] Skip option where appropriate
* [ ] Profile completion state

---

# 2. HOME

Your Home page shouldn't just be a pretty dashboard. It should become the **personalized command center**.

## Home structure

* [ ] Greeting
* [ ] User profile shortcut
* [ ] Location selector
* [ ] Search
* [ ] Notifications
* [ ] Current points
* [ ] Wallet/payment shortcut
* [ ] Upcoming booking
* [ ] Upcoming event
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

* [ ] Search → results
* [ ] Arena card → arena details
* [ ] Event card → event details
* [ ] Sponsored card → sponsored destination
* [ ] Booking card → booking details
* [ ] Upcoming event → event management
* [ ] Notification → notification detail
* [ ] Points → points history
* [ ] Wallet → transactions

## Home states

* [ ] New user
* [ ] Returning user
* [ ] No bookings
* [ ] No events
* [ ] No recommendations
* [ ] Location unavailable
* [ ] Network failure
* [ ] Loading
* [ ] Personalized content unavailable

---

# 3. ARENA

This is your primary **discovery → booking** funnel.

## Arena listing page

* [ ] Search
* [ ] Location
* [ ] Filter
* [ ] Sort
* [ ] Categories
* [ ] Nearby
* [ ] Popular
* [ ] Recommended
* [ ] Sponsored
* [ ] Recently viewed
* [ ] Recently booked

### Filters

* [ ] Distance
* [ ] Price
* [Rating
* [Platform]
* [PC]
* [PS5]
* [Xbox]
* [VR]
* [Racing]
* [Pool]
* [Bowling]
* [Other activities]
* [Availability
* [Open now]
* [Offers
* [Amenities

### Sorting

* [ ] Recommended
* [ ] Distance
* [ ] Rating
* [Price low → high
* [Price high → low
* [Popularity
* [Newest

### Listing card

Every card should support:

* [ ] Store image
* [ ] Store name
* [ ] Rating
* [ ] Review count
* [ ] Distance
* [ ] Location
* [ ] Starting price
* [ ] Available services
* [ ] Open/closed
* [ ] Sponsored badge
* [ ] Favorite
* [ ] Quick booking

---

# 4. ARENA → STORE DETAILS

You said this part is already largely developed. Now make sure it is **functionally complete**.

## Store details

* [ ] Image gallery
* [ ] Store name
* [ ] Rating
* [ ] Reviews
* [ ] Location
* [ ] Map
* [ ] Contact
* [ ] Opening hours
* [ ] About
* [ ] Amenities
* [ ] Rules
* [ ] Available platforms
* [ ] Available games
* [ ] Pricing
* [ ] Offers
* [ ] Memberships if applicable
* [ ] Photos
* [ ] Reviews
* [ ] Store policies

### Actions

* [ ] Book now
* [ ] Call
* [ ] Navigate
* [ ] Share
* [ ] Favorite
* [ ] Report
* [ ] View reviews

---

# 5. STORE → SERVICE SELECTION

This is one of the most important screens in the entire application.

### Service selection

* [ ] Select service
* [ ] PS5
* [ ] PC
* [ ] Xbox
* [ ] VR
* [ ] Racing simulator
* [ ] Other activities

For each service:

* [ ] Available units
* [ ] Pricing
* [ ] Duration
* [ ] Capacity
* [ ] Minimum booking
* [ ] Maximum booking
* [ ] Available slots

### Quantity

Example:

> PS5
> ₹200/hour
> 4 available

* [ ] Increase quantity
* [ ] Decrease quantity
* [ ] Capacity validation
* [ ] Price recalculation
* [ ] Duration selection
* [ ] Date selection
* [ ] Time selection

---

# 6. BOOKING FLOW

This should be treated as its own complete subsystem.

## Booking Step 1 → Service

* [ ] Service
* [ ] Quantity
* [ ] Duration
* [ ] Date
* [ ] Time

## Booking Step 2 → Details

* [ ] User information
* [ ] Participants
* [ ] Special requests
* [ ] Coupon
* [ ] Points usage
* [ ] Referral benefit if applicable

## Booking Step 3 → Price

Display a proper breakdown:

* [ ] Base price
* [ ] Quantity
* [ ] Duration
* [ ] Taxes
* [ ] Platform fee
* [ ] Discount
* [ ] Points discount
* [ ] Final total

## Booking Step 4 → Payment

* [ ] Payment method
* [ ] UPI
* [ ] Card
* [ ] Wallet if applicable
* [ ] Payment processing state
* [ ] Payment success
* [ ] Payment failure
* [ ] Payment timeout
* [ ] Payment cancelled

## Booking Step 5 → Confirmation

* [ ] Booking success
* [ ] Booking ID
* [ ] Store
* [ ] Date
* [ ] Time
* [ ] Services
* [ ] Quantity
* [ ] Amount
* [ ] Payment status
* [ ] QR/code if required
* [ ] Add to calendar
* [ ] Directions
* [ ] Share booking
* [ ] Cancel booking

---

# 7. BOOKING MANAGEMENT

This is where your example:

> book → confirmation → transaction → update → confirmed

becomes an actual system.

## My Bookings

Separate:

### Upcoming

* [ ] Upcoming bookings
* [ ] Booking card
* [ ] Booking status
* [ ] Countdown
* [ ] Store information
* [ ] Date/time
* [ ] QR/code

### Completed

* [ ] Past bookings
* [ ] Booking details
* [ ] Receipt
* [ ] Review
* [ ] Rebook

### Cancelled

* [ ] Cancelled bookings
* [ ] Cancellation reason
* [ ] Refund status

---

# 8. BOOKING DETAILS

Every booking should have a dedicated detail page.

* [ ] Booking ID
* [ ] Booking status
* [ ] Payment status
* [ ] Store
* [ ] Location
* [ ] Service
* [ ] Quantity
* [ ] Date
* [ ] Time
* [ ] Duration
* [ ] Price breakdown
* [ ] Payment method
* [ ] QR/check-in
* [ ] Cancellation policy
* [ ] Cancellation
* [ ] Modification
* [ ] Contact venue
* [ ] Directions
* [ ] Receipt
* [ ] Report issue

### Booking states

You need explicit UI for:

* [ ] Pending
* [ ] Confirmed
* [ ] Checked-in
* [ ] In-progress
* [ ] Completed
* [ ] Cancelled
* [ ] Refund pending
* [ ] Refunded
* [ ] Failed
* [ ] Expired
* [ ] No-show

---

# 9. MODIFY BOOKING

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

---

# 10. CANCELLATION + REFUND

## Cancellation

* [ ] Cancel button
* [ ] Cancellation policy
* [ ] Refund calculation
* [ ] Cancellation reason
* [ ] Confirmation
* [ ] Cancellation processing
* [ ] Cancellation success

## Refund

* [ ] Refund initiated
* [ ] Refund pending
* [ ] Refund completed
* [ ] Refund failed
* [ ] Refund amount
* [ ] Expected timeline
* [ ] Transaction reference

---

# 11. EVENTS

This is your second major funnel.

## Events listing

* [ ] Featured events
* [ ] Upcoming events
* [ ] Ongoing events
* [ ] Completed events
* [ ] Competitions
* [ ] Tournaments
* [ ] Community events
* [ ] Search
* [ ] Filter
* [ ] Sort
* [ ] Categories

### Filters

* [ ] Game
* [ ] Platform
* [ ] Location
* [ ] Entry fee
* [ ] Prize pool
* [ ] Date
* [ ] Team/solo
* [ ] Online/offline
* [ ] Registration open

---

# 12. EVENT DETAILS

* [ ] Event banner
* [ ] Event title
* [ ] Organizer
* [ ] Venue
* [ ] Date
* [ ] Time
* [ ] Registration deadline
* [ ] Entry fee
* [ ] Prize pool
* [ ] Participants
* [ ] Maximum capacity
* [ ] Current registrations
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

* [ ] Register
* [ ] Join event
* [ ] Share
* [ ] Favorite
* [ ] Report

---

# 13. EVENT REGISTRATION

This deserves its own flow.

### Registration

* [ ] Solo/team selection
* [ ] Player details
* [ ] Team creation
* [ ] Team name
* [ ] Team logo
* [ ] Add teammates
* [ ] Invite teammates
* [ ] Verify players
* [ ] Accept rules
* [ ] Entry fee
* [ ] Coupon
* [ ] Points
* [ ] Payment

### Registration confirmation

* [ ] Registration ID
* [ ] Event details
* [ ] Team details
* [ ] Participants
* [ ] Payment status
* [ ] QR/check-in
* [ ] Event schedule

---

# 14. EVENT MANAGEMENT

Once registered:

* [ ] My Events
* [ ] Upcoming
* [ ] Ongoing
* [ ] Completed
* [ ] Registration status
* [ ] Team management
* [ ] Teammate status
* [ ] Event announcements
* [ ] Match schedule
* [ ] Match result
* [ ] Bracket
* [ ] Leaderboard
* [ ] Notifications
* [ ] Check-in
* [ ] Event rules

### Competition states

* [ ] Registration open
* [ ] Registration closed
* [ ] Registration pending
* [ ] Confirmed
* [ ] Check-in open
* [ ] Checked in
* [ ] Match assigned
* [ ] Match ongoing
* [ ] Won
* [ ] Lost
* [ ] Eliminated
* [ ] Finalist
* [ ] Winner
* [ ] Event completed

---

# 15. PAYMENTS

Don't bury payments inside bookings. You need a central transaction system.

## Wallet / payments

* [ ] Wallet balance
* [ ] Add money if applicable
* [ ] Payment methods
* [ ] Saved methods
* [ ] Transaction history
* [ ] Transaction details
* [ ] Refunds
* [ ] Failed payments
* [ ] Pending payments

## Transaction detail

* [ ] Transaction ID
* [ ] Date
* [ ] Type
* [ ] Amount
* [ ] Status
* [ ] Related booking/event
* [ ] Payment method
* [ ] Invoice
* [ ] Refund information

### Transaction states

* [ ] Initiated
* [ ] Processing
* [ ] Successful
* [ ] Failed
* [ ] Cancelled
* [ ] Pending
* [ ] Refunded
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

* [ ] Available rewards
* [ ] Reward details
* [ ] Points required
* [ ] Redeem
* [ ] Redemption confirmation
* [ ] Redemption history

---

# 17. REFERRALS

## Referral dashboard

* [ ] Referral code
* [ ] Referral link
* [ ] Share
* [ ] Copy code
* [ ] Referral count
* [ ] Successful referrals
* [ ] Pending referrals
* [ ] Rewards earned
* [ ] Referral history

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

* [ ] Profile header
* [ ] Avatar
* [ ] Name
* [ ] Username
* [ ] Points
* [ ] Tier
* [ ] Stats
* [ ] Edit profile

### Profile sections

* [ ] Personal information
* [ ] Account settings
* [ ] Privacy
* [ ] Security
* [ ] Notifications
* [ ] Payment methods
* [ ] Addresses/location
* [ ] Preferences
* [ ] Gaming preferences
* [ ] My bookings
* [ ] My events
* [ ] Points
* [ ] Referrals
* [ ] Transactions
* [ ] Favorites
* [ ] Reviews
* [ ] Help & support
* [ ] Terms
* [ ] Privacy policy
* [ ] Delete account
* [ ] Logout

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
* [ ] Reviews
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

* [ ] Search arenas
* [ ] Search events
* [ ] Search games
* [ ] Search locations
* [ ] Search suggestions
* [ ] Recent searches
* [ ] Trending searches
* [ ] Search results
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
* [ ] Favorites page
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
* [ ] Payment successful
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
* [ ] Booking expired
* [ ] Payment succeeded but booking failed
* [ ] Booking succeeded but confirmation request failed
* [ ] Duplicate booking prevention
* [ ] Double payment prevention

---

# 29. Frontend Architecture Checklist

Don't just build screens. Build reusable systems.

### Components

* [ ] ArenaCard
* [ ] EventCard
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
* [ ] EmptyState
* [ ] ErrorState
* [ ] LoadingSkeleton
* [ ] StatusBadge
* [ ] ConfirmationModal

### State management

Separate:

* [ ] Authentication state
* [ ] User state
* [ ] Arena state
* [ ] Event state
* [ ] Booking state
* [ ] Payment state
* [ ] Points state
* [ ] Referral state
* [ ] Notification state
* [ ] Recommendation state

### API/data layer

* [ ] API service layer
* [ ] Models
* [ ] DTOs
* [ ] Serialization
* [ ] Error handling
* [ ] Request state
* [ ] Cache strategy
* [ ] Pagination
* [ ] Infinite scrolling
* [ ] Refresh
* [ ] Retry
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
