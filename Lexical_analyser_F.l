%{
#include <stdio.h>

int key = 0, id = 0, cons = 0, op = 0, del = 0;
int comment = 0;
int pre = 0;
int error = 0;
int total = 0;
int header=0;
extern FILE *yyin, *yyout;

void print_token(const char *type, const char *lexeme)
{
    total++;
    fprintf(yyout, "%-6d %-35s %s\n", total, type, lexeme);
}
%}

%%

[ \t\n]+                                  {}

\\[ntrbfav\\'"?0] {cons++;print_token("Escape Sequence", yytext);}

"#include"|"#define"|"#ifdef"|"#ifndef"|"#if"|"#elif"|"#else"|"#endif"|"#undef"|"#error"|"#pragma"|"#line" {
    pre++;
    print_token("Preprocessor Directive", yytext);
}
\<[a-zA-Z_][a-zA-Z0-9_./]*\.h\>  { header++; print_token("Header File", yytext); }
\"[a-zA-Z_][a-zA-Z0-9_./]*\.h\"  { header++; print_token("Header File", yytext); }


"__FILE__"|"__LINE__"|"__DATE__"|"__TIME__"|"__STDC__"|"__STDC_VERSION__"|"__STDC_HOSTED__" {
    cons++;
    print_token("Standard Predefined Macro", yytext);
}

"//"[^\n]*                                 { comment++; print_token("Single-line Comment", yytext); }
"/*"([^*]|\*+[^*/])*"*/"                   { comment++; print_token("Multi-line Comment", yytext); }
"/*"([^*]|\*+[^*/])*                                     { error++; print_token("Lexical Error", yytext); }

\"([^\"\\\n]|\\.)*\"                       { cons++; print_token("String", yytext); }
\"([^\"\\\n]|\\.)*$                        { error++; print_token("Lexical Error", yytext); }

\'([^'\\\n]|\\[abfnrtv\\'"?]|\\[0-7]{1,3}|\\x[0-9a-fA-F]+)\'    { cons++; print_token("Character Constant", yytext); }

\'\'                                         { error++; print_token("Lexical Error", yytext); }
\'([^'\\\n]|\\.)*\'          { error++; print_token("Lexical Error", yytext); }
\'([^'\\\n]|\\.)*             { error++; print_token("Lexical Error", yytext); }             /*unterminated character const error*/

0[xX][0-9a-fA-F]*[g-zG-Z_][a-zA-Z0-9_]*                      { error++; print_token("Lexical Error", yytext); }
0[0-7]*[89][0-9]*([uU](ll|LL|[lL])?|((ll|LL|[lL])[uU]?))?   { error++; print_token("Lexical Error", yytext); }

0[xX][0-9a-fA-F]+(([uU](ll|LL|[lL])?)|((ll|LL|[lL])[uU]?))? { cons++; print_token("Hexadecimal Constant", yytext); }
0[0-7]+(([uU](ll|LL|[lL])?)|((ll|LL|[lL])[uU]?))?           { cons++; print_token("Octal Constant", yytext); }

([0-9]+\.[0-9]*|\.[0-9]+)[eE][+-]?[0-9]+[fFlL]?            { cons++; print_token("Scientific Constant", yytext); }
[0-9]+(\.[0-9]+)?[eE][+-]?[0-9]+[fFlL]?                     { cons++; print_token("Scientific Constant", yytext); }

[0-9]+\.[0-9]*[fFlL]?                                       { cons++; print_token("Floating Constant", yytext); }
\.[0-9]+[fFlL]?                                             { cons++; print_token("Floating Constant", yytext); }

[0-9]+(([uU](ll|LL|[lL])?)|((ll|LL|[lL])[uU]?))             { cons++; print_token("Integer Constant", yytext); }

[0-9]+[a-zA-Z_][a-zA-Z0-9_]*                                { error++; print_token("Lexical Error", yytext); }

[0-9]+                                                      { cons++; print_token("Integer Constant", yytext); }



"_Bool"|"_Complex"|"_Imaginary"|"auto"|"break"|"case"|"char"|"const"|"continue"|"default"|"do"|"double"|"else"|"enum"|"extern"|"float"|"for"|"goto"|"if"|"inline"|"int"|"long"|"register"|"restrict"|"return"|"short"|"signed"|"sizeof"|"static"|"struct"|"switch"|"typedef"|"union"|"unsigned"|"void"|"volatile"|"while"  {
key++;
print_token("Keyword", yytext);
}

