module: vector-math

//define constant <3D-vector> = limited(<vector>, of: <float>, size: 3);
//define constant <3D-point>  = limited(<vector>, of: <float>, size: 4);

define constant <3D-rotation> = <simple-object-vector>;  // 4 elements, first 3 are axis, 4th is rotation amount
define constant <color> = <simple-object-vector>; // r,g,b
define constant <3D-vector> = <simple-object-vector>;
define constant <3D-point>  = <simple-object-vector>;
define constant 3d-vector   = vector;
define constant 3d-point    = vector;
define constant 3d-rotation = vector;
define constant color = vector;

// General vector math

// what's the general definition of the cross product in an
// n-dimensional room?
define inline method cross-product
    (u :: <simple-object-vector>, v :: <simple-object-vector>)
 => (cross-product :: <simple-object-vector>)
  let result = make(type-for-copy(u), size: u.size);
  local method cp(i, j) u[i] * v[j] - v[i] * u[j] end;
  result[0] := cp(1, 2);
  result[1] := cp(2, 0);
  result[2] := cp(0, 1);
  result;
end method cross-product;

define inline method \+(u :: <simple-object-vector>, v :: <simple-object-vector>)
 => (sum :: <simple-object-vector>)
  map(\+, u, v)
end method;

define inline method \-(u :: <simple-object-vector>, v :: <simple-object-vector>)
 => (difference :: <simple-object-vector>)
  map(\-, u, v)
end method;

define inline method negate(u :: <simple-object-vector>)
 => (negation :: <simple-object-vector>)
  u * -1
end method;

define inline method \*(u :: <simple-object-vector>, v :: <number>)
 => (product :: <simple-object-vector>)
  map(rcurry(\*, v), u)
end method;

define inline method \*(u :: <number>, v :: <simple-object-vector>)
 => (product :: <simple-object-vector>)
  map(curry(\*, u), v)
end method;

define inline method \*(u :: <simple-object-vector>, v :: <simple-object-vector>)
 => (dot-product :: <number>)
  reduce1(\+, map(\*, u, v))
end method;

define inline method \/(u :: <simple-object-vector>, v :: <number>)
 => (product :: <simple-object-vector>)
  map(rcurry(\/, v), u)
end method;

define inline method \/(u :: <number>, v :: <simple-object-vector>)
 => (product :: <simple-object-vector>)
  map(curry(\/, u), v)
end method;

define inline method magnitude(v :: <simple-object-vector>)
 => (length :: <number>)
  sqrt(v * v)
end method magnitude;

define inline method normalize(v :: <simple-object-vector>)
 => (normalized-vector :: <simple-object-vector>)
  v / magnitude(v)
end method normalize;

// useful geometric operations

define inline function proj(p :: <simple-object-vector>, q :: <simple-object-vector>)
  => (projection-of-p-on-q :: <simple-object-vector>)
  ((p * q) / (q * q)) * q
end function proj;

define inline function perp(p :: <simple-object-vector>, q :: <simple-object-vector>)
  => (component-of-p-perpendicular-to-q :: <simple-object-vector>)
  p - proj(p, q)
end function perp;

define method gram-schmidt-orthogonalization(basis :: <simple-object-vector>)
 => (orthoginalized-basis :: <simple-object-vector>)
  let new-basis = make(type-for-copy(basis), size: basis.size);

  new-basis[0] := basis[0];

  for(i from 1 below basis.size)
    new-basis[i] := basis[i] 
      - reduce1(\+, map(curry(proj, basis[i]), 
                        subsequence(basis, end: i - 1)));
  end for;
  new-basis
end method gram-schmidt-orthogonalization;
