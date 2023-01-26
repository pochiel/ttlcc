#include <string>
#include <iostream>
#include <vector>
#include <map>
#include "t_token.hpp"
#include "variable_manager.hpp"

#ifndef __FUNCTION_H__
#define __FUNCTION_H__

class function_info {
    public:
    std::string function_name;
    std::vector<std::string> argument_table;
    std::vector<std::string> return_val_table;
    // realname → localname 変換用の参照テーブル
    std::map<std::string, std::string> real_2_local_symbol_conv_tbl;
    int current_arg_cnt;
    int current_var_cnt;
};

class function_manager {
private:
    /**
     * Singleton用インスタンス
     */
    static function_manager *_singleton;

    /**
     * コンストラクタ
     */
    function_manager();

    /**
     * コピーコンストラクタ
     */
    function_manager(const function_manager &src);

    // 関数シンボルテーブル
    std::map<std::string, function_info *> function_symbol_tbl;

    // 変数管理クラスのインスタンス
    variable_manager * my_variable_manager;

    // 関数情報管理構造体を取得する
    function_info * get_function_info(std::string & func_name) ;

    // realname → localname 変換関数
    void set_localname_to_conv_tbl(std::string function_name, std::string realname, std::string localname);
    std::string convert_name_to_local(std::string function_name, std::string realname);
public:
    /**
     * デストラクタ
     */
    virtual ~function_manager();
    /**
     * インスタンスを取得する
     */
    static function_manager *get_instance();

    /* 新関数 */
    // (1)グローバル変数をphysical_name に読み替える
    // (2)ローカル変数をphysical_nameに読み替える
    std::string select_realname_to_physicalname(std::string function_name, std::string realname);

    // (1)-2 グローバル/ローカル変数変数を t_token に読み替える
    t_token * select_realname_to_t_token(std::string function_name, std::string realname);

    // (3)関数呼び出し時に引数セットをphysical_nameのセットに読み替えたい
    // (4)関数内で任意の引数をphysical_nameのセットに読み替えたい((2)で実現できるのでは？)
    std::vector<std::string> select_functionname_to_argument_physicalname_list(std::string funciton_name);
    
    // (5)プロトタイプ宣言から、引数・戻り値のリストを登録したい
    // (6)関数定義から、引数・戻り値のリストを登録したい
    void set_function_info(std::string & func_name, std::string & input_args, std::string & retrn_vals, bool is_prototype) ;

    // (7)関数呼び出し時に戻り値のリストを取得したい
    // (8)関数の中で戻り値のリストを取得したい
    std::vector<std::string> select_functionname_to_returnval_physicalname_list(std::string funciton_name);

    
    // (9)現在実行中の関数名を登録する
    std::string set_function_name(std::string & name) ;

    // (10)現在実行中の関数名を取得する
    std::string get_function_name() ;

    // (11)関数の中で使用するローカル変数を登録したい
    void set_localname_and_realname(std::string func_name, std::string real_name, t_token& token, bool is_function_argument) ;

    /* 旧関数　下記の関数は最終的には削除する */
    // 関数情報
    /*
    // 現在解析中の関数名
    // 関数呼び出し時の処理系
    std::string initialize_arg(std::string & function_name, t_token & input_args) ;
    std::string initialize_returnval(std::string & function_name ) ;
    // ローカル変数の設定に関する処理
    void set_localname_and_realname(std::string func_name, t_token& token, bool is_function_argument) ;
    t_token * get_local_name(std::string func_name, std::string var_name);
    */
};


#endif // __FUNCTION_H__