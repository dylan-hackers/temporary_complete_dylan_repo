module: main
rcs-header: $Header: /scm/cvs/src/d2c/compiler/main/single-file-mode-state.dylan,v 1.7 2002/03/04 21:48:13 brent Exp $
copyright: see below

//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000, 2001  Gwydion Dylan Maintainers
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University, and the Gwydion Dylan Maintainers.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
// comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
// Also, see http://www.gwydiondylan.org/ for updates and documentation. 
//
//======================================================================

define class <single-file-mode-state> (<main-unit-state>)
  slot unit-source-file :: <byte-string>, required-init-keyword: source-file:;
  
  slot unit-name :: <byte-string>; // for single files, name == module == library == executable
  slot unit-lib :: <library>;

  slot unit-mprefix :: <byte-string>;
  slot unit-tlf-vectors :: <stretchy-vector> = make(<stretchy-vector>);
  slot unit-modules :: <stretchy-vector> = make(<stretchy-vector>);
  slot unit-cback-unit :: <unit-state>;
  slot unit-other-cback-units :: <simple-object-vector>;
  
  slot unit-entry-function :: false-or(<ct-function>), init-value: #f;
  slot unit-unit-info :: <unit-info>;
  slot unit-c-file :: false-or(<file-state>) = #f;
  slot unit-stream = #f;
end class <single-file-mode-state>;

