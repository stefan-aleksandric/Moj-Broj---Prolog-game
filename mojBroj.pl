:- use_module(library(random)). % Za generisanje random brojeva u opsezima koji se koriste

% Dinamički predikat za praćenje poena igrača
:- dynamic scores/2.
scores(0, 0).  % Početni poeni igrača 1 i igrača 2

% Generisanje nasumičnog broja između Min i Max
random_number(Min, Max, Num) :-
    random_between(Min, Max, Num).

% Generisanje šest manjih brojeva
generate_numbers(Numbers) :-
    findall(X, (between(1, 4, _), random_number(1, 9, X)), SingleDigitNumbers),
    random_number(10, 49, BiggerNumber1),
    random_number(50, 100, BiggerNumber2),
    append(SingleDigitNumbers, [BiggerNumber1, BiggerNumber2], Numbers).

% Generisanje ciljnog broja i šest brojeva koji se koriste za igru
start_game(Target, Numbers) :-
    random_number(100, 999, Target),
    generate_numbers(Numbers).

% Proverava da li je izraz dobar
check_expression(Expression, Result) :- 
    catch(
        ( Result is Expression, 
          ( integer(Result) -> true ; fail)  % Proverava da li je rezultat celi broj
        ),
        _,
        fail
    ).

% Proverava validnost izraza u odnosu na dostupne brojeve
valid_expression(Expression, AvailableNumbers) :-
    extract_numbers(Expression, UsedNumbers),
    valid_number_usage(UsedNumbers, AvailableNumbers).

% Broji koliko puta se element pojavljuje u listi
count(_, [], 0).
count(X, [X | Tail], Count) :-
    count(X, Tail, TempCount),
    Count is TempCount + 1.
count(X, [_ | Tail], Count) :-
    count(X, Tail, Count).

% Ekstraktovanje svih brojeva iz izraza u listu
extract_numbers(Expression, Numbers) :-
    (   number(Expression) ->
        Numbers = [Expression];
        Expression =.. [_Op | Args],
        extract_numbers_from_list(Args, Numbers)
    ).

% Ekstraktovanje brojeve iz liste argumenata
extract_numbers_from_list([], []).
extract_numbers_from_list([Arg | Rest], Numbers) :-
    extract_numbers(Arg, NumbersArg),
    extract_numbers_from_list(Rest, NumbersRest),
    append(NumbersArg, NumbersRest, Numbers).

% Proverava da li su svi argumenti u listi dostupnih brojeva
valid_args([], _).
valid_args([Arg | Rest], Numbers) :-
    (   number(Arg) ->
        member(Arg, Numbers)
    ;   Arg =.. [Op | Args],
        member(Op, [+,-,*,/]),
        valid_args(Args, Numbers)
    ),
    valid_args(Rest, Numbers).

% Proverava da li su brojevi korišćeni validno u odnosu na dostupne brojeve
valid_number_usage([], _).
valid_number_usage([Number | Rest], AvailableNumbers) :-
    count(Number, AvailableNumbers, AvailableCount),   % Koliko puta je broj dostupan
    count(Number, [Number | Rest], UsedCount),         % Koliko puta je broj korišćen
    UsedCount =< AvailableCount,                       % Korišćenje broja ne sme biti više od dostupnog
    delete_one(AvailableNumbers, Number, NewAvailable),  % Ukloni jedan broj iz liste dostupnih brojeva
    valid_number_usage(Rest, NewAvailable).            % Proveri ostatak

% Uklanja jedno pojavljivanje broja iz liste
delete_one([X | Tail], X, Tail).
delete_one([Y | Tail], X, [Y | NewTail]) :-
    delete_one(Tail, X, NewTail).

% Logika za početak igre
play_game :-
    write('Dobrodošli u igru Moj Broj!'),nl,
    start_game(Target, Numbers),nl,
    write('Ciljni broj: '), write(Target), nl,
    write('Dostupni brojevi: '), write(Numbers), nl,nl,
    play_round(Target, Numbers).

% Logika za jednu rundu
play_round(Target, Numbers) :-
    % Igrač 1
    write('Igrač 1 je na potezu! Unesite izraz koristeći dostupne brojeve i osnovne matematičke operacije(Celi brojevi su samo validni!): '), nl,
    read(Expression1),
    handle_player_input(1, Expression1, Target, Numbers, Result1),
    % Igrač 2
    write('Igrač 2 je na potezu! Unesite izraz koristeći dostupne brojeve i osnovne matematičke operacije(Celi brojevi su samo validni!): '), nl,
    read(Expression2),
    handle_player_input(2, Expression2, Target, Numbers, Result2),
    % Provera pobednika
    check_winner(Result1, Result2, Target),
    % Ispis trenutnih poena
    print_scores,
    % Pitanje za nastavak igre
    continue_game.

