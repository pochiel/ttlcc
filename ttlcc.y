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

/* グローバル変数 */
FILE * output_file_ptr = NULL;

/* プロトタイプ宣言 */
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
/* 終端記号 */
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
/* 非終端記号 */
%type<ctype> program codes var ifst forst functionst dowhilest retrnst breakst expr return_types args typest callst manytokenst functionnamest

%start program

%%

/* プログラムとはなんぞや */
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

/* 関数とはなんぞや */
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
														// main関数内にいるなら exit でプログラム終了。	そうでなければ return
														// 暫定：最終的にはマクロ先頭で call main ジャンプするようにし、returnで戻ってきて終了するのが好ましい。
														// そのためには、全コードをトランスパイル後に 関数テーブルを走査し、main関数をもっている場合といない場合で
														// 処理を分けなきゃならん。　めんど。
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
													// ローカル変数名の設定
													if(get_function_name() != ""){
														$$->set_local_name($$->token_str);
													}
													switch($1->type){
														case TYPE_STRING:
															// string型変数を初期化
															$$->token_str = $$->token_str + "=''\n";
															break;
														case TYPE_INT:
															// int型変数を初期化
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
													// ローカル変数名の設定
													if(get_function_name() != ""){
														$$->set_local_name($$->token_str);
													}
													switch($1->type){
														case TYPE_STRING:
															// 暗黙型キャストを経ての string型変数初期化
															$$->token_str = $$->token_str + "='" + $4->token_str + "'\n";
															break;
														case TYPE_INT:
															// int型変数を初期化
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
															// string型変数を初期化
															$$->token_str = $$->token_str + "='" + $4->token_str + "'\n";
															break;
														case TYPE_INT:
															// 文字列型→整数型の暗黙の型キャストは行われない
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
													/* 暫定 */ 
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

/* 超暫定 */
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

/* 関数呼び出し */
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
//													ret->comment = "";	/* コメントは消しておく */
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
//													ret->comment = "";	/* コメントは消しておく */
//													$$ = ret;
//												}
//			| IF EXPR block ELSE ifst			{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"if (" + $2->token_str + ") then (true)\n" 
//																		+ ($1->get_format_comment() == "" ? "" : ": ;\n" + $1->get_format_comment() + "\n") 
//																		+ $3->token_str + "\n"
//																		+ "else" + $5->token_str + "\n"		/* elseif */
//																		+ ($4->get_format_comment() == "" ? "" : ": ;\n" + $4->get_format_comment() + "\n");
//													/* 末尾非終端記号の ifst で endifしているはずなので ここでは endif しない */
//													ret->comment = "";	/* コメントは消しておく */
//													$$ = ret;
//												}
//
//forst   :   FOR EXPR block						{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"while (" + $2->token_str + ")\n" 
//																		+ $1->get_format_comment() + "\n" 
//																		+ $3->token_str + "\n"
//																		+ "end while\n";
//													ret->comment = "";	/* コメントは消しておく */
//													$$ = ret;
//												}
//		|	WHILE EXPR block					{
//													t_token *ret = new t_token();;
//													ret->token_str = 	"while (" + $2->token_str + ")\n" 
//																		+ $1->get_format_comment() + "\n" 
//																		+ $3->token_str + "\n"
//																		+ "end while\n";
//													ret->comment = "";	/* コメントは消しておく */
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
//													ret->comment = "";	/* コメントは消しておく */
//													$$ = ret;
//											}
//			;

/* return */
retrnst		:	RETRN EXPR		{
									t_token *ret = new t_token();;
									ret->token_str = 	":return " + $2->token_str + ";\n" 
														+ $1->get_format_comment() + "\n"
														+ "stop\n";
									ret->comment = "";	/* コメントは消しておく */
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
									ret->comment = "";	/* コメントは消しておく */
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
	fprintf(output_file_ptr, "%s", msg.c_str()); // ファイルに書く
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
