import 'dart:html';
import 'dart:async';
import 'package:nuxeo_automation/browser_client.dart' as nuxeo;

class Note {
  
  String _title;
  String _description;
  String _content;
  String _uid;
  String _repository;
  int nbUpdates = 0;
  
  Note._internal(this._uid, this._title, this._description, this._content, this._repository);
  
  factory Note.fromDocument(nuxeo.Document doc) {
    return new Note._internal(doc.uid, doc.title, doc['dc:description'], doc['note:note'], doc.repository);
  }
  
  String get uid {
    return _uid;
  }
   
  String get title {
    return _title;
  }
  
  String get description {
    return _description;
  }
  
  String get content {
    return _content;
  }
  
  void set title(String value) {
    nbUpdates++;
    _title = value;
  }
  
  void set description(String value) {
    nbUpdates++;
    _description = value;
  }
  
  void set content(String value) {
    nbUpdates++; 
    _content = value;
  }
  
  String get repository {
    return _repository;
  }
  
  bool get dirty {
    return nbUpdates>0;
  }
  
  void resetDirty() {
    nbUpdates=0;
  }
  
  Object get propertiesAsJson {
    return {"dc:title" : _title, "dc:description" : _description, "note:note" : _content};
  }
  
}

class NoteManager {

  nuxeo.Client nxclient = null;  
  bool _online = true;
  
  NoteManager(this.nxclient);
  
  Future<List<Note>> getNotes() {
    if (_online) {
      return _getOnLineNotes();
    } else {
      return _getOffLineNotes();
    }
  }
  
  Future<List<Note>> _getOnLineNotes() {
    Completer _completer = new Completer();    
    nxclient.op("Document.PageProvider")(params : {'query' : "select * from Note order by dc:modified desc", 'pageSize' : 12}, documentSchemas : "dublincore,note")
    .then( (docs) => _completer.complete(_wrapNotes(docs)));    
    return _completer.future;
  }
  
  List<Note> _wrapNotes(nuxeo.Pageable<nuxeo.Document> docs) {
    List<Note> nlist = new List();
    for (nuxeo.Document doc in docs) {
      Note note = new Note.fromDocument(doc);
      nlist.add(note);
    }
    return nlist;
  }
  
  Future<List<Note>> _getOffLineNotes() {
    return null;
  }
  
  void _saveNotesForOffline(List<Note> notes) {
   //
  }

  void saveNotes(List<Note> notes) {
    for (Note note in notes) {
      saveNote(note);
    }
  }

  void saveNote(Note note) {
     if (note.dirty) {
       nxclient.op("Document.Update")(input:"doc:${note.uid}", params : {'properties' : note.propertiesAsJson}).then( (_) => note.resetDirty());
     }
  }
  
}
