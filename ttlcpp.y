%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <map>
#include <regex>
#include "pp_parser.hpp"

/* 定数 */

/* グローバル変数 */
FILE * output_file_ptr = NULL;

/* プロトタイプ宣言 */
void output_to_file(std::string &);
void get_comment(std::string &buf);
std::string initialize_arg(std::string & function_name, t_token & input_args);
std::string initialize_returnval(std::string & function_name);
std::string get_connector(std::string orig_label) ;
uint32_t get_comment_index();
extern "C" void yyerror(const char* s);
extern "C" int  yylex(void);

void breakp(t_token & t){
}
%}

%code requires {
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include "t_token.hpp"
#include "function.hpp"
}

%union {
	int		itype;
	t_token	* ctype;
}

%defines
/* 終端記号 */
%token<ctype> TOKEN IMPORT
%token<ctype> DEFINE DEFINE_VAL
%token<ctype> OTHER_CODE

/* 非終端記号 */
%type<ctype> program definest importst

%start program
%glr-parser
%%

/* プログラムとはなんぞや */
program		:	program definest						{
															// $$ = new t_token( *$2 + *$3); 
															// $$->token_str += "return\n";
															output_to_file($$->token_str);
														}
			|	program importst						{$$ = new t_token();}
			|	definest								{
															// $$ = new t_token(*$1 + *$2); 
															// $$->token_str += "return\n";
															output_to_file($$->token_str);
														}
			|	importst								{$$ = new t_token();}
			;

codes		:	OTHER_CODE						{ }
			;


importst	:	IMPORT TOKEN					{ }
			;

definest	:	DEFINE TOKEN DEFINE_VAL			{ }
			;

%%

void output_to_file(std::string &msg){
	fprintf(stdout, "**********************************************\n%s", msg.c_str()); // ファイルに書く
	fprintf(output_file_ptr, "%s", msg.c_str()); // ファイルに書く
}

void yyerror (char const *s) {
	fprintf (stderr, "%s\n", s);
	exit(-1);
}
