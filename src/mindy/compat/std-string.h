/*
 * string.h --
 *
 *	Declarations of ANSI C library procedures for string handling.
 *
 * Copyright (c) 1991-1993 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission is hereby granted, without written agreement and without
 * license or royalty fees, to use, copy, modify, and distribute this
 * software and its documentation for any purpose, provided that the
 * above copyright notice and the following two paragraphs appear in
 * all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * $Header: /scm/cvs/src/mindy/compat/std-string.h,v 1.1 1998/05/03 19:55:19 andreas Exp $ SPRITE (Berkeley)
 */

#ifndef _STRING
#define _STRING

#include "std-c.h"

/*
 * The following #include is needed to define size_t. (This used to
 * include sys/stdtypes.h but that doesn't exist on older versions
 * of SunOS, e.g. 4.0.2, so I'm trying sys/types.h now.... hopefully
 * it exists everywhere)
 */

#include <sys/types.h>

extern VOID *		memchr _ANSI_ARGS_((CONST VOID *s, int c, size_t n));
extern int		memcmp _ANSI_ARGS_((CONST VOID *s1, CONST VOID *s2,
			    size_t n));
extern VOID *		memcpy _ANSI_ARGS_((VOID *t, CONST VOID *f, size_t n));
extern VOID *		memmove _ANSI_ARGS_((VOID *t, CONST VOID *f,
			    size_t n));
extern VOID *		memset _ANSI_ARGS_((VOID *s, int c, size_t n));

extern int		strcasecmp _ANSI_ARGS_((CONST char *s1,
			    CONST char *s2));
extern char *		strcat _ANSI_ARGS_((char *dst, CONST char *src));
extern char *		strchr _ANSI_ARGS_((CONST char *string, int c));
extern int		strcmp _ANSI_ARGS_((CONST char *s1, CONST char *s2));
extern char *		strcpy _ANSI_ARGS_((char *dst, CONST char *src));
extern size_t		strcspn _ANSI_ARGS_((CONST char *string,
			    CONST char *chars));
extern char *		strdup _ANSI_ARGS_((CONST char *string));
extern char *		strerror _ANSI_ARGS_((int error));
extern size_t		strlen _ANSI_ARGS_((CONST char *string));
extern int		strncasecmp _ANSI_ARGS_((CONST char *s1,
			    CONST char *s2, size_t n));
extern char *		strncat _ANSI_ARGS_((char *dst, CONST char *src,
			    size_t numChars));
extern int		strncmp _ANSI_ARGS_((CONST char *s1, CONST char *s2,
			    size_t nChars));
extern char *		strncpy _ANSI_ARGS_((char *dst, CONST char *src,
			    size_t numChars));
extern char *		strpbrk _ANSI_ARGS_((CONST char *string, char *chars));
extern char *		strrchr _ANSI_ARGS_((CONST char *string, int c));
extern size_t		strspn _ANSI_ARGS_((CONST char *string,
			    CONST char *chars));
extern char *		strstr _ANSI_ARGS_((CONST char *string,
			    CONST char *substring));
extern char *		strtok _ANSI_ARGS_((CONST char *s, CONST char *delim));

#endif /* _STRING */
