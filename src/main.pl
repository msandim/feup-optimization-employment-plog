:- use_module(library(clpfd)).
:- use_module(library(lists)).

:- consult(probEx).

% *************************************************************
% ************************* Input *****************************
% *************************************************************
totalWorkHours(NumberHours) :-
        input_slots(SlotsInput),
        length(SlotsInput, NumberHours).

% ********************** Full Workers *************************

fullSalaryBase(Salary) :-
        input_fullSalaryPerHour(PerHour),
        totalWorkHours(Hours),
        Salary is PerHour * Hours.

fullSalaryPlus(Salary) :-
        fullSalaryBase(SalaryBase),
        input_fullBonus(Bonus),
        Salary is SalaryBase + Bonus.

startLunchHour(Start) :-
        input_lunchHourList(Slots),
        nth1(1, Slots, Start).

endLunchHour(End) :-
        input_lunchHourList(Slots),
        length(Slots, LastIndex),
        nth1(LastIndex, Slots, End).

countLunchSlots(Number) :-
        input_lunchHourList(Slots),
        length(Slots, Number).

% ********************* Partial Workers ***********************

partialSalaryBase(Salary) :-
        input_partialSalaryPerHour(PerHour),
        input_partialWorkHours(Hours),
        Salary is PerHour * Hours.

partialSalaryPlus(Salary) :-
        partialSalaryBase(SalaryBase),
        input_partialBonus(Bonus),
        Salary is SalaryBase + Bonus.


% *************************************************************
% ************************** DOMAINS **************************
% *************************************************************

% *************************************************************
% **************** Full Time ****************

% Defines the lunch hours list domain for Full Workers: -2: doesn't work, -1 works at lunch hour
defineLunchHoursDomain([]).
defineLunchHoursDomain([Hour|HourRest]) :-
        startLunchHour(Start),
        endLunchHour(End),
        
        Hour in {-2} \/ {-1} \/ (Start..End),
        defineLunchHoursDomain(HourRest).

% Defines the domain of the possible salaries:
defineFullWorkersSalary([]).
defineFullWorkersSalary([Salary|RSalary]) :-
        fullSalaryBase(SalaryBase),     
        fullSalaryPlus(SalaryPlus),
        
        Salary in {0} \/ {SalaryBase} \/ {SalaryPlus},
        defineFullWorkersSalary(RSalary).

% Defines the domains for the Full Time Decision variables
defineFullDomains(FullWorkersLunchHours, FullWorkersLunching, FullWorkersSalary, NumberFullWorkers, MaxFullWorkers, Slots) :-
        
        countLunchSlots(NumberLunchSlots), % Input

        % The maximum number of workers possible is 2 times the maximum input number:        
        max_member(MaxFullWorkersSlots, Slots),       
        MaxFullWorkers is 2 * MaxFullWorkersSlots,
        
        % Decision variables declaration:
        length(FullWorkersLunchHours, MaxFullWorkers), % Main variable
        length(FullWorkersLunching, NumberLunchSlots), % Auxiliar:
        length(FullWorkersSalary, MaxFullWorkers),
        
        % Domain definition:
        defineLunchHoursDomain(FullWorkersLunchHours),
        domain(FullWorkersLunching, 0, MaxFullWorkers),
        defineFullWorkersSalary(FullWorkersSalary),
        NumberFullWorkers in 0..MaxFullWorkers.


% *************************************************************
% **************** Part time ****************

% Defines the domain for the start hour of the partial worker shift
definePartialHoursDomain([]).
definePartialHoursDomain([Hour|HourRest]) :-
        input_startWork(Start),
        input_endWork(End),
        
        Hour in {-1} \/ (Start..End),
        definePartialHoursDomain(HourRest).

% Defines the domain of the possible salaries:
definePartialWorkersSalary([]).
definePartialWorkersSalary([Salary|RSalary]) :-
        partialSalaryBase(SalaryBase),     
        partialSalaryPlus(SalaryPlus),
        
        Salary in {0} \/ {SalaryBase} \/ {SalaryPlus},
        definePartialWorkersSalary(RSalary).

