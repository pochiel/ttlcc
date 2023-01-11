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
#include "common.hpp"

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
%token<ctype> INT STRING VOID STR_RETERAL INT_RETERAL MINUS_INT_RETERAL
%token<ctype> EQUAL BIT_NOT PLUS MINUS ASTA SLASH MOD LEFT_SHIFT RIGHT_SHIFT LEFT_SHIFT_LOGIC RIGHT_SHIFT_LOGIC COMMA
%token<ctype> BIT_AND BIT_XOR BIT_OR GRATER_THAN_LEFT GRATER_THAN_RIGHT EQUAL_GRATER_THAN_LEFT EQUAL_GRATER_THAN_RIGHT
%token<ctype> EQUAL_EQUAL LOGICAL_NOT NOT_EQUAL LOGICAL_AND LOGICAL_OR 
%token<ctype> TOKEN RESERVED_WORD
%token<ctype> CR BRACE END_BRACE IMPORT
%token<ctype> LEFT_INDEX_BRACKET RIGHT_INDEX_BRACKET
/* ��I�[�L�� */
%type<ctype> program codes var ifst forst functionst dowhilest retrnst expr return_types args typest callst manytokenst functionnamest else_if_list initialize_intval_st initialize_strval_st

%start program

%right BIT_NOT EQUAL
%left PLUS MINUS ASTA SLASH MOD
%left LEFT_SHIFT RIGHT_SHIFT LEFT_SHIFT_LOGIC RIGHT_SHIFT_LOGIC
%left EQUAL_EQUAL LOGICAL_NOT NOT_EQUAL LOGICAL_AND LOGICAL_OR
%left BIT_AND BIT_XOR BIT_OR GRATER_THAN_LEFT GRATER_THAN_RIGHT EQUAL_GRATER_THAN_LEFT EQUAL_GRATER_THAN_RIGHT
%glr-parser
%%

/* �v���O�����Ƃ͂Ȃ񂼂� */
program		:	program functionst				{
													$$ = new t_token(*$1 + *$2); 
													output_to_file($2->token_str);
												}
			|	functionst						{
													$$ = $1;
													output_to_file($1->token_str);
												}
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

initialize_intval_st	:	initialize_intval_st COMMA INT_RETERAL	{
																		$$ = new t_token();
																		$$->token_str = $1->token_str + " " + $3->token_str;
																	}
						|	INT_RETERAL								{ $$ = $1; }
						;

initialize_strval_st	:	initialize_strval_st COMMA STR_RETERAL	{
																		$$ = new t_token();
																		$$->token_str = $1->token_str + " " + $3->token_str;
																	}
						|	STR_RETERAL								{ $$ = $1; }
						;

