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
* $Header: /scm/cvs/src/mindy/interp/str.h,v 1.1.1.1.6.1 1998/12/19 18:02:09 igor Exp $
*
\**********************************************************************/


extern obj_t obj_ByteStringClass;
extern obj_t obj_UnicodeStringClass;

/* The following is the definition for both byte strings and unicode
   strings.  Unicode strings are stored as two byte-characters in a
   row, high byte first.  Unicode strings are terminated with the
   unicode character 0x0000 (two null byte characters).  len refers
   to the number of characters, not the number of bytes.
*/
struct string {
    obj_t /* class */ class;
    int len;
    unsigned char chars[4];
};

/* How you interpret the chars depends on whether its a byte string or 
   a unicode string.
*/
#define string_chars(str) (obj_ptr(struct string *, str)->chars)

/*
   A convenient way to access unicode characters in a stream of 
   unicode characters.  Returns an integer.
*/
#define get_unichar(str,index) ((string_chars(str)[2*index] << 8) \
				+ (string_chars(str)[2*index + 1]))


extern obj_t make_byte_string(char *chars);
extern obj_t alloc_byte_string(int len);
