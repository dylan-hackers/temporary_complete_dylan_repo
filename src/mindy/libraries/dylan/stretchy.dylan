module: dylan

//////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 1993, 1994, Carnegie Mellon University
//  All rights reserved.
//
//  This code was produced by the Gwydion Project at Carnegie Mellon
//  University.  If you are interested in using this code, contact
//  "Scott.Fahlman@cs.cmu.edu" (Internet).
//
//////////////////////////////////////////////////////////////////////
//
//  $Header: /home/housel/work/rcs/gd/src/mindy/libraries/dylan/stretchy.dylan,v 1.8 1994/06/11 02:15:01 wlott Exp $
//
//  This file implements stretchy-vectors.
//


//// <stretchy-vector>

define class <stretchy-vector> (<stretchy-collection>, <vector>)
  //
  // No slots in the abstract class <stretchy-vector>
end class <stretchy-vector>;

define method make(cls == <stretchy-vector>, #rest keys, #all-keys)
  apply(make, <simple-stretchy-vector>, keys);
end method;



//// <simple-stretchy-vector>

define class <simple-stretchy-vector> (<stretchy-vector>)
  slot ssv-data :: <simple-object-vector>, init-keyword: data:;
  slot ssv-fill :: <integer>, init-keyword: fill:;
end class <simple-stretchy-vector>;
  

define method make(cls == <simple-stretchy-vector>,
		   #next next-method,
		   #key size: sz = #f, fill, dimensions)
  if (sz & dimensions)
    error("Can't supply both a size: and dimensions:");
  else
    let size = case
		 sz => sz;
		 ~dimensions => 0;
		 size(dimensions) = 1 =>
		   first(dimensions);
		 otherwise =>
		   error("Vectors can only have one dimension.");
	       end case;
    let data-size = case
		      size < 0 =>
			error("size: can't be negative.");
		      size < 16 => 16;
		      size < 1024 =>
			for (data-size = 16 then data-size * 2,
			     until size < data-size)
			finally data-size;
			end for;
		      otherwise =>
			ceiling(size + 1024, 1024) * 1024;
		    end case;
    let data = make(<simple-object-vector>, size: data-size);
    fill!(data, fill, end: data-size);
    next-method(cls, fill: size, data: data);
  end if;
end method make;

define method size(ssv :: <simple-stretchy-vector>) => <integer>;
  ssv-fill(ssv);
end method size;

define method size-setter(new :: <integer>, ssv :: <simple-stretchy-vector>)
  let fill = ssv-fill(ssv);
  let data = ssv-data(ssv);
  if (new > fill)
    let len = size(data);
    if (new > len)
      let new-len = if (new < 1024)
		      for (new-len = 16 then new-len * 2,
			   until new < new-len)
		      finally new-len;
		      end for;
		    else 
		      ceiling(new + 1024, 1024) * 1024;
		    end if;
      let new-data = make(<simple-object-vector>, size: new-len);
      for (index from 0 below fill)
	new-data[index] := data[index];
      end for;
      ssv-data(ssv) := new-data;
    end if;
    fill!(data, #f, start: fill);
  else
    fill!(data, #f, start: new, end: fill);
  end if;
  ssv-fill(ssv) := new;
end method size-setter;

define method dimensions(ssv :: <simple-stretchy-vector>) => <list>;
  list(size(ssv));
end method dimensions;


define constant ssv_no_default = pair(#f, #f);

define method element(ssv :: <simple-stretchy-vector>, key :: <integer>,
		      #key default = ssv_no_default)
  case
    key >= 0 & key < size(ssv) =>
      ssv-data(ssv)[key];
    default == ssv_no_default =>
      error("Element %d not in %=", key, ssv);
    otherwise =>
      default;
  end case;
end method element;

define method element-setter(value, ssv :: <simple-stretchy-vector>,
			     key :: <integer>)
  if (key < 0)
    error("Element %d not in %=", key, ssv);
  else
    if (key >= size(ssv))
      size(ssv) := key + 1;
    end if;
    ssv-data(ssv)[key] := value;
  end if;
end method element-setter;

define method add!(ssv :: <simple-stretchy-vector>, new-element)
  let data = ssv-data(ssv);
  let fill = size(ssv);
  if (fill = size(data))
    let data-size = if (fill < 1024)
		      fill * 2;
		    else 
		      fill + 1024;
		    end if;
    let new-data = replace-subsequence!(make(<simple-object-vector>,
					     size: data-size),
					data, end: fill);
    ssv-data(ssv) := new-data;
    new-data[fill] := new-element;
  else 
    data[fill] := new-element;
  end if;
  ssv-fill(ssv) := fill + 1;
  ssv;
end method add!;

define method remove!(ssv :: <simple-stretchy-vector>, elem,
		      #key test = \==, count)
  unless (count & (count = 0))
    let data = ssv-data(ssv);
    let sz = size(ssv);
    local
      method copy(src, dst, deleted)
	case
	  src = sz =>
	    ssv-fill(ssv) := sz - deleted;
	  otherwise =>
	    data[dst] := data[src];
	    copy(src + 1, dst + 1, deleted);
	end case;
      end method copy,
      method search-and-copy(src, dst, deleted)
	if (src = sz)
	  ssv-fill(ssv) := sz - deleted;
	else 
	  let this-element = data[src];
	  case
	    test(this-element, elem) =>
	      let deleted = deleted + 1;
	      if (count & (deleted = count))
		copy(src + 1, dst, deleted);
	      else
		search-and-copy(src + 1, dst, deleted);
	      end if;
	    otherwise =>
	      data[dst] := data[src];
	      search-and-copy(src + 1, dst + 1, deleted);
	  end case;
	end if;
      end method search-and-copy,
      method search(src)
	unless (src = sz)
	  let this-element = data[src];
	  if (test(this-element, elem))
	    if (count & (count = 1))
	      copy(src + 1, src, 1);
	    else 
	      search-and-copy(src + 1, src, 1);
	    end if;
	  else
	    search(src + 1);
	  end if;
	end unless;
      end method search;

    search(0);
  end unless;
  ssv;
end method remove!;

define method map-into(destination :: <stretchy-vector>,
		       proc :: <function>, sequence :: <sequence>,
		       #next next_method, #rest more_sequences)
  if (empty?(more_sequences))
    let sz = size(sequence);
    if (sz > size(destination)) size(destination) := sz end if;
    let data = ssv-data(destination);
    for (key from 0, elem in sequence)
      destination[key] := proc(elem);
    end for;
    destination;
  else
    next_method();
  end if;
end method map-into;
