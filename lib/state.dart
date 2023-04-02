import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'event.dart';

final getIt = GetIt.instance;

class GlobalState {
  ValueNotifier<MainPage> mainPage = ValueNotifier(MainPage());
}
class MainPage {
  ValueNotifier<DateTime> selectedDay = ValueNotifier(DateTime.now());

  // the user created tags
  ValueNotifier<Set<String>> tags = ValueNotifier({});

  // the dates that each event has been added to
  ValueNotifier<Map<DateTime, List<Event>>> events = ValueNotifier({});

  // events for the selected day
  ValueNotifier<List<Event>> selectedEvents = ValueNotifier([]);

  MainPage clone() {
    MainPage newMainPage = MainPage();
    newMainPage.selectedDay = selectedDay;
    newMainPage.tags = tags;
    newMainPage.events = events;
    newMainPage.selectedEvents = selectedEvents;
    return newMainPage;
  }
}


void setupGlobalState() {
  getIt.registerSingleton<GlobalState>(GlobalState());
}