var			:	typest TOKEN					{
													$$ = new t_token(*$2);
													$$->type = $1->type;
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name(*$$);
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
													$$->type = $1->type;
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name(*$$);
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
			// �����z��i�������Ȃ��j
			|	INT TOKEN LEFT_INDEX_BRACKET INT_RETERAL RIGHT_INDEX_BRACKET	{
													$$ = new t_token(*$2);
													$$->type = TYPE_INT_ARRAY;
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name(*$$);
													}
													$$->token_str = "intdim " + $$->token_str + " " + $5->token_str + "\n";
												}
			// ������z��i�������Ȃ��j
			|	STRING TOKEN LEFT_INDEX_BRACKET INT_RETERAL RIGHT_INDEX_BRACKET	{
													$$ = new t_token(*$2);
													$$->type = TYPE_STRING_ARRAY;
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name(*$$);
													}
													$$->token_str = "strdim " + $$->token_str + " " + $5->token_str + "\n";
												}
			// �����z��i����������j
			|	INT TOKEN LEFT_INDEX_BRACKET INT_RETERAL RIGHT_INDEX_BRACKET EQUAL initialize_intval_st {
													std::vector<std::string> initialize_list = common_utl::split($7->token_str, ' ');
													$$ = new t_token(*$2);
													$$->type = TYPE_INT_ARRAY;
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name(*$$);
													}
													std::string local_name = $$->token_str;
													$$->token_str = "intdim " + local_name + " " + $5->token_str + "\n";
													// �����������̒ǉ�
													int i=0;
													for(std::string x : initialize_list){
														$$->token_str += local_name + "[" + std::to_string(i) + "]=" + x + "\n";
														i++;
													}
												}
			// ������z��i����������j
			|	STRING TOKEN LEFT_INDEX_BRACKET INT_RETERAL RIGHT_INDEX_BRACKET EQUAL initialize_strval_st	{
													std::vector<std::string> initialize_list = common_utl::split($7->token_str, ' ');
													$$ = new t_token(*$2);
													$$->type = TYPE_INT_ARRAY;
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name(*$$);
													}
													std::string local_name = $$->token_str;
													$$->token_str = "strdim " + local_name + " " + $5->token_str + "\n";
													// �����������̒ǉ�
													int i=0;
													for(std::string x : initialize_list){
														$$->token_str += local_name + "[" + std::to_string(i) + "]=" + x + "\n";
														i++;
													}
												}
			|	typest TOKEN EQUAL STR_RETERAL	{
													$$ = new t_token(*$2);
													$$->type = $1->type;
													// ���[�J���ϐ����̐ݒ�
													if(get_function_name() != ""){
														$$->set_local_name(*$$);
													}
													switch($1->type){
														case TYPE_STRING:
															// string�^�ϐ���������
															$$->token_str = $$->token_str + "=" + $4->token_str + "\n";
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

codes		:	var CR							{ $$ = $1; $$->token_str += "\n"; }
			|	callst CR						{ $$ = $1; $$->token_str += "\n"; }
			|	ifst							{ $$ = $1; $$->token_str += "\n"; }
			|	forst							{ $$ = $1; $$->token_str += "\n"; }
			|	dowhilest						{ $$ = $1; $$->token_str += "\n"; }
			|	BREAK CR						{ $$ = new t_token(); $$->token_str = "break\n"; }
			|	CONTINUE CR						{ $$ = new t_token(); $$->token_str = "continue\n";	}
			|	retrnst CR						{ $$ = $1; $$->token_str += "\n"; }
			|	expr CR							{ $$ = $1; $$->token_str += "\n"; }
			|	codes var CR					{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes callst CR					{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes ifst						{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes forst						{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes dowhilest					{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes BREAK CR					{ $$ = new t_token(*$1); $$->token_str = "break\n"; }
			|	codes CONTINUE CR				{ $$ = new t_token(*$1); $$->token_str = "continue\n";	}
			|	codes retrnst CR				{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes expr CR					{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			;

expr		: INT_RETERAL						{ $$ = $1; $$->type = TYPE_INT; }
			| STR_RETERAL						{ $$ = $1; $$->type = TYPE_STRING; }
			| MINUS_INT_RETERAL					{ $$ = $1; $$->type = TYPE_INT; }
			| BRACE expr END_BRACE				{ $$ = new t_token(*$2); $$->token_str = "(" + $2->token_str + ")"; }
			| expr PLUS expr					{ 
													if( ($1->type == TYPE_STRING) || ($3->type == TYPE_STRING) ){
														// �ǂ��炩��������^�Ȃ當���񌋍�
														$$ = t_token::string_concatenation(*$1, *$3);
													} else {
														// �����łȂ���ΐ��l���Z
														$$ = new t_token();
														$$->type = TYPE_INT;
														$$->token_str = $1->token_str + "+" + $3->token_str;
													}
												}
			| expr MINUS expr					{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "-" + $3->token_str;
												}
			| expr ASTA expr					{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "*" + $3->token_str;
												}
			| expr SLASH expr					{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "/" + $3->token_str;
												}
			| expr MOD expr						{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "%" + $3->token_str;
												}
			| expr EQUAL expr					{
													$$ = new t_token();
													// �O�u����������Ȃ�΂�����Ɍ�������
													if($3->preamble_str != ""){
														$$->token_str = $3->preamble_str;
													}
													$$->token_str += $1->token_str + "=" + $3->token_str;
												}
			// �_�����Z�n
			| expr EQUAL_EQUAL expr				{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "==" + $3->token_str;
												}
			| expr NOT_EQUAL expr				{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "<>" + $3->token_str;
												}
			| expr LOGICAL_NOT					{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = "!" + $1->token_str; 				
												}
			| expr LOGICAL_AND expr				{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "&&" + $3->token_str;
												}
			| expr LOGICAL_OR expr				{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "||" + $3->token_str;
												}
			| expr GRATER_THAN_LEFT expr		{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "<" + $3->token_str;
												}
			| expr GRATER_THAN_RIGHT expr		{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + ">" + $3->token_str;
												}
			| expr EQUAL_GRATER_THAN_LEFT expr	{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "=<" + $3->token_str;
												}
			| expr EQUAL_GRATER_THAN_RIGHT expr	{
													if( ($1->type == TYPE_STRING) || ($2->type == TYPE_STRING) ) {
														yyerror("[ERROR] Can not do this kind of math with strings.\n");
													}
													$$ = new t_token(); $$->token_str = $1->token_str + "=>" + $3->token_str;
												}
			// �r�b�g���Z�n
			| BIT_NOT expr						{ $$ = new t_token(); $$->token_str = "~" + $1->token_str; }
			| expr LEFT_SHIFT expr				{ $$ = new t_token(); $$->token_str = $1->token_str + "<<" + $3->token_str; }
			| expr RIGHT_SHIFT expr				{ $$ = new t_token(); $$->token_str = $1->token_str + ">>" + $3->token_str; }
			| expr LEFT_SHIFT_LOGIC expr		{ $$ = new t_token(); $$->token_str = $1->token_str + "<<<" + $3->token_str; }
			| expr RIGHT_SHIFT_LOGIC expr		{ $$ = new t_token(); $$->token_str = $1->token_str + ">>>" + $3->token_str; }
			| expr BIT_AND expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "&" + $3->token_str; }
			| expr BIT_OR expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "|" + $3->token_str; }
			| expr BIT_XOR expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "|" + $3->token_str; }
			| TOKEN								{ $$ = new t_token( t_token::get_local_name($1->token_str) ); }
			// �z��̏���
			| TOKEN	LEFT_INDEX_BRACKET expr RIGHT_INDEX_BRACKET	{
														// int�^�ȊO��z�� index �Ɏw�肵���炠����
														if($3->type != TYPE_INT){
															yyerror("[ERROR] Array index only use integer.\n");
														}
														$$ = new t_token( t_token::get_local_name($1->token_str) );
														$$->token_str += "[" + $3->token_str + "]";
														switch($$->type){
															case TYPE_INT_ARRAY:
																$$->type = TYPE_INT;
																break;
															case TYPE_STRING_ARRAY:
																$$->type = TYPE_STRING;
																break;
															default:
																yyerror("[ERROR] Indexed access to non-array variables.\n");
																break;
														}
													}
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
			| TOKEN											{ $$ = new t_token( t_token::get_local_name($1->token_str) ); }
			| INT_RETERAL									{ $$ = $1; }
			| STR_RETERAL									{ $$ = $1; }
			| TOKEN	LEFT_INDEX_BRACKET expr RIGHT_INDEX_BRACKET	{ $$ = new t_token( t_token::get_local_name($1->token_str) ); $$->token_str += "[" + $3->token_str + "]"; }
			;

/* if���n�̏��� */
else_if_list: else_if_list else_if_list						{ $$ = new t_token(*$1 + *$2); }
			| ELSE IF expr THEN codes						{
																t_token *ret = new t_token();;
																ret->token_str = 	"elseif (" + $3->token_str + ") then\n" 
																					+ $5->token_str + "\n";
																$$ = ret;
															}
			;

ifst		: IF expr THEN codes ENDIF						{
																t_token *ret = new t_token();;
																ret->token_str = 	"if (" + $2->token_str + ") then\n" 
																					+ $4->token_str + "\n"
																					+ "endif\n";
																$$ = ret;
															}
			| IF expr THEN codes ELSE codes ENDIF			{
																t_token *ret = new t_token();;
																ret->token_str = 	"if (" + $2->token_str + ") then\n" 
																					+ $4->token_str + "\n"
																					+ "else\n"
																					+ $6->token_str + "\n"
																					+ "endif\n";
																$$ = ret;
															}
			| IF expr THEN codes else_if_list ENDIF			{
																t_token *ret = new t_token();;
																ret->token_str = 	"if (" + $2->token_str + ") then\n" 
																					+ $4->token_str + "\n"
																					+ $5->token_str + "\n"
																					+ "endif\n";
																$$ = ret;
															}
			| IF expr THEN codes else_if_list ELSE codes ENDIF	{
																t_token *ret = new t_token();;
																ret->token_str = 	"if (" + $2->token_str + ") then\n" 
																					+ $4->token_str + "\n"
																					+ $5->token_str + "\n"
																					+ "else\n"
																					+ $7->token_str + "\n"
																					+ "endif\n";
																$$ = ret;
															}
			;

/* for���n�̏��� */
forst   :   FOR TOKEN EQUAL expr TO expr codes NEXT			{
																t_token *ret = new t_token();
																ret->token_str = 	"for " + $2->convert_name_to_local( get_function_name(), get_argument($2->token_str))
																					+ " " + $4->token_str + " " + $6->token_str + " \n" 
																					+ $7->token_str + "\n"
																					+ "next\n";
																$$ = ret;
															}
		|   FOR TOKEN EQUAL expr TO expr STEP expr codes NEXT {
																t_token *ret = new t_token();
																std::string counter_val = $2->convert_name_to_local( get_function_name(), get_argument($2->token_str));
																ret->token_str = 	counter_val + "=" + $4->token_str + "\n"
																					+ "while " + counter_val + "<>" + $6->token_str + "\n"
																					+ $9->token_str + "\n"
																					+ counter_val + "=" + counter_val + "+ (" + $8->token_str + ")\n" 
																					+ "endwhile\n";
																$$ = ret;
															}
		;

/* while���n�̏��� */
dowhilest	: DO WHILE expr codes LOOP						{
																t_token *ret = new t_token();
																ret->token_str = 	"do while " + $3->token_str + "\n" 
																					+ $4->token_str + "\n"
																					+ "loop\n";
																$$ = ret;
											}
			|	WHILE expr codes ENDWHILE					{
																t_token *ret = new t_token();
																ret->token_str = 	"while " + $2->token_str + "\n" 
																					+ $3->token_str + "\n"
																					+ "endwhile\n";
																$$ = ret;
															}
			;

/* return */
retrnst		:	RETRN expr		{
									// �b��B TODO:���� return �ɑΉ�������
									t_token *ret = new t_token();
									ret->token_str = "";
									$$ = ret;
								}
			|	RETRN			{
									// �b��B TODO:���� return �ɑΉ�������
									t_token *ret = new t_token();
									ret->token_str = "";
									$$ = ret;
								}
			;

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

 void yyerror (char const *s) {
   fprintf (stderr, "%s\n", s);
 }
