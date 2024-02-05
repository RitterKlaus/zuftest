program zuftest;
uses crt,dos; (* für schönere Bildschirmausgabe und *)
              (* um Dateien verwalten zu können *)

var aktion,definiert,ende,zliste_existiert,zuf_exist:integer;
    i:longint; (* Zähler *)
    stat,aktuelle_datei:string;

(* Signifikanzniveaus und Grenzen für das Chiquadrat (bei 9 und 6 Freiheitsgraden) *)
const verf_signiveau:array[1..9] of integer = (1,5,10,25,50,75,90,95,99);
      grenze_9:array[1..9] of real = (21.6660, 16.9190, 14.6837, 11.3900, 8.3400, 5.9000, 4.16816, 3.32511, 2.08781);
      grenze_6:array[1..9] of real = (16.8119, 12.5916, 10.6446, 07.8400, 5.3500, 3.4500, 2.20413, 1.63539, 0.87209);
                             (* höhere Werte: leichter zu bestehen *)

(* Routine für zentrierte Textausgabe *)
procedure center(txt:string);
var abstand:integer;
BEGIN
  abstand:=(80-(Length(txt))) div 2;
  GotoXY(abstand,WhereY);
  writeln(txt);
END;

(* Schreibt eine Zeile mit einem Zeichen voll *)
procedure zeilevoll(buchst:char);
var i:integer;
BEGIN
  for i:=1 to 80 do
  BEGIN
    write(buchst);
  END;
END;

(* Wartet auf Tastendruck *)
procedure wart_auf_taste;
BEGIN
  center('Drücken Sie bitte eine Taste.');
  repeat
  until readkey<>'';
END;

(* Wichtige Routine: MOD für Real-Zahlen *)
function real_mod(zahl,modul:real):real;
var h1,h2,h3,h4,hmodul:real; (* Hilfsvariablen *)
BEGIN
  h1:=int(zahl);
  hmodul:=int(modul);  (* sicherstellen, daß Ganzzahl *)
  h2:=h1/hmodul;
  h3:=frac(h2);
  h4:=int((h3*hmodul)+0.5); (* INT mit Rundung *)
  real_mod:=h4;
END;

procedure begrues;
BEGIN
  writeln;
  center('_________________________________________________');
  writeln;
  center('Progamm zum Erzeugen und Testen von Zufallszahlen');
  center('_________________________________________________');
  writeln;writeln;
  center('Bestandteil der Facharbeit von Klaus Ritter');
  center('(c) by Klaus Ritter - 30.01.1996 - Version 1.72');writeln;
  center('_________________________________________________');writeln;
  writeln;
  wart_auf_taste;
END;

(* Zeigt immer an, was das Programm gerade macht *)
procedure status(txt:string);
var i,j:integer;
BEGIN
  for i:=1 to 2 do
  BEGIN
    GotoXY(1,i);
    zeilevoll(' ');  (* Löscht die Zeile *)
  END;
  GotoXY(4,2);write(txt);
  GotoXY(1,3);zeilevoll('_');
  GotoXY(1,5); (* Der nächste Text erscheint in der 5. Zeile *)
END;

(* Spezielle Routine, um Fehleingaben bei ZAHLEN abzufangen *)
function zahleingabe(y,x:shortint;txt:string;bereichzeigen:shortint;min,max:longint;loeschen:shortint):longint;
var input:string; (* Eingabe des Benutzers *)
    fehler,ok:integer; (* Prüfvariablen *)
    zahl:longint;
BEGIN
  REPEAT
    ok:=0; (* Wenn OK=1 dann ist alles fehlerfrei *)
    if loeschen=1 then
    BEGIN
      GotoXY(1,y);
      zeilevoll(' '); (* eventuelle Fehleingaben löschen *)
    END;
    GotoXY(x,y);write(txt); (* Aufforderung zeigen *)
    if bereichzeigen=1 then write('(',min,'-',max,') '); (* Eingabebereich zeigen *)
    readln(input);
    val(input,zahl,fehler); (* Ist input keine Zahl, nimmt fehler einen Wert ungleich 0 an *)
    if fehler=0 then
    BEGIN
      if (zahl>=min) and (zahl<=max) then ok:=1;
    END;
  UNTIL ok=1;
  zahleingabe:=zahl; (* Wert zurückgeben *)
END;

(* Spezielle Routine, um Fehleingaben bei REAL-ZAHLEN abzufangen *)
function realeingabe(y,x:shortint;txt:string;bereichzeigen:shortint;min,max:real;loeschen:shortint):real;
var input:string; (* Eingabe des Benutzers *)
    fehler,ok:integer; (* Prüfvariablen *)
    zahl:real;
BEGIN
  REPEAT
    ok:=0; (* Wenn OK=1 dann ist alles fehlerfrei *)
    if loeschen=1 then
    BEGIN
      GotoXY(1,y);
      zeilevoll(' '); (* eventuelle Fehleingaben löschen *)
    END;
    GotoXY(x,y);write(txt); (* Aufforderung zeigen *)
    if bereichzeigen=1 then write('(',min:1:0,'-',max:13:0,') '); (* Eingabebereich zeigen *)
    readln(input);
    val(input,zahl,fehler); (* Ist input keine Zahl, nimmt fehler einen Wert ungleich 0 an *)
    if fehler=0 then
    BEGIN
      if (zahl>=min) and (zahl<=max) then ok:=1;
    END;
  UNTIL ok=1;
  realeingabe:=zahl; (* Wert zurückgeben *)
END;

(* Spezielle Routine, um Fehleingaben bei TEXT abzufangen *)
function texteingabe(y,x:shortint;txt:string;bereichzeigen:shortint;min,max:longint;loeschen,typ:shortint):string;
var input:string; (* Eingabe des Benutzers *)
    vorkommen,ok:integer; (* Prüfvariablen *)
