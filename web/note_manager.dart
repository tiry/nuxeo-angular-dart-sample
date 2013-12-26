import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'dart:convert'show JSON;
import 'package:nuxeo_automation/browser_client.dart' as nuxeo;

class NoteState {
  
  final String _value;
  
  const NoteState._internal(this._value);
  
  static const SYNC = const NoteState._internal("Synched");
  
  static const NEW = const NoteState._internal("New");
  
  static const DELETED = const NoteState._internal("Deleted");
  
  static const UPDATED = const NoteState._internal("Local Updated");  
  
}

class Note {
  
  String _title;
  String _description;
  String _content;
  String _uid;
  String _repository;
  int nbUpdates = 0;
  
  static const String _newPrefix = "NEW-";
  
  NoteState state = NoteState.SYNC;
  
  Note.empty() {
    _uid = _newPrefix + new Random().nextInt(1000).toString();
    _title = "New Note";
  }
  
  Note._internal(this._uid, this._title, this._description, this._content, this._repository);
  
  factory Note.fromDocument(nuxeo.Document doc) {
    return new Note._internal(doc.uid, doc.title, doc['dc:description'], doc['note:note'], doc.repository);
  }
  
  factory Note.fromMap(Map map) {
    return new Note._internal(map['uid'], map['title'], map['description'], map['content'], map['repository']);
  }
  
  String get uid {
    return _uid;
  }
  
  operator == (Note other) {
    if (other==null) {
      return false;
    }
    return other == null ? false : other.uid==_uid;  
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
  
  bool get isnew {
    return _uid.startsWith(_newPrefix);
  }
  
  void resetDirty() {
    nbUpdates=0;
  }
  
  Object get propertiesAsJson {
    return {"dc:title" : _title, "dc:description" : _description, "note:note" : _content};
  }
  
  String toString() {
    return '{ uid : $_uid, title : $_title}';
  }
}

class NoteManager {

  nuxeo.Client nxclient = null;  
  bool _online = true;
  
  NoteManager(this.nxclient);
  
  Future<List<Note>> getNotes() {
    if (_online) {
      return _getNotesFromServer();
    } else {
      List<Note> notes = _getNotesFromLocalStore();
      // fake future !
      Completer _completer = new Completer();
      _completer.complete(notes);
      return _completer.future;
    }
  }
  
  Future<List<Note>> _getNotesFromServer() {
    Completer _completer = new Completer();    
    nxclient.op("Document.PageProvider")(params : {'query' : "select * from Note order by dc:modified desc", 'pageSize' : 12}, documentSchemas : "dublincore,note")
    .then( (docs) => _completer.complete(_wrapNotes(docs)));    
    return _completer.future;
  }
  
  List<Note> _wrapNotes(nuxeo.Pageable<nuxeo.Document> docs) {
    List<Note> nlist = new List();
    List<Note> local_notes = _getNotesFromLocalStore();

    print("Local notes = $local_notes.toString()");
    // add newly created notes first
    for (Note lnote in local_notes) {
      if(lnote.isnew) {
        nlist.add(lnote);
      }
    }
    // now add the notes fetched from the server
    for (nuxeo.Document doc in docs) {
      Note note = new Note.fromDocument(doc);      
      // check if there is a local copy of the note
      for (Note lnote in local_notes) {
        if (lnote.uid == note.uid) {
          // keep the local copy
          note = lnote;
          break;
        }
      }      
      nlist.add(note);
    }    
    return nlist;
  }
  
  List<Note> _getNotesFromLocalStore() {
    List<Note> notes = new List();
    if (window.localStorage.containsKey('notes')) {      
      String json = window.localStorage['notes'];
      List list = JSON.decode(json);      
      for (Map ob in list) {
        Note note = new Note.fromMap(ob);
        if(ob.containsKey("updates") && ob["updates"]>0) {
          note.nbUpdates=ob["updates"];
        }
        notes.add(note);
      }      
    }
    return notes;
  }
  
  List<Note> newNote(List<Note> notes) {
    notes.insert(0, new Note.empty());
    return notes;
  }
  
  Map _toEncodable(Note note) {
    return { 'title' : note.title, 'description' : note.description, 'content' : note.content, 'uid' : note.uid, 'repository' : note.repository, 'updates' : note.nbUpdates};
  }

  void saveNotesInLocalStore(List<Note> notes) {   
    String json = JSON.encode(notes, toEncodable: _toEncodable);    
    window.localStorage['notes'] = json;
  }

  
  Future<String> saveNotes(List<Note> notes) {
    // safety first !
    saveNotesInLocalStore(notes);
    
    if (_online) {
      return _saveNotesOnServer(notes);
    } else {
      Completer _completer = new Completer();    
      _completer.complete("Saved in local storage");
      return _completer.future;
    }
  }

  void _updateSavedNote(List<Note> notes, Note tmp, nuxeo.Document newNote) {
    int idx = notes.indexOf(tmp);
    notes.remove(tmp);    
    notes.insert(idx, new Note.fromDocument(newNote));
    saveNotesInLocalStore(notes);
  }

  Future _saveNotesOnServer(List<Note> notes) {   
    List<Future> tasks = new List();
    for (Note note in notes) {
      Future res = _saveNoteOnServer(note, notes);
      if (res!=null) {
        tasks.add(res);
      }
    }
    
    Completer _completer = new Completer();    
    if (tasks.length>0) {
      int nbSaves = tasks.length;
      Future.wait(tasks).then((_) => _completer.complete("$nbSaves Notes created or updated on server"));
    } else {
      _completer.complete("Nothing to save");
    }
    return _completer.future;
  }

  Future _saveNoteOnServer(Note note, List<Note> notes) {
     if (note.dirty) {
       if (note.isnew) {
          return nxclient.op("UserWorkspace.Get")().then( (nuxeo.Document home)=> nxclient.op("Document.Create")(input:"doc:${home.uid}", params : {'type' : 'Note', 'name' : note.uid, 'properties' : note.propertiesAsJson}).then( (nuxeo.Document newNote) => _updateSavedNote(notes, note,newNote)));          
       } else {
          return nxclient.op("Document.Update")(input:"doc:${note.uid}", params : {'properties' : note.propertiesAsJson}).then( (_) => note.resetDirty());
       }
     }
     return null;
  }  
  
}
