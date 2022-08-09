%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <map>
#include <regex>
#include "parser.hpp"
#include "function.hpp"

void output_to_file(std::string &);
void get_comment(std::string &buf);
std::string get_connector(std::string orig_label) ;

uint32_t get_comment_index();

/* �O���[�o���ϐ� */
FILE * output_file_ptr = NULL;

/* �v���g�^�C�v�錾 */
extern "C" void yyerror(const char* s);
extern "C" int  yylex(void);

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
%token<ctype> IF ELSE ELSEIF THEN ENDIF
%token<ctype> FOR TO STEP NEXT 
%token<ctype> WHILE DO LOOP ENDWHILE 
%token<ctype> FUNCTION ENDFUNCTION
%token<ctype> BREAK CONTINUE RETRN 
%token<ctype> INT STRING VOID STR_RETERAL INT_RETERAL
%token<ctype> EQUAL NOT PLUS MINUS ASTA SLASH MOD LEFT_SHIFT RIGHT_SHIFT LEFT_SHIFT_LOGIC RIGHT_SHIFT_LOGIC COMMA
%token<ctype> BIT_AND BIT_XOR BIT_OR GRATER_THAN_LEFT GRATER_THAN_RIGHT EQUAL_GRATER_THAN_LEFT EQUAL_GRATER_THAN_RIGHT
%token<ctype> EQUAL_EQUAL NOT_EQUAL LOGICAL_AND LOGICAL_OR 
%token<ctype> EXPR
%token<ctype> TOKEN RESERVED_WORD
%token<ctype> CR BRACE END_BRACE IMPORT
/* ��I�[�L�� */
%type<ctype> program codes var ifst forst functionst dowhilest retrnst breakst expr return_types args typest callst manytokenst functionnamest

%start program

%%

/* �v���O�����Ƃ͂Ȃ񂼂� */
program		:	program program					{ 	
													output_to_file($1->token_str);
													output_to_file($2->token_str);
												}
			|	functionst						{ $$ = $1; }
			;

functionnamest	:	TOKEN						{ 
													$1->type = TYPE_FUNCTION;
													set_function_name($1->token_str);
													$$ = $1;
												}

/* �֐��Ƃ͂Ȃ񂼂� */
functionst	:	FUNCTION return_types functionnamest BRACE args END_BRACE codes ENDFUNCTION	{
														$$ = new t_token();
														std::cout << "return_types:" << $2->token_str << "\n";
														std::cout << "TOKEN:" << $3->token_str << "\n";
														std::cout << "args:" << $5->token_str << "\n";
														std::cout << "codes:" << $7->token_str << "\n";
														$$->token_str = 	std::string(
																					set_input_param(*$5)
																					+ set_output_param(*$2)
																					+ ":" + $3->token_str + "\n"
																					+ $7->token_str + "\n"
														);
														// main�֐����ɂ���Ȃ� exit �Ńv���O�����I���B	�����łȂ���� return
														// �b��F�ŏI�I�ɂ̓}�N���擪�� call main �W�����v����悤�ɂ��Areturn�Ŗ߂��Ă��ďI������̂��D�܂����B
														// ���̂��߂ɂ́A�S�R�[�h���g�����X�p�C����� �֐��e�[�u���𑖍����Amain�֐��������Ă���ꍇ�Ƃ��Ȃ��ꍇ��
														// �����𕪂��Ȃ���Ȃ��B�@�߂�ǁB
														if(get_function_name()=="main") {
															$$->token_str += "exit\n";
														} else {
															$$->token_str += "return\n";
														}
													}
			;

return_types:	return_types return_types		{ $$ = new t_token(*$1 + *$2); }
			|	typest							{ $$ = $1; }
			;

typest		:	INT								{ $$ = $1; }
			|	STRING							{ $$ = $1; }
			|	VOID							{ $$ = $1; }
			;

