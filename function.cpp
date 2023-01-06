#include <string>
#include <iostream>
#include <vector>
#include <sstream>
#include <map>
#include "t_token.hpp"
#include "function.hpp"
#include "common.hpp"
#include "variable_manager.hpp"

static std::string current_function_name("");
static std::string current_function_args("");
static int current_arg_cnt = 0;
static std::map<std::string, int> argument_table;
function_manager *function_manager::_singleton = NULL;

function_manager::function_manager()
{
    /* なにもしない */
}

function_manager::function_manager(const function_manager &src)
{
    /* シングルトンをコピーしておく */
    _singleton = src._singleton;
}

void function_manager::_initialize()
{
}

function_manager::~function_manager()
{
    /* オブジェクトを消す */
    delete _singleton;
}

function_manager *function_manager::get_instance()
{
    if (_singleton == NULL)
    {
        _singleton = new function_manager();
        _singleton->_initialize();
    }
    return _singleton;
}


std::string function_manager::set_function_name(std::string & name) {
    current_function_name = name;
    current_function_args = "";
    current_arg_cnt = 0;
    argument_table.clear();
    return current_function_name;
}

// プロトタイプ宣言・関数本体で関数情報を function table に追加する
void function_manager::set_function_info(std::string & func_name, std::string & input_args, std::string & retrn_vals){
    function_info * temp = new function_info();
    int current_arg_cnt = 0;

    // すでに登録済みなら何もしない
    if(function_symbol_tbl.count(func_name) != 0) {
        return;
    }

    // 関数名を保存
    temp->function_name = func_name;

    // 引数情報を保存
    std::vector<std::string> var_array = common_utl::split(input_args, ',');
	for(std::string x : var_array){
        std::vector<std::string> var = common_utl::split(x, ' ');
        temp->argument_table.push_back(var[0]);     // 型情報だけ追加
	}
    // 戻り値情報を保存
    std::vector<std::string> ret_array = common_utl::split(retrn_vals, ' ');
	for(std::string y : ret_array){
        temp->return_val_table.push_back(y);        // 型情報だけ追加
	}
    // 関数テーブルに追加
    function_symbol_tbl[func_name] = temp;
}

// 関数名から関数情報を引く
function_info * function_manager::get_function_info(std::string & func_name) {
    if(function_symbol_tbl.count(func_name) != 0) {
        return function_symbol_tbl[func_name];
    } else {
        return NULL;
    }
}


// 引数名を登録し、実効引数名を返す
std::string function_manager::set_argument(std::string name) {
    std::string ret = "arg" + std::to_string(current_arg_cnt);
    argument_table[name] = current_arg_cnt++;
    return ret;
}

// 引数名から、実効引数名を返す
std::string function_manager::get_argument(std::string name) {
    std::string ret = "arg" + std::to_string(argument_table[name]);
    return ret;
}


std::string function_manager::get_function_name() {
    return current_function_name;
}

std::string function_manager::initialize_arg(std::string & function_name, t_token & input_args) {
    std::string ret = "";
    int arg_cnt = 0;
    t_token * node = input_args.next_token;
	while(node != NULL){
        ret += variable_manager::convert_name_to_local(function_name, std::string("arg") + std::to_string(arg_cnt++));
        ret += "=" + x->token_str + "\n";
        node = input_args.next_token;
	}
    return ret;
}

std::string function_manager::initialize_returnval(std::string & function_name) {
    std::string ret = "";
/*	std::vector<std::string> arg_array = common_utl::split(args, ' ');
    int arg_cnt = 0;
    // std::cout << function_name << "  :xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:  " << args <<"\n";
	for(std::string x : arg_array){
        ret += variable_manager::convert_name_to_local(function_name, std::string("arg") + std::to_string(arg_cnt++));
        ret += "=" + x + "\n";
	}*/
    return ret;
}

/* 	ローカル変数は関数に所属し x のような「変数名」と所属している「関数名」の組み合わせから
    まず arg1 のような「 単純変数名 」に変換し、「 単純変数名 」と「関数名」の組み合わせから
    loabcdef01funcnamearg1 のような「 実効引数名 」(TTLにおける最終的に有効な変数名）を引く */

// 変数名を単純変数名に変換する
std::string function_manager::convert_name_to_simple(std::string func_name, t_token& token) {
    return ret;
}

// 当該トークンはローカル変数であると教える
// 制約：この関数は 確実に set_function_info の後に呼ぶ
void function_manager::set_local_name(std::string func_name, t_token& token) {
    function_info * func_info = get_function_info(func_name);
    if(!func_info) {
        yyerror("Error! Inner error. cant find function info %s\n", func_name.c_str());
    }
    std::string simple_name = "var" + std::to_string(func_info->current_arg_cnt);
    is_local = true;
    real_name = token_str;
    token_str = variable_manager::convert_name_to_local(func_name, simple_name);
    variable_manager::get_instance()->set_symbol_table(token_str, token);
}

void function_manager::get_local_name(std::string func_name, t_token& token) {
    function_info * func_info = get_function_info(func_name);
    if(!func_info) {
        yyerror("Error! Inner error. cant find function info %s\n", func_name.c_str());
    }
    std::string simple_name = "var" + std::to_string(func_info->current_arg_cnt);
    is_local = true;
    real_name = token_str;
    token_str = variable_manager::convert_name_to_local(func_name, simple_name);
    variable_manager::get_instance()->set_symbol_table(token_str, token);
}
