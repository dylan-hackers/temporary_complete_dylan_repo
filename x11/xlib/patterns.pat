
!  Given a C header file, generate corresponding Dylan C-FFI declarations.
!
!  This file defines a set of text transformation rules for "gema".
!
!  This supports the common functionality needed for the Microsoft Windows
!  and X Windows header files, but is not expected to handle the full
!  C language.

! Copyright (c) 1998 Functional Objects, Inc.  All rights reserved.

! $HopeName$
! $Date: 2004/03/12 00:10:34 $

@set-switch{t;1}@set-switch{w;1}
@set-syntax{L;\-\.\(\)}
@set-switch{match;1}

! command-line option for name of module:
ARGV:\N-module <G>\n=@set{heading;module\: $1\n\n}

! command-line option for file of names to be excluded:
ARGV:\N-exclude <G>\n=@load-obsolete{@read{$1}}

! command-line option for literal name(s) to be excluded:
ARGV:\N-omit *\n=@load-obsolete{$1}

load-obsolete:<wildcard>\I=@define{relevant-name\:$1\=\@fail}\
	@define{bad-struct\:_$1\=\$0\@end}
load-obsolete:<K1>\J<J1>\J<I>=\
	@define{relevant-function\:@quote{$0}\\J\<opta\>\\I\=\@fail}
load-obsolete:<K><-A0><i>=@define{relevant-name\:@quote{$1$3}\=\@fail}\
	@define{bad-struct\:@quote{_$1$3}\=\$0\@end}
