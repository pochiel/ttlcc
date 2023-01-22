#ifndef __VARIABLE_MANAGER__HPP__
#define __VARIABLE_MANAGER__HPP__

#include <string>
#include <map>
#include "t_token.hpp"

#define C_TTL_ARRAY_MAX     (65536)

class variable_manager {
private:
    /**
     * Singleton用インスタンス
     */
    static variable_manager *_singleton;

    /**
     * コンストラクタ
     */
    variable_manager();

    /**
     * コピーコンストラクタ
     */
    variable_manager(const variable_manager &src);

    // 一次変数配列
    t_token temp_val_array[C_TTL_ARRAY_MAX];
    // 一次変数配列のインデックス
    uint32_t temp_val_array_index = 0;
public:
    /**
     * デストラクタ
     */
    virtual ~variable_manager();
    /**
     * インスタンスを取得する
     */
    static variable_manager *get_instance();
    // シンボルテーブル
    std::map<std::string, t_token> var_symbol_tbl;

    // シンボルテーブル操作
    void    set_symbol_table(const std::string key, const t_token & v);
    t_token get_symbol_table(const std::string key);
    static std::string convert_name_to_local(std::string function_name, std::string realname);
    static std::string convert_name_to_temp(int id);
    const t_token & lend_temporary_variable();

    /***
     * realname     : ローカル変数などを含む実際にコード上に見える名前
     * localname    : arg1, var1 などの中間名
     * physicalname : teraterm マクロ上での物理名
     * **/
    std::string select_realname_to_localname(std::string function_name, std::string realname);
    std::string select_localname_to_physicalname(std::string function_name, std::string realname);
    std::string select_realname_to_physicalname(std::string function_name, std::string realname);

    /***
     * 変数を登録するときは arg なのか var なのかで状況が異なる
     */
    std::string regist_realname(std::string function_name, std::string realname, std::string localname, bool is_argument);
    std::string regist_many_realnames(std::string function_name, std::string realname, bool is_argument);
    void return_temporary_variable(t_token &);
};

#endif