% Defines the domains for the Partial Time Decision variables
definePartialDomains(PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, PartialWorkersPerSlot, PartialWorkersExists, Slots) :-
        totalWorkHours(NumberSlots),
        input_partialMaxWorkers(MaxPartialWorkersRes),
        
        % The maximum number of workers possible is minimum(2 times the maximum slot number, rescrited value from the input):        
        max_member(MaxPartialWorkersSlots, Slots),       
        MaxPartialWorkersInput is 2 * MaxPartialWorkersSlots,
        min_member(MaxPartialWorkers, [MaxPartialWorkersInput, MaxPartialWorkersRes]),
        
        % Decision variables declaration:
        length(PartialWorkersStartHour, MaxPartialWorkers), % Main variables
        length(PartialWorkersExtraHour, MaxPartialWorkers),
        length(PartialWorkersSalary, MaxPartialWorkers), % Auxiliar
        length(PartialWorkersPerSlot, NumberSlots),
        length(PartialWorkersExists, MaxPartialWorkers),
        
        % Domain definition:
        definePartialHoursDomain(PartialWorkersStartHour),
        domain(PartialWorkersExtraHour, 0, 1),
        definePartialWorkersSalary(PartialWorkersSalary),
        domain(PartialWorkersPerSlot, 0, MaxPartialWorkers),
        domain(PartialWorkersExists, 0, 1).

% ************************************************************************
% ***************************** RESTRICTIONS *****************************
% ************************************************************************

% ****************************************************************
% **************** Full Time Workers Restrictions ****************

% Applies the restrictions to the full workers decision variables
applyFullRestrictions(FullWorkersLunchHours, FullWorkersLunching, FullWorkersSalary, NumberFullWorkers, MaxFullWorkers, NoLunchOut) :-
        input_lunchHourList(LunchHours),
        
        fullSalaryBase(SalaryBase), fullSalaryPlus(SalaryPlus),
        
        % Ensure order on the lunch hours (avoid symmetric solutions):
        restrictOrderedList(FullWorkersLunchHours),
        
        % Restrict the salary according to the value in the lunch hour (also get non-Workers and non-Lunch workers):
        restrictFullHours(FullWorkersLunchHours, FullWorkersSalary),
        global_cardinality(FullWorkersSalary, [0-NoWorkersCount, SalaryBase-_, SalaryPlus-NoLunchOut]),
        
        % Count the number of full workers on each lunching slot:
        countWorkersLunching(LunchHours, FullWorkersLunchHours, FullWorkersLunching),
        
        % Restrict the number of real workers:
        NumberFullWorkers #= MaxFullWorkers - NoWorkersCount.

