//let Node and vector can be seen by .hpp first so union know and can get them, so use (code requires) to let compiler know it should be read first.
%code requires {
    #include<vector>
    #include<string>
	#include<map>
    using namespace std;

    enum Nodetype {
        NODE_INT, NODE_BOOL, NODE_ID,
        NODE_PLUS, NODE_MINUS, NODE_MUL, NODE_DIV, NODE_MOD,
        NODE_GREATER, NODE_SMALLER, NODE_EQUAL,
        NODE_AND, NODE_OR, NODE_NOT,
        NODE_IF, NODE_DEF, NODE_FUNC, NODE_VAR, NODE_FUNC_CALL, NODE_FUNC_PARA, NODE_NAME,
        NODE_PRINT_NUM, NODE_PRINT_BOOL
    };

    struct Node {
        Nodetype ntype;
        int val;
		bool bval;
        string name; 
        vector<Node*> children;
        Node(Nodetype t) : ntype(t), val(0) {} 
        Node(Nodetype t, int v) : ntype(t), val(v) {}
		Node(Nodetype t, bool b) : ntype(t), bval(b) {}
    };
	Node *execute(Node* node);
	Node *execute(Node* node,map<string,Node*>local_var);//c++ can, c and python can't
	extern map<string,Node*>var_val;//only declares
}

%{
    #include<stdio.h>
    #include<string.h>
    #include<iostream>

    void yyerror(const char *message);
    extern int yylex();
	
%}
    
%union{
	int ival;
	bool bval;
	char *sval;//string
	struct Node *node;
	vector <Node*> *vec;//vector as children, with pointer in.
}
//let compiler know what type will they receive during parser
%token<ival> NUMBER 
%token<bval> BOOL_VAL
%token <sval> ID
%type<vec> exps params ids 

%type<node> plus_op minus_op multiply_op divide_op modulus_op
%type<node> greater_op smaller_op equal_op
%type<node> logical_op and_op or_op not_op
%type<node> if_exp fun_exp fun_call
%type<node> exp num_op
%type<node> program stmts stmt print_stmt def_stmt 
%type<node> variable param fun_ids fun_body fun_name last_exp
%type<node> test_exp then_exp else_exp

%token PRINT_NUM PRINT_BOOL PLUS MINUS MULTIPLY DIVIDE 
%token AND OR NOT MOD GREATER SMALLER EQUAL
%token DEFINE FUNC IF
%%
//Rules Section
program : stmts
stmts : stmts stmt
      | stmt
      ;
//one line
stmt : exp {execute($1);}
     | def_stmt {execute($1);}
     | print_stmt {execute($1);}
     ;
print_stmt : '('PRINT_NUM exp')' {
				Node* node=new Node(NODE_PRINT_NUM);
				node->children.push_back($3);
				$$=node;
			}
           |'('PRINT_BOOL exp')' {
                Node* node=new Node(NODE_PRINT_BOOL);
				node->children.push_back($3);
				$$=node;
            }
           ;
params : params param{
			$1->push_back($2);
			$$=$1;
		}
       | {
		   $$=new vector<Node*>(); 
	   }
       ;
ids : ids ID{
			Node *node=new Node(NODE_ID);
			node->name=$2;
			$1->push_back(node);
			$$=$1;
	   }
       | {
		   $$=new vector<Node*>();  
	   }
       ;
exps : exps exp{
		$1->push_back($2); 
        $$=$1;
	 }
     | exp{
		 $$=new vector<Node*>(); 
         $$->push_back($1);
	 }
     ;
exp : BOOL_VAL {$$=new Node(NODE_BOOL, $1);} 
    | NUMBER {$$=new Node(NODE_INT, $1);} 
    | variable {$$=$1;}
    | num_op {$$=$1;}
    | logical_op {$$=$1;}
    | fun_exp {$$=$1;}//point at function
    | fun_call {$$=$1;}
    | if_exp {$$=$1;}
    ;
num_op : plus_op {$$=$1;}
       | minus_op {$$=$1;}
       | multiply_op {$$=$1;}
       | divide_op {$$=$1;}
       | modulus_op {$$=$1;}
       | greater_op {$$=$1;}
       | smaller_op {$$=$1;}
       | equal_op {$$=$1;}
       ;

