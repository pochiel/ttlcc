#include "t_token.hpp"
#include "function.hpp"
#include <iostream>
#include <sstream>
#include <iomanip>
#include "crc.h"

	// 文字列をハッシュ値に変えてくれる便利関数（そのうち場所移動するかも）
	std::string t_token::str_to_hash(std::string name) {
		std::ostringstream ss;
		ss << std::setfill('0') << std::setw(8) << std::hex << crc_32((uint8_t*)name.c_str(), name.length());
		return ss.str();
	}

	t_token::t_token(){
		token_str = "";
		comment = "";
		is_local = false;
		real_name="";
	}
	t_token::t_token(const t_token &t){
		token_str = t.token_str;
		comment = t.comment;
		type = t.type;
		is_local = false;
		real_name="";
	}
	// 当該トークンはローカル変数であると教える
	void t_token::set_local_name(std::string name) {
		std::string simple_name = set_argument(name);		// 引数名を登録し、実効引数名を取得する
		is_local = true;
		real_name = token_str;
		token_str = convert_name_to_local(get_function_name(), simple_name);
	}

	// トークン名を実名からローカル名に変更する
	std::string t_token::convert_name_to_local(std::string function_name, std::string realname) {
		// ローカル変数名 = lo CRC32ハッシュ(16進8桁)[関数名+変数名][関数名10文字][変数名10文字]
		std::string temp = (function_name + realname);
		std::string ret  = "lo" + str_to_hash(temp)
								+ function_name.substr(0,10)
								+ realname.substr(0,10);
		std::cout << "temp: " << temp << "\n";
		std::cout << "realname: " << realname << "\n";
		std::cout << "localname: " << ret << "\n";
		return ret;
	}

	std::string t_token::get_format_comment() {
		if(comment.empty()){
			return "";
		} else {
			return "note right\n"
					+ comment + "\n"
					+ "end note\n";
		}
	}
	//  +演算子のオーバーロード
	t_token t_token::operator+(const t_token& t2) {
		t_token ret;
		ret.token_str = this->token_str + t2.token_str;
		ret.comment = this->comment + t2.comment;
		ret.type = this->type;
		return ret;
	}
