module: c-parser
synopsis: Stuff which will only stay around during the integration process.

define class <stub-object> (<object>)
end;

define method initialize
    (object :: <stub-object>,
     #next next-method,
     #rest rest,
     #key,
     #all-keys)
  error("Cannot create stub object %=.", object);
end;


//=========================================================================
//  Making tagged types.
//=========================================================================
//  This routine creates <c-type>s for structs, unions and enums. It's big
//  and evil, but it's better to keep all this logic in one place.
//
//  This routine will be moving elsewhere in the future.

define function make-tagged-type
    (name :: type-union(<string>, <false>),
     member-list :: type-union(<list>, <false>),
     decl-token :: <token>, state :: <parse-state>)
 => (result :: <c-tagged-type>)

  // Declare a helper method.
  local method register-new-tagged-type(type :: <c-tagged-type>)
	  state.structs[type.c-type-tag] := type;
	  add-declaration(state, make(<c-tagged-type-declaration>,
				      type: type));
	  type;
	end method;

  // Convert our member list to the prefered format.
  let member-list =
    if (member-list)
      map-as(<stretchy-vector>, identity, member-list);
    else // an incomplete type
      #f
    end;

  // Figure out what we're making.
  let declaration-class = select (decl-token by instance?)
			    <struct-token> => <c-struct-type>;
			    <union-token> => <c-union-type>;
			    <enum-token> => <c-enum-type>;
			    otherwise => error("illegal tagged type!");
			  end select;

  // Have we seen this before?
  let old-type :: false-or(<c-tagged-type>) =
    if (name)
      element(state.structs, name, default: #f);
    else // a unique anonymous type.
      #f;
    end;

  // Figure out what kind of situation we're in, and handle it.
  case

    // Handle illegal redeclarations.
    (old-type & old-type.object-class ~= declaration-class) =>
      parse-error(state,
		  "tagged type doesn't match original declaration: %s",
		  name);

    // Fill out incomplete types.
    (old-type & ~old-type.c-type-complete? & member-list) =>
      old-type.c-type-members := member-list;
      old-type;
      
    // Catch redeclarations of existing types.
    (old-type & old-type.c-type-complete? & member-list) =>
      parse-error(state, "cannot declare %s twice", name);

    // Handle pre-existing declarations.
    (old-type) =>
      // XXX - We should check to make sure the declarations are compatible.
      old-type;
      
    // If we're not allowed to declare new types, fail now.
    (~instance?(state, <parse-file-state>)) =>
      parse-error(state, "type not found: %s", name);
      
    // Make a new struct-or-union type.
    (instance?(declaration-class, <c-struct-or-union-type>)) =>
      register-new-tagged-type(make(declaration-class,
				    repository: state.repository,
				    tag: name,
				    members: member-list));

    // Catch attempts to use an incomplete enum type (forbidden by ANSI C)
    (~member-list) =>
      parse-error(state, "enum %s has not been declared yet", name);
      
    // Make a new enum type.
    otherwise =>
      for (member in member-list)
	state.objects[member.c-enum-constant-name] := member;
      end;
      register-new-tagged-type(make(declaration-class,
				    repository: state.repository,
				    tag: name,
				    members: member-list));
  end case;
end function make-tagged-type;


//=========================================================================
//  C Declarations from c-decl.dylan
//=========================================================================

// Used when processing <SIZEOF-token>.
define function c-type-size (name :: <icky-type-name>)
  // XXX - need information about local C compiler
  error("cannot evaluate sizeof expressions");
end;

// Used when processing <end-include-token>.
// Used in the function parse.
define function add-cpp-declaration
    (state :: <parse-state>, macro-name :: <string>)
 => ()
  parse-warning(state, "Ignoring '#define %s' for now", macro-name);

/*
  block ()
    let value = parse-macro(macro-name, state);
    state.objects[macro-name] :=
      add-declaration(state, make(<macro-declaration>, name: macro-name,
				  value: value));
  exception (<error>)
    #f;
  end block;
*/
end function add-cpp-declaration;

// No longer used (except as a superclass in this file).
define class <declaration> (<stub-object>)
end;

// Used in rules on cast-expr.
define function true-type (#rest rest)
  error("STUB: true-type");
end;

// Used in rules on cast-expr.
define class <integer-type-declaration> (<declaration>)
end;

// Used in rules on enumerator-list.
define function make-enum-slot
    (name :: <string>, value :: false-or(<integer>),
     prev :: false-or(<c-enum-constant>), state :: <parse-state>)
 => (result :: <c-enum-constant>);
  if (element(state.objects, name, default: #f))
    parse-error(state, "Enumeration literal does not have a unique name: %s",
		name);
  else
    let value
      = case
	  value => value;
	  prev => prev.c-enum-constant-value + 1;
	  otherwise => 0;
	end case;
    state.objects[name] := make(<c-enum-constant>,
				name: name,
				value: value);
  end if;
end;
