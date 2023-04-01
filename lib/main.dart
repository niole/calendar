import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) =>
    identical(this, other) || other is Event &&
    runtimeType == other.runtimeType &&
    title == other.title;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(bodySmall: TextStyle(fontSize: 50), bodyLarge: TextStyle(fontSize: 50.0)),
      ),
      home: const DefaultTextStyle(
        style: TextStyle(fontSize: 50, color: Colors.blue),
        child: CalendarView(title: 'Calendar'),
      ),
    );
  }
}

class CalendarView extends StatefulWidget {
  const CalendarView({super.key, required this.title});
  final String title;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _selectedDay = DateTime.now();

  // the user created tags
  Set<String> tags = {};

  // the dates that each event has been added to
  Map<DateTime, List<Event>> events = {};

  late final ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();

    _selectedEvents = ValueNotifier(getSelectedEvents(_selectedDay));
  }

  void setTag(String newTag) {
    tags.add(newTag);
    setState(() {
      tags = tags;
    });
  }

  void deleteTagFromDay(Event tag, DateTime date) {
    DateTime key = getDateKey(date);
    if (events.containsKey(key)) {
      events[key] = events[key]!.where((t) => t != tag).toList();
      setState(() {
        events = events;
        _selectedEvents.value = events[key]!;
      });
    }
  }

  void addTagToDay(String tag, DateTime date) {
    setTag(tag);

    DateTime key = getDateKey(date);

    events[key] = (events[key] ?? []);
    events[key]!.add(Event(tag));

    setState(() {
      events = events;
    });
  }

  DateTime getDateKey(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  List<Event> getSelectedEvents(DateTime date) {
    return events[getDateKey(date)] ?? [];
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TableCalendar(
              calendarFormat: CalendarFormat.week,
              onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
                if (_selectedDay == selectedDay && _selectedEvents.value.isNotEmpty) {
                  _selectedEvents.value = [];
                } else {
                  setState(() {
                    _selectedDay = selectedDay;
                  });

                  _selectedEvents.value = getSelectedEvents(selectedDay);
                }
              },
              eventLoader: (day) {
                return getSelectedEvents(day);
              },
              firstDay: DateTime.now().subtract(const Duration(days: 180)),
              lastDay: DateTime.now().add(const Duration(days: 180)),
              focusedDay: _selectedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
            ),
            Expanded(
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          trailing: FloatingActionButton.small(
                            heroTag: value[index],
                            onPressed: () {
                              deleteTagFromDay(value[index], _selectedDay);
                            },
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.delete_outlined),
                          ),
                          title: Text('${value[index]}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>
                Scaffold(
                  appBar: AppBar(
                    title: const Text('Add/Pick a Label'),
                  ),
                  body: Center(
                    child: TypeAheadField(
                      suggestionsCallback: (String query) {
                        // find the matching tags and suggest new label
                        List<String> matches = [query];
                        matches.addAll(tags.where((k) => k.contains(query)).toList());
                        matches.sort((a, b) => a == query ? 0 : a.compareTo(b));
                        return matches;
                      },
                      onSuggestionSelected: (selection) {
                        addTagToDay(selection, _selectedDay);
                        Navigator.pop(context);
                      },
                      textFieldConfiguration: const TextFieldConfiguration(
                        autofocus: true,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(), hintText: 'Select/Create a Label'
                        ),
                      ),
                      itemBuilder: (BuildContext context, suggestion) {
                        // this is called with data from the suggestions callback
                        // and this renders each item in the typeahead
                        return Text(suggestion);
                      },
                      suggestionsBoxDecoration: SuggestionsBoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        elevation: 8.0,
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                  ),
                )
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
