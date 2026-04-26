%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int key = 0, id = 0, cons = 0, op = 0, del = 0;
int comment = 0, pre = 0, error = 0, header = 0, total = 0;
extern FILE *yyin, *yyout;
extern int yylineno;


typedef struct TokenNode {
    char *lexeme;
    char *type;
    int *lines;
    int lineCount;
    int lineCapacity;
    struct TokenNode *next;
} TokenNode;

TokenNode *tokenTable = NULL;

void add_token(const char *type, const char *lexeme) {
    TokenNode *node = tokenTable;
    while (node != NULL) {
        if (strcmp(node->lexeme, lexeme) == 0) {
            if (node->lines[node->lineCount - 1] != yylineno) {
                if (node->lineCount >= node->lineCapacity) {
                    node->lineCapacity *= 2;
                    node->lines = realloc(node->lines, node->lineCapacity * sizeof(int));
                }
                node->lines[node->lineCount++] = yylineno;
            }
            return;
        }
        node = node->next;
    }
    
    TokenNode *newNode = (TokenNode *)malloc(sizeof(TokenNode));
    newNode->lexeme = strdup(lexeme);
    newNode->type = strdup(type);
    newNode->lineCapacity = 4;
    newNode->lineCount = 1;
    newNode->lines = (int *)malloc(newNode->lineCapacity * sizeof(int));
    newNode->lines[0] = yylineno;
    newNode->next = tokenTable;
    tokenTable = newNode;
}

void print_token(const char *type, const char *lexeme) {
    total++;
    add_token(type, lexeme);
}



void print_unique_tokens() {
    /* Reverse list so tokens appear in source order */
    TokenNode *prev = NULL, *curr = tokenTable, *nxt = NULL;
    while (curr != NULL) {
        nxt        = curr->next;
        curr->next = prev;
        prev       = curr;
        curr       = nxt;
    }
    tokenTable = prev;

    fprintf(yyout, "##TOKENS##\n");
    fprintf(yyout, "S.No|Token Type|Lexeme|Line Numbers\n");

    int sno = 1;
    curr = tokenTable;
    while (curr != NULL) {
        /* Build comma-separated line-number list */
        char linestr[1024];
        int  pos = 0;
        for (int i = 0; i < curr->lineCount; i++) {
            if (i > 0) { linestr[pos++] = ','; linestr[pos++] = ' '; }
            pos += sprintf(linestr + pos, "%d", curr->lines[i]);
        }
        linestr[pos] = '\0';

        /* Escape any literal '|' inside the lexeme (e.g. bitwise-OR) */
        char safe[1024];
        const char *src = curr->lexeme;
        int j = 0;
        while (*src && j < 1022) {
            if (*src == '|') safe[j++] = '\\';
            safe[j++] = *src++;
        }
        safe[j] = '\0';

        fprintf(yyout, "%d|%s|%s|%s\n", sno++, curr->type, safe, linestr);
        curr = curr->next;
    }
}

void free_tokens() {
    TokenNode *node = tokenTable;
    while (node != NULL) {
        TokenNode *nxt = node->next;
        free(node->lexeme); free(node->type); free(node->lines); free(node);
        node = nxt;
    }
}
%}

%option yylineno

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
"/*"([^*]|\*+[^*/])*                       { error++; print_token("Lexical Error", yytext); return 0; }

\"([^\"\\\n]|\\.)*\"                       { cons++; print_token("String", yytext); }
\"([^\"\\\n]|\\.)*$                        { error++; print_token("Lexical Error", yytext); return 0; }

\'([^'\\\n]|\\[abfnrtv\\'"?]|\\[0-7]{1,3}|\\x[0-9a-fA-F]+)\'    { cons++; print_token("Character Constant", yytext); }

\'\'                                       { error++; print_token("Lexical Error", yytext); return 0; }
\'([^'\\\n]|\\.)*\'                        { error++; print_token("Lexical Error", yytext); return 0; }
\'([^'\\\n]|\\.)*                          { error++; print_token("Lexical Error", yytext); return 0; }

0[xX][0-9a-fA-F]*[g-zG-Z_][a-zA-Z0-9_]*                     { error++; print_token("Lexical Error", yytext); return 0; }
0[0-7]*[89][0-9]*([uU](ll|LL|[lL])?|((ll|LL|[lL])[uU]?))?   { error++; print_token("Lexical Error", yytext); return 0; }

0[xX][0-9a-fA-F]+(([uU](ll|LL|[lL])?)|((ll|LL|[lL])[uU]?))? { cons++; print_token("Hexadecimal Constant", yytext); }
0[0-7]+(([uU](ll|LL|[lL])?)|((ll|LL|[lL])[uU]?))?            { cons++; print_token("Octal Constant", yytext); }

([0-9]+\.[0-9]*|\.[0-9]+)[eE][+-]?[0-9]+[fFlL]?              { cons++; print_token("Scientific Constant", yytext); }
[0-9]+(\.[0-9]+)?[eE][+-]?[0-9]+[fFlL]?                      { cons++; print_token("Scientific Constant", yytext); }

