% Slots input:
input_slots([40, 32, 60, 79, 35, 46, 18, 100, 20, 2]).
input_startWork(9).
input_endWork(18).

input_maxExtraWorkers(2).

% *** Full time workers: ***

input_fullSalaryPerHour(80).
input_fullBonus(40).

% Lunch hour:
input_lunchHourList([12,13]).

% *** Partial time workers: ***
input_partialWorkHours(3).
input_partialMaxWorkers(6).
input_partialWorkersRatio(30). %

input_partialSalaryPerHour(50).
input_partialBonus(60).