import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'state.dart';
import 'event.dart';

void main() {
  setupGlobalState();
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
      home: DefaultTextStyle(
        style: const TextStyle(fontSize: 50, color: Colors.blue),
        child: ValueListenableBuilder<MainPage>(
          valueListenable: getIt<GlobalState>().mainPage,
          builder: (context, value, _) {
            return CalendarView(title: 'Calendar', s: value);
          }
        ),
      ),
    );
  }
}

class CalendarView extends StatelessWidget {
  const CalendarView({super.key, required this.title, required this.s});
  final String title;
  final MainPage s;

  void updateState(MainPage newState) =>
    getIt<GlobalState>().mainPage.value = newState.clone();

  void setTag(String newTag) {
    Set<String> tags = s.tags.value;

    tags.add(newTag);

    s.tags.value = tags;

    updateState(s);
  }

  void deleteTagFromDay(Event tag, DateTime date) {
    Map<DateTime, List<Event>> events = s.events.value;
    DateTime key = getDateKey(date);

    if (events.containsKey(key)) {
      events[key] = events[key]!.where((t) => t != tag).toList();

      s.events.value = events;
      s.selectedEvents.value = events[key]!;
      updateState(s);
    }
  }

  void addTagToDay(String tag, DateTime date) {
    Map<DateTime, List<Event>> events = s.events.value;

    setTag(tag);

    DateTime key = getDateKey(date);

    events[key] = (events[key] ?? []);
    events[key]!.add(Event(tag));

    s.events.value = events;
    s.selectedEvents.value = events[key]!;
    updateState(s);
  }

  DateTime getDateKey(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  List<Event> getSelectedEvents(DateTime date) {
    return s.events.value[getDateKey(date)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    DateTime _selectedDay = s.selectedDay.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TableCalendar(
              calendarFormat: CalendarFormat.week,
              onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
                if (s.selectedDay.value == selectedDay && s.selectedEvents.value.isNotEmpty) {
                  s.selectedEvents.value = [];
                } else {
                  s.selectedDay.value = selectedDay;
                  s.selectedEvents.value = getSelectedEvents(selectedDay);
                }

                updateState(s);
              },
              eventLoader: (day) {
                return getSelectedEvents(day);
              },
              firstDay: DateTime.now().subtract(const Duration(days: 180)),
              lastDay: DateTime.now().add(const Duration(days: 180)),
              focusedDay: s.selectedDay.value,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
            ),
            Expanded(
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: s.selectedEvents,
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
                        matches.addAll(s.tags.value.where((k) => k.contains(query)).toList());
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
