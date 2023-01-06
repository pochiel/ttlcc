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
#include "variable_manager.hpp"

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
%token<ctype> INT STRING VOID STR_RETERAL INT_RETERAL MINUS_INT_RETERAL
%token<ctype> EQUAL BIT_NOT PLUS MINUS ASTA SLASH MOD LEFT_SHIFT RIGHT_SHIFT LEFT_SHIFT_LOGIC RIGHT_SHIFT_LOGIC COMMA
%token<ctype> BIT_AND BIT_XOR BIT_OR GRATER_THAN_LEFT GRATER_THAN_RIGHT EQUAL_GRATER_THAN_LEFT EQUAL_GRATER_THAN_RIGHT
%token<ctype> EQUAL_EQUAL LOGICAL_NOT NOT_EQUAL LOGICAL_AND LOGICAL_OR 
%token<ctype> TOKEN RESERVED_WORD
%token<ctype> CR BRACE END_BRACE IMPORT
%token<ctype> LEFT_INDEX_BRACKET RIGHT_INDEX_BRACKET
%token<ctype> EXTERN

/* 非終端記号 */
%type<ctype> program codes var ifst forst functionst dowhilest retrnst expr return_types args typest callst manytokenst functionnamest else_if_list initialize_intval_st initialize_strval_st return_vars accessable_var array_reteral prototypest

%start program

%right BIT_NOT EQUAL
%left PLUS MINUS ASTA SLASH MOD
%left LEFT_SHIFT RIGHT_SHIFT LEFT_SHIFT_LOGIC RIGHT_SHIFT_LOGIC
%left EQUAL_EQUAL LOGICAL_NOT NOT_EQUAL LOGICAL_AND LOGICAL_OR
%left BIT_AND BIT_XOR BIT_OR GRATER_THAN_LEFT GRATER_THAN_RIGHT EQUAL_GRATER_THAN_LEFT EQUAL_GRATER_THAN_RIGHT
%glr-parser
%%

/* プログラムとはなんぞや */
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
													function_manager::get_instance()->set_function_name($1->token_str);
													$$ = $1;
												}

/* 関数とはなんぞや */
functionst	:	FUNCTION return_types functionnamest BRACE args END_BRACE codes ENDFUNCTION	{
														$$ = new t_token();
														std::cout << "return_types:" << $2->token_str << "\n";
														std::cout << "TOKEN:" << $3->token_str << "\n";
														std::cout << "args:" << $5->token_str << "\n";
														std::cout << "codes:" << $7->token_str << "\n";
														// 関数情報を登録
														function_manager::get_instance()->set_function_info($3->token_str, $5->token_str, $2->token_str);
														// ラベルを生成
														$$->token_str = 	std::string(
																					":" + $3->token_str + "\n"
																					+ $7->token_str + "\n"
														);
														// 引数にアクセスできるようにローカル変数として登録
														std::vector<std::string> var_array = common_utl::split($5->token_str, ',');
														for(std::string x : var_array){
															std::vector<std::string> var = common_utl::split(x, ' ');
															t_token * temp = new t_token();
															temp->real_name = var[1];
															if(var[0]=="int"){
																temp->type = TYPE_INT;
															} else if(var[0]=="string") {
																temp->type = TYPE_STRING;
															} else {
																temp->type = TYPE_VOID;
																break;	// 登録しないで終了
															}
															function_manager::get_instance()->set_local_name($3->token_str, *temp);
														}

														// main関数内にいるなら exit でプログラム終了。	そうでなければ return
														// 暫定：最終的にはマクロ先頭で call main ジャンプするようにし、returnで戻ってきて終了するのが好ましい。
														// そのためには、全コードをトランスパイル後に 関数テーブルを走査し、main関数をもっている場合といない場合で
														// 処理を分けなきゃならん。　めんど。
														if(function_manager::get_instance()->get_function_name()=="main") {
															$$->token_str += "exit\n";
														} else {
															$$->token_str += "return\n";
														}
													}
			;

prototypest	:	EXTERN return_types functionnamest BRACE args END_BRACE {
														// 関数情報を登録（TTLマクロ的には特にすることはない）
														function_manager::get_instance()->set_function_info($3->token_str, $5->token_str, $2->token_str);
												}

