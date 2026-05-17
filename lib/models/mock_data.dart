class MockData {
  static List<Map<String, dynamic>> tutors = [
    {
      'id': '1',
      'name': 'Sarah Jenkins',
      'subject': 'UI/UX & Graphic Design',
      'rating': 4.9,
      'reviews': 34,
      'price': 120,
      'about': 'Creative UI/UX designer with 3 years of experience helping students understand Figma and design systems.',
      'expertise': ['Figma Basics', 'Design Systems', 'Typography', 'Wireframing'],
      'availability': 'Mon - Wed, 2:00 PM - 5:00 PM',
      'onCampus': true,
      'badges': ['Student Verified', 'Top Rated Tutor', 'Dean\'s Lister'],
      'degree': 'BS Information Technology',
    },
    {
      'id': '2',
      'name': 'Marcus Wong',
      'subject': 'Calculus & Physics',
      'rating': 4.8,
      'reviews': 56,
      'price': 150,
      'about': 'Patient and knowledgeable. I adjust to my learning speed very well. Highly recommended for Engineering students.',
      'expertise': ['Calculus I & II', 'Physics Mechanics', 'Linear Algebra'],
      'availability': 'Thu - Sat, 1:00 PM - 6:00 PM',
      'onCampus': true,
      'badges': ['Student Verified', 'Dean\'s Lister'],
      'degree': 'BS Mechanical Engineering',
    },
    {
      'id': '3',
      'name': 'Elena Cruz',
      'subject': 'Python Programming',
      'rating': 5.0,
      'reviews': 21,
      'price': 140,
      'about': 'Full-stack developer ready to help you debug and understand core Python programming concepts.',
      'expertise': ['Python Syntax', 'Data Structures', 'OOP Concepts', 'Debugging'],
      'availability': 'Mon - Fri, 5:00 PM - 8:00 PM',
      'onCampus': false,
      'badges': ['Student Verified', 'Top Rated Tutor'],
      'degree': 'BS Computer Science',
    },
    {
      'id': '4',
      'name': 'Maria Santos',
      'subject': 'Calculus II & Engineering Mechanics',
      'rating': 4.9,
      'reviews': 28,
      'price': 200,
      'about': 'Third-year Engineering student with a passion for deconstructing complex structural concepts. I believe peer tutoring is the most effective way to master challenging STEM subjects while building university camaraderie.',
      'expertise': ['Calculus II', 'Physics', 'Eng. Mech.'],
      'availability': 'Mon - Fri, After 5:00 PM',
      'onCampus': true,
      'badges': ['Student Verified', 'Top Rated Tutor', 'Dean\'s Lister'],
      'degree': 'BS Civil Engineering',
    },
    {
      'id': '5',
      'name': 'Marco Santos',
      'subject': 'Advanced Calculus & Algebra',
      'rating': 5.0,
      'reviews': 42,
      'price': 250,
      'about': 'Mathematics major focusing on helping peers excel in Integration Theorems, advanced vector analysis, and linear algebra.',
      'expertise': ['Calculus II', 'Mathematics', 'Integration Theorems'],
      'availability': 'Mon - Fri, 10:00 AM - 4:00 PM',
      'onCampus': true,
      'badges': ['Student Verified', 'Top Rated Tutor'],
      'degree': 'BS Mathematics',
    }
  ];

  static List<Map<String, dynamic>> learnerBookings = [
    {
      'id': '101',
      'tutorName': 'Sarah Henderson',
      'subject': 'Python Advanced Concepts',
      'time': 'TOMORROW • 10:00 AM',
      'isUpcoming': true,
      'status': 'Confirmed',
      'imagePath': 'assets/images/tutor_sarah.png',
    },
    {
      'id': '102',
      'tutorName': 'Dr. Aris Ramos',
      'subject': 'Differential Calculus II',
      'time': 'WED, NOV 15 • 2:00 PM',
      'isUpcoming': true,
      'status': 'Confirmed',
      'imagePath': 'assets/images/tutor_aris.png',
    },
    {
      'id': '103',
      'tutorName': 'Marcus Wong',
      'subject': 'Calculus & Physics',
      'time': 'Oct 12, 10:00 AM',
      'isUpcoming': false,
      'status': 'Completed',
      'imagePath': 'assets/images/tutor_marcus.png',
    },
  ];

  static List<Map<String, dynamic>> tutorRequests = [
    {
      'id': '201',
      'learnerName': 'Elena Santos',
      'subject': 'Advanced Mathematics Tutoring',
      'time': 'Tomorrow, 2:00 PM',
      'status': 'Pending',
    },
    {
      'id': '202',
      'learnerName': 'Mark Reyes',
      'subject': 'Physics 101 Help',
      'time': 'Oct 14, 10:00 AM',
      'status': 'Completed',
    },
  ];

  static List<Map<String, dynamic>> favoriteTutors = [
    {
      'name': 'Sarah H.',
      'subject': 'Programming',
      'rating': 4.9,
    },
    {
      'name': 'Aris R.',
      'subject': 'Mathematics',
      'rating': 5.0,
    },
    {
      'name': 'Marcus W.',
      'subject': 'Engineering',
      'rating': 4.8,
    }
  ];

  static List<Map<String, dynamic>> messages = [
    {
      'name': 'Marco Santos',
      'message': 'Downloaded! Thank you so much. I\'ll see you at the Student Lounge at 2:00 PM.',
      'time': '09:50 AM',
      'isUnread': false,
    },
    {
      'name': 'Sarah Jenkins',
      'message': 'Sure, we can focus on the UI flow next session.',
      'time': '2 mins ago',
      'isUnread': true,
    },
    {
      'name': 'Marcus Wong',
      'message': 'Don\'t forget to review the physics notes!',
      'time': '1 hour ago',
      'isUnread': false,
    },
    {
      'name': 'Elena Cruz',
      'message': 'Thanks for booking! See you tomorrow.',
      'time': 'Yesterday',
      'isUnread': false,
    },
  ];
}
