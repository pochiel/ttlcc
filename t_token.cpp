#include "t_token.hpp"
#include "function.hpp"
#include <iostream>
#include <sstream>
#include <iomanip>
#include <map>
#include "crc.h"

	extern "C" void yyerror(const char* s);

	// シンボルテーブル
	static std::map<std::string, t_token> var_symbol_tbl;

	// 文字列をハッシュ値に変えてくれる便利関数（そのうち場所移動するかも）
	std::string t_token::str_to_hash(std::string name) {
		std::ostringstream ss;
		ss << std::setfill('0') << std::setw(8) << std::hex << crc_32((uint8_t*)name.c_str(), name.length());
		return ss.str();
	}

	t_token::t_token(){
		token_str = "";
		is_local = false;
		real_name="";
		preamble_str="";
	}
	t_token::t_token(const t_token &t){
		token_str = t.token_str;
		type = t.type;
		is_local = false;
		real_name="";
		preamble_str=t.preamble_str;
	}
	// 当該トークンはローカル変数であると教える
	void t_token::set_local_name(t_token& token) {
		std::string simple_name = set_argument(token.token_str);		// 引数名を登録し、実効引数名を取得する
		is_local = true;
		real_name = token_str;
		token_str = convert_name_to_local(get_function_name(), simple_name);
		var_symbol_tbl[token_str] = token;
	}

	// 登録済みの変数を取得する
	t_token t_token::get_local_name(std::string name) {
		t_token ret = var_symbol_tbl[convert_name_to_local(get_function_name(), get_argument(name))];
		printf("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
		printf("name:%s\n", name.c_str());
		printf("funcname:%s\n", get_function_name().c_str());
		printf("ret->token_str:%s\n", ret.token_str.c_str());
		printf("ret->type:%d\n", ret.type);
		printf("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
		return ret;
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

	//  +演算子のオーバーロード
	t_token t_token::operator+(const t_token& t2) {
		t_token ret;
		ret.token_str = this->token_str + t2.token_str;
		ret.type = this->type;
		ret.preamble_str = this->preamble_str + t2.preamble_str;
		return ret;
	}

	/* 例えば下記の結果 tempの中身は "abcdef111" であってほしい
		string temp = "";
		temp = ("abc" + (("de" + "f") + 111));
	上記を実現するには・・・
		loXXXXXXXXmainarg1=""
		sprintf "%s%s" "de" "f"				 (1)
		sprintf "%s%d" inputstr 111			 (2)
		sprintf "%s%s" "abc" inputstr		 (3)
		loXXXXXXXXmainarg1=inputstr
	となってほしい。
	(1) は単純に 「sprintf "%s%s" 」 $1->token_str $3->token_str を結合すれば良いが
	(2) では $1->token_str に inputstr が入っていてほしい。 ので、(1)の結果をどこかに退避しておき
		(2) を生成するときに先に (1) を結合してから
	(2) を結合する、みたいなことがしたい。　(3)でも同様にしたい。　そのために t_token に preamble_str（前置き文）っつうメンバを作った。
	*/
	// というわけで、t_token ２つを結合して 前置き文をもっている t_token を生成する関数
	t_token* t_token::string_concatenation(const t_token& t1, const t_token& t2) {
		t_token * ret = new t_token();
		ret->preamble_str = t1.preamble_str + "\n" + t2.preamble_str;
		if( (t1.type == TYPE_STRING) && (t2.type == TYPE_STRING) ) {
			ret->preamble_str += "sprintf \"%s%s\" " + t1.token_str + " " + t2.token_str + "\n";
		} else if ( (t1.type == TYPE_INT) && (t2.type == TYPE_STRING) ) {
			ret->preamble_str += "sprintf \"%d%s\" " + t1.token_str + " " + t2.token_str + "\n";
		} else if ( (t1.type == TYPE_STRING) && (t2.type == TYPE_INT) ) {
			ret->preamble_str += "sprintf \"%s%d\" " + t1.token_str + " " + t2.token_str + "\n";
		} else {
			yyerror("[ERROR] Internal error. string concatenation type missmatch.\n");
		}
		ret->token_str = "inputstr";
		ret->type = TYPE_STRING;
		return ret;
	}

