#include "t_token.hpp"
#include "function.hpp"
#include <iostream>
#include <sstream>
#include <iomanip>
#include <map>
#include "variable_manager.hpp"

	extern "C" void yyerror(const char* s);

	t_token::t_token(){
		token_str = "";
		is_local = false;
		realname="";
		preamble_str="";
		next_token = NULL;
		localname = "";
		parent_function = "";
		physicalname = "";
		synbol_info = NULL;
		array_size=0;
	}
	t_token::t_token(const t_token &t){
		*this = t;
	}

	// 登録済みの変数を取得する
	t_token t_token::get_local_name(std::string name) {
		t_token ret = *function_manager::get_instance()->select_realname_to_t_token(
				function_manager::get_instance()->get_function_name(),
				name);
		printf("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
		printf("name:%s\n", name.c_str());
		printf("funcname:%s\n", function_manager::get_instance()->get_function_name().c_str());
		printf("ret->token_str:%s\n", ret.token_str.c_str());
		printf("ret->type:%d\n", ret.type);
		printf("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
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
	messagebox(("abc"+("de"+"f")), "ghijkl");	// messagebox("abcdef", "ghijkl");	と同じ結果になってほしい
	上記を実現するには・・・
		sprintf "%s%s" "de" "f"				(1)
		テンポラリ変数1=inputstr				
		sprintf "%s%s" "abc" テンポラリ変数1 (2)
		テンポラリ変数2=inputstr
		messagebox テンポラリ変数2 "ghijkl"
	となってほしい。
	そのために t_token に preamble_str（前置き文）っつうメンバを作った。
	*/
	// というわけで、t_token ２つを結合して 前置き文をもっている t_token を生成する関数
	t_token* t_token::string_concatenation(const t_token& t1, const t_token& t2) {
		t_token * ret = new t_token();
		const t_token &temp = variable_manager::get_instance()->lend_temporary_variable();

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
		ret->preamble_str += temp.physicalname + "=inputstr\n";
		ret->token_str = temp.physicalname;
		ret->type = TYPE_STRING;
		std::cout << "preamble:" << ret->preamble_str << "\n";
		std::cout << "token_str:" << ret->token_str << "\n";
		return ret;
	}

