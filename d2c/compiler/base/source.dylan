module: source
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/source.dylan,v 1.15 1996/05/08 15:56:31 nkramer Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

// source-location -- exported.
//
// Return the location in the source where the thing came from, or #f if
// unknown.
// 
define open generic source-location (thing :: <object>)
    => res :: <source-location>;


// The <source-location-mixin> class.

define open abstract class <source-location-mixin> (<object>)
  sealed constant slot source-location :: <source-location>
      = make(<unknown-source-location>),
    init-keyword: source-location:;
end;


// The <source-location> class.

define open abstract class <source-location> (<object>)
end;

define sealed domain make (singleton(<source-location>));


define method make (wot == <source-location>, #key)
    => res :: <source-location>;
  make(<unknown-source-location>);
end;


define open generic describe-source-location
    (srcloc :: <source-location>, stream :: <stream>) => ();



// Unknown source locations.

define class <unknown-source-location> (<source-location>)
end;

define sealed domain make (singleton(<unknown-source-location>));
define sealed domain initialize (<unknown-source-location>);

define variable *unknown-srcloc* :: false-or(<unknown-source-location>) = #f;

define method make
    (class == <unknown-source-location>, #next next-method, #key)
    => res :: <unknown-source-location>;
  *unknown-srcloc* | (*unknown-srcloc* := next-method());
end method make;
  
define sealed method describe-source-location
    (srcloc :: <unknown-source-location>, stream :: <stream>)
    => ();
end method describe-source-location;

add-make-dumper(#"unknown-source-location", *compiler-dispatcher*,
		<unknown-source-location>, #());


// getcwd

#if (~mindy)

define method getcwd () => cwd :: <byte-string>;
  let buffer = make(<buffer>, size: 1024);
  if (zero?(call-out("getcwd", #"long",
		     #"ptr", buffer-address(buffer),
		     #"int", 1024)))
    error("Can't get the current directory.");
  else
    let len = block (return)
		for (index :: <integer> from 0 below 1024)
		  if (buffer[index].zero?)
		    return(index);
		  end if;
		end for;
		error("Can't get the current directory.");
	      end block;
    let result = make(<byte-string>, size: len);
    for (index :: <integer> from 0 below len)
      result[index] := as(<character>, buffer[index]);
    end for;
    result;
  end if;
end method getcwd;

#endif


// Source files.

#if (mindy)

define constant $big-buffer-threshold = 64 * 1024;

define class <big-buffer> (<vector>)
  slot size :: <integer>, setter: #f,
    required-init-keyword: size:;
  slot buffers :: <simple-object-vector>,
    required-init-keyword: buffers:;
end class <big-buffer>;

define method make
    (class == <big-buffer>, #next next-method, #key size = 0, fill = 0)
    => res :: <big-buffer>;
  let (nbuffers, extra) = floor/(size, $big-buffer-threshold);
  let buffers = make(<simple-object-vector>,
		     size: if (zero?(extra)) nbuffers else nbuffers + 1 end);
  for (index from 0 below nbuffers)
    buffers[index] := make(<buffer>, size: $big-buffer-threshold, fill: fill);
  end for;
  unless (zero?(extra))
    buffers[nbuffers] := make(<buffer>, size: extra, fill: fill);
  end unless;
  next-method(class, size: size, buffers: buffers);
end method make;

define constant $butt-plug = list(#"x");

define method element
    (vec :: <big-buffer>, index :: <integer>, #key default = $butt-plug)
    => element :: <object>;
  if (index >= 0 & index < vec.size)
    let (buf, extra) = floor/(index, $big-buffer-threshold);
    vec.buffers[buf][extra];
  elseif (default ~== $butt-plug)
    default;
  else
    error("No element %= in %=", index, vec);
  end if;
end method element;

define method element-setter
    (new :: <byte>, vec :: <big-buffer>, index :: <integer>)
    => new :: <byte>;
  if (index >= 0 & index < vec.size)
    let (buf, extra) = floor/(index, $big-buffer-threshold);
    vec.buffers[buf][extra] := new;
  else
    error("No element %= in %=", index, vec);
  end if;
end method element-setter;

define method fill-buffer (big-buf :: <big-buffer>, stream :: <stream>) => ();
  for (buf in big-buf.buffers)
    read-into!(buf, stream);
  end for;
end method fill-buffer;

define method copy-bytes
    (dst :: <byte-string>, dst-offset :: <integer>,
     src :: <big-buffer>, src-offset :: <integer>,
     count :: <integer>)
    => ();
  let (start-buf, start-byte) = floor/(src-offset, $big-buffer-threshold);
  let (end-buf, end-byte) = floor/(src-offset + count, $big-buffer-threshold);
  if (start-buf == end-buf)
    copy-bytes(dst, dst-offset, src.buffers[start-buf], start-byte, count);
  else
    local method partial-copy (buf, byte, bytes)
	    copy-bytes(dst, dst-offset, src.buffers[buf], byte, bytes);
	    dst-offset := dst-offset + bytes;
	  end method partial-copy;
    partial-copy(start-buf, start-byte, $big-buffer-threshold - start-byte);
    for (buf from start-buf + 1 below end-buf)
      partial-copy(start-buf, 0, $big-buffer-threshold);
    end for;
    partial-copy(end-buf, 0, end-byte);
  end if;
end method copy-bytes;

define constant <file-contents> = type-union(<buffer>, <big-buffer>);

define method make-buffer (size :: <integer>)
    => res :: <file-contents>;
  if (size > $big-buffer-threshold)
    make(<big-buffer>, size: size);
  else
    make(<buffer>, size: size);
  end if;
end method make-buffer;

#else // Not mindy.

define constant <file-contents> = <buffer>;

define inline method make-buffer (size :: <integer>)
    => res :: <file-contents>;
  make(<buffer>, size: size);
end method make-buffer;

#endif

define method fill-buffer (buf :: <buffer>, stream :: <stream>) => ();
  read-into!(buf, stream);
end method fill-buffer;


// <source-file> -- exported.
// 
// preserve identity for space sharing...
//
define class <source-file> (<identity-preserving-mixin>)
  //
  // The name for this source file.
  constant slot file-name :: <byte-string>,
    required-init-keyword: name:;
  //
  // The directory for this source file.  The make method defaults it to
  // the current directory and makes sure that it is absolute and ends in
  // a slash.  Unless the file-name is absolute, in which case the directory
  // is #f.
  constant slot directory :: false-or(<byte-string>) = #f,
    init-keyword: directory:;
  //
  // The contents, or #f if we haven't read them in yet.
  slot %contents :: false-or(<file-contents>) = #f;
end;

define sealed domain make (singleton(<source-file>));
define sealed domain initialize (<source-file>);

define method make
    (class == <source-file>, #next next-method,
     #key name :: <byte-string>, directory :: false-or(<byte-string>))
    => res :: <source-file>;
  if (name.first == '/')
    if (directory)
      error("Can't supply a directory when suppling an absolute pathname.");
    end if;
    next-method(class, name: name);
  else
    let absolute
      = if (directory & directory.size > 0 & directory.first == '/')
	  directory;
	else
	  let cwd = getcwd();
	  if (directory)
	    stringify(cwd, '/', directory);
	  else
	    cwd;
	  end if;
	end if;
    next-method(class, name: name,
		directory:
		  if (absolute.last == '/')
		    absolute;
		  else
		    stringify(absolute, '/');
		  end if);
  end if;
end method make;

define method print-object (sf :: <source-file>, stream :: <stream>) => ();
  pprint-fields(sf, stream, name: sf.file-name);
end;

// contents -- exported
//
// Return the contents of the source file as a buffer.  If we have
// never done this before, we read the entire file and stash the
// results so that we don't have to read the file again.  And so that
// we don't have to come up with some silly interface to read parts of
// the file and switch back and forth.
// 
define method contents (source :: <source-file>)
  source.%contents
    | begin
	let file = make(<file-stream>,
			name: if (source.directory)
				stringify(source.directory, source.file-name);
			      else
				source.file-name;
			      end if);
	block ()
	  let result = make-buffer(file.stream-size);
	  fill-buffer(result, file);
	  source.%contents := result;
	cleanup
	  close(file);
	end block;
      end;
end method contents;


define method extract-line
    (source :: <source-file>, line-start :: <integer>) => res :: <byte-string>;
  let contents = source.contents;
  for (index from line-start below contents.size,
       until: contents[index] == as(<integer>, '\n'))
  finally
    let len = index - line-start;
    let result = make(<byte-string>, size: len);
    copy-bytes(result, 0, contents, line-start, len);
    result;
  end for;
end method extract-line;



add-make-dumper(#"source-file", *compiler-dispatcher*, <source-file>,
		list(file-name, name:, #f,
		     directory, directory: #f));



// file source locations.


define class <file-source-location> (<source-location>)
  
  constant slot source-file :: <source-file>,
    required-init-keyword: source:;
  
  constant slot start-posn :: <integer>,
    required-init-keyword: start-posn:;
  
  constant slot start-line :: <integer>,
    required-init-keyword: start-line:;
  
  constant slot start-column :: <integer>,
    required-init-keyword: start-column:;
  
  constant slot end-posn :: <integer>,
    required-init-keyword: end-posn:;
  
  constant slot end-line :: <integer>,
    required-init-keyword: end-line:;
  
  constant slot end-column :: <integer>,
    required-init-keyword: end-column:;
end;

define sealed domain make (singleton(<file-source-location>));
define sealed domain initialize (<file-source-location>);

define method print-object (sl :: <file-source-location>, stream :: <stream>)
    => ();
  pprint-fields(sl, stream,
		source-file: sl.source-file,
		start-line: sl.start-line,
		start-column: sl.start-column,
		end-line: sl.end-line,
		end-column: sl.end-column);
end;


define sealed method describe-source-location
    (srcloc :: <file-source-location>, stream :: <stream>)
    => ();
  pprint-logical-block
    (stream,
     body:
       method (stream :: <stream>)
	 if (srcloc.end-line <= srcloc.start-line)
	   if (srcloc.end-column <= srcloc.start-column)
	     format(stream, "\"%s\", line %d, before character %d:",
		    srcloc.source-file.file-name, srcloc.start-line,
		    srcloc.start-column + 1);
	   elseif (srcloc.end-column == srcloc.start-column + 1)
	     format(stream, "\"%s\", line %d, character %d:",
		    srcloc.source-file.file-name, srcloc.start-line,
		    srcloc.start-column + 1);
	   else
	     format(stream, "\"%s\", line %d, characters %d through %d:",
		    srcloc.source-file.file-name, srcloc.start-line,
		    srcloc.start-column + 1, srcloc.end-column);
	   end if;
	   pprint-newline(#"mandatory", stream);
	   block (return)
	     let line
	       = begin
		   let handler (<file-not-found>)
		     = method (cond, next-handler) return() end method;
		   extract-line(srcloc.source-file,
				srcloc.start-posn - srcloc.start-column);
		 end;
	     highlight-line(line, srcloc.start-column, srcloc.end-column,
			    stream);
	   end block;
	 else
	   format(stream,
		  "\"%s\", line %d, character %d through "
		    "line %d, character %d:",
		  srcloc.source-file.file-name, srcloc.start-line,
		  srcloc.start-column + 1, srcloc.end-line,
		  srcloc.end-column);
	   pprint-newline(#"mandatory", stream);
	   block (return)
	     let (first-line, last-line)
	       = begin
		   let handler (<file-not-found>)
		     = method (cond, next-handler) return() end method;
		   values(extract-line
			    (srcloc.source-file,
			     srcloc.start-posn - srcloc.start-column),
			  extract-line
			    (srcloc.source-file,
			     srcloc.end-posn - srcloc.end-column));
		 end;
	     highlight-line(first-line, srcloc.start-column,
			    first-line.size, stream);
	     unless (srcloc.start-line + 1 == srcloc.end-line)
	       write("  through", stream);
	     end unless;
	     pprint-newline(#"mandatory", stream);
	     highlight-line(last-line, 0, srcloc.end-column, stream);
	   end block;
	 end if;
       end method);
  write("  ", stream);
end method describe-source-location;


define method highlight-line
    (line :: <byte-string>, start-char :: <integer>, end-char :: <integer>,
     stream :: <stream>)
    => ();
  write("    ", stream);
  local method repeat (index :: <integer>, column :: <integer>)
	  if (index < line.size)
	    let char = line[index];
	    if (char == '\t')
	      let new-column = floor/(column + 8, 8) * 8;
	      for (column from column below new-column)
		write(' ', stream);
	      end for;
	      repeat(index + 1, new-column);
	    else
	      write(char, stream);
	      repeat(index + 1, column + 1);
	    end if;
	  end if;
	end method repeat;
  repeat(0, 0);
  pprint-newline(#"mandatory", stream);
  let start-column = compute-column(line, start-char);
  if (start-char < end-char)
    let end-column = compute-column(line, end-char);
    for (column from 0 below start-column + 4)
      write(' ', stream);
    end for;
    for (column from start-column below end-column)
      write('^', stream);
    end for;
  else
    for (column from 0 below start-column + 3)
      write(' ', stream);
    end for;
    write("/\\", stream);
  end if;
  pprint-newline(#"mandatory", stream);
end method highlight-line;


define method compute-column (line :: <byte-string>, target :: <integer>)
  for (i from 0 below target,
       column = 0
	 then if (line[i] == '\t')
		floor/(column + 8, 8) * 8;
	      else
		column + 1;
	      end if)
  finally
    column;
  end for;
end method compute-column;


// extract-string -- exported.
//
// Extracts the text behind the source location and returns it as a string.
// Does no processing of the input.  The start: and end: keywords can
// be used to adjust exactly where to start and end the string.
// 
define method extract-string
    (source-location :: <file-source-location>,
     #key start :: <integer> = source-location.start-posn,
          end: finish :: <integer> = source-location.end-posn)
  let len = finish - start;
  if (len.positive?)
    let result = make(<string>, size: len);
    copy-bytes(result, 0, source-location.source-file.contents, start, len);
    result;
  else
    "";
  end if;
end;



define constant $source-file-location-words = 6;

// We represent most slots in file source locations as raw data to save
// space/time.  The only subobject is the source-file.
//
define method dump-od (obj :: <file-source-location>, buf :: <dump-state>)
 => ();
  let start-pos = buf.current-pos;
  dump-definition-header(#"file-source-location", buf, subobjects: #t,
  			 raw-data: $odf-word-raw-data-format);
  dump-word($source-file-location-words, buf);
  dump-word(obj.start-posn, buf);
  dump-word(obj.start-line, buf);
  dump-word(obj.start-column, buf);
  dump-word(obj.end-posn, buf);
  dump-word(obj.end-line, buf);
  dump-word(obj.end-column, buf);
  dump-od(obj.source-file, buf);
  dump-end-entry(start-pos, buf);
end method;

add-od-loader(*compiler-dispatcher*, #"file-source-location",
  method (state :: <load-state>) => res :: <file-source-location>;
    state.od-next := state.od-next + $word-bytes; // skip count
    let nbytes = $source-file-location-words * $word-bytes;
    let next = fill-at-least(nbytes, state);
    let buf = state.od-buffer;
    let s-posn = buffer-word(buf, next + (0 * $word-bytes));
    let s-line = buffer-word(buf, next + (1 * $word-bytes));
    let s-column = buffer-word(buf, next + (2 * $word-bytes));
    let e-posn = buffer-word(buf, next + (3 * $word-bytes));
    let e-line = buffer-word(buf, next + (4 * $word-bytes));
    let e-column = buffer-word(buf, next + (5 * $word-bytes));
    state.od-next := next + nbytes;
    let file = load-object-dispatch(state);
    assert-end-object(state);
    make(<file-source-location>,
         source: file,
         start-posn: s-posn,
	 start-line: s-line,
	 start-column: s-column,
	 end-posn: e-posn,
	 end-line: e-line,
	 end-column: e-column);
    end method
);

