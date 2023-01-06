/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Skeleton interface for Bison GLR parsers in C

   Copyright (C) 2002-2015, 2018-2020 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_TTLCC_TAB_H_INCLUDED
# define YY_YY_TTLCC_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 29 "ttlcc.y"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include "t_token.hpp"
#include "function.hpp"

#line 54 "ttlcc.tab.h"

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    IF = 258,
    ELSE = 259,
    ELSEIF = 260,
    THEN = 261,
    ENDIF = 262,
    FOR = 263,
    TO = 264,
    STEP = 265,
    NEXT = 266,
    WHILE = 267,
    DO = 268,
    LOOP = 269,
    ENDWHILE = 270,
    FUNCTION = 271,
    ENDFUNCTION = 272,
    BREAK = 273,
    CONTINUE = 274,
    RETRN = 275,
    INT = 276,
    STRING = 277,
    VOID = 278,
    STR_RETERAL = 279,
    INT_RETERAL = 280,
    MINUS_INT_RETERAL = 281,
    EQUAL = 282,
    BIT_NOT = 283,
    PLUS = 284,
    MINUS = 285,
    ASTA = 286,
    SLASH = 287,
    MOD = 288,
    LEFT_SHIFT = 289,
    RIGHT_SHIFT = 290,
    LEFT_SHIFT_LOGIC = 291,
    RIGHT_SHIFT_LOGIC = 292,
    COMMA = 293,
    BIT_AND = 294,
    BIT_XOR = 295,
    BIT_OR = 296,
    GRATER_THAN_LEFT = 297,
    GRATER_THAN_RIGHT = 298,
    EQUAL_GRATER_THAN_LEFT = 299,
    EQUAL_GRATER_THAN_RIGHT = 300,
    EQUAL_EQUAL = 301,
    LOGICAL_NOT = 302,
    NOT_EQUAL = 303,
    LOGICAL_AND = 304,
    LOGICAL_OR = 305,
    TOKEN = 306,
    RESERVED_WORD = 307,
    CR = 308,
    BRACE = 309,
    END_BRACE = 310,
    IMPORT = 311,
    LEFT_INDEX_BRACKET = 312,
    RIGHT_INDEX_BRACKET = 313,
    EXTERN = 314
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 39 "ttlcc.y"

	int		itype;
	t_token	* ctype;

#line 130 "ttlcc.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_TTLCC_TAB_H_INCLUDED  */