define method parse-and-finalize-library (state :: <single-file-mode-state>) => ();
  let source = make(<source-file>, name: state.unit-source-file);
  let (header, start-line, start-posn) = parse-header(source);

  state.unit-header := header;

  do(process-feature,
     split-at-whitespace(state.unit-target.default-features));
  do(process-feature,
     split-at-whitespace(element(state.unit-header, #"features",
				 default: "")));
  do(process-feature, state.unit-command-line-features);
  
  let lib-name = state.unit-header[#"module"];
  state.unit-name := lib-name;
  format(*debug-output*, "Compiling library %s\n", lib-name);
  state.unit-lib    := find-library(as(<symbol>, lib-name), create: #t);

  // XXX these two look suspicious
  // second one is ok, default is now according to DRM
  *defn-dynamic-default* := boolean-header-element(#"dynamic", #f, state);
  *implicitly-define-next-method*
    := boolean-header-element(#"implicitly-define-next-method", #t, state);

  state.unit-mprefix := as-lowercase(lib-name);

  let libmod-declaration = as(<byte-vector>, format-to-string("define library %s use common-dylan; use io; end; define module %s use common-dylan; use format-out; end;\n\n", lib-name, lib-name));

  block ()
    let tokenizer = make(<lexer>, 
                         source: make(<source-buffer>, 
                                      buffer: libmod-declaration),
                         start-line: 0,
                         start-posn: 0);
    block ()
      *Current-Library* := state.unit-lib;
      *Current-Module*  := find-module(state.unit-lib, as(<symbol>, "dylan-user"));
      let tlfs = make(<stretchy-vector>);
      *Top-Level-Forms* := tlfs;
      add!(state.unit-tlf-vectors, tlfs);
      add!(state.unit-modules, *Current-Module*);
      parse-source-record(tokenizer);
    cleanup
      *Current-Library* := #f;
      *Current-Module* := #f;
    end;
  exception (<fatal-error-recovery-restart>)
    format(*debug-output*, "skipping rest of built-in init definition\n");
  end block;


  let mod = find-module(state.unit-lib, as(<symbol>, lib-name));

  block ()
    format(*debug-output*, "Parsing %s\n", state.unit-source-file);
    let tokenizer = make(<lexer>, 
                         source: source,
                         start-line: start-line,
                         start-posn: start-posn);
    block ()
      *Current-Library* := state.unit-lib;
      *Current-Module*  := mod;
      let tlfs = make(<stretchy-vector>);
      *Top-Level-Forms* := tlfs;
      add!(state.unit-tlf-vectors, tlfs);
      add!(state.unit-modules, mod);
      parse-source-record(tokenizer);
    cleanup
      *Current-Library* := #f;
      *Current-Module* := #f;
    end;
  exception (<fatal-error-recovery-restart>)
    format(*debug-output*, "skipping rest of %s\n", state.unit-source-file);
  end block;
  format(*debug-output*, "seeding representations\n");
  seed-representations();
  format(*debug-output*, "Finalizing definitions\n");
  for(tlfs in state.unit-tlf-vectors)  
    for (tlf in copy-sequence(tlfs))
      note-context(tlf);
      finalize-top-level-form(tlf);
      end-of-context();
    end for;
  end for;
  format(*debug-output*, "inheriting slots\n");
  inherit-slots();
  format(*debug-output*, "inheriting overrides\n");
  inherit-overrides();
  begin
    let unique-id-base 
      = element(state.unit-header, #"unique-id-base", default: #f);
    if (unique-id-base)
      format(*debug-output*, "assigning unique ids\n");
      assign-unique-ids(string-to-integer(unique-id-base));
    end;
  end;
  format(*debug-output*, "laying out instances\n");
  layout-instance-slots();
end method parse-and-finalize-library;

define method compile-file (state :: <single-file-mode-state>) => ();
  format(*debug-output*, "Processing %s\n", state.unit-source-file);
  let c-name = concatenate(state.unit-name, ".c");
  let body-stream
     = make(<file-stream>, locator: c-name, direction: #"output");
  let file = make(<file-state>, unit: state.unit-cback-unit,
                     body-stream: body-stream, single-file-mode?: #t);
  state.unit-c-file := file;
  state.unit-stream := body-stream;
  emit-prologue(file, state.unit-other-cback-units);

  for (tlfs in state.unit-tlf-vectors,
       module in state.unit-modules)
      *Current-Module* := module;
      for (tlf in tlfs)
        block ()
          compile-1-tlf(tlf, file, state);
        cleanup
          end-of-context();
        exception (<fatal-error-recovery-restart>)
          #f;
        end block;
      end for;
  end for;
  format(*debug-output*, "\n", state.unit-source-file);
end method compile-file;


// Build initialization function for this library, generate the corresponding
// .c and .o and update the make file.
// 
define method build-library-inits (state :: <single-file-mode-state>) => ();
  build-unit-init-function(state.unit-mprefix, state.unit-init-functions,
                           state.unit-stream);
end method build-library-inits;

define method build-local-heap-file (state :: <single-file-mode-state>) => ();
  format(*debug-output*, "Emitting Library Heap.\n");
  let heap-stream = state.unit-stream;
  let prefix = state.unit-cback-unit.unit-prefix;
  let (undumped, extra-labels) = build-local-heap(state.unit-cback-unit, 
						  state.unit-c-file);
  let linker-options = element(state.unit-header, #"linker-options", 
			       default: #f);
  state.unit-unit-info := make(<unit-info>, unit-name: state.unit-mprefix,
			       undumped-objects: undumped,
			       extra-labels: extra-labels,
			       linker-options: linker-options);
end method build-local-heap-file;

define method build-da-global-heap (state :: <single-file-mode-state>) => ();
  format(*debug-output*, "Emitting Global Heap.\n");
  let heap-stream = state.unit-stream;
  build-global-heap(apply(concatenate, map(undumped-objects, *units*)),
		    state.unit-c-file);
end method;


define method build-inits-dot-c (state :: <single-file-mode-state>) => ();
  format(*debug-output*, "Building inits.\n");
  let stream = state.unit-stream;
  format(stream,
	 "void inits(descriptor_t *sp, int argc, char *argv[])\n{\n");
  for (unit in *units*)
    format(stream, "    %s_Library_init(sp);\n", string-to-c-name(unit.unit-name));
  end;
  format(stream, "}\n");
  format(stream, "\nextern void real_main(int argc, char *argv[]);\n\n");
#if (macos)
  format(stream, "#include<console.h>\n");
#endif
  format(stream, "int main(int argc, char *argv[]) {\n");
#if (macos)
  format(stream, "    argc = ccommand( &argv );\n");
#endif
  format(stream, "    real_main(argc, argv);\n");
  format(stream, "    return 0;\n");
  format(stream, "}\n");
end method;

define method build-executable (state :: <single-file-mode-state>) => ();
  let target = state.unit-target;
  let unit-libs = "";
  let dash-small-ells = "";
  let linker-args = concatenate(" ", target.link-executable-flags);
  if(state.unit-profile? & target.link-profile-flags)
    linker-args := concatenate(linker-args, " ", target.link-profile-flags);
  end if;

  local method add-archive (name :: <byte-string>) => ();
          if (state.unit-no-binaries)
	    // If cross-compiling use -l -L search mechanism.
	    dash-small-ells := stringify(" -l", name, dash-small-ells);
	  else
	    let archive = find-library-archive(name, state);
	    unit-libs := stringify(' ', archive, unit-libs);
	  end if;
	end method add-archive;

  // Under Unix, the order of the libraries is significant!  First to
  // be added go at the end of the command line...
  add-archive("gc");
  add-archive("runtime");

  for (unit in *units*)
    if (unit.unit-linker-options)
      linker-args
	:= stringify(' ', unit.unit-linker-options, linker-args);
    end if;
    unless (unit == state.unit-unit-info)
      add-archive(concatenate(unit.unit-name, "-dylan"));
    end unless;
  end;

  let cc-flags
    = getenv("CCFLAGS") 
    | format-to-string(if (state.unit-profile?)
                         state.unit-target.default-c-compiler-profile-flags;
                       elseif (state.unit-debug?)
                         state.unit-target.default-c-compiler-debug-flags;
                       else
                         state.unit-target.default-c-compiler-flags;
                       end if,
                       $runtime-include-dir);
  
  cc-flags := concatenate(cc-flags, getenv("CCOPTS")|"");

  let libtool = getenv("LIBTOOL") | state.unit-target.libtool-command;

  let unit-libs = use-correct-path-separator(unit-libs, state.unit-target);

  let objects = format-to-string("%s%s %s", state.unit-name, state.unit-target.object-filename-suffix, unit-libs);

  let compile-string
    = substring-replace(format-to-string(state.unit-target.compile-c-command,
                                         concatenate(state.unit-name, ".c"),
                                         concatenate(state.unit-name, state.unit-target.object-filename-suffix)),
                        "$(CCFLAGS)", cc-flags);

  close(state.unit-stream);
  state.unit-stream := #f;

  if (system(compile-string) ~== 0)
    cerror("so what", "gcc failed?");
  end if;

  let exec-name = concatenate(state.unit-name, state.unit-target.executable-filename-suffix);

  let link-string-intermediate
    = format-to-string(state.unit-target.link-executable-command,
                       exec-name,
                       concatenate(objects, dash-small-ells," "),
                       linker-args);
#if ( libtool )
  let link-string
    = substring-replace(link-string-intermediate, "$(LIBTOOL)", libtool);
#else
  let link-string = link-string-intermediate;
#endif

  if (system(link-string) ~== 0)
    cerror("so what", "gcc failed?");
  end if;

end method build-executable;

/*

define method dump-library-summary (state :: <single-file-mode-state>) => ();
  format(*debug-output*, "Dumping library summary.\n");
  let dump-buf
    = begin-dumping(as(<symbol>, state.unit-lib-name),
    		    $library-summary-unit-type);

  for (tlfs in state.unit-tlf-vectors)
    for (tlf in tlfs)
      dump-od(tlf, dump-buf);
    end;
  end;
  dump-od(state.unit-unit-info, dump-buf);
  dump-queued-methods(dump-buf);

  end-dumping(dump-buf);
  format(state.unit-makefile, "\nall-at-end-of-file : %s\n",
  	 state.unit-ar-name);
  format(state.unit-clean-stream, " %s", state.unit-ar-name);
  format(state.unit-real-clean-stream, " %s %s.lib.du", state.unit-ar-name, 
	 as-lowercase(state.unit-lib-name));
end method;


define method do-make (state :: <single-file-mode-state>) => ();
  let target = state.unit-target;
  format(state.unit-makefile, "\nclean :\n");
  format(state.unit-makefile, "\t%s %s\n", target.delete-file-command, 
	 state.unit-clean-stream.stream-contents);
  format(state.unit-makefile, "\nrealclean :\n");
  format(state.unit-makefile, "\t%s %s\n", target.delete-file-command, 
	 state.unit-real-clean-stream.stream-contents);
  close(state.unit-makefile);

  if (pick-which-file(state.unit-makefile-name,
		      state.unit-temp-makefile-name,
		      target)
	= #t)
    // If the new makefile is different from the old one, then we need
    // to recompile all .c and .s files, regardless of whether they
    // were changed.  So touch them to make them look newer than the
    // object files.
    unless (empty?(state.unit-all-generated-files))
      let touch-command = "touch";
      for (filename in state.unit-all-generated-files)
	touch-command := stringify(touch-command, ' ', filename);
      end for;
      format(*debug-output*, "%s\n", touch-command);
      if (system(touch-command) ~== 0)
	cerror("so what", "touch failed?");
      end if;
    end unless;
  end if;

  if (~state.unit-no-binaries)
    let make-string = format-to-string("%s -f %s", target.make-command, 
				       state.unit-makefile-name);
    format(*debug-output*, "%s\n", make-string);
    unless (zero?(system(make-string)))
      cerror("so what", "gmake failed?");
    end;
  end if;
end method do-make;
*/

define method compile-library (state :: <single-file-mode-state>)
    => worked? :: <boolean>;
  block (give-up)
    // We don't really have to give-up if we don't want to, but it
    // seems kind of pointless to compile a file that doesn't parse,
    // or create a dump file for library with undefined variables.
    // Thus, we stick some calls to give-up where it seems useful..
    parse-and-finalize-library(state);
    if (~ zero?(*errors*)) give-up(); end if;
    state.unit-cback-unit := make(<unit-state>, prefix: state.unit-mprefix);
    state.unit-other-cback-units := map-as(<simple-object-vector>, unit-name, 
					 *units*);
    compile-file(state);
    if (~ zero?(*errors*)) give-up(); end if;
    build-library-inits(state);
    build-local-heap-file(state);
    calculate-type-inclusion-matrix(); // Hmmm... move this to program startup time one day
    build-da-global-heap(state);
    build-inits-dot-c(state);
    build-executable(state);
/*

    if (state.unit-log-dependencies)
      spew-dependency-log(concatenate(state.unit-mprefix, ".dep"));
    end if;

    do-make(state);
*/
  cleanup
    if(state.unit-stream)
      close(state.unit-stream);
    end if;
    fresh-line(*debug-output*);
    *Current-Module* := #f;
  exception (<fatal-error-recovery-restart>)
    format(*debug-output*, "giving up.\n");
  end block;
  
  format(*debug-output*, "Optimize called %d times.\n", *optimize-ncalls*);

  let worked? = zero?(*errors*);
  format(*debug-output*,
	 "Compilation %s with %d Warning%s and %d Error%s\n",
	 if (worked?) "finished" else "failed" end,
	 *warnings*, if (*warnings* == 1) "" else "s" end,
	 *errors*, if (*errors* == 1) "" else "s" end);

  worked?;
end method compile-library;