const unerlaubt:array[1..5] of char = (' ','\','.',':',';');
      (* unerlaubte Zeichen in Dateinamen (DOS-Handbuch S. 42) *)
BEGIN
  REPEAT
    ok:=0; (* Wenn OK=1 dann ist alles fehlerfrei *)
    if loeschen=1 then
    BEGIN
      GotoXY(1,y);
      zeilevoll(' '); (* Bahn frei *)
    END;
    GotoXY(x,y);write(txt); (* Aufforderung zeigen *)
    if bereichzeigen=1 then write('(Länge ',min,'-',max,') '); (* erlaubte Länge des Texts *)
    readln(input);
    if (length(input)>=min) and (length(input)<=max) then ok:=1;

    (* TYP 1 bedeutet Dateiname: auf einige unerlaubte Zeichen prüfen *)
    (* siehe DOS-Handbuch unter "Dateinamen, Konventionen" (S. 42) *)
    if typ=1 then
    BEGIN
      for i:=1 to 5 do
      BEGIN
        vorkommen:=0;
        vorkommen:=pos(unerlaubt[i],input);
        if vorkommen<>0 then ok:=0; (* nicht mehr OK! *)
      END;
      if ok=0 then (* Fehlermeldung ausgeben *)
      BEGIN
        GotoXY(x,y+1);
        writeln('Dateinamen bitte nur maximal 8 Buchstaben und ohne die Zeichen .,:;\');
      END;
    END;
  UNTIL ok=1;
  texteingabe:=input; (* Wert zurückgeben *)
END;

(* Die Zufallszahlen werden zwischengespeichert. Diese Funktion prüft, ob *)
(* genug Platz auf der Festplatte frei ist. *)
function wievielezufaza:longint;
var zahl,benoetigt:longint;
BEGIN
  zahl:=zahleingabe(21,2,'Wieviele Zufallszahlen sollen erzeugt werden? ',1,10,1000000,1);
  benoetigt:=zahl*3+5000; (* pro Ziffer zwei Trennzeichen und Notreserve *)
                          (* maximaler Bedarf: 2935 KB = 2,9 MB *)
  if benoetigt>diskfree(0) then
  BEGIN
    writeln(' Die Zufallszahlen benötigen ',benoetigt div 1024,' KB freien Speicher auf der Festplatte.');
    writeln(' Bitte wählen Sie eine kleinere Zahl!');
    REPEAT
      zahl:=zahleingabe(21,2,'Wieviele Zufallszahlen sollen erzeugt werden? ',1,10,1000000,1);
      benoetigt:=zahl*3+5000;
    UNTIL benoetigt<diskfree(0);
  END;
  wievielezufaza:=zahl;
END;

(* Datei-Routinen: Prüfen, ob bestimmte Datei existiert *)
(*                 Namen zum Speichern eingeben *)
(*                 Namen zum Öffnen eingeben *)

(* Aus TurboPascal übernommen (siehe Beispiel zu "reset"! *)
function datei_existiert(dateiname:string):boolean;
         (* Gibt WAHR zurück, wenn die Datei existiert, sonst FALSCH *)
var dat:file;
BEGIN
  {$I-}
  assign(dat,dateiname);
  reset(dat);
  close(dat);
  {$I+}   (* wahr, wenn Datei existiert *)
  datei_existiert:=(IOResult = 0) and (dateiname <> '');
END;                      (* wahr, wenn ein Name angegeben wurde *)

(* Die folgende Funktion fragt nach einem Dateinamen zum Speichern *)
function name_zum_speichern(y,x:shortint;txt,endung:string):string;
var input:string;
    i,ok:shortint; (* Zähler, OK=1 heißt alles klar *)
BEGIN
  repeat
    GotoXY(1,y);
    zeilevoll(' ');  (* aufräumen *)
    GotoXY(x+length(txt)+8,y);
    writeln('.',endung);  (* Endung schreiben *)
    input:=texteingabe(y,x,txt,0,1,8,0,1);
    for i:=1 to length(input) do input[i]:=upcase(input[i]);
    input:=concat(input,'.',endung);
    (* Name in Großbuchstaben und mit Endung *)
    GotoXY(1,y);
    zeilevoll(' ');  (* aufräumen *)
    GotoXY(x,y);
    writeln(txt,input);
    (* aber: Existiert die Datei schon?? *)
    if datei_existiert(input)=true then
    BEGIN
      ok:=0;
      GotoXY(x,y+1);
      writeln('Es gibt schon eine Datei mit diesem Namen. Verwenden Sie einen anderen!');
    END else
    BEGIN
      ok:=1; (* alles klar! *)
      GotoXY(1,y+1);
      zeilevoll(' '); (* eventuell die Fehlermeldung löschen *)
    END;
  until ok=1;
  name_zum_speichern:=input;
END;

(* Fragt nach dem Namen einer zu ladenden Datei *)
function name_zum_laden(txt,endung:string):string;
var input,suchen,hilfsvar:string;
    ii,dateinummer,ok,max:shortint; (* Zähler, OK=1 heißt alles klar *)
    dateieintrag:searchrec; (* siehe Onlinehilfe zu FindFirst & SearchRec *)
    dateien:array[1..100] of string[12];

BEGIN
  (* Es werden alle Dateien mit der entsprechenden Endung in die Variable *)
  (* dateien[] gelesen *)
  clrscr;
  status(txt);
  suchen:=concat('*.',endung);
  ii:=0;ok:=0;
  writeln('   Nummer  Dateiname');
  FindFirst(suchen,AnyFile,dateieintrag); (* AnyFile: siehe Onlinehilfe *)
  (* writeln('     ',ii:2,'    ',dateieintrag.Name); *)
  (* dateien[ii]:=dateieintrag.Name; *)
  while (DosError=0) and (ok=0) do (* DosError: Wenn = 0 ist alles OK *)
  BEGIN
    ii:=ii+1;
    writeln('     ',ii:2,'    ',dateieintrag.Name);  (* Name der Datei schreiben *)
    dateien[ii]:=dateieintrag.name; (* Name in einem Feld speichern *)
    FindNext(dateieintrag);
    if (ii=14) or (DosError<>0) then
    BEGIN
      max:=ii;
      if DosError=0 then
      BEGIN
        writeln('     15    nächste Seite...');
        max:=15;
      END;
      dateinummer:=zahleingabe(22,4,'Geben Sie die Nummer der Datei ein ',1,1,max,1);
      if dateinummer=15 then
      BEGIN
        clrscr;
        hilfsvar:=concat(txt,' nächste Seite');
        status(hilfsvar);
        writeln('   Nummer  Dateiname');
        ok:=0;
        ii:=0;
      END else
      BEGIN
        ok:=1;
      END;
    END;
  END;
  name_zum_laden:=dateien[dateinummer];
END;

(* Prüft, ob es eine ENDUNG-Datei gibt *)
function dat_pruefen(endung:string):integer;
var suchen:string;
    dateieintrag:searchrec;
BEGIN
  suchen:=concat('*.',endung);
  findfirst(suchen,AnyFile,dateieintrag);
  dat_pruefen:=DosError; (* 0 = OK, 2 = Datei nicht gefunden (s. Hilfe) *)
END;

(* Einfaches Anzeigen des Chi-Quadrat-Symbols *)
function chq:string;
BEGIN
  chq:='X'+chr(253); (* X soll hier ein Chi darstellen *)
END;

(* Ende der Basisroutinen, nun folgen Programmteile *)

(* Der Poker-Test *)
procedure poker;
var txt,generator,kommentar,ergebnis_datei,zuf_datei:string;
    signiveau,signiv_index,noch_ok,z,i:integer; (* z: erzeugte Zufallszahl *)
    umfang,zj:longint; (* zj: Zähler der Zufallszahlen *)
    aktuelle,fortschritt,diff:integer; (* Wieviel % der Zahlen wurden getestet? *)
    dat,erg:text; (* Zum Öffnen der Datei *)
    chiquadrat,abweich,grenze:real;
    haeufigkeit:array[1..7] of longint; (* Häufigkeiten der 7 Quintupeltypen *)
    h_in_tupel:array[0..9] of integer; (* Häufigkeiten der 10 Ziffern in den Tupeln *)
    anz_der_h:array[0..5] of integer; (* Anzahl der 6 Häufigkeiten *)
    abs_erw:array[1..7] of real; (* erwartet mal n *)

const erwartet:array[1..7] of real = (0.3024,0.5040,0.1080,0.0720,0.0090,0.0045,0.0001);

BEGIN
  clrscr;
  txt:=concat('Poker-Test -- Test auf Unabhängigkeit');
  status(txt);
  writeln(' Dieser Test prüft die Zufallsziffern einer Datei auf Unabhängigkeit.');
  writeln(' Das Ergebnis wird auf dem Bildschirm angezeigt und in eine Datei geschrieben.');
  ergebnis_datei:=name_zum_speichern(8,2,'Wählen Sie einen Namen für die Datei: ','TXT');
  writeln;
  clrscr;
  status('Zufallszahlendatei wählen');
  if zliste_existiert<>0 then
  BEGIN
    writeln(' Wollen Sie die aktuelle Datei (',aktuelle_datei,') untersuchen oder eine andere?');
    aktuelle:=zahleingabe(7,2,'Geben Sie 1 ein, wenn Sie die aktuelle Datei untersuchen möchten, sonst 0 ',0,0,1,1);
    if aktuelle=1 then
    BEGIN
      zuf_datei:=aktuelle_datei;
    END else
    BEGIN
      zuf_datei:=name_zum_laden('Zufallszahlendatei öffnen','ZUF');
    END;
  END else
  BEGIN
    zuf_datei:=name_zum_laden('Zufallszahlendatei öffnen','ZUF');
  END;
  clrscr;
  status('Pokertest auf Unabhängigkeit -- Parameter');

  (* Datei öffnen und prüfen *)
  write(' Zufallszahlen-Datei wird geöffnet... ');
  assign(dat,zuf_datei);
  reset(dat);
  readln(dat,txt);
  if txt<>'Hinweise zur Datei' then
  BEGIN
    writeln;
    center('*** Falsche Datei! ***');
  END else
  BEGIN (* ich rücke nicht weiter ein: ELSE-Teil des IF-Blocks *)

  aktuelle_datei:=zuf_datei;
  zliste_existiert:=1;

  writeln('OK.');
  readln(dat,txt);
  readln(dat,umfang);
  readln(dat,generator);
  writeln(' ',umfang,' Zahlen ',generator);
  readln(dat,txt);
  readln(dat,kommentar);
  writeln(' Kommentar zum Generator: ');
  writeln(' ',kommentar);

  assign(erg,ergebnis_datei); (* Ergebnisdatei *)
  rewrite(erg);
  writeln(erg,' Ergebnis des Pokertests für ',umfang);
  writeln(erg,' Zufallszahlen ',generator,'.');
  writeln(erg,' Kommentar zum Generator:');
  writeln(erg,' ',kommentar);
  writeln(erg);

  writeln;
  for i:=1 to 9 do
  BEGIN
    write('    ',i,':  Signifikanzniveau  ',verf_signiveau[i]:2,'%,  Grenze für ',chq,' = ',grenze_6[i]:7:4);
    if i=1 then write('  einfach, unkritisch');
    if i=2 then write('  üblicher Wert');
    if i=9 then write('  schwierig, kritisch');
    writeln;
  END;

  signiv_index:=zahleingabe(20,2,'Wählen Sie das Signifikanzniveau: ',1,1,9,1);
  signiveau:=verf_signiveau[signiv_index];
  grenze:=grenze_6[signiv_index];

  clrscr;
  status('Die Häufigkeiten der 7 Quintupeltypen werden gezählt...');
  writeln(' Quintupeltyp  absolute Häufigkeit  erwartete');
  writeln(' --------------------------------------------');
  writeln('    abcde');
  writeln('    aabcd');
  writeln('    aabbc');
  writeln('    aaabc');
  writeln('    aaabb');
  writeln('    aaaab');
  writeln('    aaaaa');

  for i:=1 to 7 do
  BEGIN
    haeufigkeit[i]:=0; (* auf 0 setzen *)
    GotoXY(38,6+i);
    abs_erw[i]:=erwartet[i]*(umfang div 5);
    writeln(abs_erw[i]:8:1);
  END;

  diff:=0;
  for zj:=1 to (umfang div 5) do (* in 5er-Schritten durch die Datei *)
  BEGIN
    for i:=0 to 9 do
    BEGIN
      h_in_tupel[i]:=0; (* Häufigkeiten einzelner Zahlen im Tupel 0 setzen *)
    END;
    for i:=0 to 5 do
    BEGIN
      anz_der_h[i]:=0;  (* Anz. der H. 0 setzen *)
    END;
    for i:=1 to 5 do
    BEGIN
      readln(dat,z);  (* komplettes Tupel nacheinander einlesen *)
      inc(h_in_tupel[z]);  (* Ziffernhäufigkeiten speichern *)
    END;

    (* Tupeltypbestimmung vorbereiten*)
    for i:=0 to 9 do
    BEGIN
      inc(anz_der_h[h_in_tupel[i]]); (* Anzahl der Häufigkeiten ermitteln *)
    END;

    (* Tupeltyp durch Aussortieren bestimmen *)

    if anz_der_h[5]=1 then inc(haeufigkeit[7]) (* Tupel 7: aaaaa *)
    else
      if anz_der_h[4]=1 then inc(haeufigkeit[6]) (* Tupel 6: aaaab *)
      else
        if (anz_der_h[3]=1) and (anz_der_h[2]=1) then inc(haeufigkeit[5]) (* Tupel 5: aaabb *)
        else
          if (anz_der_h[3]=1) and (anz_der_h[1]=2) then inc(haeufigkeit[4]) (* Tupel 4: aaabc *)
          else
            if anz_der_h[2]=2 then inc(haeufigkeit[3]) (* Tupel 3: aabbc *)
            else
              if anz_der_h[1]=3 then inc(haeufigkeit[2]) (* Tupel 2: aabcd *)
              else
                inc(haeufigkeit[1]); (* Tupel 1: abcde *)

    fortschritt:=(zj*100) div (umfang div 5);
    if fortschritt<> diff then
    BEGIN
      for i:=1 to 7 do
      BEGIN
        GotoXY(24,6+i);
        write(haeufigkeit[i]:6);
      END;
      GotoXY(38,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(dat);
  writeln;
  wart_auf_taste;

  (* Berechnung des Chi-Quadrats für den POKER-Test *)
  clrscr;
  txt:=concat('Berechne das beobachtete ',chq,' beim Pokertest...');
  status(txt);

  chiquadrat:=0; (* Null setzen *)
  for i:=1 to 7 do
  BEGIN
    abweich:=(haeufigkeit[i]-abs_erw[i]);
    chiquadrat:=chiquadrat+((abweich*abweich)/abs_erw[i]);
  END;
  writeln(' Beobachtetes  ',chq,' = ',chiquadrat:8:4);
  status('Beurteilung des Generators durch den Pokertest');
  GotoXY(1,9); (* sonst wird das andere gelöscht *)
  writeln(' Grenze für das Signifikanzniveau ',signiveau:2,'% ist ',grenze:8:4);
  writeln;

  writeln(erg,' Ziffer  absolute Häufigkeit  erwartete');
  writeln(erg,' --------------------------------------');
  for i:=1 to 7 do
  BEGIN
    writeln(erg,'    ',i,'            ',haeufigkeit[i]:6,'       ',abs_erw[i]:8:2);
  END;
  writeln(erg);
  writeln(erg,' Beobachtetes ',chq,' =             ',chiquadrat:8:4);
  writeln(erg);
  writeln(erg,' Grenze für das ',signiveau:2,'%-Niveau ist ',grenze:8:4);

  if chiquadrat>grenze then
  BEGIN
    writeln(' Der Generator hat den Test nicht bestanden.');
    writeln(' Er wird auf dem ',signiveau:2,'%-Niveau abgelehnt.');
    writeln(erg,' Der Generator hat den Test nicht bestanden.');
    writeln(erg,' Er wird auf dem ',signiveau:2,'%-Niveau abgelehnt.');
  END else
  BEGIN
    writeln(' Der Generator hat den Test auf dem ',signiveau:2,'%-Niveau bestanden.');
    writeln(erg,' Der Generator hat den Test auf dem ',signiveau:2,'%-Niveau bestanden.');
  END;

  (* Welches Signifikanz-Niveau hätte den Generator noch angenommen *)
  noch_ok:=0;
  for i:=1 to 9 do
  BEGIN
    if chiquadrat<grenze_6[i] then
    BEGIN
      noch_ok:=i;
    END;
  END;

  writeln;
  writeln(erg);
  if noch_ok=0 then
  BEGIN
    writeln(' Der Generator wäre von keinem Signifikanzniveau < 1% angenommen worden.');
    writeln(erg,' Der Generator wäre von keinem Signifikanzniveau < 1% angenommen worden.');
  END else
  BEGIN
    writeln(' Ein Signifikanzniveau von ',verf_signiveau[noch_ok],'% hätte den Generator noch angenommen.');
    writeln(erg,' Ein Signifikanzniveau von ',verf_signiveau[noch_ok],'% hätte den Generator noch angenommen.');
  END;
  close(erg);
  END; (* vom IF-Block! *)
  writeln;writeln;
  wart_auf_taste;
END;
(* ENDE des Pokertests *)

(* Der CHI-QUADRAT-TEST *)
procedure chiquad;
var txt,generator,kommentar,ergebnis_datei,zuf_datei:string;
    signiveau,signiv_index,noch_ok,z:integer; (* z: erzeugte Zufallszahl *)
    umfang,zj:longint; (* zj: Zähler der Zufallszahlen *)
    aktuelle,fortschritt,diff:integer; (* Wieviel % der Zahlen wurden getestet? *)
    dat,erg:text; (* Zum Öffnen der Datei *)
    haeufigkeit:array[0..9] of longint; (* Häufigkeit der 10 Ziffern *)
    erwartet,chiquadrat,abweich,grenze:real;

BEGIN
  clrscr;
  txt:=concat(chq,' (Chi-Quadrat) Anpassungstest auf Gleichverteilung');
  status(txt);
  writeln(' Dieser Test prüft die Zufallsziffern einer Datei auf Gleichverteilung.');
  writeln(' Das Ergebnis wird auf dem Bildschirm angezeigt und in eine Datei geschrieben.');
  ergebnis_datei:=name_zum_speichern(8,2,'Wählen Sie einen Namen für die Datei: ','TXT');
  writeln;
  clrscr;
  status('Zufallszahlendatei wählen');
  if zliste_existiert<>0 then
  BEGIN
    writeln(' Wollen Sie die aktuelle Datei (',aktuelle_datei,') untersuchen oder eine andere?');
    aktuelle:=zahleingabe(7,2,'Geben Sie 1 ein, wenn Sie die aktuelle Datei untersuchen möchten, sonst 0 ',0,0,1,1);
    if aktuelle=1 then
    BEGIN
      zuf_datei:=aktuelle_datei;
    END else
    BEGIN
      zuf_datei:=name_zum_laden('Zufallszahlendatei öffnen','ZUF');
    END;
  END else
  BEGIN
    zuf_datei:=name_zum_laden('Zufallszahlendatei öffnen','ZUF');
  END;

  clrscr;
  status('Anpassungstest auf Gleichverteilung -- Parameter');

  (* Datei öffnen und prüfen *)
  write(' Zufallszahlen-Datei wird geöffnet... ');
  assign(dat,zuf_datei);
  reset(dat);
  readln(dat,txt);
  if txt<>'Hinweise zur Datei' then
  BEGIN
    writeln;
    center('*** Falsche Datei! ***');
  END else
  BEGIN (* ich rücke nicht weiter ein: ELSE-Teil des IF-Blocks *)

  aktuelle_datei:=zuf_datei;
  zliste_existiert:=1;

  writeln('OK.');
  readln(dat,txt);
  readln(dat,umfang);
  readln(dat,generator);
  writeln(' ',umfang,' Zahlen ',generator);
  readln(dat,txt);
  readln(dat,kommentar);
  writeln(' Kommentar zum Generator:');
  writeln(' ',kommentar);

  assign(erg,ergebnis_datei); (* Egebnisdatei *)
  rewrite(erg);
  writeln(erg,' Ergebnis des ',chq,'-Anpassungs-Tests für ',umfang);
  writeln(erg,' Zufallszahlen ',generator,'.');
  writeln(erg,' Kommentar zum Generator:');
  writeln(erg,' ',kommentar);
  writeln(erg);

  writeln;
  for i:=1 to 9 do
  BEGIN
    write('    ',i,':  Signifikanzniveau  ',verf_signiveau[i]:2,'%,  Grenze für ',chq,' = ',grenze_9[i]:8:4);
    if i=1 then write('  einfach, unkritisch');
    if i=2 then write('  üblicher Wert');
    if i=9 then write('  schwierig, kritisch');
    writeln;
  END;

  signiv_index:=zahleingabe(20,2,'Wählen Sie das Signifikanzniveau: ',1,1,9,1);
  signiveau:=verf_signiveau[signiv_index];
  grenze:=grenze_9[signiv_index];

  clrscr;
  status('Die Häufigkeiten der Ziffern 0 bis 9 werden gezählt...');
  writeln(' Ziffer  absolute Häufigkeit  erwartete');
  writeln(' --------------------------------------');
  erwartet:=umfang/10; (* Erwartete Häufigkeiten (für alle Ziffern gleich *)

  for i:=0 to 9 do
  BEGIN
    writeln('    ',i,'                         ',erwartet:6:1);
    haeufigkeit[i]:=0; (* auf 0 setzen *)
  END;

  diff:=0;
  for zj:=1 to umfang do
  BEGIN
    readln(dat,z); (* Zufallszahl einlesen *)
    inc(haeufigkeit[z]); (* Häufigkeit der Ziffern entsprechend +1 *)

    fortschritt:=(zj*100) div umfang;
    if fortschritt<> diff then
    BEGIN
      for i:=0 to 9 do
      BEGIN
        GotoXY(18,7+i);
        write(haeufigkeit[i]:6);
      END;
      GotoXY(37,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(dat);
  writeln;
  wart_auf_taste;

  clrscr;
  txt:=concat('Berechne das beobachtete ',chq,'...');
  status(txt);
  writeln;
  chiquadrat:=0; (* Null setzen *)
  for i:=0 to 9 do
  BEGIN
    abweich:=(haeufigkeit[i]-erwartet);
    chiquadrat:=chiquadrat+((abweich*abweich)/erwartet);
  END;
  writeln(' Beobachtetes  ',chq,' = ',chiquadrat:3:3);
  writeln;
  txt:=concat('Beurteilung des Generators durch den ',chq,'-Anpassungs-Test');
  status(txt);
  GotoXY(1,9); (* sonst wird das andere gelöscht *)
  writeln(' Grenze für das Signifikanzniveau ',signiveau,'% ist ',grenze:8:4);
  writeln;

  writeln(erg,' Ziffer  absolute Häufigkeit  erwartete');
  writeln(erg,' --------------------------------------');
  for i:=0 to 9 do
  BEGIN
    writeln(erg,'    ',i,'            ',haeufigkeit[i]:6,'       ',erwartet:6:2);
  END;
  writeln(erg);
  writeln(erg,' Beobachtetes ',chq,' =             ',chiquadrat:8:4);
  writeln(erg);
  writeln(erg,' Grenze für das ',signiveau:2,'%-Niveau ist ',grenze:8:4);

  if chiquadrat>grenze then
  BEGIN
    writeln(' Der Generator hat den Test nicht bestanden.');
    writeln(' Er wird auf dem ',signiveau:2,'%-Niveau abgelehnt.');
    writeln(erg,' Der Generator hat den Test nicht bestanden.');
    writeln(erg,' Er wird auf dem ',signiveau:2,'%-Niveau abgelehnt.');
  END else
  BEGIN
    writeln(' Der Generator hat den Test auf dem ',signiveau:2,'%-Niveau bestanden.');
    writeln(erg,' Der Generator hat den Test auf dem ',signiveau:2,'%-Niveau bestanden.');
  END;

  (* Welches Sig-Niveau hätte den Generator noch angenommen *)

  noch_ok:=0;
  for i:=1 to 9 do
  BEGIN
    if chiquadrat<grenze_9[i] then
    BEGIN
      noch_ok:=i;
    END;
  END;

  writeln;
  writeln(erg);
  if noch_ok=0 then
  BEGIN
    writeln(' Der Generator wäre von keinem Signifikanzniveau < 1% angenommen worden.');
    writeln(erg,' Der Generator wäre von keinem Signifikanzniveau < 1% angenommen worden.');
  END else
  BEGIN
    writeln(' Ein Signifikanzniveau von ',verf_signiveau[noch_ok],'% hätte den Generator noch angenommen.');
    writeln(erg,' Ein Signifikanzniveau von ',verf_signiveau[noch_ok],'% hätte den Generator noch angenommen.');
  END;
  close(erg);
  END; (* vom IF-Block! *)
  writeln;writeln;
  wart_auf_taste;
END;

(* schreibt einen Kopf für die ZUF-Datei *)
procedure datei_kopf(var dat:text;umfang:longint;generator,kommentar:string);
BEGIN
  writeln(dat,'Hinweise zur Datei');
  writeln(dat,'Umfang der Stichprobe:');
  writeln(dat,umfang);
  writeln(dat,'erzeugt durch einen ',generator);
  writeln(dat,'Kommentar zum Generator:');
  writeln(dat,kommentar);
END;

(* Die folgenden Prozeduren fragen nach den Parametern und erzeugen *)
(* eine festzulegende Anzahl von Zufallszahlen. Die Zahlen werden *)
(* in einer Datei gespeichert. Die Testprozeduren laden die Datei und *)
(* testen die Zahlen. *)

(* Der Folgen-Verlängerungs-Generator *)
procedure folgen;
var anz,z,i,j:integer; (* i und j: Zähler *)
                       (* Anz: Anzahl der Folgen *)
                       (* z: erzeugte Zufallszahl *)
    periode,umfang,zj:longint; (* zj: Zähler der Zufallszahlen *)
                               (* Umfang: Anzahl der Zufallszahlen *)
    len:array[1..10] of integer; (* Länge der verschiedenen Folgen *)
    folge:array[1..4,1..30] of integer; (* Zahlen der Folgen *)
    jj:array[1..30] of integer; (* Gibt an, wo ich mich in welcher Folge befinde *)
    fortschritt,diff:integer; (* Wieviel % der Zahlen wurden erzeugt? *)
    dat:text; (* zum Speichern *)
    dateiname,itext,jtext,txt,kommentar:string;

BEGIN
  clrscr;
  status('Verlängerung von Folgen -- Parameter');
  writeln(' Sie können die Anzahl und die Länge der Folgen festlegen. Dann müssen');
  writeln(' Sie die einzelnen Zahlen der Folgen eingeben.');
  writeln(' (Die Basis des Zahlensystems ist auf 10 festgelegt!)');writeln;
  anz:=zahleingabe(9,2,'Anzahl der Folgen ',1,2,4,1);
  periode:=1;
  for i:=1 to anz do
  BEGIN
    str(i:1,itext); (* Nummer der Folge muß angezeigt werden *)
    txt:=concat('Länge der Folge ',itext,' ');
    len[i]:=zahleingabe(10+i,2,txt,1,2,30,1);
    periode:=periode*len[i];
  END;
  clrscr;
  status('Verlängerung von Folgen -- Parameter -- Zahlen der Folgen');
  writeln(' Die Periode wird vermutlich ',periode,' betragen, wenn der GGT der Längen');
  writeln(' gleich 1 ist.');
  writeln(' Nun müssen Sie die Zahlen der ',anz,' Folgen eingeben. Benutzen Sie Dezimalziffern.');
  for i:=1 to anz do
  BEGIN
    GotoXY(2,9+i);
    write('Folge ',i,' Länge ',len[i]);
    for j:=1 to len[i] do
    BEGIN
      folge[i,j]:=zahleingabe(9+i,20+(j*2),'',0,0,9,0);
    END;
  END;
  writeln;
  umfang:=wievielezufaza;
  clrscr;
  status('Verlängerung von Folgen -- Erzeugung der Zufallszahlen');

  dateiname:=name_zum_speichern(5,2,'Wählen Sie einen Namen für die Datei: ','ZUF');
  GotoXY(2,7);writeln('Geben Sie einen Kommentar zu diesem Generator ein:');
  kommentar:=texteingabe(9,2,'-> ',0,1,75,1,0);

  aktuelle_datei:=dateiname;
  zliste_existiert:=1;
  assign(dat,dateiname);
  rewrite(dat); (* Die Datei zum Speichern wurde angelegt und geöffnet *)
  datei_kopf(dat,umfang,'Folgen-Verlängerungs-Generator',kommentar);

  (* PROGRAMM DES FOLGEN-VERLÄNGERUNGS-GENRATORS *)

  for i:=1 to 30 do
  BEGIN
    jj[i]:=0; (* Null setzen *)
  END;

  j:=0;diff:=0;
  for zj:=1 to umfang do
  BEGIN
    z:=0;
    for i:=1 to anz do
    BEGIN
      jj[i]:=jj[i]+1; (* Zähler innerhalb der Folgen checken *)
      if jj[i]>len[i] then jj[i]:=1;
    END;
    for i:=1 to anz do
    BEGIN
      z:=(z+folge[i,jj[i]]);
    END;
    z:=z mod 10;
    writeln(dat,z); (* Zahl speichern *)

    fortschritt:=(zj*100) div umfang;
    if fortschritt<> diff then
    BEGIN
      GotoXY(38,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(dat);
  writeln;
  wart_auf_taste;
END;

procedure tubo_random;
var z,obrandomize:integer; (* z: erzeugte Zufallszahl *)
    umfang,zj:longint; (* zj: Zähler der Zufallszahlen *)
    fortschritt,diff:integer; (* Wieviel % der Zahlen wurden erzeugt? *)
    dat:text; (* zum Speichern *)
    dateiname,kommentar:string;

BEGIN
  clrscr;
  status('TurboPascals interner Zufallsgenerator RANDOM -- Parameter');
  writeln(' Sie können nur festlegen, ob RANDOMIZE ausgeführt werden soll oder nicht.');
  writeln(' Der Generator erzeugt ganze Zahlen aus [0; 9].');writeln;
  obrandomize:=zahleingabe(8,2,'Geben Sie 1 ein, wenn RANDOMIZE ausgeführt werden soll, sonst 0 ',0,0,1,1);
  umfang:=wievielezufaza;
  clrscr;
  status('TurboPascals RANDOM -- Erzeugung der Zufallszahlen');
  dateiname:=name_zum_speichern(5,2,'Wählen Sie einen Namen für die Datei: ','ZUF');
  GotoXY(2,7);writeln('Geben Sie einen Kommentar zu diesem Generator ein:');
  kommentar:=texteingabe(9,2,'-> ',0,1,75,1,0);

  aktuelle_datei:=dateiname;
  zliste_existiert:=1;
  assign(dat,dateiname);
  rewrite(dat); (* Die Datei zum Speichern wurde angelegt und geöffnet *)
  datei_kopf(dat,umfang,'TurboPascal-Generator',kommentar);

  (* PROGRAMM DES TurboPascal-INTERNEN GENRATORS *)

  if obrandomize=1 then RANDOMIZE;

  diff:=0;
  for zj:=1 to umfang do
  BEGIN
    z:=RANDOM(10);  (* range ist 10 (siehe Hilfe mit Ctrl+F1) *)
    writeln(dat,z); (* Zahl speichern *)

    fortschritt:=(zj*100) div umfang;
    if fortschritt<> diff then
    BEGIN
      GotoXY(38,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(dat);
  writeln;
  wart_auf_taste;
END;

procedure quami;
var stellen,hilfsvariable:integer; (* z: erzeugte Zufallszahl *)
    z,anfangszahl,umfang,zj,quadrat,qumitte,ausgabe:longint; (* zj: Zähler der Zufallszahlen *)
    fortschritt,diff:integer; (* Wieviel % der Zahlen wurden erzeugt? *)
    quad,quadmitte,dateiname,kommentar:string;
    dat:text; (* zum Speichern *)

BEGIN
  clrscr;
  status('Quadratmittengenerator -- Parameter');
  writeln(' Sie können die Anzahl der Stellen und die Anfangszahl festlegen.');
  writeln(' (Die Basis des Zahlensystems ist 10!)');
  writeln(' Der Generator erzeugt ganze Zahlen aus [0; 9].');writeln;
  REPEAT
    stellen:=zahleingabe(9,2,'Geben Sie die Anzahl der Stellen ein (2 oder 4) ',0,2,4,1);
    hilfsvariable:=stellen mod 2
  UNTIL hilfsvariable=0; (* Sicherstellen, daß es eine gerade Zahl ist *)
  hilfsvariable:=trunc(exp(stellen*ln(10)))-1; (* 10 hoch 'Stellen' -1 ist maximale Zahl *)
  anfangszahl:=zahleingabe(11,2,'Geben Sie die Anfangszahl ein ',1,1,hilfsvariable,1);
  umfang:=wievielezufaza;
  clrscr;
  status('Quadratmittengenerator -- Erzeugung der Zufallszahlen');
  writeln(' Die Zufallszahlen werden in einer Datei gespeichert.');
  dateiname:=name_zum_speichern(5,2,'Wählen Sie einen Namen für die Datei: ','ZUF');
  GotoXY(2,7);writeln('Geben Sie einen Kommentar zu diesem Generator ein:');
  kommentar:=texteingabe(9,2,'-> ',0,1,75,1,0);

  aktuelle_datei:=dateiname;
  zliste_existiert:=1;
  assign(dat,dateiname);
  rewrite(dat); (* Die Datei zum Speichern wurde angelegt und geöffnet *)
  datei_kopf(dat,umfang,'Quadratmitten-Generator',kommentar);

  (* PROGRAMM DES QUAMI-GENRATORS *)

  z:=anfangszahl;

  diff:=0;
  for zj:=1 to umfang do
  BEGIN
    quadrat:=z*z; (* z quadrieren *)
    str(quadrat:stellen,quad); (* Quadrat in string umwandeln *)
    while length(quad)<(stellen*2) do
    BEGIN
      insert('0',quad,1);  (* Nullen ergänzen *)
    END;
    quadmitte:=copy(quad,(stellen div 2)+1,stellen); (* Mitte des string holen *)
    val(quadmitte,qumitte,hilfsvariable); (* Quadratmitte in Zahl umwandeln *)
    z:=qumitte; (* neue Zufallszahl = Quadratmitte *)
    ausgabe:=z mod 10; (* In Dezimalzahl umwandeln *)
    writeln(dat,ausgabe); (* Zahl speichern *)

    fortschritt:=(zj*100) div umfang;
    if fortschritt<> diff then
    BEGIN
      GotoXY(38,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(dat);
  writeln;
  wart_auf_taste;
END;

(* FIBONACCI-Generator *)
procedure fibonacci;
var stellen,hilfsvariable:integer;
    z,n_0,n_1,m:real; (* z: erzeugte Zufallszahl und  die Parameter *)
    ausgabe,umfang,zj:longint; (* zj: Zähler der Zufallszahlen *)
    fortschritt,diff:integer; (* Wieviel % der Zahlen wurden erzeugt? *)
    dateiname,kommentar:string;
    dat:text; (* zum Speichern *)

BEGIN
  clrscr;
  status('Fibonacci-Generator -- Parameter');
  writeln(' Form:');
  writeln('           z   = x + x    (mod M)');
  writeln('            n+1   n   n-1');
  writeln;
  writeln(' Die Zahlen werden anschließend zu Dezimalzahlen modifiziert.');
  writeln(' Es werden nur ganzzahlige Werte verwendet.');writeln;
  m:=int(realeingabe(12,2,'Geben Sie die Basis M ein: ',1,2,4294967296.0,1));
  n_0:=int(realeingabe(14,2,'Geben Sie x.n   ein: ',1,1,(m-1),1)); (* Zahlen bis m-1 *)
  n_1:=int(realeingabe(16,2,'Geben Sie x.n-1 ein: ',1,1,(m-1),1));

  umfang:=wievielezufaza;
  clrscr;
  status('Fibonacci-Generator -- Erzeugung der Zufallszahlen');
  writeln(' Die Zufallszahlen werden in einer Datei gespeichert.');
  dateiname:=name_zum_speichern(5,2,'Wählen Sie einen Namen für die Datei: ','ZUF');
  GotoXY(2,7);writeln('Geben Sie einen Kommentar zu diesem Generator ein:');
  kommentar:=texteingabe(9,2,'-> ',0,1,75,1,0);

  aktuelle_datei:=dateiname;
  zliste_existiert:=1;
  assign(dat,dateiname);
  rewrite(dat); (* Die Datei zum Speichern wurde angelegt und geöffnet *)
  datei_kopf(dat,umfang,'Fibonacci-Generator',kommentar);

  (* PROGRAMM DES FIBONACCI-GENERATORS *)

  diff:=0;
  for zj:=1 to umfang do
  BEGIN
    z:=n_0+n_1;  (* z entspricht n+1 *)
    z:=real_mod(z,m); (* MOD *)
    n_1:=n_0; (* verschieben *)
    n_0:=z;

    (* z in Dezimalzahl umwandeln *)
    z:=z/m;
    ausgabe:=trunc(z*10); (* ganzzahlig aus [0; 9] *)
    writeln(dat,ausgabe); (* Zahl speichern *)

    fortschritt:=(zj*100) div umfang;
    if fortschritt<> diff then
    BEGIN
      GotoXY(38,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(dat);
  writeln;
  wart_auf_taste;
END;

(* Multiplikativer Generator *)
procedure multiplik;
var stellen,hilfsvariable:integer;
    z,n,c,m:real; (* z: erzeugte Zufallszahl und die Parameter *)
    ausgabe,umfang,zj:longint; (* zj: Zähler der Zufallszahlen *)
    fortschritt,diff:integer; (* Wieviel % der Zahlen wurden erzeugt? *)
    dateiname,kommentar:string;
    dat:text; (* zum Speichern *)

BEGIN
  clrscr;
  status('Multiplikativer Generator -- Parameter');
  writeln(' Form:');
  writeln('           z   = c x    (mod M)');
  writeln('            n+1     n');
  writeln;
  writeln(' Die Zahlen werden anschließend zu Dezimalzahlen modifiziert.');
  writeln(' Es werden nur ganzzahlige Werte verwendet.');writeln;
  m:=int(realeingabe(12,2,'Geben Sie die Basis M ein: ',1,2,4294967296.0,1));
  c:=int(realeingabe(14,2,'Geben Sie c   ein: ',1,2,(m-1),1)); (* Zahlen bis m-1 *)
  n:=int(realeingabe(16,2,'Geben Sie x.n ein: ',1,1,(m-1),1));

  umfang:=wievielezufaza;
  clrscr;
  status('Multiplikativer Generator -- Erzeugung der Zufallszahlen');
  writeln(' Die Zufallszahlen werden in einer Datei gespeichert.');
  dateiname:=name_zum_speichern(5,2,'Wählen Sie einen Namen für die Datei: ','ZUF');
  GotoXY(2,7);writeln('Geben Sie einen Kommentar zu diesem Generator ein:');
  kommentar:=texteingabe(9,2,'-> ',0,1,75,1,0);

  aktuelle_datei:=dateiname;
  zliste_existiert:=1;
  assign(dat,dateiname);
  rewrite(dat); (* Die Datei zum Speichern wurde angelegt und geöffnet *)
  datei_kopf(dat,umfang,'multiplikativen Generator',kommentar);

  (* PROGRAMM DES MULTIPLIKATIVEN GENERATORS *)

  diff:=0;
  for zj:=1 to umfang do
  BEGIN
    z:=c*n;  (* z entspricht n+1 *)
    z:=real_mod(z,m); (* MOD *)
    n:=z; (* verschieben *)

    (* z in Dezimalzahl umwandeln *)
    z:=z/m;
    ausgabe:=trunc(z*10); (* ganzzahlig aus [0; 9] *)
    writeln(dat,ausgabe); (* Zahl speichern *)

    fortschritt:=(zj*100) div umfang;
    if fortschritt<> diff then
    BEGIN
      GotoXY(38,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(dat);
  writeln;
  wart_auf_taste;
END;

(* Gemischter Generator *)
procedure gemischt;
var stellen,hilfsvariable:integer;
    z,n,a,b,m:real; (* z: erzeugte Zufallszahl und die Parameter *)
    ausgabe,umfang,zj:longint; (* zj: Zähler der Zufallszahlen *)
    fortschritt,diff:integer; (* Wieviel % der Zahlen wurden erzeugt? *)
    dateiname,kommentar:string;
    dat:text; (* zum Speichern *)

BEGIN
  clrscr;
  status('Gemischter Generator -- Parameter');
  writeln(' Form:');
  writeln('           z   = a x + b   (mod M)');
  writeln('            n+1     n');
  writeln;
  writeln(' Die Zahlen werden anschließend zu Dezimalzahlen modifiziert.');
  writeln(' Es werden nur ganzzahlige Werte verwendet.');writeln;
  m:=int(realeingabe(12,2,'Geben Sie die Basis M ein: ',1,2,4294967296.0,1));
  a:=int(realeingabe(14,2,'Geben Sie a   ein: ',1,1,(m-1),1)); (* Zahlen bis m-1 *)
  n:=int(realeingabe(16,2,'Geben Sie x.n ein: ',1,1,(m-1),1));
  b:=int(realeingabe(18,2,'Geben Sie b   ein: ',1,1,(m-1),1));

  umfang:=wievielezufaza;
  clrscr;
  status('Gemischter Generator -- Erzeugung der Zufallszahlen');
  writeln(' Die Zufallszahlen werden in einer Datei gespeichert.');
  dateiname:=name_zum_speichern(5,2,'Wählen Sie einen Namen für die Datei: ','ZUF');
  GotoXY(2,7);writeln('Geben Sie einen Kommentar zu diesem Generator ein:');
  kommentar:=texteingabe(9,2,'-> ',0,1,75,1,0);

  aktuelle_datei:=dateiname;
  zliste_existiert:=1;
  assign(dat,dateiname);
  rewrite(dat); (* Die Datei zum Speichern wurde angelegt und geöffnet *)
  datei_kopf(dat,umfang,'gemischten Generator',kommentar);

  (* PROGRAMM DES GEMISCHTEN GENERATORS *)

  diff:=0;
  for zj:=1 to umfang do
  BEGIN
    z:=(a*n)+b;  (* z entspricht n+1 *)
    z:=real_mod(z,m); (* MOD *)
    n:=z; (* verschieben *)

    (* z in Dezimalzahl umwandeln *)
    z:=z/m;
    ausgabe:=trunc(z*10); (* ganzzahlig aus [0; 9] *)
    writeln(dat,ausgabe); (* Zahl speichern *)

    fortschritt:=(zj*100) div umfang;
    if fortschritt<> diff then
    BEGIN
      GotoXY(38,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(dat);
  writeln;
  wart_auf_taste;
END;

procedure gen_auswahl;
var wahl:integer;
BEGIN
  clrscr;
  status('Zufallsgenerator-Typ auswählen');
  writeln('       Wählen Sie eine der allgemeinen Formen, deren Parameter Sie');
  writeln('       anschließend festlegen können.');
  writeln;
  writeln;
  writeln('   1   Verlängerung von Folgen          Seite  6');
  writeln('   2   Quadratmittengenerator                  7');
  writeln('   3   Fibonacci-Generator                     9');
  writeln('   4   Multiplikativer Generator               9');
  writeln('   5   Gemischter Generator                    9');
  writeln('   6   RANDOM von TurboPascal                 17');writeln;
  writeln('   7   zurück ins Hauptmenü');writeln;
  wahl:=zahleingabe(19,8,'Wählen Sie: ',0,1,7,1);
  definiert:=1;    (* Ich gehe davon aus, daß ein Generator definiert wird *)
  case wahl of
    1: folgen;
    2: quami;
    3: fibonacci;
    4: multiplik;
    5: gemischt;
    6: tubo_random;
    7: definiert:=0; (* doch nicht... *)
  end;
  (* ... also zurück ins Hauptmenü *)
END;

(* Diese Prozedur wandelt eine Zahlenliste in eine Tabelle (z.B. zum Drucken) um *)
procedure zliste_zu_tabelle;
var name,neuname,hilfsvar,txt,generator,kommentar:string;
    tupel,zahl,stelle,tupeli,tupelprozeile,fortschritt,diff:integer;
    umfang,ii:longint;
    dat,tab:text; (* dateien *)
BEGIN
  clrscr;
  status('Zufallszahlenliste in Tabelle umwandeln');
  name:=name_zum_laden('Wählen Sie eine Zufallszahlenliste','ZUF');
  clrscr;
  hilfsvar:=concat('Liste ',name,' in Tabelle umwandeln');
  status(hilfsvar);

  write(' Datei wird geöffnet... ');
  assign(dat,name);
  reset(dat);
  readln(dat,txt);
  if txt<>'Hinweise zur Datei' then
  BEGIN
    writeln('Falsche Datei!');
  END else
  BEGIN (* ich rücke nicht weiter ein: ELSE-Teil vom IF-Block *)

  writeln('OK.');
  readln(dat,txt);
  readln(dat,umfang);
  readln(dat,generator);
  writeln(' ',umfang,' Zahlen ',generator);
  readln(dat,txt);
  readln(dat,kommentar);
  writeln(' Kommentar zum Generator:');
  writeln(' ',kommentar);

  writeln;
  writeln(' Sie können die Liste nun in eine Tabelle mit folgendem Format umwandeln:');
  writeln;
  writeln(' xxxx xxxx xxxx usw. bis an den Seitenrand');
  writeln(' xxxx xxxx xxxx usw.');
  writeln(' usw.');
  writeln;
  tupel:=zahleingabe(16,2,'Wieviele Ziffern sollen zu einer Gruppe zusammengefaßt werden? ',1,1,10,1);
  neuname:=name;
  delete(neuname,length(name)-3,4);
  neuname:=concat(neuname,'.TAB');
  if datei_existiert(neuname)=true then
  BEGIN
    neuname:=name_zum_speichern(18,2,'Unter welchem Namen soll die Tabelle gespeichert werden? ','TAB');
  END else
  BEGIN
    writeln;
    writeln(' Die Tabelle wird unter dem Namen ',neuname,' gespeichert.');
  END;

  assign(tab,neuname); (* Tabellendatei anlegen *)
  rewrite(tab);
  writeln(tab,umfang,' Zufallszahlen,');
  writeln(tab,generator);
  writeln(tab,kommentar);
  writeln(tab,'-------------------------------------------------------------------------------');

  diff:=0;
  stelle:=0;
  tupeli:=0;

  for ii:=1 to umfang do
  BEGIN
    inc(tupeli);
    inc(stelle);
    if tupeli>tupel then
    BEGIN
      tupeli:=1;
      if (stelle+tupel)>79 then (* Wenn das nächste Tupel nicht mehr in die Zeile paßt *)
      BEGIN
        writeln(tab,' '); (* writeLN und Leerzeichen *)
        stelle:=1;
      END else
      BEGIN
        write(tab,' '); (* ansonsten nur ein Leerzeichen *)
        inc(stelle); (* Leerzeichen mitzählen *)
      END;
    END;
    readln(dat,zahl); (* Zahl einlesen *)
    write(tab,zahl); (* und speichern *)

    fortschritt:=(ii*100) div umfang;
    if fortschritt<> diff then
    BEGIN
      GotoXY(38,21);
      write(fortschritt,'%');
      diff:=fortschritt;
    END;
  END;
  close(tab);
  close(dat);
  END; (* vom IF-Block *)
  writeln;
  wart_auf_taste;
END;

function menue:integer;
BEGIN
  writeln;
  writeln('       Definieren Sie einen Generator und erzeugen Sie Zufallszahlen, um');
  writeln('       sie anschließend mit einer Testmethode zu überprüfen.');writeln;
  writeln('   1   Einen Generator definieren und Zahlen erzeugen');writeln;
  writeln('   2   Eine Liste von Zahlen auf Gleichverteilung testen (',chq,'-Test)');writeln;
  writeln('   3   Eine Liste von Zahlen auf Unabhängigkeit testen (Poker-Test)');writeln;
  writeln('   4   Eine Liste gespeicherter Zahlen in eine Tabelle umwandeln');writeln;
  writeln('   5   Das Programm beenden');writeln;
  menue:=zahleingabe(19,8,'Wählen Sie: ',0,1,5,1);
END;

(* HAUPTPROGRAMM bzw. HAUPTMENÜ *)
BEGIN
  ende:=0;
  aktuelle_datei:='';
  zliste_existiert:=0;
  clrscr;
  begrues; (* Begrüßungsbildschirm *)
  clrscr;

REPEAT (* wird beim Beenden verlassen *)

  (* Prüfen, ob es überhaupt eine ZUF-Datei gibt *)
  (* Wenn es keine gibt, wird das Testen deaktivert *)
  zuf_exist:=dat_pruefen('ZUF');
  if zuf_exist=0 then
  BEGIN
    if zliste_existiert=0 then
    BEGIN
      stat:='Sie haben seit Programmstart keine Zufallszahlendatei bearbeitet.';
    END else
    BEGIN
      stat:=concat('Die aktuelle Datei ist "',aktuelle_datei,'".');
    END;
  END else
  BEGIN
    stat:='Es gibt keine Zufallszahlendatei. Menüpunkte 2, 3 und 4 sind inaktiv!';
  END;

  clrscr;
  status(stat);
  aktion:=menue; (* Hauptmenü anzeigen *)
  if zuf_exist=0 then
  BEGIN
  case aktion of
    1: gen_auswahl;
    2: if dat_pruefen('ZUF')=0 then chiquad;
    3: if dat_pruefen('ZUF')=0 then poker;
    4: if dat_pruefen('ZUF')=0 then zliste_zu_tabelle;
    5: ende:=1;        (* Hier hatte Windows mich einmal überlistet: *)
  end;                 (* Wechselt man aus dem Menü in den Dateimanager *)
  END else             (* von Windows und löscht alle ZUF-Dateien, *)
  BEGIN                (* stürzt das Programm hoffnungslos ab. Jetzt *)
  case aktion of       (* prüfe ich nochmal KURZ vorher, ob die *)
    1: gen_auswahl;    (* Dateien existieren. *)
    5: ende:=1;
    (* keine ZUF-Datei, also Testen deaktiviert *)
  end;
  END;
UNTIL ende=1; (* wird beim Beenden verlassen *)
END.