[0-9]+\.[0-9]*[fFlL]?                                         { cons++; print_token("Floating Constant", yytext); }
\.[0-9]+[fFlL]?                                               { cons++; print_token("Floating Constant", yytext); }

[0-9]+(([uU](ll|LL|[lL])?)|((ll|LL|[lL])[uU]?))              { cons++; print_token("Integer Constant", yytext); }

[0-9]+[a-zA-Z_][a-zA-Z0-9_]*                                  { error++; print_token("Lexical Error", yytext); }

[0-9]+                                                         { cons++; print_token("Integer Constant", yytext); }


"_Bool"|"_Complex"|"_Imaginary"|"auto"|"break"|"case"|"char"|"const"|"continue"|"default"|"do"|"double"|"else"|"enum"|"extern"|"float"|"for"|"goto"|"if"|"inline"|"int"|"long"|"register"|"restrict"|"return"|"short"|"signed"|"sizeof"|"static"|"struct"|"switch"|"typedef"|"union"|"unsigned"|"void"|"volatile"|"while" {
    key++;
    print_token("Keyword", yytext);
}

"EOF"|"WEOF"|"BUFSIZ"|"FOPEN_MAX"|"FILENAME_MAX"|"L_tmpnam"|"TMP_MAX"|"EXIT_SUCCESS"|"EXIT_FAILURE"|"RAND_MAX"|"CLOCKS_PER_SEC"|"M_PI"|"M_E"|"M_SQRT2"|"INT_MAX"|"INT_MIN"|"UINT_MAX"|"LONG_MAX"|"LONG_MIN"|"ULONG_MAX"|"CHAR_BIT"|"CHAR_MAX"|"CHAR_MIN"|"SCHAR_MAX"|"SCHAR_MIN"|"SHRT_MAX"|"SHRT_MIN"|"USHRT_MAX"|"FLT_MAX"|"FLT_MIN"|"DBL_MAX"|"DBL_MIN"|"LDBL_MAX"|"LDBL_MIN" {
    cons++;
    print_token("Predefined Constant", yytext);
}

[a-zA-Z_][a-zA-Z0-9_]*[@#$!^][a-zA-Z0-9_@#$!^]* { error++; print_token("Lexical Error", yytext); return 0; }
[a-zA-Z_][a-zA-Z0-9_]*                            { id++;    print_token("Identifier", yytext); }

"="|"+="|"-="|"*="|"/="|"%="|"<<="|">>="|"&="|"^="|"|=" { op++; print_token("Assignment Operator", yytext); }

"++"                                       { op++; print_token("Increment Operator", yytext); }
"--"                                       { op++; print_token("Decrement Operator", yytext); }

"<="|">="|"=="|"!="|"<"|">"                { op++; print_token("Relational Operator", yytext); }

"&&"|"||"|"!"                              { op++; print_token("Logical Operator", yytext); }

"<<"|">>"|"&"|"|"|"^"|"~"                  { op++; print_token("Bitwise Operator", yytext); }

"->"                                       { op++; print_token("Arrow Operator", yytext); }

"+"|"-"|"*"|"/"|"%"                        { op++; print_token("Arithmetic Operator", yytext); }

"?"|":"                                    { op++; print_token("Ternary Operator", yytext); }

"##"                                       { op++; print_token("Token Pasting Operator", yytext); }

"#"                                        { op++; print_token("Stringizing Operator", yytext); }

"."                                        { op++; print_token("Dot Operator", yytext); }

"..."                                      { op++; print_token("Ellipsis Operator", yytext); }

";"|","|"("|")"|"{"|"}"|"["|"]"           { del++; print_token("Delimiter", yytext); }

.                                          { error++; print_token("Lexical Error", yytext); return 0; }
%%

int yywrap() { return 1; }

int main(int argc, char *argv[]) {
    if (argc < 2) return 1;
    yyin  = fopen(argv[1], "r");
    yyout = fopen("output.txt", "w");
    if (!yyin || !yyout) return 1;

    yylex();
    print_unique_tokens();

    /* Summary section - pipe-delimited, parsed by the JS frontend */
    fprintf(yyout, "##SUMMARY##\n");
    fprintf(yyout, "Keywords|%d\n",                key);
    fprintf(yyout, "Identifiers|%d\n",             id);
    fprintf(yyout, "Constants|%d\n",               cons);
    fprintf(yyout, "Operators|%d\n",               op);
    fprintf(yyout, "Delimiters|%d\n",              del);
    fprintf(yyout, "Comments|%d\n",                comment);
    fprintf(yyout, "Preprocessor Directives|%d\n", pre);
    fprintf(yyout, "Header Files|%d\n",            header);
    fprintf(yyout, "Lexical Errors|%d\n",          error);
    fprintf(yyout, "Total Lexemes|%d\n",           total);
    fprintf(yyout, "Valid Tokens|%d\n",            total - error);

    free_tokens();
    fclose(yyin);
    fclose(yyout);
    return 0;
}
