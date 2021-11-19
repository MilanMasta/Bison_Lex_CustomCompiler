%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
	#define MAX_SWITCH 100  //MAKSIMALAN broj case-ova
  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int tip  = -1;
  char * id;
  int param = 0;  // brojac parametara
  int args1 = 0; // brojac argumenata
  int tip_a = 0;  //tipovi argumenata
  int tip_switch = -1;  //tip za swich da ne bi doslo do missmatch-a
  int list_case[MAX_SWITCH]; // PROVJERA ZA DUPLIKAT CASE
  int brojac_case = 0; 
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _COMMA
%token _LPAREN
%token _RPAREN
%token _PARA
%token _PASO
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP
%token _INC
%token _SARROW
%token _SWITCH
%token _SCASE
%token _SDEF
%token _SLB
%token _SRB

%type <i> num_exp exp literal function_call argument rel_exp f_call


%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
       }
  ;

function_list
  : function
  | function_list function
  ;



function
  : _TYPE _ID  
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
        else 
          err("redefinition of function '%s'", $2);
      }
    _LPAREN parameter _RPAREN body 
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        param = 0;
      }
  ;

body
  : _LBRACKET fbody _RBRACKET
  ;

fbody //razdvojeno zbof returna exp koji se ne smije naci u void fji
	: variable_list statement_list
				{
        if(get_type(fun_idx) != VOID){
          warn("SEMANTIC: No value returned");
          }
      }
	| variable_list statement_list return_statement 
	;
	
variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : _TYPE 
   { tip =$1; 
           if($1 == VOID)
        {
					err("SEMANTIC ERR : type of variable can't be void");
				}
   }
   vars _SEMICOLON
	;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assign_in_one_line
    :
    | _ASSIGN literal
    {
    if(tip != get_type($2))
      err("missmatch of variables");
    }
    ;
    
vars 
	:	_ID assign_in_one_line
	      {
	      id = $1;
        if(lookup_symbol($1, VAR|PAR) == NO_INDEX)
           insert_symbol($1, VAR, tip, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $1);
      }
  | vars _COMMA _ID
	      {
        if(lookup_symbol($3, VAR|PAR) == NO_INDEX)
           insert_symbol($3, VAR, tip, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $3);
      }
	;	

switch
	: switch_head _SRB _LBRACKET switch_body _RBRACKET { brojac_case = 0;}
	;
switch_head
	: _SWITCH _SLB _ID { tip_switch = get_type(lookup_symbol($3, VAR|PAR)); }
	;


switch_body
	: case
	| case default
	;
default
	: _SDEF _SARROW statement
	;

case
	: _SCASE literal
	{
	if(tip_switch != get_type($2) ){
	err("SEMANTIC : type missmatch");
	}else{
		list_case[brojac_case] = $2;
		brojac_case++; 
	}
  } _SARROW statement 
  
	| case _SCASE literal 	{
	if(tip_switch != get_type($3)){
	err("SEMANTIC : type missmatch");
	}else{
	int i;
	int a = 1;
	for(i = 0;i < brojac_case;i++){
		if(list_case[i] == $3){
			a = 0;
		}
	}
	if(a == 1){
		list_case[brojac_case] = $3;
		brojac_case++;
	}else{
		err("SEMANTIC : cant switch with same case values");
	}
	}
	} _SARROW statement 

	;

para_f
		: _PARA _LPAREN _TYPE vars _SEMICOLON rel_exp _SEMICOLON _RPAREN statement
			 { 
	 int inx = lookup_symbol(id, VAR|PAR); 
	 	clear_symbols(inx); // brisanje int i iz tabele jer je to lokalna prom samo za ovu fju 
	 }
	| _PARA _LPAREN _TYPE vars _SEMICOLON rel_exp _SEMICOLON _PASO literal _RPAREN statement
	 { 
	 int inx = lookup_symbol(id, VAR|PAR);
	 	clear_symbols(inx);  // brisanje int i iz tabele jer je to lokalna prom samo za ovu fju 
	 }
	;

