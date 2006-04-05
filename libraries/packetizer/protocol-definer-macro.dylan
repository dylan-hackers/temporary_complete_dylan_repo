module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.


define macro real-class-definer
  { real-class-definer(?:name; ?superclasses:*; ?fields-aux:*) }
 => { define abstract class ?name (?superclasses)
      end;
      define inline method frame-name (frame :: ?name) => (res :: <string>)
        ?"name"
      end;
      define inline method fields (frame :: ?name) => (res :: <simple-vector>)
          "$" ## ?name ## "-fields"
      end;
      define method fields-initializer
          (frame :: subclass(?name), #next next-method) => (frame-fields :: <simple-vector>)
        let res = concatenate(next-method(), vector(?fields-aux));
        for (ele in res,
             i from 0)
          ele.index := i;
        end;
        res;
      end;
      define constant "$" ## ?name ## "-fields" = fields-initializer(?name);
      begin
        compute-static-offset("$" ## ?name ## "-fields");
        if (element($protocols, ?#"name", default: #f))
          error("Protocol with same name already exists");
        else
          $protocols[?#"name"] := "$" ## ?name ## "-fields";
        end;
      end;
      define inline method field-size (frame :: subclass(?name)) => (res :: <number>)
        static-end(last("$" ## ?name ## "-fields"));
      end;
      define method make (class == ?name, #rest rest, #key, #all-keys) => (res :: ?name)
        let frame = apply(make, cache-class(?name), rest);
        for (field in fields(frame))
          if (field.getter(frame) = #f)
            field.setter(field.init-value, frame);
          end;
        end;
        frame;
      end;
    }

  fields-aux:
   { } => { }
   { field ?:name \:: ?field-type:name; ... }
     => { make(<single-field>,
               name: ?#"name",
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter"), ... }
   { field ?:name \:: ?field-type:name, ?args:*; ... }
     => { make(<single-field>,
               name: ?#"name",
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { variably-typed-field ?:name, ?args:*; ... }
     => { make(<variably-typed-field>,
               name: ?#"name",
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { repeated field ?:name \:: ?field-type:name, ?args:*; ... }
     => { make(<repeated-field>,
               name: ?#"name",
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { field ?:name \:: ?field-type:name = ?init:expression ; ... }
     => { make(<single-field>,
               name: ?#"name",
               init-value: ?init,
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter"), ... }
   { field ?:name \:: ?field-type:name = ?init:expression , ?args:*; ... }
     => { make(<single-field>,
               name: ?#"name",
               init-value: ?init,
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { variably-typed-field ?:name = ?init:expression , ?args:*; ... }
     => { make(<variably-typed-field>,
               name: ?#"name",
               init-value: ?init,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { repeated field ?:name \:: ?field-type:name = ?init:expression, ?args:*; ... }
     => { make(<repeated-field>,
               name: ?#"name",
               init-value: ?init,
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }

  args: //FIXME: better types, not <frame>!
    { } => { }
    { start: ?start:expression, ... }
      => { dynamic-start: method(?=frame :: <frame>) ?start end, ... }
    { end: ?end:expression, ... }
      => { dynamic-end: method(?=frame :: <frame>) ?end end, ... }
    { length: ?length:expression, ... }
      => { dynamic-length: method(?=frame :: <frame>) ?length end, ... }
    { count: ?count:expression, ... }
      => { count: method(?=frame :: <frame>) ?count end, ... }
    { type-function: ?type:expression, ... }
      => { type-function: method(?=frame :: <frame>) ?type end, ... }
    { reached-end?: ?reached:expression, ... }
      => { reached-end?: ?reached, ... }
    { fixup: ?fixup:expression, ... }
      => { fixup: method(?=frame :: <frame>) ?fixup end, ... }
    { static-start: ?start:expression, ... }
      => { static-start: ?start, ... }
    { static-length: ?length:expression, ... }
      => { static-length: ?length, ... }
    { static-end: ?end:expression, ... }
      => { static-end: ?end, ... }
end;


define macro cache-class-definer
    { cache-class-definer(?:name; ?superclasses:*; ?fields:*) } 
    => { define class ?name (?superclasses) ?fields end }
    
    fields:
    { } => { }
    { ?field:*; ... } => { ?field ; ... }
    
    field:
    { field ?:name \:: ?field-type:name ?rest:* }
      => { slot ?name :: false-or(high-level-type(?field-type)) = #f, init-keyword: ?#"name" }
    { variably-typed-field ?:name, ?rest:* }
      => { slot ?name :: false-or(<frame>) = #f, init-keyword: ?#"name" }
    { repeated field ?:name ?rest:* }
      => { slot ?name :: false-or(<stretchy-vector>) = #f, init-keyword: ?#"name" }
    
end;

define macro decoded-class-definer
    { decoded-class-definer(?:name; ?superclasses:*; ?fields:*) }
      => { define class ?name (?superclasses) ?fields end }

    fields:
    { } => { }
    { ?field:*; ... } => { ?field ; ... }
    
    field:
    { field ?:name \:: ?field-type:name ?rest:* }
    => { slot ?name :: high-level-type(?field-type),
      required-init-keyword: ?#"name" }
    { variably-typed-field ?:name, ?rest:* }
    => { slot ?name :: <frame>,
      required-init-keyword: ?#"name" }
    { repeated field ?:name ?rest:* }
      => { slot ?name :: <stretchy-vector>,
      required-init-keyword: ?#"name" }
end;

define macro gen-classes
  { gen-classes(?:name; ?superframe:name) }
 => { define inline method cache-class
       (type :: subclass("<" ## ?name ## ">")) => (class == "<" ## ?name ## "-cache>");
        "<" ## ?name ## "-cache>"
      end;

      define inline method unparsed-class
       (type :: subclass("<" ## ?name ## ">")) => (class == "<unparsed-" ## ?name ## ">");
        "<unparsed-" ## ?name ## ">"
      end;

      define inline method decoded-class
       (type :: subclass("<" ## ?name ## ">")) => (class == "<decoded-" ## ?name ## ">");
        "<decoded-" ## ?name ## ">"
      end;

      define class "<unparsed-" ## ?name ## ">" ("<" ## ?name ## ">", "<unparsed-" ## ?superframe ## ">")
        inherited slot cache :: "<" ## ?name ## ">" = make("<" ## ?name ## "-cache>");
      end; }
end;

define macro unparsed-frame-field-generator
  { unparsed-frame-field-generator(?:name,
                                   ?frame-type:name,
                                   ?field-index:expression) }
 => { define inline method ?name (mframe :: ?frame-type)
         if (mframe.cache.?name)
           mframe.cache.?name
         else
          let field = fields(mframe)[?field-index];
          mframe.cache.?name := parse-frame-field(field, mframe).frame;
          mframe.cache.?name
        end;
      end;
      define sealed domain ?name (?frame-type); }
end;

define method parse-frame-field
   (field :: <field>, frame :: <unparsed-container-frame>)
 => (frame-field :: <frame-field>);
 let full-frame-size = frame.packet.size * 8;
 let start
   = if (field.static-start = $unknown-at-compile-time)
       if (field.dynamic-start)
         field.dynamic-start(frame)
       else
         //ugh, we need to get end of the predecessor frame
         if (field.index = 0)
           error("first field doesn't know where it starts");
         end;
         let predecessor-index = field.index - 1;
         end-offset(get-frame-field(predecessor-index, frame));
       end;
     else
       //hey, we can just parse it :)
       if (field.dynamic-start)
         error("found a gap: in %s knew start offset statically (%d), but got a dynamic offset (%d)\n",
               field.field-name, field.static-start, field.dynamic-start(frame))
       end;
       field.static-start;
     end;
  let end-of-field
    = if (field.static-length = $unknown-at-compile-time)
        if (field.dynamic-length)
          //dynamic :)
          start + field.dynamic-length(frame);
        else
          //damn, we need to get end dynamically 
          if (field.dynamic-end)
            field.dynamic-end(frame);
          else
            if (field.index = field-count(frame.object-class) - 1)
              //last field, just return the end...
              full-frame-size;
            else
              let successor-field = frame.fields[field.index + 1];
              if (successor-field.dynamic-start)
                //should we generate a half-done frame-field here?
                //somehow, we should cache the result...
                successor-field.dynamic-start(frame)
              else
                //maybe we should try to find length of remaining fixed-size fields?
                format-out("Not able to find end of field %s\n", field.field-name);
                full-frame-size;
              end;
            end
          end;
        end;
      else
        //hey, we have a static length :)
        if (field.dynamic-length)
          error("found a gap: in %s knew length statically (%d), but got a dynamic length (%d)\n",
                field.field-name, field.static-length, field.dynamic-length(frame));
        end;
        if (field.dynamic-end)
          error("found a gap: in %s knew end offset statically (%d), but got a dynamic end (%d)\n",
                field.field-name, field.static-end, field.dynamic-end(frame));
        end;
        start + field.static-length;
      end;
  if (end-of-field > full-frame-size)
    format-out("Wanted to read beyond frame, field %s start %d end %d frame-size %d\n",
               field.field-name, start, end-of-field, full-frame-size);
    end-of-field := full-frame-size;
  end;
  let (subframe, length)
    = parse-frame-field-aux(field,
                            frame,
                            bit-offset(start),
                            subsequence(frame.packet,
                                        start: byte-offset(start),
                                        end: byte-offset(end-of-field + 7)));
  if (length)
    let real-end = length - bit-offset(start) + start;
    unless (real-end = end-of-field)
      if (real-end < end-of-field)
        format-out("estimated end in %s at %d (%d bytes), but parser was ready after %d (%d bytes)\n",
                   field.field-name, end-of-field, byte-offset(end-of-field), real-end, byte-offset(real-end));
        //padding? only if end-of-field ~= end-of-frame!?
        end-of-field := real-end;
      else
        error("This shouldn't happen... in %s, start %d end %d (%d bits), used %d\n",
            field.field-name, start, end-of-field, end-of-field - start, length - bit-offset(start));
      end;
    end;
  elseif ((~ length) & (field.index + 1 ~= field-count(frame.object-class)))
    end-of-field := end-offset(get-frame-field(field-count(subframe.object-class) - 1, subframe));
  end;
  let frame-field = make(<frame-field>,
                         start: start,
                         end: end-of-field,
                         length: end-of-field - start,
                         frame: subframe,
                         field: field);
  frame.concrete-frame-fields[field.field-name] := frame-field;
  frame.concrete-frame-fields[field.index] := frame-field;
  frame-field;
end;

define method parse-frame-field-aux
 (field :: <single-field>,
  frame :: <unparsed-container-frame>,
  start :: <integer>,
  packet :: <byte-sequence>)
 maybe-parse-frame(field.type, packet, start, frame);
end;
define method parse-frame-field-aux
  (field :: <variably-typed-field>,
   frame :: <unparsed-container-frame>,
   start :: <integer>,
   packet :: <byte-sequence>)
  let type = field.type-function(frame);
  maybe-parse-frame(type, packet, start, frame);
end;

define method parse-frame-field-aux
  (field :: <self-delimited-repeated-field>,
   frame :: <unparsed-container-frame>,
   start :: <integer>,
   packet :: <byte-sequence>)
  let frames = make(<stretchy-vector>);
  let start = start;
  if (packet.size > 0)
    let (value, offset)
      = maybe-parse-frame(field.type,
                          subsequence(packet,
                                      start: byte-offset(start)),
                          bit-offset(start),
                          frame);
    unless (offset)
        let last-child-field = value.fields.last;
        offset := end-offset(get-frame-field(last-child-field.field-name, value));
    end;
    frames := add!(frames, value);
    start := byte-offset(start) * 8 + offset;
    while ((~ field.reached-end?(frames.last)) & (byte-offset(start) < packet.size))
      let (value, offset)
        = maybe-parse-frame(field.type,
                            subsequence(packet,
                                        start: byte-offset(start)),
                            bit-offset(start),
                            frame);
      unless (offset)
        let last-child-field = value.fields.last;
        offset := end-offset(get-frame-field(last-child-field.field-name, value));
      end;
      frames := add!(frames, value);
      start :=  byte-offset(start) * 8 + offset;
    end;
  end;
  values(frames, start);
end;
define method parse-frame-field-aux
  (field :: <count-repeated-field>,
   frame :: <unparsed-container-frame>,
   start :: <integer>,
   packet :: <byte-sequence>)
  let frames = make(<stretchy-vector>);
  let start = start;
  if (packet.size > 0)
    for (i from 0 below field.count(frame))
      let (value, offset)
        = maybe-parse-frame(field.type,
                            subsequence(packet,
                                        start: byte-offset(start)),
                            bit-offset(start),
                            frame);
      unless (offset)
        let last-child-field = value.fields.last;
        offset := end-offset(get-frame-field(last-child-field.field-name, value));
      end;
      frames := add!(frames, value);
      start := byte-offset(start) * 8 + offset;
    end;
  end;
  values(frames, start);
end;

define inline method maybe-parse-frame (frame-type :: subclass(<frame>),
                                        packet :: <byte-vector>,
                                        start :: <integer>,
                                        parent :: false-or(<container-frame>))
  maybe-parse-frame(frame-type, subsequence(packet), start, parent);
end;

define method parse-frame (frame-type :: subclass(<container-frame>),
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0,
                           parent :: false-or(<container-frame>) = #f)
  byte-aligned(start);
  let frame = make(unparsed-class(frame-type),
                   packet: packet,
                   parent: parent);
  let length = field-size(frame-type);
  if (length = $unknown-at-compile-time)
    frame;
  else
    values(frame, length)
  end;
end;
define inline method maybe-parse-frame (frame-type :: subclass(<frame>),
                                        packet :: <byte-sequence>,
                                        start :: <integer>,
                                        parent :: false-or(<container-frame>))
  parse-frame(frame-type, packet, start: start, parent: parent);
end;


define macro frame-field-generator
    { frame-field-generator(?type:name; ?count:expression; field ?field-name:name ?foo:*  ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?count);
         frame-field-generator(?type; ?count + 1; ?rest) }
    { frame-field-generator(?type:name; ?count:expression; variably-typed-field ?field-name:name ?foo:* ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?count);
         frame-field-generator(?type; ?count + 1; ?rest) }
    { frame-field-generator(?type:name; ?count:expression; repeated field ?field-name:name ?foo:* ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?count);
         frame-field-generator(?type; ?count + 1; ?rest) }
    { frame-field-generator(?:name; ?count:expression) }
    => { define inline method field-count (type :: subclass(?name)) => (res :: <integer>) ?count end; }
end;

define macro summary-generator
    { summary-generator(?type:name; ?summary-string:expression, ?summary-getters:*) }
    => { define method summary (frame :: ?type) => (result :: <string>);
           apply(format-to-string,
                 ?summary-string, 
                 map(method(x) frame.x end,
                     list(?summary-getters)));
         end; }
end;

define macro protocol-definer
    { define protocol ?:name (?superprotocol:name)
        summary ?summary:* ;
        ?fields:*
      end } =>
      { summary-generator("<" ## ?name ## ">"; ?summary);
        define protocol ?name (?superprotocol) ?fields end; }

    { define protocol ?:name (?superprotocol:name)
        ?fields:*
      end } =>
      { real-class-definer("<" ## ?name ## ">"; "<" ## ?superprotocol ## ">"; ?fields);
        cache-class-definer("<" ## ?name ## "-cache>";
                            "<" ## ?name ## ">", "<" ## ?superprotocol ## "-cache>";
                            ?fields);
        decoded-class-definer("<decoded-" ## ?name ## ">";
                              "<" ## ?name ## ">", "<decoded-" ## ?superprotocol ## ">";
                              ?fields);
        gen-classes(?name; ?superprotocol);
        frame-field-generator("<unparsed-" ## ?name ## ">";
                              field-count("<unparsed-" ## ?superprotocol ## ">");
                              ?fields);
      }
end;

define macro leaf-frame-constructor-definer
  { define leaf-frame-constructor(?:name) end }
 =>
  {
    define method ?name (data :: <byte-vector>) 
     => (res :: "<" ## ?name ## ">");
      parse-frame("<" ## ?name ## ">", data)
    end;

    define method ?name (data :: <collection>)
     => (res :: "<" ## ?name ## ">");
      ?name(as(<byte-vector>, data))
    end;

    define method ?name (data :: <string>)
     => (res :: "<" ## ?name ## ">");
      read-frame("<" ## ?name ## ">", data)
    end;

  }
end;