% Restricts the full workers salary according to FullWorkerLunchHour decision variable (also count non worker and non lunch workers)
restrictFullHours([], []).
restrictFullHours([FullWorkerLunchHour|RFullWorkerLunchHour], [Salary|RSalary]) :-
        fullSalaryBase(SalaryBase), fullSalaryPlus(SalaryPlus),
        
        (FullWorkerLunchHour #= -2 #/\ Salary #= 0) #\/
        (FullWorkerLunchHour #= -1 #/\ Salary #= SalaryPlus) #\/
        (FullWorkerLunchHour #>= 0 #/\ Salary #= SalaryBase),

        restrictFullHours(RFullWorkerLunchHour, RSalary).

% Counts the number of full workers lunching on each of the possible lunch hours
countWorkersLunching([], _, []).
countWorkersLunching([LunchHour|RLunchHours], FullWorkersLunchHours, [FullWorkersLunching|RFullWorkersLunching]) :-
        countWorkersLunchingAux(LunchHour, FullWorkersLunchHours, FullWorkersLunching),

        countWorkersLunching(RLunchHours, FullWorkersLunchHours, RFullWorkersLunching).

countWorkersLunchingAux(_, [], 0).      
countWorkersLunchingAux(LunchHour, [FullWorkerLunchHour|RFullWorkerLunchHour], FullWorkersLunchingOut) :-
        (FullWorkerLunchHour #= LunchHour) #<=> Bool,
        FullWorkersLunchingOut #= FullWorkersLunchingNext + Bool,

        countWorkersLunchingAux(LunchHour, RFullWorkerLunchHour, FullWorkersLunchingNext).


% *******************************************************************
% **************** Partial Time Workers Restrictions ****************

% Applies the restrictions to the partial workers decision variables
applyPartialRestrictions(PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, PartialWorkersPerSlot, PartialWorkersExists) :-
        input_startWork(StartHour),
        
        % Ensure order on the start hours:
        restrictOrderedList(PartialWorkersStartHour),

        restrictPartialHours(PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, PartialWorkersExists),
        restrictPartialSlots(StartHour, PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersPerSlot).

% Restricts the full workers salary (and PartialWorkersExist) according to the StartHour and ExtraHour decision variable
restrictPartialHours([], [], [], []).
restrictPartialHours([StartHour|RStartHour], [ExtraHour|RExtraHour], [Salary|RSalary], [PartialWorkersExists|RPartialWorkersExits]) :-
        partialSalaryBase(SalaryBase), partialSalaryPlus(SalaryPlus),
        
        (StartHour #> -1 #/\ ExtraHour #= 0 #/\ Salary #= SalaryBase #/\ PartialWorkersExists #= 1) #\/ 
        (StartHour #> -1 #/\ ExtraHour #= 1 #/\ Salary #= SalaryPlus #/\ PartialWorkersExists #= 1)  #\/
        (StartHour #= -1 #/\ ExtraHour #= 0 #/\ Salary #= 0 #/\ PartialWorkersExists #= 0),

        restrictPartialHours(RStartHour, RExtraHour, RSalary, RPartialWorkersExits).

% Counts the number of partial workers on each Time Slot
restrictPartialSlots(_, _, _, []).
restrictPartialSlots(StartHour, PartialWorkersStartHour, PartialWorkersExtraHour, [PartialWorkersPerSlot|RPartialWorkersPerSlot]) :-
        restrictPartialSlotsAux(StartHour, PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersPerSlot),

        NextHour is StartHour + 1,
        restrictPartialSlots(NextHour, PartialWorkersStartHour, PartialWorkersExtraHour, RPartialWorkersPerSlot).

restrictPartialSlotsAux(_, [], [], 0).
restrictPartialSlotsAux(CurrentHour, [StartHour|RStartHour], [ExtraHour|RExtraHour], PartialWorkersPerSlotOut) :-
        input_partialWorkHours(MaxHours),
        
        ((CurrentHour #>= StartHour #/\ CurrentHour #=< StartHour + MaxHours - 1 #/\ ExtraHour #= 0) #\/
        (CurrentHour #>= StartHour #/\ CurrentHour #=< StartHour + MaxHours #/\ ExtraHour #= 1)) #<=> Number,
        PartialWorkersPerSlotOut #= Number + NumberTemp,

        restrictPartialSlotsAux(CurrentHour, RStartHour, RExtraHour, NumberTemp).


% *************************************************************
% **************** Common Workers Restrictions ****************

% Ensures that the list is ordered (used to avoid symmetric solutions)
restrictOrderedList(List) :-
        length(List, ListSize),
        length(Xs, ListSize),
        length(Ps, ListSize),
            
        sorting(Xs,Ps,List).

% Applies the restrictions to the full/partial workers decision variables
applyCommonRestrictions(NoLunch, FullWorkersLunching, NumberFullWorkers, PartialWorkersExtraHour, PartialWorkersPerSlot, PartialWorkersExists, Slots, NumberPartialWorkers) :-
        input_startWork(StartHour),
        input_lunchHourList(LunchHours),
        input_maxExtraWorkers(MaxExtraWorkers),
        input_partialWorkersRatio(PartialRatio),
        
        % Restrict the number of full workers with no lunch + partial workers with extra hour:
        sum(PartialWorkersExtraHour, #=, TotalExtraHour),
        TotalExtraHour + NoLunch #=< MaxExtraWorkers,
        
        % Restrict the ratio of full/partial workers:
        sum(PartialWorkersExists, #=, NumberPartialWorkers),
        NumberPartialWorkers #=< (PartialRatio * NumberFullWorkers) // 100, % HARCODED
        
        % Restricts the number of total workers on each Time Slot (has to be at minimum the original Time Slot)
        restrictSlots(StartHour, LunchHours, FullWorkersLunching, NumberFullWorkers, PartialWorkersPerSlot, Slots).


restrictSlots(_, [], [], _, [], []).

% If lunch time, restrict current slot and advance all lists:
restrictSlots(CurrentHour, [LunchHour|RLunchHours], [FullWorkersLunching|RFullWorkersLunching], NumberFullWorkers, [PartialWorkersPerSlot|RPartialWorkersPerSlot], [CurrentSlot|RSlots]) :-
        CurrentHour = LunchHour,
        CurrentSlot #=< (NumberFullWorkers - FullWorkersLunching) + PartialWorkersPerSlot,

        NextHour is CurrentHour + 1,
        restrictSlots(NextHour, RLunchHours, RFullWorkersLunching, NumberFullWorkers, RPartialWorkersPerSlot, RSlots).

% If not lunch time, restrict current slot and advance PartialWorkersPerSlot list and Slots list:
restrictSlots(CurrentHour, LunchHours, FullWorkersLunching, NumberFullWorkers, [PartialWorkersPerSlot|RPartialWorkersPerSlot], [CurrentSlot|RSlots]) :-
        CurrentSlot #=< NumberFullWorkers + PartialWorkersPerSlot,

        NextHour is CurrentHour + 1,
        restrictSlots(NextHour, LunchHours, FullWorkersLunching, NumberFullWorkers, RPartialWorkersPerSlot, RSlots).

% *************************************************************
% **************** Solution Cost Calculation ******************
calculateCost(FullWorkersSalary, PartialWorkersSalary, TotalSalary) :-
        sum(FullWorkersSalary, #=, TotalFullWorkersSalary),
        sum(PartialWorkersSalary, #=, TotalPartialWorkersSalary),
        TotalSalary #= TotalFullWorkersSalary + TotalPartialWorkersSalary.

% *************************************************************
% ********************** Solution Search **********************
searchSolution(FullWorkersLunchHours, PartialWorkersStartHour, PartialWorkersExtraHour, TotalSalary) :-
        append([FullWorkersLunchHours, PartialWorkersStartHour, PartialWorkersExtraHour], Vars),
        
        write('Labeling...'),
        labeling([ffc, step, up, minimize(TotalSalary)], Vars).


% *************************************************************
% ********************** Final Slot Calculation ***************

calculateFinalSolution(FullWorkersLunching, NumberFullWorkers, PartialWorkersPerSlot, FinalSlots) :- 
        totalWorkHours(SlotNumber),
        input_startWork(StartHour),
        input_lunchHourList(LunchSlots),
           
        length(FinalSlots, SlotNumber),
        
        calculateFinalSlots(StartHour, LunchSlots, FullWorkersLunching, NumberFullWorkers, PartialWorkersPerSlot, FinalSlots).

calculateFinalSlots(_, [], [], _, [], []).
calculateFinalSlots(CurrentHour, [LunchHour|RLunchHours], [FullWorkersLunching|RFullWorkersLunching], NumberFullWorkers, [PartialWorkersPerSlot|RPartialWorkersPerSlot], [FinalSlot|RFinalSlots]) :-
        CurrentHour = LunchHour,
        FinalSlot is NumberFullWorkers - FullWorkersLunching + PartialWorkersPerSlot,

        NextHour is CurrentHour + 1,
        calculateFinalSlots(NextHour, RLunchHours, RFullWorkersLunching, NumberFullWorkers, RPartialWorkersPerSlot, RFinalSlots).

calculateFinalSlots(CurrentHour, LunchHours, FullWorkersLunching, NumberFullWorkers, [PartialWorkersPerSlot|RPartialWorkersPerSlot], [FinalSlot|RFinalSlots]) :-
        FinalSlot is NumberFullWorkers + PartialWorkersPerSlot,

        NextHour is CurrentHour + 1,
        calculateFinalSlots(NextHour, LunchHours, FullWorkersLunching, NumberFullWorkers, RPartialWorkersPerSlot, RFinalSlots).
        
                              
              

% ***************************************************************
% ******************* MAIN SOLVER *******************************
% ***************************************************************

schedule :-
        prepareStatistics,

        input_slots(SlotsInput),
        
        % Define decision variables domains:
        defineFullDomains(FullWorkersLunchHours, FullWorkersLunching, FullWorkersSalary, NumberFullWorkers, MaxFullWorkers, SlotsInput),
        definePartialDomains(PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, PartialWorkersPerSlot, PartialWorkersExists, SlotsInput),
        
        % Apply restrictions:
        applyFullRestrictions(FullWorkersLunchHours, FullWorkersLunching, FullWorkersSalary, NumberFullWorkers, MaxFullWorkers, NoLunch),
        applyPartialRestrictions(PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, PartialWorkersPerSlot, PartialWorkersExists),
        applyCommonRestrictions(NoLunch, FullWorkersLunching, NumberFullWorkers, PartialWorkersExtraHour, PartialWorkersPerSlot, PartialWorkersExists, SlotsInput, NumberPartialWorkers),
        
        % Calculate solution cost:
        calculateCost(FullWorkersSalary, PartialWorkersSalary, TotalSalary),
        
        % Label variables according to the best solution possible and calculate the final slots:
        searchSolution(FullWorkersLunchHours, PartialWorkersStartHour, PartialWorkersExtraHour, TotalSalary),
        calculateFinalSolution(FullWorkersLunching, NumberFullWorkers, PartialWorkersPerSlot, FinalSlots),
        
        % Show the time passed:
        showStatistics,   
        
        % Debug:
        %write('Full Workers Lunch Hours: '), write(FullWorkersLunchHours), nl,
        %write('Full Workers Lunching: '), write(FullWorkersLunching), nl,
        %write('Full Workers Salary: '), write(FullWorkersSalary), nl,
        %write('NumberFullWorkers: '), write(NumberFullWorkers), nl,
        %write('Partial Workers Start Hour: '), write(PartialWorkersStartHour), nl,
        %write('Partial Workers Extra Hour: '), write(PartialWorkersExtraHour), nl,
        %write('Partial Workers Salary: '), write(PartialWorkersSalary), nl,
        %write('Partial Workers Per Slot: '), write(PartialWorkersPerSlot), nl,
        
        % **** Display optimal solution: ****
        printSolution(FinalSlots, NoLunch, NumberFullWorkers, FullWorkersLunching,
                      PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, NumberPartialWorkers,
                      TotalSalary).  


%slotsEx(Slots) :- Slots = [4, 3, 3, 6, 5, 6, 8, 8].
%slotsEx2(Slots) :- Slots = [2, 2, 2, 2, 2, 2, 2, 2].
%slotsEx3(Slots) :- Slots = [3, 3, 3, 3, 3, 3, 3, 3].
%slotsBig(Slots) :- Slots = [100, 100, 100, 100, 100, 100, 100, 100].
%slotsBig2(Slots) :- Slots = [40, 50, 40, 70, 50, 60, 30, 20].


% *************************************************************************
% ******************************** PRINT ********************************** 
% *************************************************************************

% Prints the solution: textual, final timetable and graphical solution:
printSolution(FinalSlots, NoLunch, NumberFullWorkers, FullWorkersLunching, PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, NumberPartialWorkers, TotalSalary) :-
        input_lunchHourList(LunchSlots),
        input_startWork(StartHour),
        input_endWork(EndHour),
        
        write('*** Solution ***'), nl, nl,
       
        % Print textual information regarding the full and partial workers shifts:
        write('* Textual display of the schedule for each type of worker: '), nl,        
        printFullWorkers(LunchSlots, NoLunch, NumberFullWorkers, FullWorkersLunching), nl,
        printPartialWorkers(PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, NumberPartialWorkers), nl,
        
        printTimetable(StartHour, EndHour, FinalSlots), nl, nl,
        printScheduleBoard(StartHour, EndHour, LunchSlots, FullWorkersLunching, NoLunch, PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary), nl,
        
        write('Total Salary Cost: '), write(TotalSalary), nl.
        
% ***********************************************
% ************** Textual Solution ***************
% ***********************************************        
printFullWorkers(LunchHours, NoLunch, NumberFullWorkers, FullWorkersLunching) :-
        fullSalaryPlus(SalaryPlus),
        
        write(NumberFullWorkers), write(' full workers'), nl,
        write('-> '), write(NoLunch), write(' full workers do extra hour at lunch and receive a salary of '), write(SalaryPlus), nl,
        
        printFullWorkersLunching(LunchHours, FullWorkersLunching).

printFullWorkersLunching([], []).
printFullWorkersLunching([LunchHour|RLunchHour], [FullWorkersLunching|RFullWorkersLunching]) :-
        fullSalaryBase(SalaryBase),
        
        write('-> '), write(FullWorkersLunching), write(' full workers lunch at '), write(LunchHour), write(' and receive a salary of '), write(SalaryBase), nl,
        printFullWorkersLunching(RLunchHour, RFullWorkersLunching).

printPartialWorkers(PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary, NumberPartialWorkers) :-
        write(NumberPartialWorkers), write(' partial workers'), nl,
        printPartialWorkersAux(PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary).

printPartialWorkersAux([], [], []).
printPartialWorkersAux([StartHour|RStartHour], [ExtraHour|RExtraHour], [Salary|RSalary]) :-
        StartHour > -1,
        calculateEndHour(StartHour, ExtraHour, EndHour),
        write('-> A partial worker starts at '), write(StartHour), write(', ends at '), write(EndHour), write(' and receives a salary of '), write(Salary), nl,
        printPartialWorkersAux(RStartHour, RExtraHour, RSalary).
printPartialWorkersAux([_|RStartHour], [_|RExtraHour], [_|RSalary]) :-
        printPartialWorkersAux(RStartHour, RExtraHour, RSalary).


calculateEndHour(StartHour, 0, EndHourOut) :-
        input_partialWorkHours(Hours),
        EndHourOut is StartHour + Hours.
calculateEndHour(StartHour, 1, EndHourOut) :-
        input_partialWorkHours(Hours),
        EndHourOut is StartHour + Hours + 1.


% **********************************************
% ************** Final Timetable ***************
% **********************************************
printTimetable(StartHour, LastHour, Slots) :-
        nl, write('* Final timetable: '), nl,
        write('Hours      '), printHours(StartHour, LastHour), nl,
        write('Workers    '), printSlots(StartHour, LastHour, Slots), nl.

printHours(CurrentHour, LastHour) :-
        CurrentHour =< LastHour,
        format("~5|~d~5+", [CurrentHour]),

        NextHour is CurrentHour + 1,
        printHours(NextHour, LastHour).
printHours(_, _).

printSlots(_, _, []).
printSlots(CurrentHour, LastHour, [CurrentSlot|RSlots]) :-
        CurrentHour =< LastHour,
        format("~5|~d~5+", [CurrentSlot]),

        NextHour is CurrentHour + 1,
        printSlots(NextHour, LastHour, RSlots).

% **********************************************
% ************** Schedual Board ****************
% **********************************************
printScheduleBoard(StartHour, LastHour, LunchHours, FullWorkersLunching, NoLunch, PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary) :-
        fullSalaryBase(SalaryBase),
        fullSalaryPlus(SalaryPlus),
        
        write('* Graphical solution of all the workers\' schedule:'), nl,
        
        printHours(StartHour, LastHour), write('Salary'), nl,
        printFullWorkersLunching(StartHour, LastHour, LunchHours, FullWorkersLunching, SalaryBase),
        printFullWorkersNoLunch(StartHour, LastHour, NoLunch, SalaryPlus),
        printPartialWorkersX(StartHour, LastHour, PartialWorkersStartHour, PartialWorkersExtraHour, PartialWorkersSalary).

printFullWorkersLunching(_, _, [], [], _).
printFullWorkersLunching(StartHour, LastHour, [LunchHour|RLunchHour], [FullWorkersLunching|RFullWorkersLunching], Salary) :-
        printFullWorkersAtLunchX(StartHour, LastHour, LunchHour, FullWorkersLunching, Salary),
        printFullWorkersLunching(StartHour, LastHour, RLunchHour, RFullWorkersLunching, Salary).

printFullWorkersAtLunchX(_, _, _, 0, _).
printFullWorkersAtLunchX(StartHour, LastHour, LunchHour, Counter, Salary) :-
        printFullWorkerAtLunchX(StartHour, LastHour, LunchHour), format("~5|~d~5+", [Salary]), nl,

        NextCounter is Counter - 1,
        printFullWorkersAtLunchX(StartHour, LastHour, LunchHour, NextCounter, Salary).

printFullWorkerAtLunchX(CurrentHour, LastHour, LunchHour) :-
        CurrentHour =< LastHour,
        CurrentHour = LunchHour,
        format("~5|~s~5+", [" "]),

        NextHour is CurrentHour + 1,
        printFullWorkerAtLunchX(NextHour, LastHour, LunchHour).
printFullWorkerAtLunchX(CurrentHour, LastHour, LunchHour) :-
        CurrentHour =< LastHour,
        format("~5|~s~5+", ["X"]),

        NextHour is CurrentHour + 1,
        printFullWorkerAtLunchX(NextHour, LastHour, LunchHour).
printFullWorkerAtLunchX(_, _, _).

printFullWorkersNoLunch(_, _, 0, _).
printFullWorkersNoLunch(StartHour, LastHour, NoLunch, Salary) :-
        printFullWorkerExtraHour(StartHour, LastHour), format("~5|~d~5+", [Salary]), nl,

        NextNoLunch is NoLunch - 1,
        printFullWorkersNoLunch(StartHour, LastHour, NextNoLunch, Salary).

printFullWorkerExtraHour(CurrentHour, LastHour) :-
        CurrentHour =< LastHour,
        format("~5|~s~5+", ["X"]),

        NextHour is CurrentHour + 1,
        printFullWorkerExtraHour(NextHour, LastHour).
printFullWorkerExtraHour(_, _).

printPartialWorkersX(_, _, [], [], []).
printPartialWorkersX(StartHour, LastHour, [PartialWorkersStartHour|RPartialWorkersStartHour], [PartialWorkersExtraHour|RPartialWorkersExtraHour], [Salary|RSalary]) :-
        PartialWorkersStartHour >= 0,
        printPartialWorkerX(StartHour, LastHour, PartialWorkersStartHour, PartialWorkersExtraHour), format("~5|~d~5+", [Salary]), nl,
        printPartialWorkersX(StartHour, LastHour, RPartialWorkersStartHour, RPartialWorkersExtraHour, RSalary).
printPartialWorkersX(StartHour, LastHour, [_|RPartialWorkersStartHour], [_|RPartialWorkersExtraHour], [_|RSalary]) :-
        printPartialWorkersX(StartHour, LastHour, RPartialWorkersStartHour, RPartialWorkersExtraHour, RSalary).

printPartialWorkerX(CurrentHour, LastHour, PartialWorkerStartHour, PartialWorkerExtraHour) :-
        input_partialWorkHours(PartialHours),
        
        CurrentHour =< LastHour,
        CurrentHour >= PartialWorkerStartHour,
        PartialWorkerExtraHour = 0,
        CurrentHour =< PartialWorkerStartHour + PartialHours - 1,
        format("~5|~s~5+", ["X"]),

        NextHour is CurrentHour + 1,
        printPartialWorkerX(NextHour, LastHour, PartialWorkerStartHour, PartialWorkerExtraHour).
printPartialWorkerX(CurrentHour, LastHour, PartialWorkerStartHour, PartialWorkerExtraHour) :-
        input_partialWorkHours(PartialHours),
        
        CurrentHour =< LastHour,
        CurrentHour >= PartialWorkerStartHour,
        PartialWorkerExtraHour = 1,
        CurrentHour =< PartialWorkerStartHour + PartialHours,
        format("~5|~s~5+", ["X"]),

        NextHour is CurrentHour + 1,
        printPartialWorkerX(NextHour, LastHour, PartialWorkerStartHour, PartialWorkerExtraHour).
printPartialWorkerX(CurrentHour, LastHour, PartialWorkerStartHour, PartialWorkerExtraHour) :-
        CurrentHour =< LastHour,
        format("~5|~s~5+", [" "]),

        NextHour is CurrentHour + 1,
        printPartialWorkerX(NextHour, LastHour, PartialWorkerStartHour, PartialWorkerExtraHour).
printPartialWorkerX(_, _, _, _).


% **************************************************************
% ************************* STATISTICS *************************
% **************************************************************

prepareStatistics :-
        fd_statistics(resumptions, _),
        fd_statistics(entailments, _),
        fd_statistics(prunings, _),
        fd_statistics(backtracks, _),
        fd_statistics(constraints, _),
        statistics(total_runtime, _).

showStatistics :-
        nl, nl, write('*** Sicstus: Statistics ***'), nl,
        %fd_statistics,
        statistics(total_runtime,[_,Time]),
        write('Time passed (ms): '),  write(Time), nl, nl, nl.