plus_op : '(''+' exp exps')' {
    Node *node = new Node(NODE_PLUS); 
    node->children.push_back($3);
    node->children.insert(node->children.end(), $4->begin(), $4->end());
    delete $4;
    $$=node;
};
minus_op : '(''-' exp exp')'{
	Node *node = new Node(NODE_MINUS); 
    node->children.push_back($3);
	node->children.push_back($4);
    $$=node;
};
multiply_op : '(''*' exp exps')'{
    Node *node = new Node(NODE_MUL); 
    node->children.push_back($3);
    node->children.insert(node->children.end(), $4->begin(), $4->end());
    delete $4;
    $$=node;
};
divide_op : '(''/' exp exp')'{
	Node *node = new Node(NODE_DIV); 
    node->children.push_back($3);
	node->children.push_back($4);
    $$=node;
};
modulus_op : '('MOD exp exp')'{
	Node *node = new Node(NODE_MOD); 
    node->children.push_back($3);
	node->children.push_back($4);
    $$=node;
};
greater_op : '(''>' exp exp')'{
	Node *node = new Node(NODE_GREATER); 
    node->children.push_back($3);
	node->children.push_back($4);
    $$=node;
};
smaller_op : '(''<' exp exp')'{
	Node *node = new Node(NODE_SMALLER); 
    node->children.push_back($3);
    node->children.push_back($4);
    $$=node;
};
equal_op : '(''=' exp exps')'{
	Node *node = new Node(NODE_EQUAL); 
    node->children.push_back($3);
    node->children.insert(node->children.end(), $4->begin(), $4->end());
    delete $4;
    $$=node;
};
logical_op : and_op {$$=$1;}
           | or_op {$$=$1;}
           | not_op {$$=$1;}
           ;
and_op : '('AND exp exps')'{
	Node *node = new Node(NODE_AND); 
    node->children.push_back($3);
    node->children.insert(node->children.end(), $4->begin(), $4->end());
    delete $4;
    $$=node;
};
or_op : '('OR exp exps')'{
	Node *node = new Node(NODE_OR); 
    node->children.push_back($3);
    node->children.insert(node->children.end(), $4->begin(), $4->end());
    delete $4;
    $$=node;
};
not_op : '('NOT exp')'{
	Node *node = new Node(NODE_NOT); 
    node->children.push_back($3);
    $$=node;
};
def_stmt : '('DEFINE variable exp')'{
	Node *node=new Node(NODE_DEF);
	node->children.push_back($3);//name
	node->children.push_back($4);//exp,which may be integer or function(Node) or others.
	$$=node;
};
variable : ID {
	Node *node=new Node(NODE_VAR);
	node->name=$1;//variable name
	$$=node;
};
//define function
fun_exp : '('FUNC fun_ids fun_body')'{ //(fun (x) (+ x 1))
	Node *node=new Node(NODE_FUNC);
	node->children.push_back($3);//parameters
	node->children.push_back($4);//Body
	$$=node;
};
fun_ids : '('ids')'{
	Node *node=new Node(NODE_FUNC_PARA);
	node->children.insert(node->children.end(), $2->begin(), $2->end());
	delete $2;
	$$=node;
};
fun_body : exp{//(+ 3 4) (- 8 6) like these
	$$=$1;
};
fun_call : '('fun_exp params')' {//anonymous
			Node *node=new Node(NODE_FUNC_CALL);
			node->children.push_back($2);//function body
			node->children.insert(node->children.end(), $3->begin(), $3->end());//parameters
			delete $3;
			$$=node;
		 }
         | '('fun_name params')'{//named
			Node *node=new Node(NODE_FUNC_CALL);
			node->children.push_back($2);//function name
			node->children.insert(node->children.end(), $3->begin(), $3->end());//parameters
			delete $3;
			$$=node; 
		 }
         ;
param : exp {$$=$1;};
last_exp : exp {$$=$1;};
fun_name : ID {
			Node *node=new Node(NODE_NAME);
			node->name=$1;
			$$=node;
		 };
