module: top-level-forms
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/front/tlf.dylan,v 1.11 1996/03/17 00:31:59 wlott Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

define variable *Top-Level-Forms* = make(<stretchy-vector>);

define open primary abstract class <top-level-form> (<source-location-mixin>)
end;

define open primary abstract class <define-tlf> (<top-level-form>)
end;

define open primary abstract class <simple-define-tlf> (<define-tlf>)
  slot tlf-defn :: <definition>, init-keyword: defn:;
end;

define method print-object (tlf :: <simple-define-tlf>, stream :: <stream>)
    => ();
  pprint-fields(tlf, stream, name: tlf.tlf-defn.defn-name);
end;

// finalize-top-level-form -- exported.
//
// Called by the main driver on each top level form in *Top-Level-Forms*
// after everything has been parsed.
//
define open generic finalize-top-level-form (tlf :: <top-level-form>) => ();

// convert-top-level-form
//
define open generic convert-top-level-form
    (builder :: <fer-builder>, tlf :: <top-level-form>)
    => ();


// Specific top level forms.

define open abstract class <define-generic-tlf> (<simple-define-tlf>)
  //
  // Make the definition required.
  required keyword defn:;
end class <define-generic-tlf>;


define open abstract class <define-method-tlf> (<simple-define-tlf>)
end class <define-method-tlf>;

define method print-message
    (tlf :: <define-method-tlf>, stream :: <stream>) => ();
  format(stream, "Define Method %s", tlf.tlf-defn.defn-name);
end;


define open abstract class <define-bindings-tlf> (<define-tlf>)
  constant slot tlf-required-defns :: <simple-object-vector>,
    required-init-keyword: required-defns:;
  constant slot tlf-rest-defn :: false-or(<bindings-definition>),
    required-init-keyword: rest-defn:;
end class <define-bindings-tlf>;


define class <define-class-tlf> (<simple-define-tlf>)
  //
  // Make the definition required.
  required keyword defn:;
  //
  // Stretchy vector of <init-function-definition>s.
  constant slot tlf-init-function-defns :: <stretchy-vector>
    = make(<stretchy-vector>);
end;

define method print-message
    (tlf :: <define-class-tlf>, stream :: <stream>) => ();
  format(stream, "Define Class %s", tlf.tlf-defn.defn-name);
end;



define class <magic-interal-primitives-placeholder> (<top-level-form>)
end;

define method print-message
    (tlf :: <magic-interal-primitives-placeholder>, stream :: <stream>) => ();
  write("Magic internal primitives.", stream);
end;



// Dump stuff.

// If name's var isn't visible outside this library, don't bother dumping the
// definition.
//
define method dump-od
    (tlf :: <simple-define-tlf>, state :: <dump-state>) => ();
  let defn = tlf.tlf-defn;
  if (name-inherited-or-exported?(defn.defn-name))
    dump-simple-object(#"define-binding-tlf", state, defn);
  end if;
end;

add-od-loader(*compiler-dispatcher*, #"define-binding-tlf",
	      method (state :: <load-state>) => res :: <definition>;
		let defn = load-sole-subobject(state);
		note-variable-definition(defn);
		defn;
	      end);
