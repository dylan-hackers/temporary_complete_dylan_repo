Module: flow
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/data-flow.dylan,v 1.9 1995/04/22 02:34:43 wlott Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

// This file contains definitions of classes describing data flow in a static
// single-assignment (SSA) form.

/*

object
    annotatable {mixin}

expression
    leaf {abstract}
        abstract-variable [annotatable] {abstract}
	    definition-site-variable {abstract}
	        ssa-variable
		initial-definition
	    multi-definition-variable {abstract}
	        initial-variable
		global-variable
    operation [dependent-mixin] {abstract}
        join-operation

variable-info {abstract}

dependency
dependent-mixin

abstract-assignment [source-location-mixin, dependent-mixin] {abstract}
    assignment
    join-assignment

*/

// Defines the Info slot used for back-end annotation.
//
define class <annotatable> (<object>)
  slot info, init-value: #f;
end class;


// Expressions:
//
//    And expression represents a fine-grain step evaluation: a constant, a
// variable, or the application of an operator to constants and variables.
// These simple expressions are combined via explicit temporary variables
// (there are no nested expressions.)
//
//    In order to make common-subexpression detection easy, expressions can be
// hash-consed: if the same expression is needed in two different locations,
// then the same == expression is used.  This means that once an expression has
// been created, it can't be modified in a way that would change the meaning of
// the expression.  This commoning isn't actually done until we do code motion,
// since the initial expressions are almost certain to change during the first
// optimize iteration.
//
define abstract class <expression> (<object>)
  //
  // Threaded list of the dependencies connecting this expression to the
  // dependent that use this expression.
  slot dependents :: false-or(<dependency>),
    init-value: #f, init-keyword: dependents:;
  //
  // Type we have inferred for this expression.  Any actual value will be an
  // instance of this type.  In <continuation>s and <operation>s this may be a
  // multiple-value type.
  slot derived-type :: <values-ctype>, init-function: object-ctype,
    init-keyword: derived-type:;
end class;


