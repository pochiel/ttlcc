#include <string>
#include <iostream>
#include <vector>
#include <sstream>
#include <map>
#include "t_token.hpp"
#include "function.hpp"
#include "common.hpp"
#include "variable_manager.hpp"

/* 定数 */
#define C_ERRORBUF_MAX (256)

/* グローバル変数 */
static std::string current_function_name("");
static std::string current_function_args("");
function_manager *function_manager::_singleton = NULL;

/* プロトタイプ宣言 */
extern "C" void yyerror(const char* s);

function_manager::function_manager()
{
    my_variable_manager = variable_manager::get_instance();
}

function_manager::function_manager(const function_manager &src)
{
    /* シングルトンをコピーしておく */
    _singleton = src._singleton;
}


// (1)グローバル変数をphysical_name に読み替える
// (2)ローカル変数をphysical_nameに読み替える
std::string function_manager::select_realname_to_physicalname(std::string function_name, std::string realname){
    return my_variable_manager->select_localname_to_physicalname(
                                                                    function_name,
                                                                    convert_name_to_local(function_name, realname)
                                                                );
}

// (1)-2 グローバル/ローカル変数変数を t_token に読み替える
t_token * function_manager::select_realname_to_t_token(std::string function_name, std::string realname) {
    t_token * ret = my_variable_manager->get_physicalname_from_table(convert_name_to_local(function_name, realname));
    return ret;
}

// (3)関数呼び出し時に引数セットをphysical_nameのセットに読み替えたい
// (4)関数内で任意の引数をphysical_nameのセットに読み替えたい((2)で実現できるのでは？)
std::vector<std::string> function_manager::select_functionname_to_argument_physicalname_list(std::string funciton_name) {
    function_info * func_info = get_function_info(funciton_name);
    std::vector<std::string> ret;
    int current_arg_cnt = 0;
    for(t_token arg : func_info->argument_table){
        // 型情報を取り出して、"argX" のルールで localnameを作り、そこからさらに physicalname に変換してvectorに登録する
        ret.push_back( 
            my_variable_manager->select_localname_to_physicalname(
                                                                    funciton_name,
                                                                    "arg" + std::to_string(current_arg_cnt++)
                                                                )
        );
    }
    return ret;
}

std::vector<t_token> function_manager::select_functionname_to_argument_t_token_info_list(std::string funciton_name) {
    function_info * func_info = get_function_info(funciton_name);
    return func_info->argument_table;
}


// (5)プロトタイプ宣言から、引数・戻り値のリストを登録したい
// (6)関数定義から、引数・戻り値のリストを登録したい
void function_manager::set_function_info(std::string & func_name, std::vector<t_token> & input_args, std::vector<t_token> & retrn_vals, bool is_prototype){
    // シンボルテーブルに関数情報が登録されていなければ登録する
    // シンボルテーブルに関数情報が登録されていない＝プロトタイプ宣言 or 関数定義実体
    // どちらかを見つけたら片方でだけ下記の処理を行う
    func_name = common_utl::trim(func_name);
    int current_arg_cnt = 0;
    if(function_symbol_tbl.count(func_name) == 0) {
        function_info * temp = new function_info();
        // 関数名を保存
        temp->function_name = func_name;
        // 引数情報を保存
        temp->argument_table = input_args;
        // 戻り値情報を保存
        temp->return_val_table = retrn_vals;
        // 関数テーブルに追加
        function_symbol_tbl[func_name] = temp;
        // 戻り値実体変数を作成
        // set_localname_and_realname の中で関数テーブルにアクセスしているので
        // 関数テーブルに値を追加してから戻り値を登録しないとコンパイルエラーになってしまう
        for(t_token y : retrn_vals){
            // 戻り値はユニークな realname を持たないため、プロトタイプ宣言の時点で実体変数を登録してしまう
            std::string retname = "ret" + std::to_string(current_arg_cnt++);
            set_localname_and_realname(func_name, retname, y, E_KIND_FUNCTION_RETURN_VALUE );
        }

    }
    // シンボルテーブルに関数情報登録済み かつ 関数定義実体作成時のみ変数の登録を行う
    if( !is_prototype ){    // プロトタイプ宣言では変数の実体は作らない
        // 引数の実体を登録する
        for(t_token x : input_args){
            set_localname_and_realname(func_name, x.token_str, x, E_KIND_FUNCTION_ARGUMENT );
        }
    }
}

