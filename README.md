nuxeo-angular-dart-sample
=========================

A simple Angular Dart sample

## Goal

The goal of this sample is to play with Angular Dart and Nuxeo Automation Dart client.

## What it does

The goal is to build a simple note editor in Html.

## Feedback on Automation Dart Client API

### operation builder

From my undertsanding in the current Dart API, I would need to do : 

     nuxeo.op("opid", input : "yyyy", params : { p1: "v1"})


For the operation builder, I like the *"fluent like"* API we have in Java and JS

     nuxeo.op("opid").set("p1","v1").setInput("yyyy").execute()


### login

The login is exposed as a getter.

    nuxeo.login

Not sure I understand why.

I may be missing some Dart idiomatic stuff, but I would find it more logic to have a function(username, password).

### Document properties

Document properties are exposed via the `[]` operator.

This is great.

However, for some reasons, it does not seem to play well with the Angular bindings.

Let's says that `notectrl.selectedNote` returns we a `Document` 

     Object get selectedNote {
       if (_selectedNote==null) {
         return {};
       }
       return _selectedNote;
     }

the following expression should work : 

     {{notectrl.selectedNote['dc:description']}}


but it does not :( !

      Error: Attempted field access on a non-list, non-map while evaling [notectrl.selectedNote['dc:description']]

However, exposing a method in the controller :

      Object getCurrentNoteValue(String fieldXPath) {
         if (_selectedNote==null) {
           return "";
         }
         return _selectedNote[fieldXPath];
       }

and inside the template : 

     {{notectrl.getCurrentNoteValue('dc:description')}}

=> it does work ... 

May be we should provide also a simple getProperty API in addition of the `[]` operator ? 