// <dependent-mixin> is inherited by all things that can be the direct target
// of a dependency: assignments, operations, IF-regions, and lambda results.
//
define class <dependent-mixin> (<object>)
  //
  // Head of list of dependencies for the expressions that we depend on,
  // threaded by dependent-next.
  slot depends-on :: false-or(<dependency>), init-value: #f,
    init-keyword: depends-on:;
  //
  // Thread running through dependents in the component reoptimize-queue, or
  // #"absent" if this dependent is not currently in the queue (hence is up to
  // date.)
  slot queue-next :: union(<dependent-mixin>, one-of(#f, #"absent")),
    init-value: #"absent";
end class;


// <dependency> represents a use site of an expression (i.e. a link between an
// expression and a single thing that is data-dependent on the value of the
// expression.)
//
// Expressions are used by:
// -- assignments,
// -- In the case of leaves, also by
//     - <operation> expression operands, and
//     - IF condition test values.
// -- In the case of variables, also by
//     - lambda results
//
// Expressions are only linked to the direct uses of that expression.  If I
// have an expression like "X + Y", then the <operation> "X + Y" is a use of X
// and Y.  An assignment like "T := X + Y" is a use of "X + Y", but not of X
// and Y.
//
define class <dependency> (<object>)
  //
  // The source expression generating the value.
  slot source-exp :: <expression>, required-init-keyword: source-exp:;
  //
  // Thread running through all the edges with this source-exp (uses of this
  // expression) in no particular order.
  slot source-next :: false-or(<dependency>), init-value: #f,
    init-keyword: source-next:;
  //
  // The thing that depends on the value of this expression.  Since the type is
  // so weak, it will generally be necessary to dynamically dispatch off of the
  // dependent object in order to interpret the edge.
  slot dependent :: <dependent-mixin>, required-init-keyword: dependent:;
  //
  // Thread running through all incoming edges at a given Dependent object.
  // This list is ordered according to the needs of the dependent (e.g. the
  // argument ordering in an <operation>.)
  slot dependent-next :: false-or(<dependency>), init-value: #f,
    init-keyword: dependent-next:;
end class;


// Leaves:
//
//    Variables, constants and functions are all represented by <Leaf>
// expressions.  Only leaf expressions can be used as the arguments to
// operations.
//
define abstract class <leaf> (<expression>)
  //
  // Pseudo-random hash code used to associate operands with operations.
  // slot leaf-hash :: <fixed-integer>, required-init-keyword: leaf-hash:;
end;


// Represents all mutable leaf types.  Semantic and source-context info is
// factored into the <variable-info> structure so that we can avoid a
// cross-product between the single/multi data flow aspect and the semantic
// aspects.  This also makes it trivial to preserve the semantic aspects when
// creating a copy of a variable during SSA conversion.
//
define abstract class <abstract-variable> (<leaf>, <annotatable>)
  slot var-info :: <variable-info>, required-init-keyword: var-info:;
end class;

define abstract class <variable-info> (<object>)
  slot asserted-type :: <values-ctype>, required-init-keyword: asserted-type:;
end class;


// Represents the "variables" that can appear directly as an assignment target.
// 
define abstract class <definition-site-variable> (<abstract-variable>)
  // The assignment that defines this variable.  Only #f during creation
  // or if the variable has been deleted.
  slot definer :: false-or(<abstract-assignment>),
    init-keyword: definer:, init-value: #f;

  // Thread through all the variables defined at our defining operation.
  slot definer-next :: false-or(<definition-site-variable>),
    init-keyword: definer-next:, init-value: #f;

  // #f if the assignment to this variable does not need to be type checked.
  slot needs-type-check? :: <boolean>, init-value: #t;
end;


// Represents a single-assignment (local or temporary) variable.
//
define class <ssa-variable> (<definition-site-variable>)
end class;

//
// The <initial-definition> and <multi-definition-variable> leaves conspire to
// represent variables with multiple definitions.

// <initial-definition> represents a definition site of a mutiply assigned
// variable.  Its dependents slot is always #f, since the definition-of var
// has all of the read references.
//
define class <initial-definition> (<definition-site-variable>)
  slot definition-of :: <multi-definition-variable>,
    required-init-keyword: definition:;
  slot next-initial-definition :: false-or(<initial-definition>),
    required-init-keyword: next-initial-definition:;
end;

// When we make an initial-definition, add to definitions list in multi-def
// var.
//
define method initialize
    (obj :: <initial-definition>, #next next-method, #all-keys);
  let of = obj.definition-of;
  of.definitions := pair(obj, of.definitions);
end;


// <multi-definition-variable> represents a (potentially) multiply assigned
// variable.
//
define abstract class <multi-definition-variable> (<abstract-variable>)
  // List of <initial-definition>s representing the definition points.
  slot definitions :: <list>, init-value: #();
end;

// Represents the initial references to a variable which we want to be SSA
// converted.
//
define class <initial-variable> (<multi-definition-variable>)
end class;

// Represents a global variable, which doesn't get SSA converted.
//
define class <global-variable> (<multi-definition-variable>)
end class;


// Operations:
//
//    Operations represent non-leaf expressions, i.e. primitives and function
// calls.  An <operation> bundles an operator with a particular set of <leaf>
// operands.
//
define abstract class <operation> (<expression>, <dependent-mixin>)
  inherited slot derived-type, init-function: wild-ctype;
  //
  // Head of operand list, threaded by Dependent-Next.
  inherited slot depends-on;
end class;


// Represents the joining of values on the RHS of a join assignment.
//
define class <join-operation> (<operation>)
end class;


// Assignments:
//
//    An assignment represents a concrete step in program executation.
// Assignments appear in sequence and pair expressions with target variables.
//
define abstract class <abstract-assignment> 
    (<source-location-mixin>, <dependent-mixin>)

  //
  // Dependency for the expression generating the assigned value(s).
  inherited slot depends-on;

  // Linked list of variables defined by this operation (results), threaded by
  // DEFINER-NEXT.  If #F, then there are no results, hence any computed result
  // is unused.
  slot defines :: false-or(<definition-site-variable>), init-value: #f;

  // The <simple-region> containing this operation.  #F only in deleted or new
  // code.
  slot region :: false-or(<simple-region>), init-keyword: region:,
    init-value: #f;

  // Pointers in the doubly linked list of operations in the Region.
  slot next-op :: false-or(<abstract-assignment>), init-value: #f;
  slot prev-op :: false-or(<abstract-assignment>), init-value: #f;
end;

// The <assignment> object represents a normal assignment to variables based on
// evaluation of an expression.
//
define class <assignment> (<abstract-assignment>)
end;

// <join-assignment> represents the assignment of a new joined definition at a
// join point in the control flow (a SSA phi-assignment.)  The expression is
// always a <join-operation>
// 
define abstract class <join-assignment> (<abstract-assignment>)
end;
