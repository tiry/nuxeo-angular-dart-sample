import 'dart:html';
import 'package:angular/angular.dart';
import 'package:nuxeo_automation/browser_client.dart' as nuxeo;
import 'package:perf_api/perf_api.dart';
//import 'package:nuxeo_automation/nuxeo_client.dart'; 

@NgController(
    selector: '[nuxeo-notes]',
    publishAs: 'notectrl')
class NotesController {

  nuxeo.Pageable<nuxeo.Document> _notes;  
  nuxeo.Client nxclient = null;  
  nuxeo.Document _selectedNote;
  
  NotesController() {  
    nxclient = new nuxeo.Client(url: "http://127.0.0.1:8080/nuxeo");    
    nxclient.login
      .then((_) => fetchNotes());    
  }

  String get baseUrl {
    return "http://127.0.0.1:8080/nuxeo";
  }
  
  void fetchNotes() {
    print("fetching notes !");
    nxclient.op("Document.PageProvider")(params : {'query' : "select * from Note order by dc:modified desc", 'pageSize' : 20}, documentSchemas : "dublincore,note")
    .then(setNotes);
    //.then( (docs)=> _notes = docs);
  }

  void setNotes(nuxeo.Pageable<nuxeo.Document> docs) {
    _notes = docs;
    _selectedNote = docs.first;
  }
  
  nuxeo.Pageable<nuxeo.Document> get notes {
    return _notes;
  }

  void selectNote(nuxeo.Document note) {
    _selectedNote = note;
  }  
  
  Object getCurrentNote() {
    if (_selectedNote==null) {
      return {};
    }
    return _selectedNote;    
  }
  
  Object getCurrentNoteValue(String fieldXPath) {
    if (_selectedNote==null) {
      return "";
    }
    return _selectedNote[fieldXPath];
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


