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
	t_token();
	t_token(const t_token &t);
	std::string token_str;
	std::string preamble_str;		// 前置き文（次の結合時に先に結合する）
	E_Types type;
	//  +演算子のオーバーロード
	t_token operator+(const t_token& t2);
	// ローカル変数であるかどうか
	bool is_local;
	std::string real_name;
	void set_local_name(t_token& token);
	static t_token get_local_name(std::string name);
	static t_token* string_concatenation(const t_token& t1, const t_token& t2);
	static std::string str_to_hash(std::string name);
	static std::string convert_name_to_local(std::string function_name, std::string realname);
};

#endif // __T_TOKEN_HPP_