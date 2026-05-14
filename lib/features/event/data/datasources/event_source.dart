import '../models/event_model.dart';

abstract class EventSource {
  Future<List<EventModel>> getUpcomingEvents();
}

class EventSourceImpl implements EventSource {
  @override
  Future<List<EventModel>> getUpcomingEvents() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      EventModel(
        id: '1',
        title: "Flutter Hackathon 2025",
        subtitle: "Join us for a 2-day hackathon!", 
        image: 'assets/Hackathon.jpg',
        date: "12 July 2025",
        time: "10:00 AM",
        location: "Bhubaneswar Tech Park",
        cost: "Free", 
        points: 100, 
        enrollments: 50, 
        dateTime: DateTime(2025, 7, 12, 10, 0, 0), 
        desc: "A fun and engaging hackathon for Flutter developers.", 
        tags: ['Flutter', 'Hackathon', 'Mobile Development'], 
        perks: [
          EventPerkModel(name: 'Networking', icon: 'assets/ticket_cut.svg'), 
          EventPerkModel(name: 'Free Swag', icon: 'assets/ticket_cut.svg') 
        ],
      ),
      EventModel(
        id: '2',
        title: "Tech Innovators Meetup",
        subtitle: "Monthly meetup for tech enthusiasts.", 
        image: 'assets/arena_color.png',
        date: "18 Aug 2025",
        time: "6:00 PM",
        location: "Online",
        cost: "Free", 
        points: 20, 
        enrollments: 120, 
        dateTime: DateTime(2025, 8, 18, 18, 0, 0), 
        desc: "Discuss the latest trends in technology and innovation.", 
        tags: ['Tech', 'Innovation', 'Meetup'], 
        perks: [
          EventPerkModel(name: 'Online Access', icon: 'assets/ticket_cut.svg'), 
          EventPerkModel(name: 'Q&A Session', icon: 'assets/ticket_cut.svg') 
        ],
      ),
    ];
  }
}
