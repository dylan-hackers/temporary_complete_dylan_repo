module: dylan-user
copyright: this program may be freely used by anyone, for any purpose

define library icfp2000
  use common-dylan;
  use io;
  use transcendental;
end library;

define module types
  use dylan;
  use transcendental;
  
  export <fp>, $pi,
     <point>, point-x, point-y, point-z; //XXX
end module types;

define module our-matrix
  use dylan;
  use transcendental;
  
  use types;
  
  export <3D-vector>, <3D-point>, <transform>, 
    $origin,
    make-identity, $origin, vector3D, point3D,
    homogenize, normalize, magnitude,
    v00, v01, v02, v03, v00-setter, v01-setter, v02-setter, v03-setter,
    v10, v11, v12, v13, v10-setter, v11-setter, v12-setter, v13-setter,
    v20, v21, v22, v23, v20-setter, v21-setter, v22-setter, v23-setter,
    v30, v31, v32, v33, v30-setter, v31-setter, v32-setter, v33-setter,
    x, y, z, w;
end module our-matrix;

define module gml-lexer
  use Dylan;
  use common-dylan;
  use standard-io;
  use streams;
  use format;
  use Extensions,
    import: {<extended-integer>, ratio, <false>};

  export lex-gml;
end module gml-lexer;

define module ray-tracer
  use dylan;
  use transcendental;
  use extensions;

  // Debug:
  use streams;
  use format;
  use format-out;
  use standard-io;
  // End debug...

  use types;
  use our-matrix;

  export <obj>, <sphere>, <plane>, <cube>, <cylinder>, <cone>,
    <csg-union>,
    <star>, <firefly>, <flashlight>,
    <color>, export-with-depth, 
    uniform-scale, scale, x-rotate, y-rotate, z-rotate, translate,
    render-image;

  create <ppm-image>, close-ppm, write-pixel;

end module ray-tracer;

define module gml-compiler
  use Dylan;
  use Transcendental;
  use Extensions,
    import: {false-or};
  use format-out, rename: {format-out => debug-print};

  use types;
  use ray-tracer;
  use our-matrix;

  export compile-gml, run-gml;
end module gml-compiler;

define module icfp2000
  use common-dylan;
  use format-out;
  use format;
  use streams;
  use print;
  use standard-io;
  use extensions, import: {report-condition};

  use gml-lexer;
  use gml-compiler;
  use ray-tracer;
  use our-matrix;
end module;
