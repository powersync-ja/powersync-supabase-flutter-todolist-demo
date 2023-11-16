import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:powersync_flutter_demo/models/todo_item.dart';
import 'package:powersync_flutter_demo/models/todo_list.dart';

import './todo_list_page.dart';

final log = Logger('powersync-supabase');

class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List>(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data?[index].name),
                onTap: () {
                  close(context, null);
                },
              );
            },
            itemCount: snapshot.data?.length,
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    NavigatorState navigator = Navigator.of(context);

    return FutureBuilder<List>(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                // I ran into typing issues so needed to do a null check
                title: Text(snapshot.data?[index]['name'] ?? ''),
                onTap: () {
                  navigator.push(MaterialPageRoute(
                      builder: (context) => TodoListPage(
                          list: _convertToTodoList(snapshot.data![index]))));
                },
              );
            },
            itemCount: snapshot.data?.length,
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  TodoList _convertToTodoList(Map<String, dynamic> data) {
    return TodoList(id: data['id'], name: data['name']);
  }

  Future<List> _search() async {
    List listsSearchResults = await TodoList.search(query);
    List todoItemsSearchResults = await TodoItem.search(query);
    List formattedListResults = listsSearchResults
        .map((result) => {"id": result['id'], "name": result['name']})
        .toList();
    List formattedTodoItemsResults = todoItemsSearchResults
        .map((result) => {
              // Do this so the navigation goes to the list page
              "id": result['list_id'],
              "name": result['description'],
            })
        .toList();
    List formattedResults = [
      ...formattedListResults,
      ...formattedTodoItemsResults
    ];
    return formattedResults;
  }
}
