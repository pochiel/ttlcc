#include <string>
#include <iostream>
#include <vector>
#include <sstream>
#include <map>
#include "t_token.hpp"
#include "function.hpp"
#include "common.hpp"

static std::string current_function_name("");
static std::string current_function_args("");
static int current_arg_cnt = 0;
static std::map<std::string, int> argument_table;

std::string set_function_name(std::string & name) {
    current_function_name = name;
    current_function_args = "";
    current_arg_cnt = 0;
    argument_table.clear();
    return current_function_name;
}

// 引数名を登録し、実効引数名を返す
std::string set_argument(std::string name) {
    std::string ret = "arg" + std::to_string(current_arg_cnt);
    argument_table[name] = current_arg_cnt++;
    return ret;
}

// 引数名から、実効引数名を返す
std::string get_argument(std::string name) {
    std::string ret = "arg" + std::to_string(argument_table[name]);
    return ret;
}


std::string get_function_name() {
    return current_function_name;
}

std::string set_input_param(t_token & param) {
	// std::cout << "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" << param.token_str << "\n";
	return param.token_str;
}

std::string set_output_param(t_token & param) {
	if(param.type == TYPE_VOID) {
		return std::string("");
	}
	return param.token_str;
}

std::string initialize_arg(std::string & function_name, std::string & args) {
	std::vector<std::string> arg_array = common_utl::split(args, ',');
    std::string ret = "";
    int arg_cnt = 0;
    std::cout << function_name << "  :xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:  " << args <<"\n";
	for(std::string x : arg_array){
        ret += t_token::convert_name_to_local(function_name, std::string("arg") + std::to_string(arg_cnt));
        ret += "=" + x + "\n";
	}
    return ret;
}