if_exp : '('IF test_exp then_exp else_exp')'{
	Node *node=new Node(NODE_IF);
	node->children.push_back($3);
	node->children.push_back($4);
	node->children.push_back($5);
	$$=node;
};
test_exp : exp {$$=$1;};
then_exp : exp {$$=$1;};
else_exp : exp {$$=$1;};
%%
    //Subroutine Section
	map<string, Node*> var_val;
	string whaterror(int t){
		switch(t) {
			case NODE_INT:  return "Number";
			case NODE_BOOL: return "Boolean";
			case NODE_FUNC: return "Function";
		}
	}
	Node *execute(Node* node) {
		map<string, Node*> empty_local;
		return execute(node, empty_local);
	}
	Node *execute(Node* node, map<string,Node*>local_var){
		if (node->ntype == NODE_INT) {
			return node;
		}
		if (node->ntype == NODE_BOOL) {
			return node;
		}
		if (node->ntype == NODE_VAR) {
			if (local_var.find(node->name)!=local_var.end()) {//local var
				return local_var[node->name];
			}
			else if (var_val.find(node->name)!=var_val.end()) {//global_var
				return var_val[node->name];
			}
		}
		switch (node->ntype) {
			case NODE_PRINT_NUM:{
				Node *ans = execute((node->children)[0],local_var);
				cout<<ans->val<<endl;
				return 0;
			}	
			case NODE_PRINT_BOOL:{
				Node *ans = execute((node->children)[0],local_var);
				if(ans->bval==true)cout<<"#t"<<endl;
				else cout<<"#f"<<endl;
				return 0;
			}
			case NODE_PLUS:{
				int sum=0;
				for(int i=0; i<node->children.size();i++){
					Node* result = execute(node->children[i], local_var);
					if(result->ntype!=NODE_INT){
						cout<<"Type Error: Expect 'Number' but got '" << whaterror(result->ntype) << "'" << endl;
						exit(1);
					}
					sum+=result->val;
				}
				Node *ret=new Node(NODE_INT);
				ret->val=sum;
				return ret;
			}
			case NODE_MINUS:{
				Node* result = execute(node->children[0], local_var);
				if(result->ntype!=NODE_INT){
					cout<<"Type Error: Expect 'Number' but got '" << whaterror(result->ntype) << "'" << endl;
					exit(1);
				}
				Node* result1 = execute(node->children[1], local_var);
				if(result1->ntype!=NODE_INT){
					cout<<"Type Error: Expect 'Number' but got '" << whaterror(result1->ntype) << "'" << endl;
					exit(1);
				}
				int ans=(result->val)-(result1->val);
				Node *ret=new Node(NODE_INT);
				ret->val=ans;
				return ret;
			}
			case NODE_MUL:{
				int ans=1;
				for(int i=0; i<node->children.size();i++){
					Node* result = execute(node->children[i], local_var);
					if(result->ntype!=NODE_INT){
						cout<<"Type Error: Expect 'Number' but got '" << whaterror(result->ntype) << "'" << endl;
						exit(1);
					}
					ans*=result->val;
				}
				Node *ret=new Node(NODE_INT);
				ret->val=ans;
				return ret;
			}
			case NODE_DIV:{
				Node* result = execute(node->children[0], local_var);
				if(result->ntype!=NODE_INT){
					cout<<"Type Error: Expect 'Number' but got '" << whaterror(result->ntype) << "'" << endl;
					exit(1);
				}
				Node* result1 = execute(node->children[1], local_var);
				if(result1->ntype!=NODE_INT){
					cout<<"Type Error: Expect 'Number' but got '" << whaterror(result1->ntype) << "'" << endl;
					exit(1);
				}
				int ans=(result->val)/(result1->val);
				Node *ret=new Node(NODE_INT);
				ret->val=ans;
				return ret;
			}
			case NODE_MOD:{
				Node* result = execute(node->children[0], local_var);
				if(result->ntype!=NODE_INT){
					cout<<"Type Error: Expect 'Number' but got '" << whaterror(result->ntype) << "'" << endl;
					exit(1);
				}
				Node* result1 = execute(node->children[1], local_var);
				if(result1->ntype!=NODE_INT){
					cout<<"Type Error: Expect 'Number' but got '" << whaterror(result1->ntype) << "'" << endl;
					exit(1);
				}
				int ans=(result->val)%(result1->val);
				Node *ret=new Node(NODE_INT);
				ret->val=ans;
				return ret;
			}
			case NODE_AND:{
				Node *ans=new Node(NODE_BOOL);
				for(int i=0; i<node->children.size();i++){
					Node *res=execute(node->children[i],local_var);
					if(res->ntype != NODE_BOOL) {
						cout<< "Type Error: Expect 'Boolean' but got '" << whaterror(res->ntype) << "'" << endl;
						exit(1);
					}
					if(res->bval==false){
						ans->bval=false;
						return ans;
					}
				}
				ans->bval=true;
				return ans;
			}
			case NODE_OR:{
				Node *ans=new Node(NODE_BOOL);
				for(int i=0; i<node->children.size();i++){
					Node *res=execute(node->children[i],local_var);
					if(res->ntype != NODE_BOOL) {
						cout<< "Type Error: Expect 'Boolean' but got '" << whaterror(res->ntype) << "'" << endl;
						exit(1);
					}
					if(res->bval==true){
						ans->bval=true;
						return ans;
					}
				}
				ans->bval=false;
				return ans;
			}
			case NODE_NOT:{
				Node *res=execute(node->children[0],local_var);
				if(res->ntype != NODE_BOOL) {
					cout<< "Type Error: Expect 'Boolean' but got '" << whaterror(res->ntype) << "'" << endl;
					exit(1);
				}
				Node *ans=new Node(NODE_BOOL);
				if(res->bval==true)ans->bval=false;
				else ans->bval=true;
				return ans;
			}
			case NODE_IF:{
				Node *tf=execute(node->children[0],local_var);
				if(tf->ntype!=NODE_BOOL){
					cout << "Type Error: Expect 'Boolean' but got '" << whaterror(tf->ntype) << "'" << endl;
					exit(1);
				}
				if(tf->bval==true)return execute(node->children[1],local_var);
				else return execute(node->children[2],local_var);
			}
			case NODE_GREATER:{
				Node *l=execute(node->children[0],local_var);
				Node *r=execute(node->children[1],local_var);
				Node *ans=new Node(NODE_BOOL);
				if(l->ntype!=NODE_INT){
					cout << "Type Error: Expect 'Number' but got '" << whaterror(l->ntype) << "'" << endl;
					exit(1);
				}
				if(r->ntype!=NODE_INT){
					cout << "Type Error: Expect 'Number' but got '" << whaterror(r->ntype) << "'" << endl;
					exit(1);
				}
				if(l->val>r->val){
					ans->bval=true;
				}
				else{
					ans->bval=false;
				}
				return ans;
			}
			case NODE_SMALLER:{
				Node *l=execute(node->children[0],local_var);
				Node *r=execute(node->children[1],local_var);
				Node *ans=new Node(NODE_BOOL);
				if(l->ntype!=NODE_INT){
					cout << "Type Error: Expect 'Number' but got '" << whaterror(l->ntype) << "'" << endl;
					exit(1);
				}
				if(r->ntype!=NODE_INT){
					cout << "Type Error: Expect 'Number' but got '" << whaterror(r->ntype) << "'" << endl;
					exit(1);
				}
				if(l->val<r->val){
					ans->bval=true;
				}
				else{
					ans->bval=false;
				}
				return ans;
			}
			case NODE_EQUAL:{
				Node *l=execute(node->children[0],local_var);
				Node *r=execute(node->children[1],local_var);
				Node *ans=new Node(NODE_BOOL);
				if(l->ntype!=NODE_INT){
					cout << "Type Error: Expect 'Number' but got '" << whaterror(l->ntype) << "'" << endl;
					exit(1);
				}
				if(r->ntype!=NODE_INT){
					cout << "Type Error: Expect 'Number' but got '" << whaterror(r->ntype) << "'" << endl;
					exit(1);
				}
				if(l->val==r->val){
					ans->bval=true;
				}
				else{
					ans->bval=false;
				}
				return ans;
			}
			case NODE_DEF:{
				string s=node->children[0]->name;
				if(node->children[1]->ntype==NODE_FUNC){//is fun_exp
					var_val[s]=node->children[1];
				}
				else{
					Node *value=execute(node->children[1],local_var);
					var_val[s]=value;
				}
				return 0;
			}
			case NODE_FUNC:{
				return 0;//define a function, no need to do anything.
			}
			case NODE_FUNC_CALL:{
				Node *function=nullptr;
				map<string,Node*>local_var_newdef=local_var;//map[name]=Node;
				if(node->children[0]->ntype==NODE_FUNC){//anonymous function
					function=node->children[0];//point to the function we want to call, both left and right are pointers. fun_exp
				}
				else{//named function
					string function_name=node->children[0]->name;//find function with name
					function=var_val[function_name];	
				}
				for(int i=1;i<node->children.size();i++){
					Node* func=execute(node->children[i], local_var);
					local_var_newdef[function->children[0]->children[i-1]->name]=func;//fill up variable with value
					//cout<<function->children[0]->children[i-1]->name<<" "<<execute(node->children[i], local_var)<<endl;
					//function->children[0] is fun_ids, a vector with paramters of anonymous function.
					//function->children[0]->children[i-1] are parameters like x,y
					//function->children[1] is fun_body, which shows what this function will do
					//node->children[i] is parameters like 5,104
				}
				return execute(function->children[1],local_var_newdef);//calculate function
			}
			case NODE_FUNC_PARA:{
				return 0;//actually won't be executed, add PARA for readability
			}
		}
	}
    void yyerror(const char *message){
        printf("syntax Error\n");
    }
    
    int main(int argc, char *argv[]) {
        yyparse();
        return(0);
    }