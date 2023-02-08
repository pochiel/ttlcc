#ifndef __VARIABLE_MANAGER__HPP__
#define __VARIABLE_MANAGER__HPP__

#include <string>
#include <memory>
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
    std::shared_ptr<t_token> temp_val_array[C_TTL_ARRAY_MAX];
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
    std::map<std::string, std::shared_ptr<t_token>> var_symbol_tbl;

    // シンボルテーブル操作
    void    set_physicalname_to_table(const std::string localname, std::shared_ptr<t_token> v);
    std::shared_ptr<t_token> get_physicalname_from_table(const std::string localname);
    static std::string convert_name_to_physical(std::string function_name, std::string name);
    static std::string convert_name_to_temp(int id);
    const std::shared_ptr<t_token> lend_temporary_variable();

    /***
     * realname     : ローカル変数などを含む実際にコード上に見える名前
     * localname    : arg1, var1 などの中間名
     * physicalname : teraterm マクロ上での実際の名前
     * **/
    std::string select_localname_to_physicalname(std::string function_name, std::string realname);
    
    void return_temporary_variable(t_token &);
};

#endif