return_types:	return_types typest				{
													$$ = new t_token();
													$$->token_str = $1->token_str + " " + $2->token_str;
												}
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
													// ローカル変数名の設定
													if(function_manager::get_instance()->get_function_name() != ""){
														function_manager::get_instance()->set_local_name(function_manager::get_instance()->get_function_name(), *$$);
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
													$$->type = $1->type;
													// ローカル変数名の設定
													if(function_manager::get_instance()->get_function_name() != ""){
														function_manager::get_instance()->set_local_name(function_manager::get_instance()->get_function_name(), *$$);
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
			// 整数配列（初期化なし）
			|	INT TOKEN LEFT_INDEX_BRACKET INT_RETERAL RIGHT_INDEX_BRACKET	{
													$$ = new t_token(*$2);
													$$->type = TYPE_INT_ARRAY;
													// ローカル変数名の設定
													if(function_manager::get_instance()->get_function_name() != ""){
														function_manager::get_instance()->set_local_name(function_manager::get_instance()->get_function_name(), *$$);
													}
													$$->token_str = "intdim " + $$->token_str + " " + $5->token_str + "\n";
												}
			// 文字列配列（初期化なし）
			|	STRING TOKEN LEFT_INDEX_BRACKET INT_RETERAL RIGHT_INDEX_BRACKET	{
													$$ = new t_token(*$2);
													$$->type = TYPE_STRING_ARRAY;
													// ローカル変数名の設定
													if(function_manager::get_instance()->get_function_name() != ""){
														function_manager::get_instance()->set_local_name(function_manager::get_instance()->get_function_name(), *$$);
													}
													$$->token_str = "strdim " + $$->token_str + " " + $5->token_str + "\n";
												}
			// 整数配列（初期化あり）
			|	INT TOKEN LEFT_INDEX_BRACKET INT_RETERAL RIGHT_INDEX_BRACKET EQUAL LEFT_INDEX_BRACKET initialize_intval_st RIGHT_INDEX_BRACKET {
													std::vector<std::string> initialize_list = common_utl::split($8->token_str, ' ');
													$$ = new t_token(*$2);
													$$->type = TYPE_INT_ARRAY;
													// ローカル変数名の設定
													if(function_manager::get_instance()->get_function_name() != ""){
														function_manager::get_instance()->set_local_name(function_manager::get_instance()->get_function_name(), *$$);
													}
													std::string local_name = $$->token_str;
													$$->token_str = "intdim " + local_name + " " + $5->token_str + "\n";
													// 初期化処理の追加
													int i=0;
													for(std::string x : initialize_list){
														$$->token_str += local_name + "[" + std::to_string(i) + "]=" + x + "\n";
														i++;
													}
												}
			// 文字列配列（初期化あり）
			|	STRING TOKEN LEFT_INDEX_BRACKET INT_RETERAL RIGHT_INDEX_BRACKET EQUAL LEFT_INDEX_BRACKET initialize_strval_st RIGHT_INDEX_BRACKET	{
													std::vector<std::string> initialize_list = common_utl::split($8->token_str, ' ');
													$$ = new t_token(*$2);
													$$->type = TYPE_INT_ARRAY;
													// ローカル変数名の設定
													if(function_manager::get_instance()->get_function_name() != ""){
														function_manager::get_instance()->set_local_name(function_manager::get_instance()->get_function_name(), *$$);
													}
													std::string local_name = $$->token_str;
													$$->token_str = "strdim " + local_name + " " + $5->token_str + "\n";
													// 初期化処理の追加
													int i=0;
													for(std::string x : initialize_list){
														$$->token_str += local_name + "[" + std::to_string(i) + "]=" + x + "\n";
														i++;
													}
												}
			|	typest TOKEN EQUAL STR_RETERAL	{
													$$ = new t_token(*$2);
													$$->type = $1->type;
													// ローカル変数名の設定
													if(function_manager::get_instance()->get_function_name() != ""){
														function_manager::get_instance()->set_local_name(function_manager::get_instance()->get_function_name(), *$$);
													}
													switch($1->type){
														case TYPE_STRING:
															// string型変数を初期化
															$$->token_str = $$->token_str + "=" + $4->token_str + "\n";
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

args		:	args COMMA typest TOKEN			{
													$$ = new t_token();
													$$->token_str = $1->token_str + "," + $3->token_str + " " + $4->token_str;
												}
			|	typest TOKEN					{ 
													$$ = new t_token();
													$$->token_str = $1->token_str + " " + $2->token_str;
												}
			;

codes		:	var CR							{ $$ = $1; $$->token_str += "\n"; }
			|	callst CR						{ $$ = $1; $$->token_str += "\n"; }
			| 	array_reteral EQUAL callst CR	{ 	$$ = new t_token();
													$$->token_str = $3->token_str + $1->token_str; }
			|	ifst							{ $$ = $1; $$->token_str += "\n"; }
			|	forst							{ $$ = $1; $$->token_str += "\n"; }
			|	dowhilest						{ $$ = $1; $$->token_str += "\n"; }
			|	BREAK CR						{ $$ = new t_token(); $$->token_str = "break\n"; }
			|	CONTINUE CR						{ $$ = new t_token(); $$->token_str = "continue\n";	}
			|	retrnst CR						{ $$ = $1; $$->token_str += "\n"; }
			|	expr CR							{ $$ = $1; $$->token_str += "\n"; }
			|	codes var CR					{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes callst CR					{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			| 	codes array_reteral EQUAL callst CR	{ $$ = new t_token();
													$$->token_str = $1->token_str + $4->token_str + $2->token_str; }
			|	codes ifst						{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes forst						{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes dowhilest					{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes BREAK CR					{ $$ = new t_token(*$1); $$->token_str = "break\n"; }
			|	codes CONTINUE CR				{ $$ = new t_token(*$1); $$->token_str = "continue\n";	}
			|	codes retrnst CR				{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			|	codes expr CR					{ $$ = new t_token(*$1 + *$2); $$->token_str += "\n"; }
			;

accessable_var	:	TOKEN												{ $$ = new t_token( t_token::get_local_name($1->token_str) ); }
				|	TOKEN LEFT_INDEX_BRACKET expr RIGHT_INDEX_BRACKET	{ $$ = new t_token( t_token::get_local_name($1->token_str) ); $$->token_str += "[" + $3->token_str + "]"; }
				;

return_vars	: return_vars COMMA accessable_var							{
																			$$ = new t_token();
																			$$->token_str = $1->token_str + " " + $3->token_str;
																		}
			| accessable_var											{ $$ = $1; }
			;

array_reteral	: LEFT_INDEX_BRACKET return_vars RIGHT_INDEX_BRACKET 	{ $$ = $1; }
				;

expr		: INT_RETERAL						{ $$ = $1; $$->type = TYPE_INT; }
			| STR_RETERAL						{ $$ = $1; $$->type = TYPE_STRING; }
			| MINUS_INT_RETERAL					{ $$ = $1; $$->type = TYPE_INT; }
			| BRACE expr END_BRACE				{ $$ = new t_token(*$2); $$->token_str = "(" + $2->token_str + ")"; }
			| expr PLUS expr					{ 
													if( ($1->type == TYPE_STRING) || ($3->type == TYPE_STRING) ){
														// どちらかが文字列型なら文字列結合
														$$ = t_token::string_concatenation(*$1, *$3);
													} else {
														// そうでなければ数値加算
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
													// 前置き文があるならばそれを先に結合する
													if($3->preamble_str != ""){
														$$->token_str = $3->preamble_str;
													}
													$$->token_str += $1->token_str + "=" + $3->token_str;
												}
			// 論理演算系
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
			// ビット演算系
			| BIT_NOT expr						{ $$ = new t_token(); $$->token_str = "~" + $1->token_str; }
			| expr LEFT_SHIFT expr				{ $$ = new t_token(); $$->token_str = $1->token_str + "<<" + $3->token_str; }
			| expr RIGHT_SHIFT expr				{ $$ = new t_token(); $$->token_str = $1->token_str + ">>" + $3->token_str; }
			| expr LEFT_SHIFT_LOGIC expr		{ $$ = new t_token(); $$->token_str = $1->token_str + "<<<" + $3->token_str; }
			| expr RIGHT_SHIFT_LOGIC expr		{ $$ = new t_token(); $$->token_str = $1->token_str + ">>>" + $3->token_str; }
			| expr BIT_AND expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "&" + $3->token_str; }
			| expr BIT_OR expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "|" + $3->token_str; }
			| expr BIT_XOR expr					{ $$ = new t_token(); $$->token_str = $1->token_str + "|" + $3->token_str; }
			| TOKEN								{ $$ = new t_token( t_token::get_local_name($1->token_str) ); }
			// 配列の処理
			| TOKEN	LEFT_INDEX_BRACKET expr RIGHT_INDEX_BRACKET	{
														// int型以外を配列 index に指定したらあかん
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

/* 関数呼び出し */
callst		: TOKEN BRACE manytokenst END_BRACE 			{
																$$ = new t_token();
																// 前置き文があるならばそれを先に結合する
																if($3->preamble_str != ""){
																	$$->token_str = $3->preamble_str;
																}
																$$->token_str += function_manager::get_instance()->initialize_arg($1->token_str, *$3);
																$$->token_str += function_manager::get_instance()->initialize_returnval($1->token_str);
																$$->token_str += "call " + $1->token_str;
															}
			| RESERVED_WORD BRACE manytokenst END_BRACE		{
																$$ = new t_token();
																// 前置き文があるならばそれを先に結合する
																if($3->preamble_str != ""){
																	$$->token_str = $3->preamble_str;
																}
																$$->token_str += $1->token_str + " " + $3->token_str;
															}
			;

/*
	messagebox(("abc"+("de"+"f")), "ghijkl");	// messagebox("abcdef", "ghijkl");	と同じ結果になってほしい
	上記を実現するには・・・
		sprintf "%s%s" "de" "f"				(1)
		テンポラリ変数1=inputstr				
		sprintf "%s%s" "abc" テンポラリ変数1 (2)
		テンポラリ変数2=inputstr
		messagebox テンポラリ変数2 "ghijkl"
	となってほしい。
	次のルールでやればよいか？
		expr PLUS expr	:	{
			・static int i=0;
			・sprintf "%s%s" $1->token_str $3->token_str
				テンポラリ変数(++i)=inputstr
					を preamble_str に代入
			・token_str=テンポラリ変数(i)
		}

			↓↓

	("de"+"f") を評価したとき
		expr PLUS expr	:	{
			・sprintf "%s%s" "de" "f"
				テンポラリ変数(1)=inputstr
					を preamble_str に代入
			・token_str=テンポラリ変数(1)
		}
	("abc"+("de"+"f")) を評価したとき
		expr PLUS expr	:	{
			・sprintf "%s%s" "abc" テンポラリ変数(1)
				テンポラリ変数(2)=inputstr
					を preamble_str に代入
			・token_str=テンポラリ変数(2)
		}
	manytokenst	: manytokenst COMMA expr		: {
		$$->preamble_str=$1->preamble_str + $3->preamble_str;
		$$->token_str = $1->token_str + " " + $3->token_str;
	}
	RESERVED_WORD BRACE manytokenst END_BRACE	: {
		// 前置き文があるならばそれを先に結合する
		if($3->preamble_str != ""){
			$$->token_str = $3->preamble_str;
		}
		$$->token_str = "messagebox" + " " + $3->token_str;
	}

*/
manytokenst	: manytokenst COMMA expr				{
														$$ = new t_token(*$3);
														$$->preamble_str=$1->preamble_str + $3->preamble_str;
														$$->token_str = $1->token_str + " " + $3->token_str;
														$$->next_token = $1;
													}
			| expr									{
														$$ = $1;
													}
			;

/* if文系の処理 */
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

/* for文系の処理 */
forst   :   FOR TOKEN EQUAL expr TO expr codes NEXT			{
																t_token *ret = new t_token();
																ret->token_str = 	"for " + variable_manager::convert_name_to_local( function_manager::get_instance()->get_function_name(), function_manager::get_instance()->get_argument($2->token_str))
																					+ " " + $4->token_str + " " + $6->token_str + " \n" 
																					+ $7->token_str + "\n"
																					+ "next\n";
																$$ = ret;
															}
		|   FOR TOKEN EQUAL expr TO expr STEP expr codes NEXT {
																t_token *ret = new t_token();
																std::string counter_val = variable_manager::convert_name_to_local( function_manager::get_instance()->get_function_name(), function_manager::get_instance()->get_argument($2->token_str));
																ret->token_str = 	counter_val + "=" + $4->token_str + "\n"
																					+ "while " + counter_val + "<>" + $6->token_str + "\n"
																					+ $9->token_str + "\n"
																					+ counter_val + "=" + counter_val + "+ (" + $8->token_str + ")\n" 
																					+ "endwhile\n";
																$$ = ret;
															}
		;

/* while文系の処理 */
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
									// 暫定。 TODO:複数 return に対応させる
									t_token *ret = new t_token();
									ret->token_str = "";
									$$ = ret;
								}
			|	RETRN LEFT_INDEX_BRACKET manytokenst RIGHT_INDEX_BRACKET		{
									// 暫定。 TODO:複数 return に対応させる
									t_token *ret = new t_token();
									ret->token_str = "";
									$$ = ret;
								}
			|	RETRN			{
									// 暫定。 TODO:複数 return に対応させる
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