// (7)関数呼び出し時に戻り値のリストを取得したい
// (8)関数の中で戻り値のリストを取得したい
std::vector<std::string> function_manager::select_functionname_to_returnval_physicalname_list(std::string funciton_name){
    function_info * func_info = get_function_info(funciton_name);
    std::vector<std::string> ret;
    int current_arg_cnt = 0;
    for(t_token arg : func_info->return_val_table){
        // 型情報を取り出して、"retX" のルールで localnameを作り、そこからさらに physicalname に変換してvectorに登録する
        ret.push_back( 
            my_variable_manager->select_localname_to_physicalname(
                                                                    funciton_name,
                                                                    "ret" + std::to_string(current_arg_cnt++)
                                                                )
        );
    }
    return ret;
}
std::vector<t_token> function_manager::select_functionname_to_returnval_t_token_info_list(std::string funciton_name) {
    function_info * func_info = get_function_info(funciton_name);
    return func_info->return_val_table;
}

// (9)現在実行中の関数名を登録する
std::string function_manager::set_function_name(std::string & name) {
    current_function_name = name;
    current_function_args = "";
    return current_function_name;
}

// (10)現在実行中の関数名を取得する
std::string function_manager::get_function_name() {
    return current_function_name;
}

// (11)関数の中で使用するローカル変数を登録したい
void function_manager::set_localname_and_realname(std::string func_name, std::string realname, t_token& token, E_VARIABLE_KIND variable_kind) {
    function_info * func_info = get_function_info(func_name);
    t_token * temp = new t_token(token);
    if(!func_info) {
        char buf[C_ERRORBUF_MAX];
        snprintf(buf, sizeof(buf), "Error! Inner error. cant find function info %s\n", func_name.c_str());
        yyerror(buf);
    }
    // localnameの登録
    switch(variable_kind) {
        case E_KIND_FUNCTION_ARGUMENT:
            // 関数引数
            temp->localname = "arg" + std::to_string(func_info->current_arg_cnt);
            func_info->current_arg_cnt++;
            break;
        case E_KIND_FUNCTION_RETURN_VALUE:
            // 単なる変数
            temp->localname = "ret" + std::to_string(func_info->current_ret_cnt);
            func_info->current_ret_cnt++;
            break;
        case E_KIND_VARIABLE:
            // 単なる変数
            temp->localname = "var" + std::to_string(func_info->current_var_cnt);
            func_info->current_var_cnt++;
            break;
        default:
            break;
    }
    set_localname_to_conv_tbl(func_name, realname, temp->localname);
    temp->realname = token.realname;
    temp->is_lending = false;
    temp->parent_function = func_name;
    temp->synbol_info = &token;
    // physicalname の登録
    temp->physicalname = "";     // physicalname は variable_manager におまかせ
    my_variable_manager->set_physicalname_to_table(temp->localname, *temp);
}

// 関数名から関数情報を引く
function_info * function_manager::get_function_info(std::string & func_name) {
    if(function_symbol_tbl.count(func_name) != 0) {
        return function_symbol_tbl[func_name];
    } else {
        // 関数情報未登録 コンパイルエラー
        char buf[256];
        snprintf(buf, sizeof(buf), "Error! Inner error. cant find function info %s\n", func_name.c_str());
        yyerror(buf);
        return NULL;
    }
}

// 関数名 + realname で localname を登録する
void function_manager::set_localname_to_conv_tbl(std::string function_name, std::string realname, std::string localname) {
    function_info * func = get_function_info(function_name);
    func->real_2_local_symbol_conv_tbl[realname] = localname;
}

// 関数名 + realname から localname を引く
std::string function_manager::convert_name_to_local(std::string function_name, std::string realname) {
    function_info * func = get_function_info(function_name);
    return func->real_2_local_symbol_conv_tbl[realname];
}


/************************************ 汎用インターフェース **************************************/

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
    }
    return _singleton;
}

/************************************ ここから先は未使用 **************************************/

#if 0
void function_manager::_initialize()
{
}

/* 	ローカル変数は関数に所属し x のような「変数名」と所属している「関数名」の組み合わせから
    まず arg1 のような「 単純変数名 」に変換し、「 単純変数名 」と「関数名」の組み合わせから
    loabcdef01funcnamearg1 のような「 実効引数名 」(TTLにおける最終的に有効な変数名）を引く */

// 変数名を単純変数名に変換する
std::string function_manager::convert_name_to_simple(std::string func_name, t_token& token) {
    return ret;
}

t_token * function_manager::get_local_name(std::string func_name, std::string var_name) {
    function_info * func_info = get_function_info(func_name);
    if(!func_info) {
        yyerror("Error! Inner error. cant find function info %s\n", func_name.c_str());
    }
    std::string physical_name = variable_manager::get_instance()->select_localname_to_physicalname(
				function_manager::get_instance()->get_function_name(),
				var_name
			);
    return variable_manager::get_instance()->get_physicalname_from_table(physical_name).synbol_info;
}

#endif