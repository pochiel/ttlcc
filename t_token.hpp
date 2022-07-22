#ifndef __T_TOKEN_HPP_
#define __T_TOKEN_HPP_
#include <string>

typedef enum {
	TYPE_INT=0,
	TYPE_STRING,
	TYPE_VOID,
} E_Types;

class t_token {
	public:
	t_token();
	t_token(const t_token &t);
	std::string token_str;
	std::string comment;
	E_Types type;
	std::string get_format_comment();
	//  +演算子のオーバーロード
	t_token operator+(const t_token& t2);
};

#endif // __T_TOKEN_HPP_