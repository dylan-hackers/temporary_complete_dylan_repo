module: dylan

//////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 1994, Carnegie Mellon University
//  All rights reserved.
//
//  This code was produced by the Gwydion Project at Carnegie Mellon
//  University.  If you are interested in using this code, contact
//  "Scott.Fahlman@cs.cmu.edu" (Internet).
//
//////////////////////////////////////////////////////////////////////
//
//  $Header: /home/housel/work/rcs/gd/src/mindy/libraries/dylan/vec.dylan,v 1.12 1994/06/23 03:17:44 wlott Exp $
//
//  This file contains the support for vectors.
//


//// Iteration protocol.

define constant vector-prev-state =
  begin
    local
      method vector-prev-state (vec :: <vector>, state :: <integer>)
	  => <integer>;
	state - 1;
      end;
    vector-prev-state;
  end;

define constant vector-next-state =
  begin
    local
      method vector-next-state (vec :: <vector>, state :: <integer>)
	  => <integer>;
	state + 1;
      end;
    vector-next-state;
  end;

define constant vector-finished? =
  begin
    local
      method vector-finished? (vec :: <vector>, state :: <integer>,
			       limit :: <integer>)
	state == limit;
      end;
    vector-finished?;
  end;

define constant vector-current-key =
  begin
    local
      method vector-current-key (vec :: <vector>, state :: <integer>)
	  => <object>;
	state;
      end;
    vector-current-key;
  end;

define constant vector-current-element =
  begin
    local
      method vector-current-element (vec :: <vector>, state :: <integer>)
	  => <object>;
	element(vec, state);
      end;
    vector-current-element;
  end;

define constant vector-current-element-setter =
  begin
    local
      method vector-current-element-setter (value :: <object>, vec :: <vector>,
					    state :: <integer>)
	  => <object>;
	element(vec, state) := value;
      end;
    vector-current-element-setter;
  end;

define constant vector-copy-state =
  begin
    local
      method vector-copy-state (vec :: <vector>, state :: <integer>)
	  => <integer>;
	state;
      end;
    vector-copy-state;
  end;

define method forward-iteration-protocol (vec :: <vector>)
  values(0, size(vec), vector-next-state, vector-finished?,
	 vector-current-key, vector-current-element,
	 vector-current-element-setter, vector-copy-state);
end;

define method backward-iteration-protocol (vec :: <vector>)
  values(size(vec) - 1, -1, vector-prev-state, vector-finished?,
	 vector-current-key, vector-current-element,
	 vector-current-element-setter, vector-copy-state);
end;


//// Collection routines.

define method \=(vec1 :: <vector>, vec2 :: <vector>)
  let (size1, size2) = values(size(vec1), size(vec2));
  (size1 == size2) & for (index from 0 below size1,
			 while vec1[index] = vec2[index])
		    finally
		      // #t iff we fell off the end
		      index == size1;
		    end for;
end method \=;