load-obsolete:<I>=@define{relevant-name\:@quote{$1}\=\@fail}
load-obsolete:\S=;,=
load-obsolete:\/\/*\n=
load-obsolete:\/\*<comment>\*\/=
load-obsolete:<G>= @err{\N"@file" line @line, unrecognized: $1\n}

! command-line option to specify that only those names listed in
! a file are to be translated.
ARGV:\N-only <G>\n=@set-switch{t;0}\
	@load-only{@read{$1}}@undefine{relevant-name\:\<I\>}\
	@define{bad-struct\:\_\<relevant-name\>\\I\=\@fail}\
	@define{bad-struct\:tag\<relevant-name\>\\I\=\$0\@fail}\
	@define{nogood\:\\W\<relevant-name\>\=\$1\@fail}

! additional identifiers to be included (after -only file)
ARGV:\N-add *\n=@load-only{$1}

load-only:<wildcard>\I=@define{relevant-name\:$1\=\$0\@end}
load-only:<K1>\J<J1>\J<I>=\
	@define{relevant-function\:$0\<opta\>\\I\=\$0\@end}
load-only:<K1><k3>\J_\J<K>\I=\
	@define{relevant-constant\:$1$2_\<K\>\<d\>\\I\=\$0\@end}\
	@define{relevant-name\:$0\=\$0\@end}
load-only:<I>=@define{relevant-name\:$1\<opta\>\\I\=\$0\@end}
load-only:\S=;,=
load-only:\/\/*\n=
load-only:\/\*<comment>\*\/=
load-only:<G>= @err{\N"@file" line @line, unrecognized: $1\n}

opta:\JA=A@end;=@end

! optional name of generated export file:
ARGV:\N-exports <G>\n=@set{-exports;$1}

wildcard:\*<-I>=@fail
wildcard:\?<-I>=@fail
wildcard:<i>\J\*<morewild>=@quote{$1}\\J\<I\>$2
wildcard:<i>\J\?<morewild>=@quote{$1}\\J\<I1\>$2\\I
wildcard:<S0>=@terminate
wildcard:=@terminate
morewild:<I>=\\J@quote{$1}
morewild:<S0>=@end
morewild:=@end

! change underscores to hyphens:
map-name:\J_\J=-;?=?

@set-wrap{70;\t}
! use variable x to avoid duplication of Foo for FooA and FooW
@set{x;}
export:\A$x\Z=$x
export:*=@set{x;@map-name{$1}}$x\
	@write{${export-file};${export-head}@wrap{ $x}}\
	@set{export-head;\,}@set{export-tail;\;\n}

export-end:=@write{${export-file};${export-tail;}}\
	@set{export-head;  export}@set{export-tail;}

\B=@var{heading;@err{Missing -module\n}}@bind{heading;}\
 @set{O;@outpath}@err{\ @file -\> @relative-path{$O;$O} ...\n}\
 \/\/ This file is automatically generated from \"@file\"\; do not edit.\n\n\
 @bind{export-file;@var{-exports;@mergepath{@outpath;@file;.exp}}}\
 @bind{export-head;  export}@bind{export-tail;}\
 @write{${export-file};\n\ \ \/\/ from \"@file\"\:\n}

close-export:=@export-end{}\
	@cmps{${-exports;};${export-file};@close{${export-file}};;}\
	@unbind{export-file}@unbind{export-head}@unbind{export-tail}

\E=\N\n${defer;}@set{defer;}@close-export{}@unbind{heading}

! hack to keep export list from getting too long:
\N\/\*\n<P>\n\*\/\n=@export-end{}
\n\n\n=@export-end{}
\n\n\Ptypedef=@export-end{}
\/\/\n\/\/\L<P>\n\G\/\/\n=@export-end{}

\B\W\/\*<Y2><comment>\n<header>\*\/=\n\/\/ Adapted from\:\n$0\n
header:\L\CCopyright*\n=\N

\/\J\/*\n=
\/\J\*<comment>\*\J\/=
comment:\/\J\*<comment>\*\J\/=
comment:\/\J\/\P\L*\*\J\/=\/\ \/! To fix BUG 395

! optional space
space:\/\J\/*\n= $0
space:\/\J\*<comment>\*\J\/= $0 ;
space:<S>=$1
space:\N\W\#*\n=$0
space:=@end

\"<string>\"=
string:\\?=\\?
\'<char>\'=
char:\\?=\\?@end;?=?@end

matchparen:(#)=(#)
matchparen:\{#\}=\{#\}
matchparen:\/\J\*<comment>\*\J\/=
matchparen:\/\J\/*\n=
matchparen:\"<string>\"=$0
matchparen:\'<char>\'=$0
matchparen:\#if\J*\n<matchcond>\G\#e\J*\n=$0
matchparen:\P\)=@end
matchparen:\P\}=@end

! this one preserves comments
matchparen2:\/\J\*<comment>\*\J\/=$0
matchparen2:\/\J\/*\n=$0
matchparen2::matchparen


! ---- data types ----

type:struct _\J<I>\W<stars>\W<L0>=@resolve-type{$2$1}@end
type:struct tag\J<I>\W<stars>\W<L0>=@resolve-type{$2$1}@end
type:struct <I>\W<stars>\W<L0>=@resolve-type{$2$1}@failed{error type struct $1}@end
type:struct=@fail
type:const <type>= \/\* const \*\/ $1@end
type:CONST <type>= \/\* const \*\/ $1@end
type:int<stars>=\<C-int$1\>@end
type:unsigned long<stars>=\<C-both-unsigned-long$1\>@end
type:signed long<stars>=\<C-both-signed-long$1\>@end
type:unsigned short<stars>=\<C-unsigned-short$1\>@end
type:unsigned char<stars>=\<C-unsigned-char$1\>@end
type:signed char<stars>=\<C-signed-char$1\>@end
type:unsigned int<stars>=\<C-unsigned-int$1\>@end
type:unsigned<stars>=\<C-unsigned-int$1\>@end
type:long int<stars>=\<C-both-long$1\>@end
type:long<stars>=\<C-both-long$1\>@end
type:short int<stars>=\<C-short$1\>@end
type:short<stars>=\<C-short$1\>@end
type:float<stars>=\<C-float$1\>@end
type:double<stars>=\<C-double$1\>@end
type:\Cchar\W\*<stars>=\<C-string$1\>@end
type:wchar_t\W\*<stars>=\<C-unicode-string$1\>@end
type:char<stars>=\<C-char$1\>@end
type:void<stars>=\<C-void$1\>@end
type:0\J=@fail!  0xFFL is not an identifier
type:<I><stars>=@resolve-type{$2$1}@end
type:\/\*<comment>\*\/\W=
type:=@fail

stars:\*=\*
stars:const= \/\* const \*\/ ;
stars:\S=
stars:volatile=
stars:=@end

resolve-type:\A\ \/\**\*\/\W=\I\/\**\*\/\ \<
resolve-type:\A=\<
resolve-type:\Z=\>
resolve-type:\J_\J=-
resolve-type:\*<ptr-type>=$1
resolve-type:\*<space><K><f>=$2@map-name{$3}\*
resolve-type:\*<stars><I>=@map-name{$2}\*$1\
	@err{Warning - possible undefined type\: \<@map-name{$2}\*$1\>\n}
resolve-type:\/\**\*\/=
resolve-type:<A>=$1
resolve-type:\S=
resolve-type:?<g>=@failed{error resolve-type $0}@end

ptr-type:\S=\S
ptr-type:\/\**\*\/=$0
ptr-type:=@fail

! function types:
typedef <type>(<link>\*\W<relevant-name>)(\W<typelist>)\;=\
  \Ndefine constant @export{\<$3\>} \=\
	\S\<C-function-pointer\>\;\n

! general type equivalence:
typedef <ctype>\G\W<optstars>\G\W<I>,<matchparen>\;=\
	@{typedef $1\I$2$3\;typedef $1\I$4\;}
typedef <L><i> <relevant-name>\G\W\;=\
	\Ndefine inline constant @export{@type{$3}} \= @type{$1$2}\;\n
typedef <type>\W<relevant-name>\G\W\;=@do-typedef{$2\d$1}

do-typedef:*\d*=\Ndefine inline constant @export{@type{$1}} \= $2\;\n


ctype:\Cconst\W=$0
ctype:unsigned\W=$0
ctype:signed\W=$0
ctype:struct <I>=$0@end
ctype:struct=@fail
ctype:<I>=\I$1@end
ctype:\S=\I;=@fail

optstars:\*=\*
optstars:\S=\I
optstars:=@end

typelist:<type>\W<i>=$1
typelist:\/\J\*<comment>\*\J\/=
typelist:,=,\s;\S=;<G>=@failed{error typelist $1}@fail

! ---- constants ----

typedef<space>enum <bad-struct><space>\{<matchparen>\}<nogood><matchparen>\;=
typedef<space>enum\W<i><space>\{\W<enumbody>\}\W<i>=\N\/\/ enum $5\:\n$4\n\
	@set{prev;-1}@cmps{$5;;;;@define{type\:$5\<stars\>=\<C-int\$1\>\@end}}
enumbody:\/\/*\n=
enumbody:\/\*<comment>\*\/=
enumbody:<S>=
enumbody:<I>\W\=\W<number>=define inline-only constant @export{\$$1} \= \
		$2\;\n@set{prev;$2}
enumbody:<I>\W\=\W<I><space><term>=\
	define inline-only constant @export{\$$1} \= \$$2\;\n@set{prev;\$$1}
enumbody:<I><space><term>=define inline-only constant @export{\$$1} \= \
	${prev;-1} + 1\;\n@set{prev;\$@map-name{$1}}
enumbody:,=
enumbody:<G>=@failed{error enumbody $1}

term:,=@end;\P\;=@end;\P\}=@end;\P\)=@end;\S=;=@fail

number:<D>\J<optL>\W\<\<\W<number>=ash($1,$3)@end
number:(int)\W<signed-number>=$1@end
number:0x0\J<X7><optL>\I=\#x0$1@end
number:\C0xFFFFFFFF\J<optL>\I=\$FFFFFFFF@end
number:0x\J<X8><optL>\I=as(\<machine-word\>, \#x$1)@end

number:(<I>\W\|<or-args>)=logior(@number{$1},$2)@end
number:(<type>)\W<number>=c-type-cast($1,$2)@end
number:(\W)=@fail
number:(\W<number>\W)=$1@end
number:-\W<number>=-$1@end
number:\~\W<number>=lognot($1)@end
number:0x\J<X><optL>\I=\#x$1@end
number:0\J<O><optL>\I=\#o$1@end
number:int=@fail
number:<D><optL>\I=$1@end
number:<I>\L\W/[-+*]/\W<D>=\$@map-name{$1} $2 $3@end
number:<I>\L\W\P<termchar>\G=\$@map-name{$1}@end
number:=@fail
optL:\C\JU\J=
optL:\C\JL\J=
optL:=@end

signed-number:\C0xFFFFFFFF\J<optL>\I=lognot(0)@end
signed-number:(\W#\W)=$1@end
signed-number::number

or-args:\|=,
or-args:\S=
or-args:\\\n=
or-args:<number>=\S$1
or-args:=@fail

termchar:,=@end;\;=@end;\]=@end;\)=@end;\}=@end;\#=@end;\|=@end;=@fail

\#define\L <defn>=\N$1\N
defn:\N=@terminate;=@fail
defn:<K>\L <reqlink><endline>=\
  @define{link\:\\I$1\\I\=@quote{$2}\@end}@end

! try to avoid forward references:
defn:\L<relevant-constant>\G <symconst>\W<endline>=@append{defer;\
    define inline-only constant @export{\$$1} @tab{42}\=@wrap{\s$2\;}\n}@end
symconst:<K>\J_\J<I>=\$@map-name{$1_$2}@end
symconst:=@fail

! general case for numeric constants:
defn:\L<relevant-constant>\G <number>\W<endline>=\
	\Ndefine inline-only constant @export{\$$1} @tab{57}\=\
		@wrap{\s@right{4;$2}\;}\n@end

! string constants in COMMDLG.H and COMMCTRL.H
defn:\L<relevant-constant>\JA \"<string>\"<endline>=\
	\Ndefine constant @export{\$$1} @tab{32} \=@wrap{\ \"$2\"\;}\n@end

relevant-constant:NULL\I=@fail
relevant-constant:TRUE\I=@fail
relevant-constant:FALSE\I=@fail
relevant-constant::relevant-name
relevant-name:FLOAT=@fail! don't try to redefine Dylan <float>
relevant-name:<I>=$1@end
relevant-name:=@fail

endline:\/\/*\n=@end
endline:\/\*<comment>\*\/=
endline:\n=@end
endline:^M^J=@end
endline:\s=;\t=
endline:=@fail

! ---- functions ----


link:=@end
reqlink:<link>=$1@terminate


args:,=;\S=
args:...=\ \ varargs \;\n@fail! C-FFI doesn't implement this yet (Bug 4176) ???
args:va_list=@fail! don't know how to handle this yet ???

args:\#if\I\W<false-flag><endline><matchcond><elsepart>=@args{$4}
args:\#if\I\W<true-flag><endline><matchcond><elsepart>=@args{$3}

! special case for output parameters:
args:<scalar>\G\W\*\W<outok>=@outparm{$1\* $2}
outparm:<type>\W<I>=\ \ output @putparm{$2,$1}
outparm:*=@failed{error outparm *}

putparm:<G>,*=parameter @map-name{$1} @tab{24}\:\: $2\;\n
putparm:,*=parameter @argname{$1} @tab{24}\:\: $1\;\n

! general case:
args:<type>\W<arg-id>=\ \ @putparm{$2,$1}
args:void<space>=@end

args:\/\J\*<comment>\*\J\/=
args:\/\J\/*\n=
args:<P1>*\,=@failed{error args $0}@fail
args:<P1>*\P\)=@failed{error args $0}@fail

arg-id:<I>=$1@end
arg-id:<space><I>=$1@end
arg-id:\/\*\W<I>\W\*\/=$1@end
arg-id:=@end

argname:\/\*<comment>\*\/=
argname:\*=P
argname:<I>=@downcase{$1}
argname:\<C-=
argname:?=
argname:\Z=${argnum}@incr{argnum}
args:\A=@set{argnum;1}

failed:\Cerror\W=@exit-status{1}
failed:\Cwarning\W=
failed:<F> <U40><i20>=\
 @err{\N"@file" line @line, failed match for $1\: $2$3...\n}@end
failed:<F> *=\
 @err{\N"@file" line @line, failed match for $1\: $2\N}@end

result:\<C-void\>=
result:*=\ \ result value \:\: $1\;\n

! scalar data types:
scalar:int=$0@end
scalar:long=$0@end
scalar:short=$0@end
scalar:unsigned =$0
scalar:signed =$0
scalar:=@fail

outok:<I>=$1@end
outok:=@fail


! ---- structures ----

! don't want these
typedef<space>struct <bad-struct><space>\{<matchparen>\}<nogood><matchparen>\;=
typedef union <bad-struct><space>\{<matchparen>\}<nogood><matchparen>\;=
bad-struct:<relevant-name>=$1@fail
bad-struct:<I>=@end
bad-struct:=@fail
nogood:=@end

@set{packing;}
\#pragma pack(<D>)=@set{packing;\ \ pack\:\ $1\;\n}
\#pragma pack(push,<D>)=@push{packing;\ \ pack\:\ $1\;\n}
\#pragma pack(push)=@push{packing;${packing}}
\#pragma pack(pop)=@pop{packing}
\#include \C<Y1>pshpack\J<D>\.h<Y1>=@push{packing;\ \ pack\:\ $2\;\n}
\#include \C<Y1>poppack.h<Y1>=@pop{packing}

map-ptr-name:*=@map-name{*}\*

typedef<space>struct\I\W<i><space>\{<matchparen2>\}\W<relevant-name><term>*\;=\
	@bind{fields;@fields{$4}}\N\n@bind{sclass;@map-name{$5}}\
	define C-struct @export{\<${sclass}\>}\n${fields}\N${packing}\
	@define{ptr-type\:\\J@quote{$5}\=@quote{@map-ptr-name{${sclass}}}}\
	\ \ pointer-type-name\: @export-ptr{\<@map-ptr-name{${sclass}}\>}\;\n\
	@cmps{$2;;;;\ \ c-name\: \"struct $2\"\;\n}\
	end C-struct \<${sclass}\>\;\
	\N@styps{*}\N@unbind{sclass}@unbind{fields}
typedef union\I\W<i><space>\{<fields>\}\W<relevant-name><term>*\;=\N\n\
	@bind{sclass;@map-name{$4}}\
	define C-union @export{\<${sclass}\>}\n$3\N${packing}\
	end C-union \<${sclass}\>\;\
	\N@styps{*}\N@unbind{sclass}
fields:\S=
fields:\/\J\/*\n=
fields:\/\J\*<comment>\*\J\/\W=
fields:<I> <I>\[\W<number>\]<space>\;=\
	\ \ sealed inline-only array slot @export{$2-array} @tab{42}\:\:\
	@wrap{\ @type{$1},}@wrap{\ length\: $3,}\
	@ignore{@export{$2-array-setter}}\
	@wrap{\ address-getter\: @export{$2-value}\;}\n
! a 1-bit field will never need to be a <machine-word>.
fields:int <I>\W\:\W<D1><space>\;=\
	\ \ sealed bitfield slot @export-slot{$1} @tab{40}\:\:\
	@wrap{\ \<C-unsigned-int\>, width\: $2\;}\n
fields:<I> <I>\W\:\W<D><space>\;=\
	\ \ sealed bitfield slot @export-slot{$2} @tab{42}\:\:\
	@wrap{\ @type{$1}, width\: $3\;}\n
fields:<type>\G\W<I><space>\;=\
	\ \ sealed inline-only slot @export-slot{$2} @tab{42}\:\: $1\;\n
fields:<ctype>\G\W<I>,<matchcond>\;=\
   \ \ sealed inline-only slot @export-slot{$2} @tab{42}\:\: @type{$1}\;\n\
   @fields{$1 $3\;}
fields:\#if\I\W<false-flag><endline><matchcond><elsepart>=@fields{$4}
fields:\#if\I\W<true-flag><endline><matchcond><elsepart>=@fields{$3}
fields:\#ifdef <undef-flag><endline><matchcond><elsepart>=@fields{$4}
fields:\#ifdef <def-flag><endline><matchcond><elsepart>=@fields{$3}
fields:\#ifndef <undef-flag><endline><matchcond><elsepart>=@fields{$3}
fields:\#ifndef <def-flag><endline><matchcond><elsepart>=@fields{$4}
@set{gencount;0}
fields:union\I\W<i>\{<fields>\}\W<I>\W<matchparen>\;=@incr{gencount}\
	@out{define C-union \<$3\%${gencount}\>\n$2\N${packing}\
	     @cmps{$1;;;;\ \ c-name\: \"union $1\"\;\n}\
	     end\;\n}\
	@emit-slots{,$3 $4\d\<$3\%${gencount}\>}
fields:struct\I\W<i>\{<fields>\}\W<I>\W<matchparen>\;=@incr{gencount}\
	@out{define C-struct \<$3\%${gencount}\>\n$2\N${packing}\
	     @cmps{$1;;;;\ \ c-name\: \"struct $1\"\;\n}\
	     end\;\n}\
	@emit-slots{,$3 $4\d\<$3\%${gencount}\>}
emit-slots:\d=@end
emit-slots:\S=
emit-slots:,<space><I>\W*\d*=\
	\ \ sealed inline-only slot @export{$2-value} @tab{42}\:\:\
		\ $4, setter\: \#f\;\n\
	@emit-slots{$3\d$4}
fields:union\{<fields>\}\G\;=@incr{gencount}\
	@out{define C-union \<u\%${gencount}\>\n$1\N${packing}end\;\n}\
       \ \ sealed inline-only slot @export-slot{u} @tab{42}\:\:\
		\ \<u\%${gencount}\>\;\n
fields:struct\{<fields>\}\G\;=@incr{gencount}\
	@out{define C-struct \<s\%${gencount}\>\n$1\N${packing}end\;\n}\
       \ \ sealed inline-only slot @export-slot{u} @tab{42}\:\:\
		\ \<s\%${gencount}\>\;\n
fields:*\n=@failed{warning fields *}@fail

export-slot:\Cspare\J*=$0@end
export-slot:*\JReserved\J*=*Reserved*@end
export-slot:*=@export{$1-value}@ignore{@export{$1-value-setter}}@end

export-ptr:*=@export{$1}@append{defer;\
  define sealed domain make (singleton($1))\;\n\
  define sealed domain initialize ($1)\;\n}

ignore:=@end

make-list:\W<D>\W\Z=\#($1)
make-list:*=list(*)

styps:\S=
styps:<I>=define inline constant @export{\<$1\>} \= \<${sclass}\>\;\n
styps:\*<I>=@do-typedef{$1\d\<@map-ptr-name{${sclass}}\>}
styps:\,=

strip-angle-brackets:\<<G>\>=$1

! ---- conditionals ----

elsepart:\#endif=@end
elsepart:\#else <matchcond>\#endif=$1@end
elsepart:\#elif<true-flag><endline><matchcond><elsepart>=$3@end
elsepart:\#elif\W<false-flag><endline><matchcond>\P\#e\J=
elsepart:=@fail

def-flag:=@fail
ARGV:\N-D\J\W<I>\n=@define{def-flag\:$1\=\$0\@end}@undefine{undef-flag\:$1}

\#ifdef <def-flag><endline><matchcond><elsepart>=@{$3}
\#ifndef <def-flag><endline><matchcond><elsepart>=@{$4}

\#if\I\W<false-flag><endline><matchcond><elsepart>=@{$4}
\#if\I<true-flag><endline><matchcond><elsepart>=@{$3}

false-flag:0=$0@end
false-flag:FALSE=$0@end
false-flag:defined(\W<undef-flag>)=$1
false-flag:\!defined(\W<def-flag>)=$1
false-flag:\!(\L\W<true-flag>)=$0
false-flag:(#)=$1
false-flag:(<true-flag>)\&\&(\W<false-flag>)=$0
false-flag:\&\&\L<matchparenline>=@end
false-flag:\|\|=$0
false-flag:\L<S>=
false-flag:=@terminate

true-flag:defined(\W<def-flag>)=$1
true-flag:\!defined(\W<undef-flag>)=$1
true-flag:\!(\L\W<false-flag>)=$0
true-flag:(<matchparen>)\|\|<true-flag>=$2
true-flag:(#)=$1
true-flag:\|\|\L<matchparenline>=@end
true-flag:\&\&=$0
true-flag:\L<S>=
true-flag:=@terminate

matchparenline:\P\n=@end
matchparenline::matchparen

\#ifdef <undef-flag><endline><matchcond><elsepart>=@{$4}
\#ifndef <undef-flag><endline><matchcond><elsepart>=@{$3}

undef-flag:_MIPS_=@end
undef-flag:_PPC_=@end
undef-flag:_MPPC_=@end
undef-flag:_ALPHA_=@end
undef-flag:_MAC=@end
undef-flag:_68K_=@end
undef-flag:__cplusplus=@end

undef-flag:=@fail
ARGV:\N-U\J\W<I>\n=@define{undef-flag\:$1\=\$0\@end}@undefine{def-flag\:$1}

matchcond:\#if\J*\n<matchcond>\G\W<elsecond>=$0
matchcond:\P\#endif=@end
matchcond:\P\#else=@end
matchcond:\P\#elif<true-flag><endline>=@end
matchcond:\#elif\W<false-flag><endline><matchcond>=
matchcond:\#*\n=$0
elsecond:\#endif<endline>=$0\n@end
elsecond:\#else <matchcond>\#endif<endline>=$0\n@end
elsecond:\#elif<true-flag><endline><matchcond>\W<elsecond>=$3@end
elsecond:=@fail


! ---- defaults ----

\N\W\#*\n=
<I>=
\S=