"EOF"|"WEOF"|"BUFSIZ"|"FOPEN_MAX"|"FILENAME_MAX"|"L_tmpnam"|"TMP_MAX"|"EXIT_SUCCESS"|"EXIT_FAILURE"|"RAND_MAX"|"CLOCKS_PER_SEC"|"M_PI"|"M_E"|"M_SQRT2"|"INT_MAX"|"INT_MIN"|"UINT_MAX"|"LONG_MAX"|"LONG_MIN"|"ULONG_MAX"|"CHAR_BIT"|"CHAR_MAX"|"CHAR_MIN"|"SCHAR_MAX"|"SCHAR_MIN"|"SHRT_MAX"|"SHRT_MIN"|"USHRT_MAX"|"FLT_MAX"|"FLT_MIN"|"DBL_MAX"|"DBL_MIN"|"LDBL_MAX"|"LDBL_MIN" {
    cons++; 
    print_token("Predefined Constant", yytext); 
}

[a-zA-Z_][a-zA-Z0-9_]*                     { id++; print_token("Identifier", yytext); }


"="|"+="|"-="|"*="|"/="|"%="|"<<="|">>="|"&="|"^="|"|="              { op++; print_token("Assignment Operator", yytext); }

"++"                                       { op++; print_token("Increment Operator", yytext); }
"--"                                       { op++; print_token("Decrement Operator", yytext); }

"<="|">="|"=="|"!="|"<"|">"                { op++; print_token("Relational Operator", yytext); }

"&&"|"||"|"!"                              { op++; print_token("Logical Operator", yytext); }

"<<"|">>"|"&"|"|"|"^"|"~"                  { op++; print_token("Bitwise Operator", yytext); }

"->"                                       { op++; print_token("Arrow Operator", yytext); }

"+"|"-"|"*"|"/"|"%"                        { op++; print_token("Arithmetic Operator", yytext); }

"?"|":"                                    { op++; print_token("Ternary Operator", yytext); }

"##"   {op++;print_token("Token Pasting Operator", yytext);}

"#"        {op++;print_token("Stringizing Operator", yytext);}

"."      { op++; print_token("Dot Operator", yytext); }

"..."   { op++; print_token("Ellipsis Operator", yytext); }

";"|","|"("|")"|"{"|"}"|"["|"]"|"."        { del++; print_token("Delimiter", yytext); }

.                                          { error++; print_token("Lexical Error", yytext); }

%%

int yywrap()
{
    return 1;
}

int main()
{
    yyin = fopen("input.txt", "r");
    yyout = fopen("Output.txt", "w");

    if (!yyin)
    {
        fprintf(stderr, "Error: Cannot open input.txt\n");
        return 1;
    }

    if (!yyout)
    {
        fprintf(stderr, "Error: Cannot open Output.txt\n");
        fclose(yyin);
        return 1;
    }

    fprintf(yyout, "%-6s %-35s %s\n", "S.No", "Token Type", "Lexeme");
    fprintf(yyout, "______________________________________________\n");

    yylex();

    fprintf(yyout, "\n\n---------------- Token Summary ----------------\n");
    fprintf(yyout, "Keywords              : %d\n", key);
    fprintf(yyout, "Identifiers           : %d\n", id);
    fprintf(yyout, "Constants             : %d\n", cons);
    fprintf(yyout, "Operators             : %d\n", op);
    fprintf(yyout, "Delimiters            : %d\n", del);
    fprintf(yyout, "Comments              : %d\n", comment);
    fprintf(yyout, "Preprocessor Directives: %d\n", pre);
fprintf(yyout, "Header Files:  %d\n", header);
    fprintf(yyout, "Lexical Errors        : %d\n", error);
    fprintf(yyout, "Total Lexemes         : %d\n", total);
    fprintf(yyout, "Valid Tokens          : %d\n", total - error);
    fprintf(yyout, "-----------------------------------------------\n");

    fclose(yyin);
    fclose(yyout);

    return 0;
}