#include "variable_manager.hpp"
#include <string>
#include <iostream>
#include "common.hpp"

variable_manager *variable_manager::_singleton = NULL;

variable_manager::variable_manager()
{
    /* なにもしない */
}

variable_manager::variable_manager(const variable_manager &src)
{
    /* シングルトンをコピーしておく */
    _singleton = src._singleton;
}

void variable_manager::_initialize()
{
    // temporary変数の初期化
    for(int i=0;i<C_TTL_ARRAY_MAX;i++){
        temp_val_array[i].id = i;
        temp_val_array[i].is_lending = false;
        temp_val_array[i].name = variable_manager::convert_name_to_temp(i);
    }
}

variable_manager::~variable_manager()
{
    /* オブジェクトを消す */
    delete _singleton;
}

variable_manager *variable_manager::get_instance()
{
    if (_singleton == NULL)
    {
        _singleton = new variable_manager();
        _singleton->_initialize();
    }
    return _singleton;
}

void variable_manager::set_symbol_table(const std::string key, const t_token & v) {
    var_symbol_tbl[key] = v;
}

t_token variable_manager::get_symbol_table(const std::string key) {
    return var_symbol_tbl[key];
}

// トークン名を実名からローカル名に変更する
std::string variable_manager::convert_name_to_local(std::string function_name, std::string name) {
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
const temp_val & variable_manager::lend_temporary_variable(){
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
void variable_manager::return_temporary_variable(const temp_val &v){
    // 返却処理
    temp_val_array[v.id].is_lending = false;
}

// realname から localnameを引く。
// 登録されていない場合、""を返す。
std::string variable_manager::select_realname_to_localname(std::string function_name, std::string realname){
    if (var_symbol_tbl.count(function_name + realname) == 0) {
        return "";
    }
    return var_symbol_tbl[(function_name + realname)].localname;
}
// localname から physicalname を引く。
// 登録されていない場合、""を返す。
std::string variable_manager::select_localname_to_physicalname(std::string function_name, std::string realname){
    // これだけはぶん回して検索する（参照ツリー作っちゃおうかな・・・）
    for(variable_node node : var_symbol_tbl){
        if(node.localname == ""){
            return node.physicalname;
        }
    }
}

// realname から physicalname を引く。
// 登録されていない場合、""を返す。
std::string variable_manager::select_realname_to_physicalname(std::string function_name, std::string realname){
    if (var_symbol_tbl.count(function_name + realname) == 0) {
        return "";
    }
    return var_symbol_tbl[(function_name + realname)].physicalname;
}
// realnameを登録する
std::string variable_manager::regist_realname(std::string function_name, std::string realname, std::string localname, bool is_argument){
    // is_argument って何に使おうと思ったんだっけ・・・？
    variable_node * p_symbol_node = new variable_node(0, realname, localname, function_name);
    // realname は最終的に (function_name + realname) でユニークになる
    var_symbol_tbl[(function_name + realname)] = p_symbol_node;
}
std::string variable_manager::regist_many_realnames(std::string function_name, std::string realname, bool is_argument){}