var			:	typest TOKEN					{
													$$ = new t_token(*$2);
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name($$->token_str);
													}
													switch($1->type){
														case TYPE_STRING:
															// string�^�ϐ���������
															$$->token_str = $$->token_str + "=''\n";
															break;
														case TYPE_INT:
															// int�^�ϐ���������
															$$->token_str = $$->token_str + "=0\n";
															break;
														case TYPE_VOID:
														default:
															yyerror("[ERROR] A void type variable cannot be created.\n");
															break;
													}
												}
			|	typest TOKEN EQUAL INT_RETERAL	{
													$$ = new t_token(*$2);
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name($$->token_str);
													}
													switch($1->type){
														case TYPE_STRING:
															// �Öٌ^�L���X�g���o�Ă� string�^�ϐ�������
															$$->token_str = $$->token_str + "='" + $4->token_str + "'\n";
															break;
														case TYPE_INT:
															// int�^�ϐ���������
															$$->token_str = $$->token_str + "=" + $4->token_str.c_str() + "\n";
															break;
														case TYPE_VOID:
														default:
															yyerror("[ERROR] A void type variable cannot be created.\n");
															break;
													}
												}
			|	typest TOKEN EQUAL STR_RETERAL	{
													$$ = new t_token(*$2);
													switch($1->type){
														case TYPE_STRING:
															// string�^�ϐ���������
															$$->token_str = $$->token_str + "='" + $4->token_str + "'\n";
															break;
														case TYPE_INT:
															// ������^�������^�̈Öق̌^�L���X�g�͍s���Ȃ�
															yyerror("[ERROR] trying to assign a string to an integer type variable.\n");
															break;
														case TYPE_VOID:
														default:
															yyerror("[ERROR] A void type variable cannot be created.\n");
															break;
													}
												}
			|	VOID							{ $$ = $1; $$->token_str = ""; }
			;

args		:	args args						{ $$ = new t_token(*$1 + *$2); }
			|	var								{ $$ = $1; }
			;

codes		:	codes codes						{ $$ = new t_token(*$1 + *$2); }	
			|	var								{ $$ = $1; }
			|	ifst							{ $$ = $1; }
			|	forst							{ $$ = $1; }
			|	dowhilest						{ $$ = $1; }
			|	breakst							{ $$ = $1; }
			|	CONTINUE						{
													/* �b�� */ 
													t_token *ret = new t_token();;
													ret->token_str = ":continue;\n";
													$$ = ret; 
												}
			|	expr							{ $$ = $1; }
			|	retrnst							{ $$ = $1; }
			|	callst							{ $$ = $1; }
			|	CR								{ $$ = $1; $$->token_str = "\n";}
			;

ifst		: IF								{/* dummy */}
forst		: FOR								{/* dummy */}
dowhilest	: WHILE								{/* dummy */}

/* ���b�� */
expr		: expr expr							{ $$ = new t_token(*$1 + *$2); }
			| INT_RETERAL						{ $$ = $1; }
			| expr PLUS expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "+" + $3->token_str; }
			| expr MINUS expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "-" + $3->token_str; }
			| expr ASTA expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "*" + $3->token_str; }
			| expr SLASH expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "/" + $3->token_str; }
			| expr MOD expr						{ $$ = new t_token(); $$->token_str = $1->token_str + "%" + $3->token_str; }
			| expr EQUAL expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "=" + $3->token_str; }
			| TOKEN								{ $$ = $1; $$->token_str = $$->convert_name_to_local( get_function_name(), get_argument($$->token_str)) ; }
			;

/* �֐��Ăяo�� */
callst		: TOKEN BRACE manytokenst END_BRACE 			{
																$$ = new t_token();
																$$->token_str = initialize_arg($1->token_str, $3->token_str);
																$$->token_str = $$->token_str + "call " + $1->token_str;
															}
			| RESERVED_WORD BRACE manytokenst END_BRACE		{ $$ = new t_token(); $$->token_str = $1->token_str + " " + $3->token_str; }
			;

