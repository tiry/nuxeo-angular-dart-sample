import 'dart:html';
import 'package:angular/angular.dart';
import 'package:nuxeo_automation/browser_client.dart' as nuxeo;
import 'package:perf_api/perf_api.dart';
import 'note_manager.dart';
//import 'package:nuxeo_automation/nuxeo_client.dart'; 

@NgController(
    selector: '[nuxeo-notes]',
    publishAs: 'notectrl')
class NotesController {

  List<Note> _notes;
  nuxeo.Client nxclient = null;  
  Note _selectedNote;
  NoteManager noteManager;
  
  NotesController() {  
    nxclient = new nuxeo.Client(url: "http://127.0.0.1:8080/nuxeo");
    noteManager = new NoteManager(nxclient);
    nxclient.login
      .then((_) => noteManager.getNotes().then(_setNotes));    
  }

  String get baseUrl {
    return "http://127.0.0.1:8080/nuxeo";
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

  void saveCurrentNote() {  
    if (_selectedNote==null) {
      return;
    }
    noteManager.saveNote(_selectedNote);
  }
  
  void _setNotes(List<Note> docs) {
    _notes = docs;
    _selectedNote = docs.first;
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


