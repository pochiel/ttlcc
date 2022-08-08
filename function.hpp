#include <string>
#include <iostream>
#include "t_token.hpp"

#ifndef __FUNCTION_H__
#define __FUNCTION_H__

std::string set_input_param(t_token & param) ;
std::string set_output_param(t_token & param) ;
std::string set_function_name(std::string & name) ;
std::string get_function_name() ;
std::string initialize_arg(std::string & function_name, std::string & args) ;
std::string set_argument(std::string name) ;

#endif // __FUNCTION_H__