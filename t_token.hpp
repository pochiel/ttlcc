#ifndef __T_TOKEN_HPP_
#define __T_TOKEN_HPP_
#include <string>

typedef enum {
	TYPE_INT=0,
	TYPE_STRING,
	TYPE_VOID,
	TYPE_FUNCTION,
	TYPE_INT_ARRAY,
	TYPE_STRING_ARRAY,
} E_Types;

class t_token {
public:
	t_token * next_token;			// funciton_info の argument_table/return_val_table に t_token * のリストを代入するための線形リスト用ポインタ
	t_token();
	t_token(const t_token &t);
	std::string token_str;
	std::string preamble_str;		// 前置き文（次の結合時に先に結合する）

	/* 付随する変数関連の情報 */
	E_Types type;
	// ローカル変数であるかどうか
	bool is_local;
	// コード中どんな名前で呼ばれているか
    std::string parent_function;
    std::string realname;
    std::string localname;
    std::string physicalname;
    t_token * synbol_info;
    bool is_lending;
	int array_size;
	//  +演算子のオーバーロード
	t_token operator+(const t_token& t2);
	// callst(関数呼び出し) の引数など
	static t_token get_local_name(std::string name);
	static t_token* string_concatenation(const t_token& t1, const t_token& t2);
};

#endif // __T_TOKEN_HPP_