statement_list
  : /* empty */
  | statement_list statement
  ;
	

statement
  : compound_statement
  | assignment_statement
  | if_statement
  | increment_statement
	| void_call_statement
	| para_f
	| switch
  ;


inc
	: 
	| _INC 
	;
	
increment_statement          
	: _ID _INC _SEMICOLON   
	{
        int m = lookup_symbol($1, VAR|PAR);
        if(m == NO_INDEX)
          err("'%s' undeclared", $1);
      }
	;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
      {
        int idx = lookup_symbol($1, VAR|PAR);
        if(idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(get_type(idx) != get_type($3))
            err("incompatible types in assignment");
      }
  ;

num_exp
  : exp
  | num_exp _AROP exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
      }
  ;
  
void_call_statement  // VOID poziv bez dodjele
:f_call _SEMICOLON 			
			{
        if(get_type(fcall_idx) != VOID){
          err("SEMANTIC: int/uint must return a value ! ");
          }
      }
;

exp
  : literal 
	| _ID inc
      {
        $$ = lookup_symbol($1, VAR|PAR);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
      }
  | f_call 
  | _LPAREN num_exp _RPAREN
      { $$ = $2;  }
  ;

	
literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;
f_call
	: function_call
	| function_call _INC
	{ err("SEMANTIC : can't increment function"); }
	;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' is not a function", $1);
      }
    _LPAREN argument _RPAREN  
      {
        if(get_atr1(fcall_idx) != args1){
          err("wrong number of args to function '%s'", get_name(fcall_idx));
          }
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
        args1= 0;
      }
  ;

args
	: _ID  { tip_a = get_type(lookup_symbol($1, VAR|PAR)); } 
	| literal  { tip_a = get_type($1); } 
	;
	
args_f
: args { args1++; }
|args_f _COMMA args { args1++;  }
;

argument
  : /* empty */
    { args1 = 0; }

  | argument args_f
    { 
      if(get_atr2(fcall_idx) != tip_a){
      int a = get_atr2(fcall_idx);
        err("incompatible type for argument in '%s'",
            get_name(fcall_idx));
            }
            
    }
  ;

parameter
  : /* empty */
      { set_atr1(fun_idx, 0); }

  | parameter params
  ;
  
params
	: _TYPE _ID 
      {
        if($1 == VOID)
        {
					err("SEMANTIC ERR : type of parameter can't be void");
				}
				param++;
        insert_symbol($2, PAR, $1, param, NO_ATR);
        set_atr1(fun_idx, param);
        set_atr2(fun_idx, $1);

      }
  | params _COMMA _TYPE _ID 
        {
        if($3 == VOID)
        {
					err("SEMANTIC ERR : type of parameter can't be void");
				}
				param++;
        insert_symbol($4, PAR, $3, param, NO_ATR);
        set_atr1(fun_idx, param);
        set_atr2(fun_idx, $3);
      }
	;


if_statement
  : if_part %prec ONLY_IF
  | if_part _ELSE statement
  ;

if_part
  : _IF _LPAREN rel_exp _RPAREN statement
  ;
  

rel_exp
  : num_exp _RELOP num_exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
      }
  ;

ret
	: //empt
			{
        if(get_type(fun_idx) != VOID){
          warn("SEMANTIC: No value returned");
          }
      }
	| num_exp
		{
      if(get_type(fun_idx) == VOID){
      	err("SEMANTIC: Void can't return value");
      	}
    }
	;
return_statement
  : _RETURN ret _SEMICOLON
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}


int main() {
  int synerr;
  init_symtab();

  synerr = yyparse();

  clear_symtab();
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count)
    printf("\n%d error(s).\n", error_count);

  if(synerr)
    return -1; //syntax error
  else
    return error_count; //semantic errors
}