% Obrada unosa igrača
handle_player_input(Player, Expression, Target, Numbers, Result) :-
    (   valid_expression(Expression, Numbers),   % Proveri validnost izraza
        check_expression(Expression, Result) ->  % Proveri rezultat izraza
        nl, write('Igrač '), write(Player), write(' je dobio broj: '), write(Result), nl, nl;
        
        % Ako je nevalidan izraz
        nl, write('Unešeni izraz igrača '), write(Player), write(' nije validan ili su brojevi korišćeni više puta nego što je dostupno.'), nl, nl,
        Result = 0  % Igrač ne dobija poene
    ),
    _ = Target.

% Proverava pobednika na osnovu brojeva
check_winner(Result1, Result2, Target) :-
    (   Result1 =:= Target, Result2 =:= Target -> 
        add_score(1, 5),  % Igrač 1 dobija 5 poena
        add_score(2, 5),  % Igrač 2 dobija 5 poena
        nl,write('Oba igrača su pogodila tačan broj!'), nl;
        Result1 =:= Target -> 
        add_score(1, 10),  % Igrač 1 dobija 10 poena
        nl,write('Igrač 1 je pogodio tačan broj!'), nl;
        Result2 =:= Target -> 
        add_score(2, 10),  % Igrač 2 dobija 10 poena
        nl,write('Igrač 2 je pogodio tačan broj!'), nl;   
        Result1 = 0, Result2 = 0 -> 
        nl,write('Oba igrača su uneli nepravilne izraze.'), nl;
        Result1 =\= 0, Result2 =\= 0 -> 
        Diff1 is abs(Result1 - Target),
        Diff2 is abs(Result2 - Target),
        (   Diff1 < Diff2 -> 
            add_score(1, 5),  % Igrač 1 dobija 5 poena
            nl,write('Igrač 1 je pobedio rundu jer je uneo približniji broj ciljanom broju!'), nl;
            Diff2 < Diff1 -> 
            add_score(2, 5),  % Igrač 2 dobija 5 poena
            nl,write('Igrač 2 je pobedio rundu jer je uneo približniji broj ciljanom broju!'), nl; 
            nl,write('Izjednačenje! Oba igrača su podjednako blizu.'), nl
        );   
        Result1 =:= 0 -> 
        nl,write('Igrač 1 je uneo nepravilni izraz, a igrač 2 je pobedio zbog pravilnog izraz.'), nl,
        add_score(2, 5);  % Igrač 2 dobija 5 poena
        Result2 =:= 0 -> 
        nl,write('Igrač 2 je uneo nepravilni izraz, a igrač 1 pobedio zbog pravilnog izraz.'), nl,
        add_score(1, 5)  % Igrač 1 dobija 5 poena
    ).

% Ažuriranje poena igrača
add_score(Player, Points) :-
    retract(scores(Score1, Score2)),
    (   
        Player == 1 -> NewScore1 is Score1 + Points, NewScore2 = Score2;
        Player == 2 -> NewScore1 = Score1, NewScore2 is Score2 + Points
    ),
    assert(scores(NewScore1, NewScore2)).

% Ispis trenutnih poena nakon svake runde
print_scores :-
    scores(Score1, Score2),
    nl,
    write('Trenutni poeni: '), nl,
    write('Igrač 1: '), write(Score1), nl,
    write('Igrač 2: '), write(Score2), nl.

% Pitanje da li igrači žele da nastave ili završe igru
continue_game :-
    nl,write('Da li želite da završite igru? (da/ne): '), nl,nl,
    read(Response),
    (   Response == da ->
        print_scores,  % Ispis finalnih poena
        nl,
        declare_winner,  % Provera ko je pobednik
        nl,
        write('Kraj igre!')
    ;   Response == ne ->
        play_game
    ).

% Deklariše pobednika na osnovu rezultata
declare_winner :-
    scores(Score1, Score2),
    (   Score1 > Score2 ->
        nl, write('Igrač 1 je pobednik sa osvojenih '), write(Score1), write(' poena!'), nl
    ;   Score2 > Score1 ->
        nl, write('Igrač 2 je pobednik sa osvojenih '), write(Score2), write(' poena!'), nl
    ;   nl, write('Igra je završena nerešeno!'), nl
    ).