manytokenst	: manytokenst COMMA manytokenst					{ $$ = new t_token(); $$->token_str = $1->token_str + " " + $3->token_str; }
			| TOKEN											{ $$ = $1; $$->token_str = $$->convert_name_to_local( get_function_name(), get_argument($$->token_str)) ; }
			| INT_RETERAL									{ $$ = $1; }
			| STR_RETERAL									{ $$ = $1; }
			;

//ifst		: IF EXPR block						{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
//																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n") 
//																		+ $3->token_str + "\n"
//																		+ "endif\n";
//													ret->comment = "";	/* �R�����g�͏����Ă��� */
//													$$ = ret;
//												}
//			| IF EXPR block ELSE block			{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
//																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n")
//																		+ $3->token_str + "\n"
//																		+ "else\n"
//																		+ ($4->get_format_comment() == "" ? "" : ": ;\n" + $4->get_format_comment() + "\n")
//																		+ $5->token_str + "\n"
//																		+ "endif\n";
//													ret->comment = "";	/* �R�����g�͏����Ă��� */
//													$$ = ret;
//												}
//			| IF EXPR block ELSE ifst			{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
//																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n") 
//																		+ $3->token_str + "\n"
//																		+ "else" + $5->token_str + "\n"		/* elseif */
//																		+ ($4->get_format_comment() == "" ? "" : ": ;\n" + $4->get_format_comment() + "\n");
//													/* ������I�[�L���� ifst �� endif���Ă���͂��Ȃ̂� �����ł� endif ���Ȃ� */
//													ret->comment = "";	/* �R�����g�͏����Ă��� */
//													$$ = ret;
//												}
//
//forst   :   FOR EXPR block						{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"while (" + $2->token_str + ")\n" 
//																		+ $1->get_format_comment() + "\n" 
//																		+ $3->token_str + "\n"
//																		+ "end while\n";
//													ret->comment = "";	/* �R�����g�͏����Ă��� */
//													$$ = ret;
//												}
//		|	WHILE EXPR block					{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"while (" + $2->token_str + ")\n" 
//																		+ $1->get_format_comment() + "\n" 
//																		+ $3->token_str + "\n"
//																		+ "end while\n";
//													ret->comment = "";	/* �R�����g�͏����Ă��� */
//													$$ = ret;
//												}
//
//dowhilest	: DO block WHILE EXPR			{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"repeat\n"
//																		+ $1->get_format_comment() + "\n" 
//																		+ $2->token_str + "\n" 
//																		+ "repeat while(" + $4->token_str + ")\n"
//																		+ $3->get_format_comment() + "\n" ;
//													ret->comment = "";	/* �R�����g�͏����Ă��� */
//													$$ = ret;
//											}
//			;

/* return */
retrnst		:	RETRN EXPR		{
									t_token *ret = new t_token();;
									ret->token_str = 	":return " + $2->token_str + ";\n" 
														+ $1->get_format_comment() + "\n"
														+ "stop\n";
									ret->comment = "";	/* �R�����g�͏����Ă��� */
									$$ = ret;
								}
			|	RETRN			{ }
			;

/* break */
breakst		:	BREAK			{ 
									t_token *ret = new t_token();;
										ret->token_str = ":break;\n"
														+ $1->get_format_comment() + "\n"
														+ "break\n";
									ret->comment = "";	/* �R�����g�͏����Ă��� */
									$$ = ret; 
								}

%%

static std::string g_comment_buf;

void set_comment(const std::string &com) {
	g_comment_buf = com;
}

void get_comment(std::string &buf) {
	buf = g_comment_buf;
	g_comment_buf = "";
}

void output_to_file(std::string &msg){
	fprintf(output_file_ptr, "%s", msg.c_str()); // �t�@�C���ɏ���
}

std::map <std::string, std::string> g_connector_map;
int connector_index = 0;
std::string get_connector(std::string orig_label) {
	std::string ret = "";
	orig_label = std::regex_replace(orig_label, std::regex("(:|;)"), "");
	if(g_connector_map.count(orig_label) == 0){
		ret = (char)('a'+(connector_index++));
		g_connector_map[orig_label] = ret;
	} else {
		ret = g_connector_map[orig_label];	
	}
	return ret;
}