// No collection alignment done here because it only handles the
// all-vector case.
define method map-as(cls :: <class>, function :: <function>,
		     vector :: <vector>,
		     #next next-method,
		     #rest more_vectors)
  if (~subtype?(cls, <vector>))
    next-method();
  elseif (empty?(more_vectors))
    let size = size(vector);
    let result = make(cls, size: size);
    for (key from 0 below size)
      result[key] := function(vector[key]);
    end for;
    result;
  elseif (~every?(rcurry(instance?, <vector>), more_vectors))
    next-method();
  else
    let size = reduce(method (a, b) min(a, size(b)) end method, size(vector),
		      more_vectors);
    let result = make(cls, size: size);
    for (key from 0 below size)
      result[key] := apply(function, vector[key],
			   map(rcurry(element, key), more_vectors));
    end for;
    result;
  end if;
end method map-as;

define method concatenate-as(cls :: <class>, vector :: <vector>,
			     #next next-method,
			     #rest more_vectors)
  if (~subtype?(cls, <vector>) |
	~every?(rcurry(instance?, <vector>), more_vectors))
    next-method();
  else 
    let length = reduce(method (int, seq) int + size(seq) end method,
			size(vector), more_vectors);
    let result = make(cls, size: length);
    local method do_copy(state, vector :: <vector>) // :: state
	    for (state from state,
		 key from 0 below size(vector))
	      result[state] := vector[key];
	    finally state;
	    end for;
	  end method do_copy;
    reduce(do_copy, do_copy(0, vector), more_vectors);
    result;
  end if;
end method concatenate-as;

define method member?(value :: <object>, vector :: <vector>,
		      #key test = \==)
  block (return)
    for (key from 0 below size(vector))
      if (test(value, vector[key])) return(#t) end if;
    end for;
  end block;
end method member?;

define method empty?(vector :: <vector>)
  size(vector) = 0;
end method empty?;

// No collection alignment done here because it only handles the
// all-vector case.
define method every?(proc :: <function>, vector :: <vector>,
		     #next next_method,
		     #rest more_vectors) => <object>;
  if (empty?(more_vectors))
    block (return)
      for (key from 0 below size(vector))
	unless (proc(vector[key])) return(#f) end unless;
      end for;
      #t;
    end block;
  elseif (every?(rcurry(instance?, <vector>), more_vectors))
    // since we only specify one sequence, this will not produce an infinite
    // recursion.
    block (return)
      let sz = reduce(method(a,b) min(a, size(b)) end method,
		      size(vector), more_vectors);
      for (key from 0 below size)
	let result = apply(proc, vector[key],
			   map(rcurry(element, key), more_vectors));
	unless (result) return(#f) end unless;
      end for;
      #t;
    end block;
  else
    next_method();
  end if;
end method every?;

define method subsequence-position(big :: <vector>, pattern :: <vector>,
				   #key test = \==, count = 1)
  let sz = size(big);
  let pat-sz = size(pattern);

  select (pat-sz)
    0 =>
      0;
    1 =>
      let ch = pattern[0];
      for (key from 0 below sz,
	   until test(big[key], ch) & (count := count - 1) <= 0)
      finally
	if (key < sz) key end if;
      end for;
    2 =>
      let ch1 = pattern[0];
      let ch2 = pattern[1];
      for (key from 0 below sz - 1,
	   until test(big[key], ch1) & test(big[key + 1], ch2)
	     & (count := count - 1) <= 0)
      finally
	if (key < (sz - 1)) key end if;
      end for;
    otherwise =>
      local method search(index, big-key, pat-key, count)
	      case
		pat-key >= pat-sz =>  // End of pattern -- We found one.
		  if (count = 1) index
		  else search(index + 1, index + 1, 0, count - 1);
		  end if;
		big-key = sz =>	      // End of big vector -- it's not here.
		  #f;
		test(big[big-key], pattern[pat-key]) =>
		  // They match -- try one more.
		  search(index, big-key + 1, pat-key + 1, count);
		otherwise =>          // Don't match -- try one further along.
		  search(index + 1, index + 1, 0, count);
	      end case;
	    end method search;
      search(0, 0, 0, count);
  end select;
end method subsequence-position;

define method subsequence-position(big :: <byte-string>,
				   pattern :: <byte-string>,
				   #key test = \==, count = 1)
  let sz = size(big);
  let pat-sz = size(pattern);

  select (pat-sz)
    0 =>
      0;
    1 =>
      let ch = pattern[0];
      for (key from 0 below sz,
	   until test(big[key], ch) & (count := count - 1) <= 0)
      finally
	if (key < sz) key end if;
      end for;
    2 =>
      let ch1 = pattern[0];
      let ch2 = pattern[1];
      for (key from 0 below sz - 1,
	   until test(big[key], ch1) & test(big[key + 1], ch2)
	     & (count := count - 1) <= 0)
      finally
	if (key < (sz - 1)) key end if;
      end for;
    otherwise =>
      if (test ~= \==)
	local method search(index, big-key, pat-key, count)
		case
		  pat-key >= pat-sz =>  // End of pattern -- We found one.
		    if (count = 1) index
		    else search(index + 1, index + 1, 0, count - 1);
		    end if;
		  big-key = sz =>      // End of big vector -- it's not here.
		    #f;
		  test(big[big-key], pattern[pat-key]) =>
		    // They match -- try one more.
		    search(index, big-key + 1, pat-key + 1, count);
		  otherwise =>         // Don't match -- try one further along.
		    search(index + 1, index + 1, 0, count);
		end case;
	      end method search;
	search(0, 0, 0, count);
      else
	// It's worth doing something Boyer-Moore-ish....
	let pat-last = pat-sz - 1;
	let last-char = pattern[pat-last];
	let skip = make(<vector>, size: 256, fill: pat-sz);
	for (i from 0 below pat-last)
	  skip[as(<integer>, pattern[i])] := pat-last - i;
	end for;
	local method do-skip(index, count)
		if (index >= sz)
		  #f;
		else 
		  let char = big[index];
		  if (char == last-char)
		    search(index - pat-last, index, pat-last, count);
		  else
		    do-skip(index + skip[as(<integer>, char)], count);
		  end if;
		end if;
	      end method,
              method search(index, big-key, pat-key, count)
		case
		  pat-key < 0 =>  // End of pattern -- We found one.
		    if (count = 1) index
		    else do-skip(index + pat-sz, count - 1)
		    end if;
		  big[big-key] == pattern[pat-key] =>
		    // They match -- try one more.
		    search(index, big-key - 1, pat-key - 1, count);
		  otherwise =>    // Don't match -- try one further along.
		    do-skip(index + pat-sz, count);
		end case;
	      end method search;
	do-skip(pat-last, count);
      end if;
  end select;
end method subsequence-position;

define method replace-elements!(vector :: <vector>,
				predicate :: <function>,
				new_value_fn :: <function>,
				#key count: count) => <vector>;
  for (key from 0 below size(vector),
       until count == 0)
    let this_element = vector[key];
    if (predicate(this_element))
      vector[key] := new_value_fn(this_element);
      if (count) count := count - 1 end if;
    end if;
  end for;
  vector;
end method replace-elements!;

// No collection alignment done here because it only handles the
// all-vector case.
define method do(proc :: <function>, vector :: <vector>,
		 #next next_method,
		 #rest more_vectors)
  if (empty?(more_vectors))
    for (key from 0 below size(vector)) proc(vector[key]) end for;
  elseif (every?(rcurry(instance?, <vector>), more_vectors))
    let size = reduce(method (sz, vec) min(sz, size(vec)) end method,
		      size(vector), more_vectors);
    for (key from 0 below size)
      apply(proc, vector[key],
	    map(rcurry(element, key), more_vectors));
    end for;
  else
    next_method();
  end if;
end method do;

define method fill!(vector :: <vector>, value :: <object>,
		    #key start: first = 0, end: last)
  let last = if (last) min(last, size(vector)) else size(vector) end if;
  for (i from first below last)
    vector[i] := value;
  end for;
end method fill!;

define method copy-sequence(vector :: <vector>, #key start = 0, end: last)
  let src-sz = size(vector);
  let last = if (last & last < src-sz) last else src-sz end if;
  let sz = last - start;
  let result = make(class-for-copy(vector), size: sz);
  for (src-index from start, index from 0 below sz)
    result[index] := vector[src-index];
  end for;
  result;
end method copy-sequence;


//// Array methods.

define method aref (vector :: <vector>, #rest indices)
  if (indices.size == 1)
    vector[indices[0]];
  else
    error("Invalid number of indices for %=.  Expected 1, got %d",
	  vector, indices.size);
  end;
end;

define method aref-setter (new, vector :: <vector>, #rest indices)
  if (indices.size == 1)
    vector[indices[0]] := new;
  else
    error("Invalid number of indices for %=.  Expected 1, got %d",
	  vector, indices.size);
  end;
end;

define method size (v :: <vector>) => size :: <integer>;
  error("The array method for size must be overridden by vectors.");
end;

define method dimensions (v :: <vector>) => dimensions :: <sequence>;
  vector (size (v));
end method dimensions;


//// Special purpose element setter methods.

define method element-setter (value, v :: <byte-vector>, index :: <integer>)
  error("%= is not an integer between 0 and 255.", value);
end;

define method element-setter (value, v :: <buffer>, index :: <integer>)
  error("%= is not an integer between 0 and 255.", value);
end;

