#include <string>
#include <iostream>
#include <map>
#include "t_token.hpp"

#ifndef __FUNCTION_H__
#define __FUNCTION_H__

class function_info {
    public:
    std::string function_name;
    static std::map<std::string, int> argument_table;
    static std::map<std::string, int> return_val_table;
    int current_arg_cnt;
};

class function_manager {
private:
    /**
     * Singleton用インスタンス
     */
    static function_manager *_singleton;

private:
    /**
     * コンストラクタ
     */
    function_manager();

    /**
     * コピーコンストラクタ
     */
    function_manager(const function_manager &src);

    /**
     * 初期化する
     */
    void _initialize();

public:
    /**
     * デストラクタ
     */
    virtual ~function_manager();
    /**
     * インスタンスを取得する
     */
    static function_manager *get_instance();
    // 関数情報
    std::map<std::string, function_info *> function_symbol_tbl;
    void set_function_info(std::string & func_name, std::string & input_args, std::string & retrn_vals) ;
    function_info * get_function_info(std::string & func_name) ;
    // 現在解析中の関数名
    std::string set_function_name(std::string & name) ;
    std::string get_function_name() ;
    // 関数呼び出し時の処理系
    std::string initialize_arg(std::string & function_name, t_token & input_args) ;
    std::string initialize_returnval(std::string & function_name ) ;
    // 引数の登録に関する処理（改善したい
    std::string set_argument(std::string name) ;
    std::string get_argument(std::string name) ;
    // ローカル変数の設定に関する処理
    void set_local_name(std::string func_name, t_token& token) ;

};


#endif // __FUNCTION_H__