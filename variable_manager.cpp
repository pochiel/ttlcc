#include "variable_manager.hpp"
#include <string>
#include <iostream>
#include "common.hpp"
#include "t_token.hpp"

/* 定数 */

/* グローバル変数 */
variable_manager *variable_manager::_singleton = NULL;

/* プロトタイプ宣言 */

variable_manager::variable_manager()
{
    // temporary変数の初期化
    for(int i=0;i<C_TTL_ARRAY_MAX;i++){
        temp_val_array[i].is_lending = false;
        temp_val_array[i].physicalname = variable_manager::convert_name_to_temp(i);
    }
}

variable_manager::~variable_manager()
{
    delete _singleton;
}

variable_manager *variable_manager::get_instance()
{
    if (_singleton == NULL)
    {
        _singleton = new variable_manager();
    }
    return _singleton;
}

// localname から physicalnameを登録
void variable_manager::set_physicalname_to_table(const std::string localname, t_token & v) {
    // physicalname を作成して登録
    v.physicalname = variable_manager::convert_name_to_physical(v.parent_function, v.localname);
    var_symbol_tbl[localname] = v;
}

// localname から physicalnameのデータ型を取得
t_token * variable_manager::get_physicalname_from_table(const std::string localname) {
    return & var_symbol_tbl[localname];
}

// トークン名を localname から physicalname に変更する
std::string variable_manager::convert_name_to_physical(std::string function_name, std::string name) {
    // ローカル変数名 = lo CRC32ハッシュ(16進8桁)[関数名+変数名][関数名10文字][変数名10文字]
    std::string temp = (function_name + name);
    std::string ret  = "lo" + common_utl::str_to_hash(temp)
                            + function_name.substr(0,10)
                            + name.substr(0,10);
    return ret;
}

// トークン名を実名からテンポラリ変数名に変更する
std::string variable_manager::convert_name_to_temp(int id) {
    // ローカル変数名 = temp + CRC32ハッシュ + id
    std::string temp = std::to_string(id);
    std::string ret  = "temp" + common_utl::str_to_hash(temp)
                            + temp.substr(0,10);
    return ret;
}
// 一次変数を 貸し出す
const t_token & variable_manager::lend_temporary_variable(){
    // Todo: 未使用の一次変数がない場合にエラーとする処理を追加する
    if(temp_val_array_index==C_TTL_ARRAY_MAX) {
        temp_val_array_index = 0;
    }
    // 未使用の変数を探して貸出処理
    while(temp_val_array[temp_val_array_index].is_lending) {
        temp_val_array_index++;
    }
    temp_val_array[temp_val_array_index].is_lending = true;
    return temp_val_array[temp_val_array_index++];
}
void variable_manager::return_temporary_variable(t_token &v){
    // 返却処理
    v.is_lending = false;
}

// localname から physicalname を引く。
// 登録されていない場合、""を返す。
std::string variable_manager::select_localname_to_physicalname(std::string function_name, std::string localname){
    return variable_manager::convert_name_to_physical(function_name, localname);
}
