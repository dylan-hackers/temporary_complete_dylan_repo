/**********************************************************************\
*
*  Copyright (c) 1994  Carnegie Mellon University
*  All rights reserved.
*  
*  Use and copying of this software and preparation of derivative
*  works based on this software are permitted, including commercial
*  use, provided that the following conditions are observed:
*  
*  1. This copyright notice must be retained in full on any copies
*     and on appropriate parts of any derivative works.
*  2. Documentation (paper or online) accompanying any system that
*     incorporates this software, or any part of it, must acknowledge
*     the contribution of the Gwydion Project at Carnegie Mellon
*     University.
*  
*  This software is made available "as is".  Neither the authors nor
*  Carnegie Mellon University make any warranty about the software,
*  its performance, or its conformity to any specification.
*  
*  Bug reports, questions, comments, and suggestions should be sent by
*  E-mail to the Internet address "gwydion-bugs@cs.cmu.edu".
*
***********************************************************************
*
* $Header: /home/housel/work/rcs/gd/src/mindy/interp/lexer.c,v 1.3 1995/09/14 19:26:14 nkramer Exp $
*
* This file is the lexer for the debugger.
*
\**********************************************************************/



#include "../compat/std-c.h"
#include "../compat/std-os.h"

#include "mindy.h"
#include "lexer.h"
#include "parser.h"
#include "list.h"
#include "char.h"
#include "str.h"
#include "sym.h"
#include "num.h"
#include "bool.h"

#define BUFFER_SIZE	1024

FILE *yyin;

static char line[1024];
static char *next_char = line;
static int eof;

void yyinput_setter(FILE *input)
{
  yyin = input;
}

void yyinput_clear(void)
{
#ifdef HAVE_LIBREADLINE
    for ( ; *next_char != 0 && *next_char != '\n'; next_char++)
	;
#else
    int c;
    while ((c = getc(yyin)) != EOF && c != '\n')
	;
    if (c == '\n')
	ungetc(c, yyin);
#endif
}

int yyeof()
{
#ifdef HAVE_LIBREADLINE
    return eof ? -1 : 0;
#else
    if (errno == EINTR) {
	errno = 0;
	clearerr(yyin);
	return 0;
    } else
	return -1;
#endif
}

static int yygetc()
{
#ifdef HAVE_LIBREADLINE
    char *l;

    if ( *next_char) 
	return *next_char++;
    
    l = readline("mindy> ");
    if ( l == 0) {
	eof = 1;
	return -1;
    }
    
    if ( *l != 0) 
	add_history(l);
    
    strcpy( line, l);
    strcat( line, "\n"); /* I hate this */
    next_char = line;
    return *next_char++;
#else
    return getc(yyin);
#endif
}

static int yyungetc(int c)
{
#ifdef HAVE_LIBREADLINE
    if (next_char > line) {
	next_char--;
	*next_char = c;
	return c;
    } else 
	return EOF;  /* actually, can handle this if necessary. */
#else
  return ungetc(c, yyin);
#endif
}

static int yypeekc()
{
  return yyungetc(yygetc());
}

static int yyescape(int c)
{
  switch (c) {
  case '\\': return '\\';
  case '\'': return '\'';
  case '"': return '"';
  case 'a': return '\a';
  case 'b': return '\b';
  case 'e': return '\033';
  case 'f': return '\f';
  case 'n': return '\n';
  case 'r': return '\r';
  case 't': return '\t';
  case '0': return '\0';
  default: return c;
  }
}

static char map[] = {
  /* digits => 0..9,
     alphabetics => 10..35,
     other symbolics => 36,
     other 37
     sgi <ctype.h> claimed that high ascii
     had alphabetics, too, but I ignored it.
   */
  36,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,36,37,37,36,36,36,37,37,37,36,36,37,36,37,36,
   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,37,37,36,36,36,36,
  36,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
  25,26,27,28,29,30,31,32,33,34,35,37,37,37,36,36,
  37,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
  25,26,27,28,29,30,31,32,33,34,35,37,37,37,36,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
  37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,
};

static int yyisnumeric(int c, int radix)
{
  return map[c] < radix;
}

static int yyissymbolic(int c)
{
  return map[c] < 37;
}

static int yysymbol(int c)
{
    char buff[1024], *p = buff;
    
    do {
	if (p == buff+sizeof(buff))
	    return tok_ERROR;
	*p++ = c;
	c = yygetc();
	if (c == EOF) return tok_ERROR;
    } while (yyissymbolic(c));
    *p = 0;

    if (c == ':') {
	c = yygetc();
	if (c == EOF) return tok_ERROR;
	if (yyissymbolic(c)) {
	    obj_t result = list1(symbol(buff));
	    while (1) {
		p = buff;
		do {
		    if (p == buff+sizeof(buff))
			return tok_ERROR;
		    *p++ = c;
		    c = yygetc();
		    if (c == EOF) return tok_ERROR;
		} while (yyissymbolic(c));
		*p = 0;
		result = pair(symbol(buff), result);
		if (c != ':')
		    break;
		c = yygetc();
		if (c == EOF) return tok_ERROR;
		if (!yyissymbolic(c)) {
		    yyungetc(c);
		    return tok_ERROR;
		}
	    }
	    yyungetc(c);
	    if (length(result) > 3)
		return tok_ERROR;
	    yylval = result;
	    return tok_EXTERN_NAME;
	}
	else {
	    yyungetc(c);
	    yylval = symbol(buff);
	    return tok_KEYWORD;
	}
    }
    else {
	yyungetc(c);

	/* Uh, wouldn't it be better if these used # instead of $
	   so we couldn't be shadowing user variables? Or \ so we
	   couldn't shadow syntax, either? */
	if (buff[0] == '$') {
	    if (buff[1] == 0) {
		yylval = make_fixnum(-1);
		return tok_DEBUGVAR;
	    }
	    if (buff[1] == '$' && buff[2] == 0) {
		yylval = make_fixnum(-2);
		return tok_DEBUGVAR;
	    }
	    if (buff[1] == '-' || yyisnumeric(buff[1], 10)) {
		yylval = make_fixnum(strtol(buff+1, NULL, 10));
		return tok_DEBUGVAR;
	    }
	    if ((buff[1] == 'a' || buff[1] == 'A')
		&& yyisnumeric(buff[2], 10)) {
		yylval = make_fixnum(strtol(buff+2, NULL, 10));
		return tok_ARG;
	    }
	}
	yylval = symbol(buff);
	return tok_SYMBOL;
    }
}

