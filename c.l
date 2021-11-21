%option yylineno
%{
#include <stdio.h> /* printf() */
#include <string.h> /* strcpy */
#include <stdlib.h> /* atoi(), atof() */
#include "common.h" /* MAX_STR_LEN */
#include "c.tab.h" /* deklaracja symboli końcowych */

/* wypisanie informacji o znalezionym symbolu końcowym */
int process_token(const char *text, const char *TokenType,
                  const char *TokenVal, const int TokenID); 

int comm_beg = 0; /* wiersz rozpoczęcia komentarza */
int text_beg = 0;
int text_beg_tracker = 0;
%}

/* deklaracja warunków początkowych analizatora */
/* (nie deklarujemy domyślnego warunku INITIAL) */
/* ..................... */
%x KOMENTARZ NAPIS


%%
 /* tu należy umieścić odpowiednie reguły w odpowiedniej kolejności */

 /* L) wykrywanie napisów z użyciem warunków początkowych */
<INITIAL>\" { BEGIN(NAPIS); text_beg_tracker=yylineno; }
<NAPIS>\" { BEGIN(INITIAL); return process_token(yytext, "STRING_CONST", yytext, STRING_CONST); }
<NAPIS>. yymore();
<NAPIS>\n {text_beg=text_beg_tracker;  BEGIN(INITIAL); } 

 /* M) usuwanie komentarzy wielowierszowych z użyciem warunków początkowych */
<INITIAL>"/*" { BEGIN(KOMENTARZ); comm_beg = yylineno;}
<INITIAL>"*/" { comm_beg=0; printf("Nieoczekiwane zamknięcie komentarza w wierszu %d\n", yylineno); } /*Podpunkt N) */
<KOMENTARZ>"*/" { BEGIN(INITIAL);  }
<KOMENTARZ>.|\n

 /* B) wykrywanie słów kluczowych */
char return process_token(yytext,"KW_CHAR","",KW_CHAR);
short return process_token(yytext,"KW_SHORT","",KW_SHORT);
unsigned return process_token(yytext,"KW_UNSIGNED","",KW_UNSIGNED);
int return process_token(yytext,"KW_INT","",KW_INT);
float return process_token(yytext,"KW_FLOAT","",KW_FLOAT);
long return process_token(yytext,"KW_LONG","",KW_LONG);
void return process_token(yytext,"KW_VOID","",KW_VOID);
for return process_token(yytext,"KW_FOR","",KW_FOR);
double return process_token(yytext,"KW_DOUBLE","",KW_DOUBLE);
while return process_token(yytext,"KW_WHILE","",KW_WHILE);
else return process_token(yytext,"KW_ELSE","",KW_ELSE);
if return process_token(yytext,"KW_IF","",KW_IF);
struct return process_token(yytext,"KW_STRUCT","",KW_STRUCT);
do return process_token(yytext,"KW_DO","",KW_DO);


 /* C) usuwanie białych znaków */
[[:space:]]+ ;

 /* D) usuwanie komentarzy jednowierszowych bez użycia warunków początkowych */
"//".*  ;

 /* E) wykrywanie operatorów wieloznakowych */
"++" return process_token(yytext, "INC", "", INC);
"<=" return process_token(yytext, "LE", "", LE);

 /* F) Wykrywanie identyfikatorów */
[A-Za-z_][a-zA-Z0-9_]*   return process_token(yytext, "IDENT", yytext, IDENT);

 /* G) Wykrywanie liczb całkowitych i zmiennoprzecinkowych */
[0-9]+    return process_token(yytext, "INTEGER_CONST", yytext, INTEGER_CONST);
(([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+))([eE](\+|-)?[0-9]{1,2})? 	return process_token(yytext, "FLOAT_CONST", yytext, FLOAT_CONST);

 /* H) wykrywanie stałych tekstowych (napisów) bez użycia mechanizmu warunków początkowych */
\"[^"]*\" return process_token(yytext, "STRING_CONST", yytext, STRING_CONST);

 /* I) wykrywanie stałych znakowych */
\'.\' return process_token(yytext, "STRING_CONST", yytext, STRING_CONST);

 /* K) wykrywanie dyrektywy dołączania plików */
^"#include "<[a-z]+(.h)*> printf("Przetwarzanie dyrektywy %s\n",yytext);
^"#include "\"[a-z]+(.h)*\" printf("Przetwarzanie dyrektywy %s\n",yytext);



 /* N) znajdowanie znaków zamknięcia komentarza przy braku jego rozpoczęcia z użyciem warunków początkowych */


 /* O) wykrywanie niezamkniętego komentarza ze wskazaniem wiersza jego rozpoczęcia z użyciem warunków początkowych */
 /*zrealizowany w funkcji yywrap*/

 /* J) wykrywanie symboli końcowych jednoznakowych: operatorów, interpunkcji */
.    return process_token(yytext, yytext, "", *yytext);

%%

/* Nazwa:       process_token
 * Cel:         Wypisanie informacji o wykrytym elemencie i przekazanie
 *              tej informacji wyżej z ewentualną wartością elementu, jeśli
 *              takowa występuje.
 * Parametry:   text            - (i) tekst, do którego nastąpiło dopasowanie;
 *              TokenType       - (i) napis będący tekstową reprezentacją
 *                                      nazwy typu elementu;
 *              TokenVal        - (i) wartość elementu, o ile występuje;
 *              TokenID         - (i) identyfikator typu elementu zadeklarowany
 *                                      za pomocą dyrektywy %token
 *                                      w pliku c.y lub kod pojedynczego
 *					znaku (w pliku analizatora składniowego
 *					występuje ujęty w apostrofy).
 * Zwraca:      Identyfikator typu elementu (TokenID).
 * Uwagi:       Informacja o wykrytym elemencie zwracana jest
 *              w trzech kolumnach. W pierwszej wypisywany jest tekst,
 *              do którego nastąpiło dopasowanie, w drugiej - typ elementu,
 *              w trzeciej - wartość elementu (o ile występuje).
 */
int process_token(const char *text, const char *TokenType,
                  const char *TokenVal, const int TokenID)
{
  int l;
  printf("%-20.20s%-15s %s\n", text, TokenType, TokenVal);
  switch (TokenID) {

  case INTEGER_CONST:
    yylval.i = atoi(text); break;

  case FLOAT_CONST:
    yylval.d = atof(text); break;

  case IDENT:
    strncpy(yylval.s, text, MAX_STR_LEN); break;

  case STRING_CONST:
    l = strlen(TokenVal);
    yylval.s[0] = '\0';
    strncpy(yylval.s, TokenVal + 1, l - 2 <= MAX_STR_LEN ? l - 1 : MAX_STR_LEN);
    break;

  case CHARACTER_CONST:
    yylval.i = text[1]; break;

  }
  return(TokenID);
}


int yywrap( void )
{ /* funkcja wywoływana po napotkaniu końca strumienia wejściowego

  /* sprawdzenie, czy warunek poczatkowy YY_START różni się od INITIAL. */
  /* Jeżeli tak, to oznacza to niezamknięty komentarz lub stała tekstową
     - wypisujemy informację o błędzie. */
  /* ..................... */
  if( text_beg > 0)
    		printf("Niezamknięty napis otwarty w wierszu %d\n", text_beg);
  if( YYSTATE != INITIAL ) {
	if( comm_beg > 0)
		printf("Brak zamknięcia komentarza otwartego w wierszu %d\n", comm_beg);
	}
  return( 1 ); /* koniecznie, by analiza nie rozpoczęła się od nowa */
}
