import 'dart:html';
import 'dart:async';
import 'dart:core';
import 'package:angular/angular.dart';
import 'package:nuxeo_automation/browser_client.dart' as nuxeo;
import 'package:perf_api/perf_api.dart';
import 'note_manager.dart';

@NgController(
    selector: '[nuxeo-notes]',
    publishAs: 'notectrl')
class NotesController {

  List<Note> _notes;
  nuxeo.Client nxclient = null;  
  Note _selectedNote;
  NoteManager noteManager;
  Timer _autoSaveTimer;
  Duration _autoSaveDuration = new Duration(minutes: 1);
  String localStatus;
  String serverStatus;  
  
  NotesController() {  
    nxclient = new nuxeo.Client(url: "http://127.0.0.1:8080/nuxeo");
    noteManager = new NoteManager(nxclient);
    nxclient.login
      .then((_) => noteManager.getNotes().then(_setNotes));    
  }

  String get baseUrl {
    return "http://127.0.0.1:8080/nuxeo";
  }
  
  bool get online {
    return true;
  }
  
  bool isActive(Note note) {
    if(note==null) {
      print("null note!!!");
    }
    if (_selectedNote!=null && note!=null) {
      return _selectedNote.uid==note.uid;
    }
    false;
  }
  
  void saveAll() {  
    Future<String> status = noteManager.saveNotes(notes);
    status.then((status) => serverStatus = status + " " + new DateTime.now().toString());
  }
       
  void _setNotes(List<Note> docs) {
    _notes = docs;
    _selectedNote = docs.first;
    _autoSaveTimer = new Timer.periodic(_autoSaveDuration,_autoSave);    
  }
  
  void _autoSave(_) {
    noteManager.saveNotesInLocalStore(notes);    
    localStatus = "draft saved at " + new DateTime.now().toString();
  }
  
  List<Note> get notes {
    return _notes;
  }
  
  void selectNote(Note note) {
    _selectedNote = note;
  }  
  
  
  Object getCurrentNote() {
    if (_selectedNote==null) {
      return {};
    }
    return _selectedNote;    
  }
    
  Object get selectedNote {
    if (_selectedNote==null) {
      return {};
    }
    return _selectedNote;
  }
    
  void newNote() {
    noteManager.newNote(_notes);
    _selectedNote = _notes.first;    
  }
  
}

class NuxeoAppModule extends Module {
  NuxeoAppModule() {
    type(NotesController);
    type(Profiler, implementedBy: Profiler); // comment out to enable profiling
  }
}

void main() {
  ngBootstrap(module: new NuxeoAppModule());
}


