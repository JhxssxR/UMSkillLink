import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:um_skill_link/main.dart';
import 'package:um_skill_link/widgets/student_layout.dart';
import 'package:um_skill_link/widgets/tutor_layout.dart';

void main() {
  setUpAll(() {
    // Disable Google Fonts HTTP fetching in tests to avoid network errors
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Login screen loads with expected elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UMSkillLinkApp());
    await tester.pumpAndSettle();

    expect(find.text('UM SkillLink'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(
      find.text('Only @umindanao.edu.ph accounts are accepted.'),
      findsOneWidget,
    );
    expect(find.text('Access Super Admin Portal'), findsOneWidget);
  });

  testWidgets('Google Sign-In: rejects invalid email domains', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UMSkillLinkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('to continue to UM SkillLink'), findsOneWidget);

    // Test completely invalid email syntax
    await tester.enterText(find.byType(TextFormField).first, 'notanemail');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    // Test wrong domain
    await tester.enterText(find.byType(TextFormField).first, 'test@gmail.com');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('Use your @umindanao.edu.ph school account'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Google Sign-In: accepts @umindanao.edu.ph and transitions to password step',
    (WidgetTester tester) async {
      await tester.pumpWidget(const UMSkillLinkApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'maria.santos@umindanao.edu.ph',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('maria.santos@umindanao.edu.ph'), findsOneWidget);
    },
  );

  testWidgets('Google Sign-In: rejects short passwords', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UMSkillLinkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'maria.santos@umindanao.edu.ph',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '123');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Wrong password. Try again or click Forgot password to reset it.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Google Sign-In: signs in with valid credentials and routes to StudentLayout',
    (WidgetTester tester) async {
      await tester.pumpWidget(const UMSkillLinkApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'maria.santos@umindanao.edu.ph',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'password123');
      await tester.tap(find.text('Next'));

      // Allow async Firestore call and navigator push to settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(StudentLayout), findsOneWidget);
      // Active tab 0 (Market) label is visible in the bubble nav
      expect(find.text('Market'), findsOneWidget);
    },
  );

  testWidgets('StudentLayout: animated bubble nav switches tabs correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StudentLayout()));
    await tester.pumpAndSettle();

    // Tab 0 (Market) active by default — label visible in bubble
    expect(find.text('Market'), findsOneWidget);

    // Tap Bookings nav item by ValueKey
    await tester.tap(find.byKey(const ValueKey('student_nav_1')));
    await tester.pumpAndSettle();
    // 'Bookings' appears in the active nav bubble
    expect(find.text('Bookings'), findsAtLeast(1));

    // Tap Messages nav item
    await tester.tap(find.byKey(const ValueKey('student_nav_2')));
    await tester.pumpAndSettle();
    // 'Messages' appears in both the nav bubble and the screen AppBar — either is fine
    expect(find.text('Messages'), findsAtLeast(1));

    // Tap Profile nav item
    await tester.tap(find.byKey(const ValueKey('student_nav_3')));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsAtLeast(1));
  });

  testWidgets('Student Profile: Switch to Tutor Mode navigates to TutorLayout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StudentLayout(initialIndex: 3)),
    );
    await tester.pumpAndSettle();

    // Student name is near the top and always visible
    expect(find.text('Juan Dela Cruz'), findsOneWidget);

    // Scroll until 'Switch to Tutor Mode' is built and visible (ListView is lazy)
    await tester.scrollUntilVisible(
      find.text('Switch to Tutor Mode'),
      150.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Now tap the button
    await tester.tap(find.text('Switch to Tutor Mode'));
    await tester.pumpAndSettle();

    expect(find.byType(TutorLayout), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('TutorLayout: animated bubble nav switches tabs correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TutorLayout()));
    await tester.pumpAndSettle();

    // Tab 0 (Dashboard) active by default
    expect(find.text('Dashboard'), findsOneWidget);

    // Tap Services tab by ValueKey
    await tester.tap(find.byKey(const ValueKey('tutor_nav_1')));
    await tester.pumpAndSettle();
    expect(find.text('Services'), findsAtLeast(1));

    // Tap Requests tab
    await tester.tap(find.byKey(const ValueKey('tutor_nav_2')));
    await tester.pumpAndSettle();
    expect(find.text('Requests'), findsAtLeast(1));

    // Tap Profile tab
    await tester.tap(find.byKey(const ValueKey('tutor_nav_3')));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsAtLeast(1));
  });

  testWidgets(
    'Tutor Profile: Switch to Student Mode navigates back to StudentLayout',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TutorLayout()));
      await tester.pumpAndSettle();

      // Navigate to Profile tab using ValueKey
      await tester.tap(find.byKey(const ValueKey('tutor_nav_3')));
      await tester.pumpAndSettle();

      // Maria Santos is near the top of tutor profile — always visible
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('BS Civil Engineering'), findsOneWidget);

      // Scroll until the Switch button is built and visible (lazy ListView)
      await tester.scrollUntilVisible(
        find.text('Switch to Student Mode'),
        150.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Switch to Student Mode'));
      await tester.pumpAndSettle();

      expect(find.byType(StudentLayout), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
    },
  );
}
