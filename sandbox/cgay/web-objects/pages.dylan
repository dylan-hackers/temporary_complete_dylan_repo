Module: dsp
Author: Carl Gay
Synopsis: Link web pages to <database-record>s

// When displaying a page that corresponds to a specific record, such as
// edit-account.dsp, this is bound to the record.
//
define thread variable *record* :: false-or(<database-record>) = #f;

// Key used to store the record that is currently being edited in the session.
//
define constant $edit-record-key = #"dsp.edit-record";

define function get-edit-record
    (request :: <request>) => (record :: false-or(<database-record>))
  get-attribute(get-session(request), $edit-record-key)
end;


// Not clear what the purpose of this class is yet, but it seemed
// appropriate to have a layer between <dylan-server-page> and <edit-record-page>.
//
define primary class <record-page> (<dylan-server-page>)
end;

// Any page that is for editing a database record should inherit from this.
//
define open primary class <edit-record-page> (<record-page>)
end;

// Thrown when a field in a web form fails to validate.
//
define class <invalid-form-field-exception> (<dsp-error>)
end;

// This method is called under two different circumstances:
// (1) As the result of the user clicking a link of the form
//     <a href="edit-account.dsp&id=n">, in which case there is an 'id'
//     query parameter, or
// (2) As the result of a successful login.
// Therefore, if there is an 'id' query parameter it is used to find the
// record to edit.  If the user isn't logged in then that record is stored
// in the session and is redirected to the login page.  If there is no 'id'
// query parameter, the record to edit is already in the session.
//
define method respond-to-get (page :: <edit-record-page>)
  let session = get-session(current-request());
  let record-id = get-query-value("id");
  let record-type = get-query-value("type");
  let record = select (record-id by \=)
                 "new" =>     // new record being created
                   let record-class = record-class-from-type-name(record-type);
                   initialize-record(make(record-class, id: next-record-id()));
                 #f =>        // no record id means record is in session.
                   get-attribute(session, $edit-record-key);
                 otherwise =>
                   let record-class = record-class-from-type-name(record-type);
                   load-record(record-class, as(<integer>, record-id));
               end;
  // TODO: this call to application-error doesn't work because it doesn't
  //       accept any keyword arguments.
  record
    | application-error(format-string: "No record was found for editing.  Record id = %=, type = %=",
                        format-arguments: list(record-id, record-type));
  set-attribute(session, $edit-record-key, record);
  dynamic-bind (*record* = record)
    respond-to-get-edit-record(page,
                               current-request(),
                               current-response(),
                               record);
  end;
end method respond-to-get;

define open generic respond-to-get-edit-record
    (page :: <object>,
     request :: <request>,
     response :: <response>,
     record :: <database-record>);

define method respond-to-get-edit-record (page :: <edit-record-page>,
                                          request :: <request>,
                                          response :: <response>,
                                          record :: <database-record>)
  process-template(page);
end;

define open generic respond-to-post-edit-record
    (page :: <object>,
     request :: <request>,
     response :: <response>,
     record :: <database-record>);

define method respond-to-post-edit-record (page :: <edit-record-page>,
                                           request :: <request>,
                                           response :: <response>,
                                           record :: <database-record>)
  // default does nothing
end;

// Client libraries should set this to some page that users can return to
// if the origin page can't be found.  Normally the home page is a good choice.
//
define variable *default-origin-page* :: false-or(<page>) = #f;

define function return-to-origin
    (request :: <request>, response :: <response>,
     #key default = *default-origin-page*)
  bind (origin = get-query-value("origin"),
        // It may be common to forget to use a leading / since it's not required...
        page = origin & (url-to-page(origin) | url-to-page(concatenate("/", origin))))
    respond-to-get(page | default);
  end;
end;

define method respond-to-post (page :: <edit-record-page>)
  let request :: <request> = current-request();
  let record :: <database-record> = get-edit-record(request);
  let slots = slot-descriptors(object-class(record));
  let bindings = make(<string-table>); // maps form input name to parsed value
  let field-name = #f;
  let field-value = #f;
  block ()
    // Update the record with values from the page.
    for (slot in slots)
      field-name := slot-column-name(slot);
      field-value := get-query-value(field-name, as: slot-type(slot));
      if (field-value)
        validate-record-field(page, record, slot, field-value);
        let f = slot-setter(slot);
        // ---TODO: determine whether any slots changed.  If not, no need to save the record.
        if (f)
          log-debug("record posted: Setting %= to %=", field-name, field-value);
          f(field-value, record);
        else
          log-debug("record posted: No setter found for %=.  Value was %=.", field-name, field-value);
        end;
      else
        /* ---TODO
        if (slot-required?(slot))
          throw(<missing-required-field>, name: field-name)
        end;
        */
      end;
    end;
    let response :: <response> = current-response();
    dynamic-bind (*record* = record)
      respond-to-post-edit-record(page, request, response, record);
    end;
    save-record(record);
    // ---TODO: capitalize the pretty name.  add methods for capitalizing
    //          strings to the strings library.
    note-form-message("%s updated.", record-pretty-name(record));
    remove-attribute(get-session(request), $edit-record-key);     // clean up session
    return-to-origin(request, response);
  exception (err :: <invalid-form-field-exception>)
    note-form-error("Error while processing the %= field.  %=",
                    field-name, err);
    next-method();
  end;
end;

define tag show-id in dsp
    (page :: <dylan-server-page>)
    (key)
  let record = select (key by \=)
                 "row"     => current-row();
                 "record"  => *record*;
                 otherwise => current-row() | *record*;
               end;
  format(output-stream(current-response()), "%s", record-id(record));
end;

define tag show-hidden-fields in dsp
    (page :: <dylan-server-page>)
    ()
  display-hidden-fields(page, output-stream(current-response()));
end;

// Methods on display-hidden-fields can call this.
//
define function display-hidden-field
    (stream :: <stream>, name :: <string>, value :: <object>)
  format(stream, "<input type='hidden' name='%s' value='%s'>", name, value);
end;

// Pass along the 'origin' query value.
//
define method display-hidden-fields
    (page :: <dylan-server-page>, stream :: <stream>)
  bind (origin = get-query-value("origin"))
    iff(origin,
        display-hidden-field(stream, "origin", origin));
  end;
end;


// Called to validate each input field in an <edit-record-page> HTML form.
// Methods should throw <invalid-form-field-exception> (usually by calling
// note-field-error) if the input is invalid.
//
define open generic validate-record-field
    (page :: <edit-record-page>,
     record :: <database-record>,
     slot :: <slot-descriptor>,
     value :: <object>);

define method validate-record-field (page :: <edit-record-page>,
                                     record :: <database-record>,
                                     slot :: <slot-descriptor>,
                                     input :: <object>)
  // do nothing
end;


// ---TODO:
// Eventually these should be distinguished from other form errors so that
// they can be displayed differently.  e.g., by highlighting the cell containing
// the input field that got an error.
//
define method note-field-error
    (field-name :: <string>, msg :: <string>, #rest args)
  apply(note-form-error, concatenate(field-name, ": ", msg), args);

  // ---TODO: This shouldn't really signal an error since eventually it should
  //          validate all form fields and report all problems at once.
  signal(make(<invalid-form-field-exception>,
              format-string: "Invalid form field."));
end;

