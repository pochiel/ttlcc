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
std::map <std::string, std::string> define_tbl;		/* define�u�������}�N���e�[�u�� */

/* �v���g�^�C�v�錾 */
void output_to_file(std::string &);
void get_comment(std::string &buf);
std::string initialize_arg(std::string & function_name, t_token & input_args);
std::string initialize_returnval(std::string & function_name);
std::string get_connector(std::string orig_label) ;
uint32_t get_comment_index();
extern "C" void yyerror(const char* s);
extern "C" int  yylex(void);
t_token * replace_macro(t_token * codes);

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
%type<ctype> program definest importst codes

%start program
%glr-parser
%%

/* �v���O�����Ƃ͂Ȃ񂼂� */
program		:	program definest						{
															/* �H���� */
															// $$ = new t_token( *$2 + *$3); 
															// $$->token_str += "return\n";
															// output_to_file($$->token_str);
														}
			|	program importst						{	/* �H���� */$$ = new t_token();}
			|	program codes							{
															output_to_file($2->token_str);
														}
			|	definest								{
															/* �H���� */
															// $$ = new t_token(*$1 + *$2); 
															// $$->token_str += "return\n";
														}
			|	importst								{	/* �H���� */$$ = new t_token();}
			|	codes									{
															output_to_file($1->token_str);
														}
			;

codes		:	OTHER_CODE								{
															$$ = new t_token(*$1);
															$$->token_str += "\n";
															// define�}�N���̒u����������
															$$ = replace_macro($$);
														}
			;


importst	:	IMPORT TOKEN							{ /* �H���� */ }
			;

definest	:	DEFINE TOKEN DEFINE_VAL					{
															define_tbl[*(new std::string($2->token_str.c_str()))] = *(new std::string($3->token_str.c_str()));
														}
			;

%%

/* define�}�N���̒�`�e�[�u�����Q�Ƃ��āA����̒u�����������{���� */
t_token * replace_macro(t_token * codes) {
    for (const auto& [key, value] : define_tbl){
		codes->token_str = std::regex_replace(codes->token_str, std::regex(key), value);
    }
	return codes;
}

void output_to_file(std::string &msg){
	fprintf(stdout, "**********************************************\n%s", msg.c_str()); // �t�@�C���ɏ���
	fprintf(output_file_ptr, "%s", msg.c_str()); // �t�@�C���ɏ���
}

void yyerror (char const *s) {
	fprintf (stderr, "%s\n", s);
	exit(-1);
}
