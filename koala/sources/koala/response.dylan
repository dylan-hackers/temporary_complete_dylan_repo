Module:    httpi
Author:    Carl Gay
Synopsis:  An API for generating responses to HTTP requests.
Copyright: Copyright (c) 2001-2002 Carl L. Gay.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND


// Exported
//
// If you add a slot to this class you may need to reset that slot to
// its initial value in the reinitialize-resource method below.
//
define open primary class <response> (<object>)
  slot get-request :: <request>, required-init-keyword: #"request";

  // The output stream is created lazily so that the user has the opportunity to
  // set properties such as stream type (e.g., binary or text) and buffering
  // characteristics.
  // @see output-stream
  slot %output-stream :: false-or(<stream>) = #f;

  // Headers to send with the response.
  // @see add-header
  slot response-headers :: <header-table>, required-init-keyword: #"headers";

  // Whether or not the headers were allocated with allocate-resource, in which
  // case they need to be deallocated with deallocate-resource.
  slot headers-resourced? :: <boolean> = #f, init-keyword: #"headers-resourced?";
  slot headers-sent? :: <boolean> = #f;

  // Whether or not this is a buffered response.
  // @see output-stream
  slot buffered? :: <boolean> = #t;
end;

define method initialize
    (response :: <response>, #key, #all-keys)
  next-method();
  when (*generate-server-header*)
    add-header(response, "Server", $server-header-value);
  end;
end;

// Exported
//
define method add-header
    (response :: <response>, header :: <string>, value :: <object>, #key if-exists? = #"append")
  if (headers-sent?(response))
    throw(<koala-api-error>,
          "Attempt to add a %s header after headers have already been sent.",
          header);
  elseif (string-equal?(header, "content-type"))
    set-content-type(response, value)
  else
    add-header(response.response-headers, header, value, if-exists?: if-exists?)
  end;
end;

// Exported
//
// ---TODO: The first time the output stream is requested, check the content
//          type and create the appropriate type of stream.
define method output-stream
    (response :: <response>) => (stream :: <stream>)
  response.%output-stream
  | begin
      // The user can override this if they do it before writing to the
      // output stream.
      set-content-type(response, *default-dynamic-content-type*, if-exists?: #"ignore");
      response.%output-stream := allocate-resource(<string-stream>);
    end
end;

// Exported
//
define method clear-output
    (response :: <response>) => ()
  let out = response.%output-stream;
  out & stream-contents(out, clear-contents?: #t)
end;

// Exported
//
define method set-content-type
    (response :: <response>, content-type :: <object>, #key if-exists? = #"replace")
  let out = response.%output-stream;
  if (out & stream-size(out) ~= 0)
    throw(<koala-api-error>,
          "Attempt to set the Content-Type header after reply has begun to be sent.");
  else
    add-header(response.response-headers, "Content-Type", content-type, if-exists?: if-exists?);
  end;
end;


// Implements part of the resource protocol.
//
define method new-resource
    (resource-class == <response>,
     #rest initargs,
     #key request :: <request>, headers :: false-or(<header-table>))
 => (response :: <response>)
  make(<response>,
       request: request,
       headers: headers | allocate-resource(<header-table>),
       headers-resourced?: ~headers);
end;
  

// Implements part of the resource protocol.
//
define method reinitialize-resource
    (response :: <response>,
     #rest init-args,
     #key request :: <request>, headers)
  get-request(response) := request;
  response-headers(response) := (headers | allocate-resource(<header-table>));
  headers-resourced?(response) := ~headers;
  // Note some reinitialization is done in the resource-deallocated method below.
end;

// Implements part of the resource protocol.
//
define method resource-deallocated
    (response :: <response>)
  let stream = %output-stream(response);
  when (stream)
    deallocate-resource(<string-stream>, stream);
    response.%output-stream := #f;
    response.headers-sent? := #f;
    iff (response.headers-resourced?,
         deallocate-resource(<header-table>, response.response-headers));
  end;
  next-method();
end;

// Implements part of the resource protocol.
//
define method resource-size
    (response :: <response>) => (size :: <integer>)
  let stream = response.%output-stream;
  iff (stream,
       stream-size(stream),
       0)
end;

// The caller is telling us that either the request is complete or it's OK to
// send a partial response.  Send the header lines, whatever part of the body
// has been generated so far, and then clear the output stream.
//---*** Not sure this is legal HTTP.
//define method force-output
//    (response :: <response>) => ()
//  send-response(response);
//end;

define method send-header
    (stream :: <stream>, name :: <string>, val :: <pair>)
  for (v in val)
    send-header(stream, name, v)
  end;
end;

define method send-header
    (stream :: <stream>, name :: <string>, val :: <object>)
  format(stream, "%s: %s\r\n", name, val);
  log-copious("-->%s: %s", name, val);
end;

define method send-headers
    (response :: <response>, stream :: <stream>)
  // Send the headers
  let headers :: <header-table> = response-headers(response);
  for (val keyed-by name in headers)
    send-header(stream, name, val);
  end;
  write(stream, "\r\n");  // blank line separates headers from body
  headers-sent?(response) := #t;
end;

define method send-response
    (response :: <response>, #key response-code = 200, response-message) => ()
  let stream :: <stream> = request-socket(get-request(response));
  unless (headers-sent?(response))
    // Send the response line
    let response-line
      = format-to-string("%s %d %s\r\n",
                         $http-version, response-code, response-message | "OK");
    log-copious("-->%s", response-line);
    write(stream, response-line);

    add-header(response, "Date", as-rfc-1123-date(current-date()));

    let content-length :: <string> = integer-to-string(stream-size(output-stream(response)));
    // Add required headers
    add-header(response, "Content-Length", content-length);
    send-headers(response, stream);

    if (*logfile*)
      // Log in Common Logfile Format
      // (http://www.w3.org/Daemon/User/Config/Logging.html)
      let req :: <request> = get-request(response);
      let request = concatenate(as(<string>, request-method(req)), " ",
                                request-url(req), " ",
                                as(<string>, request-version(req)));
      let date = as-common-logfile-date(current-date());
      let remoteaddr = host-address(remote-host(request-socket(req)));
      log-logfile(*logfile*, concatenate(remoteaddr, " ",
                                         "-", " ",
                                         "-", " ",
                                         "[", date, "] ",
                                         "\"", request, "\" ",
                                         integer-to-string(response-code), " ",
                                         content-length, "\n"));
    end if;
  end unless;

  // Send the body (or what there is of it so far).
  let contents = stream-contents(output-stream(response), clear-contents?: #t);
  write(stream, contents);

end;

// Exported
// Convenience.  Seems common to want to add a numeric cookie value.
//
define method add-cookie
    (response :: <response>, name :: <string>, value :: <integer>, #rest args,
     #key max-age, path, domain, comment)
  apply(add-cookie, response, name, integer-to-string(value), args)
end;

// Exported
// This isn't the right way to handle cookies, but it's simple for now.
// ---TODO: Verify that comment is a TOKEN or QUOTED-STRING, and that other values are TOKENs.
//          See RFC 2109.
//
define method add-cookie
    (response :: <response>, name :: <string>, value :: <string>,
     #key max-age, path, domain, comment)
  add-header(response, "Set-cookie",
             with-output-to-string (s)
               format(s, "%s=%s; Version=%s", name, value, $default-cookie-version);
               max-age & format(s, "; Max-age=%s", max-age);
               path    & format(s, "; Path=%s", path);
               domain  & format(s, "; Domain=%s", domain);
               comment & format(s, "; Comment=\"%s\"", comment);
             end);
end;
