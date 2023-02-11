%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <map>
#include <regex>
#include "pp_parser.hpp"

/* �萔 */

/* �O���[�o���ϐ� */
FILE * output_file_ptr = NULL;

/* �v���g�^�C�v�錾 */
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
/* �I�[�L�� */
%token<ctype> TOKEN IMPORT
%token<ctype> DEFINE DEFINE_VAL
%token<ctype> OTHER_CODE

/* ��I�[�L�� */
%type<ctype> program definest importst

%start program
%glr-parser
%%

/* �v���O�����Ƃ͂Ȃ񂼂� */
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
	fprintf(stdout, "**********************************************\n%s", msg.c_str()); // �t�@�C���ɏ���
	fprintf(output_file_ptr, "%s", msg.c_str()); // �t�@�C���ɏ���
}

void yyerror (char const *s) {
	fprintf (stderr, "%s\n", s);
	exit(-1);
}