static int yynumber(int c, int radix, int addressp)
{
  char buff[1024], *p = buff, isfloat = 0;
# define append(c)	{if (p == buff+sizeof(buff)) return tok_ERROR; *p++ = c;}
# define advance(c)	{c = yygetc(); if (c == EOF) return tok_ERROR;}

  if (c != '.') {
    do {
      append(c);
      advance(c);
    } while (yyisnumeric(c, radix));
  }
  if (radix == 10) {
    if (c == '.') {
      isfloat = 1;
      do {
	append(c);
	advance(c);
      } while (yyisnumeric(c, radix));
    }
    if (strchr("eEsSdDxX", c)) {
      isfloat = c;
      append('e');
      advance(c);
      if (c != '-' && c != '+' && ! yyisnumeric(c, radix)) {
	yyungetc(c);
	return tok_ERROR;
      }
      do {
	append(c);
	advance(c);
      } while (yyisnumeric(c, radix));
    }
  }

  yyungetc(c);
  append(0);

  switch (isfloat) {
  case 'd': case 'D':
    yylval = make_double(strtod(buff, NULL));
    return tok_NUMBER;
  case 1:
  case 'e': case 'E':
  case 's': case 'S':
    yylval = make_single(strtod(buff, NULL));
    return tok_NUMBER;
  case 'x': case 'X':
    yylval = make_extended(strtod(buff, NULL));
    return tok_NUMBER;
  default:
    if (addressp) {
      yylval =  (obj_t)strtoul(buff, NULL, radix);
      return tok_ADDRESS;
    } else {
      yylval =  make_fixnum(strtol(buff, NULL, radix));
      return tok_NUMBER;
    }
  }
# undef append
# undef advance
}

static int yystring(int q, int symbolp)
{
  char buff[1024], *p = buff;
  int c;

  while ((c = yygetc()) != EOF && c != '"') {
    if (c == '\\') {
      c = yygetc();
      if (c == EOF)
	return tok_ERROR;
      else
	*p++ = yyescape(c);
    } else {
      *p++ = c;
    }
    if (p == buff+sizeof(buff))
      return tok_ERROR;
  }
  if (c == EOF)
    return tok_ERROR;
  *p = 0;
  if (symbolp) {
    yylval = symbol(buff);	/* symbol with embedded \0 how? */
    return tok_KEYWORD;
  } else {
    yylval = alloc_byte_string(p-buff);
    memcpy(string_chars(yylval), buff, p-buff);
    return tok_STRING;
  }
}

int yylex()
{
  int c;

  c = yygetc();
  switch (c) {
  case EOF:			return yyeof() ? -1 : yylex();
  case '\n':			return -1;
  case ' ': case '\t':		return yylex();
  case '(':			return tok_LPAREN;
  case ')':			return tok_RPAREN;
  case ',':			return tok_COMMA;
  case '#':
    c = yygetc();
    switch (c) {
    case 't': case 'T':			return tok_TRUE;
    case 'f': case 'F':			return tok_FALSE;
    case 'b': case 'B':			return yynumber(yygetc(), 2, 0);
    case 'o': case 'O':			return yynumber(yygetc(), 8, 0);
    case 'x': case 'X':			return yynumber(yygetc(), 16, 0);
    case '"':				return yystring(c, 1);
    default:
      yyungetc(c);
      return tok_ERROR;
    }
  case '"':			return yystring(c, 0);
  case '\'':
    c = yygetc();
    if (c == '\\') {
      c = yygetc();
      if (c == EOF)
	return tok_ERROR;
      else
	yylval = int_char(yyescape(c));
    } else {
      yylval = int_char(c);
    }
    if (yygetc() != '\'')
      return tok_ERROR;
    else
      return tok_CHARACTER;

  case '.':
    if (yyisnumeric(yypeekc(), 10))
      return yynumber(c, 10, 0);
    return tok_ERROR;

  case '-': case '+':
    if (yyisnumeric(yypeekc(), 10))
      return yynumber(c, 10, 0);
    return yysymbol(c);

  case '0':
    c = yygetc();
    if (c == 'x' || c == 'X')
      return yynumber(yygetc(), 16, 1);
    yyungetc(c);
    return yynumber('0', 10, 0);

  default:
    if (yyisnumeric(c, 10))
      return yynumber(c, 10, 0);
    if (yyissymbolic(c))
      return yysymbol(c);
    return tok_ERROR;
  }
}
